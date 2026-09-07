import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zstandard/zstandard.dart';

import 'archive_safety.dart';

class _StagedMedia {
  final File source;
  final File destination;
  const _StagedMedia(this.source, this.destination);
}

/// A prepared media import. Files are validated and written to a staging
/// directory first; [commit] is called inside the database transaction so a
/// file-system failure also rolls database changes back.
class MediaImportPlan {
  MediaImportPlan._(this._stagingDir, this._items, this.renames);

  final Directory? _stagingDir;
  final List<_StagedMedia> _items;
  final Map<String, String> renames;
  final List<File> _created = [];

  int get mediaCount => renames.length;

  static Future<MediaImportPlan> prepare(Archive archive) async {
    ArchiveFile? find(String name) {
      for (final file in archive.files) {
        if (file.name == name) return file;
      }
      return null;
    }

    final mediaIndex = find('media');
    if (mediaIndex == null) return MediaImportPlan._(null, [], {});
    var indexBytes = Uint8List.fromList((mediaIndex.content as List<int>));
    if (_isZstd(indexBytes)) {
      final declared = zstdDeclaredContentSize(indexBytes);
      if (declared == null || declared > 16 * 1024 * 1024) {
        throw ImportException('Индекс медиа имеет неизвестный или слишком большой размер.');
      }
      indexBytes = await Zstandard().decompress(indexBytes) ?? Uint8List(0);
    }
    if (indexBytes.isEmpty) return MediaImportPlan._(null, [], {});
    if (indexBytes.length > 16 * 1024 * 1024) {
      throw ImportException('Индекс медиа превышает безопасный лимит 16 МБ.');
    }

    final Map<String, dynamic> rawMap;
    try {
      rawMap = jsonDecode(utf8.decode(indexBytes)) as Map<String, dynamic>;
    } on Object {
      throw ImportException('Повреждён индекс медиафайлов.');
    }

    final appDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    await mediaDir.create(recursive: true);
    final staging = Directory(p.join(mediaDir.path, '.import_${DateTime.now().microsecondsSinceEpoch}'));
    await staging.create();

    final items = <_StagedMedia>[];
    final renames = <String, String>{};
    final reservedNames = <String, String>{};
    var stagedIndex = 0;
    try {
      for (final entry in rawMap.entries) {
        if (entry.value is! String) throw ImportException('Некорректное имя медиафайла.');
        final archived = find(entry.key);
        if (archived == null) continue;
        final bytes = Uint8List.fromList((archived.content as List<int>));
        if (bytes.length > maxSingleMediaBytes) {
          throw ImportException('Медиафайл «${entry.value}» превышает безопасный лимит 128 МБ.');
        }

        final originalName = entry.value as String;
        final baseName = p.basename(originalName).trim();
        if (baseName.isEmpty || baseName == '.' || baseName == '..') continue;
        final digest = sha256.convert(bytes).toString();
        final finalName = await _collisionSafeName(mediaDir, baseName, digest, reservedNames);
        reservedNames[finalName] = digest;
        renames[originalName] = finalName;

        final destination = File(p.join(mediaDir.path, finalName));
        if (await destination.exists() && await _digestOfFile(destination) == digest) continue;
        final staged = File(p.join(staging.path, '${stagedIndex++}.media'));
        await staged.writeAsBytes(bytes, flush: true);
        items.add(_StagedMedia(staged, destination));
      }
      return MediaImportPlan._(staging, items, renames);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  String rewriteReferences(String value) {
    var result = value.replaceAllMapped(
      RegExp('''src=["']([^"']+)["']''', caseSensitive: false),
      (match) {
        final original = match.group(1)!;
        final replacement = renames[original];
        return replacement == null ? match.group(0)! : 'src="${htmlEscape.convert(replacement)}"';
      },
    );
    result = result.replaceAllMapped(RegExp(r'\[sound:([^\]]+)\]'), (match) {
      final original = match.group(1)!;
      return '[sound:${renames[original] ?? original}]';
    });
    return result;
  }

  Future<void> commit() async {
    for (final item in _items) {
      if (await item.destination.exists()) {
        if (await _digestOfFile(item.destination) == await _digestOfFile(item.source)) {
          await item.source.delete();
          continue;
        }
        throw ImportException('Конфликт медиафайла «${p.basename(item.destination.path)}».');
      }
      await item.source.rename(item.destination.path);
      _created.add(item.destination);
    }
  }

  Future<void> rollbackFiles() async {
    for (final file in _created.reversed) {
      if (await file.exists()) await file.delete();
    }
    _created.clear();
  }

  Future<void> cleanup() async {
    final staging = _stagingDir;
    if (staging != null && await staging.exists()) await staging.delete(recursive: true);
  }

  static Future<String> _collisionSafeName(
    Directory mediaDir,
    String requested,
    String digest,
    Map<String, String> reservedNames,
  ) async {
    final reservedDigest = reservedNames[requested];
    if (reservedDigest == digest) return requested;
    final direct = File(p.join(mediaDir.path, requested));
    if (reservedDigest == null && (!await direct.exists() || await _digestOfFile(direct) == digest)) {
      return requested;
    }

    final stem = p.basenameWithoutExtension(requested);
    final extension = p.extension(requested);
    for (final prefixLength in [8, 12, 16, 32, 64]) {
      final candidate = '${stem}_${digest.substring(0, prefixLength)}$extension';
      final plannedDigest = reservedNames[candidate];
      if (plannedDigest == digest) return candidate;
      final file = File(p.join(mediaDir.path, candidate));
      if (plannedDigest == null && (!await file.exists() || await _digestOfFile(file) == digest)) return candidate;
    }
    throw ImportException('Не удалось безопасно разрешить конфликт файла «$requested».');
  }

  static Future<String> _digestOfFile(File file) async => (await sha256.bind(file.openRead()).first).toString();

  static bool _isZstd(Uint8List bytes) =>
      bytes.length >= 4 && bytes[0] == 0x28 && bytes[1] == 0xb5 && bytes[2] == 0x2f && bytes[3] == 0xfd;
}
