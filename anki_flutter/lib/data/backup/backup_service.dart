import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';

/// What a backup is for; decides its file name and how long it is kept.
enum BackupKind {
  /// Made automatically, at most once a day. The newest [BackupService.keepAuto] are kept.
  auto,

  /// Made from the Backups screen.
  manual,

  /// Made just before a restore replaced the collection, so a restore can
  /// itself be undone.
  beforeRestore,
}

class BackupInfo {
  const BackupInfo({required this.file, required this.createdAt, required this.kind, required this.sizeBytes});
  final File file;
  final DateTime createdAt;
  final BackupKind kind;
  final int sizeBytes;
}

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Whole-collection backups: the database (every deck, card, review and
/// setting), the media folder (images and pronunciations) and the theme
/// choice, in one zip.
///
/// The database snapshot is taken with SQLite's `VACUUM INTO`, which gives
/// a consistent copy while the app keeps running. Restoring replaces the
/// database file and media folder, then asks the app to reopen the
/// collection ([onReopen]) - no restart needed.
class BackupService {
  BackupService(
    this._db, {
    this.onReopen,
    Future<Directory> Function()? baseDir,
    Future<File> Function()? databaseFile,
  })  : _baseDir = baseDir ?? getApplicationSupportDirectory,
        _databaseFile = databaseFile ?? defaultDatabaseFile;

  final AppDatabase _db;
  final Future<File> Function() _databaseFile;

  /// Closes nothing itself: called after the files were swapped, to open
  /// the restored collection. Null where restore isn't possible (tests).
  final Future<void> Function()? onReopen;
  final Future<Directory> Function() _baseDir;

  static const keepAuto = 10;
  static const autoInterval = Duration(hours: 24);
  static const _manifestName = 'manifest.json';
  static const _dbEntry = 'collection.sqlite';
  static const _settingsEntry = 'settings.json';

  /// Where the database lives (drift_flutter's default for `anki_flutter`).
  static Future<File> defaultDatabaseFile() async =>
      File(p.join((await getApplicationDocumentsDirectory()).path, 'anki_flutter.sqlite'));

  Future<Directory> backupsDir() async {
    final dir = Directory(p.join((await _baseDir()).path, 'backups'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _mediaDir() async => Directory(p.join((await _baseDir()).path, 'media'));

  Future<File> _settingsFile() async => File(p.join((await _baseDir()).path, 'settings.json'));

  // --- creating ------------------------------------------------------------

  Future<BackupInfo> create({BackupKind kind = BackupKind.manual, DateTime? now}) async {
    final at = now ?? DateTime.now();
    final dir = await backupsDir();
    final tmp = File(p.join(dir.path, '.snapshot-${at.microsecondsSinceEpoch}.sqlite'));
    try {
      final escaped = tmp.path.replaceAll("'", "''");
      await _db.customStatement("VACUUM INTO '$escaped'");

      final archive = Archive()..addFile(ArchiveFile.bytes(_dbEntry, await tmp.readAsBytes()));
      final media = await _mediaDir();
      var mediaFiles = 0;
      if (await media.exists()) {
        await for (final f in media.list()) {
          if (f is File) {
            archive.addFile(ArchiveFile.bytes('media/${p.basename(f.path)}', await f.readAsBytes()));
            mediaFiles++;
          }
        }
      }
      final settings = await _settingsFile();
      if (await settings.exists()) {
        archive.addFile(ArchiveFile.bytes(_settingsEntry, await settings.readAsBytes()));
      }
      final counts = await _counts();
      archive.addFile(ArchiveFile.bytes(
        _manifestName,
        utf8.encode(jsonEncode({
          'app': 'Anki (anki_flutter)',
          'schemaVersion': _db.schemaVersion,
          'createdAt': at.toIso8601String(),
          'kind': kind.name,
          'decks': counts.$1,
          'cards': counts.$2,
          'mediaFiles': mediaFiles,
        })),
      ));

      final file = File(p.join(dir.path, _fileName(kind, at)));
      await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
      if (kind == BackupKind.auto) await _prune();
      return BackupInfo(file: file, createdAt: at, kind: kind, sizeBytes: await file.length());
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
  }

  /// Makes the daily automatic backup if the last one is older than
  /// [autoInterval]. Returns it, or null if none was due.
  Future<BackupInfo?> autoBackupIfDue({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final last = (await list()).where((b) => b.kind == BackupKind.auto).firstOrNull;
    if (last != null && at.difference(last.createdAt) < autoInterval) return null;
    return create(kind: BackupKind.auto, now: at);
  }

  Future<(int, int)> _counts() async {
    final decks = await _db.select(_db.decks).get();
    final cards = await _db.customSelect('SELECT COUNT(*) AS c FROM cards').getSingle();
    return (decks.length, cards.read<int>('c'));
  }

  static String _fileName(BackupKind kind, DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${at.year}-${two(at.month)}-${two(at.day)}-${two(at.hour)}${two(at.minute)}${two(at.second)}';
    final label = switch (kind) {
      BackupKind.auto => 'auto',
      BackupKind.manual => 'manual',
      BackupKind.beforeRestore => 'before-restore',
    };
    return 'Anki-backup-$stamp-$label.zip';
  }

  static final _namePattern = RegExp(r'^Anki-backup-(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})-([a-z-]+)\.zip$');

  /// Backups on this device, newest first.
  Future<List<BackupInfo>> list() async {
    final dir = await backupsDir();
    final out = <BackupInfo>[];
    await for (final f in dir.list()) {
      if (f is! File) continue;
      final m = _namePattern.firstMatch(p.basename(f.path));
      if (m == null) continue;
      final at = DateTime(
        int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), //
        int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!),
      );
      final kind = switch (m[7]) {
        'auto' => BackupKind.auto,
        'before-restore' => BackupKind.beforeRestore,
        _ => BackupKind.manual,
      };
      out.add(BackupInfo(file: f, createdAt: at, kind: kind, sizeBytes: await f.length()));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> _prune() async {
    final autos = (await list()).where((b) => b.kind == BackupKind.auto).toList();
    for (final old in autos.skip(keepAuto)) {
      await old.file.delete();
    }
  }

  Future<void> delete(BackupInfo backup) => backup.file.delete();

  // --- restoring -----------------------------------------------------------

  /// Checks that [bytes] are a backup this version can restore; returns
  /// its manifest.
  Map<String, dynamic> inspect(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('Это не файл резервной копии');
    }
    final manifestFile = archive.findFile(_manifestName);
    final dbFile = archive.findFile(_dbEntry);
    if (manifestFile == null || dbFile == null) {
      throw const BackupException('Это не резервная копия этого приложения');
    }
    final manifest = jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
    final version = (manifest['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version > _db.schemaVersion) {
      throw const BackupException('Копия сделана более новой версией приложения — сначала обновите приложение');
    }
    return manifest;
  }

  /// Replaces the whole collection with the backup in [bytes]. The current
  /// collection is backed up first ([BackupKind.beforeRestore]).
  Future<void> restore(List<int> bytes) async {
    final reopen = onReopen;
    if (reopen == null) throw const BackupException('Восстановление здесь недоступно');
    inspect(bytes);
    final archive = ZipDecoder().decodeBytes(bytes);

    await create(kind: BackupKind.beforeRestore);

    final dbFile = await _databaseFile();
    final media = await _mediaDir();
    final settings = await _settingsFile();

    await _db.close();
    try {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final f = File('${dbFile.path}$suffix');
        if (await f.exists()) await f.delete();
      }
      await dbFile.writeAsBytes(archive.findFile(_dbEntry)!.content, flush: true);

      if (await media.exists()) await media.delete(recursive: true);
      await media.create(recursive: true);
      for (final entry in archive.files) {
        if (!entry.isFile || !entry.name.startsWith('media/')) continue;
        final name = p.basename(entry.name);
        if (name.isEmpty) continue;
        await File(p.join(media.path, name)).writeAsBytes(entry.content);
      }

      final settingsEntry = archive.findFile(_settingsEntry);
      if (settingsEntry != null) await settings.writeAsBytes(settingsEntry.content, flush: true);
    } finally {
      // Whatever happened, reopen a collection so the app keeps working.
      await reopen();
    }
  }
}
