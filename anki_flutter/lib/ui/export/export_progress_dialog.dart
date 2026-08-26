import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/export/apkg_exporter.dart';
import '../theme/app_theme.dart';

/// Exports [deckIds] (with full scheduling state - interval, ease, due
/// date, lapses, review history) to a `.apkg` file, showing progress in a
/// small non-dismissible dialog, then lets the user pick where to save it.
///
/// The export runs to a temp file *before* the destination picker opens,
/// and that file's bytes are handed to [FilePicker.saveFile] rather than
/// writing to its returned path afterward. On iOS, `saveFile` without
/// `bytes` opens its "export to" picker pointing at a file the plugin
/// never actually creates - `bytes` is what it writes into the app's
/// Documents directory before presenting that picker, so skipping it left
/// export silently non-functional on iOS while still appearing to work on
/// Windows (whose native save dialog doesn't need a source file to exist).
Future<void> exportDecksToFile(
  BuildContext context, {
  required List<int> deckIds,
  required String suggestedFileName,
}) async {
  final db = context.read<AppDatabase>();
  final exporter = ApkgExporter(db);
  final tempDir = await getTemporaryDirectory();
  final tempPath = p.join(tempDir.path, 'export_${DateTime.now().microsecondsSinceEpoch}.apkg');
  if (!context.mounted) return;

  ExportProgress? progress;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          if (progress == null && error == null) {
            exporter.exportDecks(deckIds, tempPath).listen(
              (p) => setState(() => progress = p),
              onDone: () {
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                });
              },
              onError: (Object e) => setState(() => error = e.toString()),
            );
          }

          final colors = dialogContext.appColors;
          return AlertDialog(
            title: const Text('Экспорт .apkg'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error == null) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    Text(progress?.phase ?? 'Подготовка…', style: Theme.of(dialogContext).textTheme.bodyMedium),
                  ] else
                    Text(error!, style: TextStyle(color: colors.muted)),
                ],
              ),
            ),
            actions: error == null
                ? null
                : [
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Закрыть')),
                  ],
          );
        },
      );
    },
  );

  if (!context.mounted) return;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $error')));
    return;
  }

  final tempFile = File(tempPath);
  if (!await tempFile.exists()) return;
  final bytes = await tempFile.readAsBytes();
  await tempFile.delete();
  if (!context.mounted) return;

  final savedPath = await FilePicker.saveFile(
    dialogTitle: 'Экспорт колоды',
    fileName: '$suggestedFileName.apkg',
    type: FileType.custom,
    allowedExtensions: ['apkg'],
    bytes: bytes,
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(savedPath != null ? 'Экспорт завершён' : 'Экспорт отменён')),
  );
}
