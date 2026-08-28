import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/import/apkg_importer.dart';
import '../theme/app_theme.dart';

/// Picks a `.apkg`/`.colpkg` file and imports it, showing live progress.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportProgress? _progress;
  String? _error;
  bool _running = false;
  bool _done = false;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['apkg', 'colpkg'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() {
      _running = true;
      _done = false;
      _error = null;
      _progress = null;
    });

    final importer = ApkgImporter(context.read<AppDatabase>());
    try {
      await for (final progress in importer.import(path)) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
      if (!mounted) return;
      setState(() {
        _running = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт .apkg')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ПЕРЕНОС ДАННЫХ', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Text('Импорт колоды', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Поддерживаются файлы .apkg и .colpkg из настольного или мобильного Anki.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(kAppRadius),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.file_present_outlined, color: AppColors.accent, size: 32),
                      const SizedBox(height: AppSpacing.md),
                      Text('Файл коллекции Anki', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Данные объединятся с текущей коллекцией.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _running ? null : _pickAndImport,
                        icon: const Icon(Icons.file_open_outlined, size: 18),
                        label: const Text('Выбрать файл'),
                      ),
                    ],
                  ),
                ),
                if (_running || _progress != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  if (_running)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: colors.border,
                      ),
                    ),
                  if (_progress != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_progress!.phase, style: Theme.of(context).textTheme.bodyMedium),
                    if (_progress!.total > 1)
                      Text('${_progress!.current} / ${_progress!.total}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_done && _error == null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: AppColors.good),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Импорт завершён', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
