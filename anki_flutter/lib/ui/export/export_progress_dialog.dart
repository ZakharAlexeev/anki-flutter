import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/export/apkg_exporter.dart';
import '../theme/app_theme.dart';

/// Lets the user pick a destination, then exports [deckIds] (with full
/// scheduling state - interval, ease, due date, lapses, review history) to
/// a `.apkg` file there, showing progress in a small non-dismissible dialog.
Future<void> exportDecksToFile(
  BuildContext context, {
  required List<int> deckIds,
  required String suggestedFileName,
}) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Экспорт колоды',
    fileName: '$suggestedFileName.apkg',
    type: FileType.custom,
    allowedExtensions: ['apkg'],
  );
  if (path == null || !context.mounted) return;

  final db = context.read<AppDatabase>();
  final exporter = ApkgExporter(db);

  ExportProgress? progress;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          if (progress == null && error == null) {
            exporter.exportDecks(deckIds, path).listen(
              (p) => setState(() => progress = p),
              onDone: () {
                Future.delayed(const Duration(milliseconds: 400), () {
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error != null ? 'Ошибка экспорта: $error' : progress?.phase ?? 'Экспорт завершён')),
  );
}
