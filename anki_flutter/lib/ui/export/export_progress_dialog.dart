import 'dart:async';
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

  String? error;

  final tempFile = File(tempPath);
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportProgressDialog(
        stream: exporter.exportDecks(deckIds, tempPath),
        onError: (value) => error = value,
      ),
    );

    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $error')));
      return;
    }
    if (!await tempFile.exists()) return;
    final bytes = await tempFile.readAsBytes();
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
  } finally {
    if (await tempFile.exists()) await tempFile.delete();
  }
}

class _ExportProgressDialog extends StatefulWidget {
  const _ExportProgressDialog({required this.stream, required this.onError});

  final Stream<ExportProgress> stream;
  final ValueChanged<String> onError;

  @override
  State<_ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<_ExportProgressDialog> {
  StreamSubscription<ExportProgress>? _subscription;
  ExportProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onDone: () {
        Future<void>.delayed(const Duration(milliseconds: 200), () {
          if (mounted) Navigator.of(context).pop();
        });
      },
      onError: (Object error) {
        final message = error.toString();
        widget.onError(message);
        if (mounted) setState(() => _error = message);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
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
              Text(_progress?.phase ?? 'Подготовка…', style: Theme.of(context).textTheme.bodyMedium),
            ] else
              Text(error, style: TextStyle(color: context.appColors.muted)),
          ],
        ),
      ),
      actions: error == null
          ? null
          : [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть'))],
    );
  }
}
