import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/import/apkg_importer.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';

/// Picks a `.apkg`/`.colpkg` file and imports it, showing live progress -
/// in the same grouped iOS style as the rest of the app.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportProgress? _progress;
  String? _error;
  String? _fileName;
  bool _running = false;
  bool _done = false;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['apkg', 'colpkg'],
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || !mounted) return;

    setState(() {
      _running = true;
      _done = false;
      _error = null;
      _progress = null;
      _fileName = file!.name;
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
    final progress = _progress;
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: AppColors.good, borderRadius: BorderRadius.circular(15)),
                      child: const Icon(CupertinoIcons.arrow_down_doc, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Колода из Anki', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Файлы .apkg и .colpkg из Anki на компьютере, AnkiMobile или AnkiDroid. '
                      'Карточки, история повторений, настройки и звук добавятся к вашей коллекции.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.35, color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Файл'),
              GroupedSection(children: [
                GroupedRow(
                  title: _running ? 'Импортирую…' : 'Выбрать файл',
                  icon: CupertinoIcons.folder,
                  iconColor: AppColors.easy,
                  chevron: !_running,
                  trailing: _running ? const CupertinoActivityIndicator() : null,
                  onTap: _running ? null : _pickAndImport,
                ),
              ]),
              const SectionFooter('Перед импортом стоит сохранить резервную копию — её можно сделать во вкладке «Ещё».'),
              if (_fileName != null) ...[
                SectionHeader(_fileName!),
                GroupedSection(children: [
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(progress.phase, style: TextStyle(fontSize: 16, color: colors.text)),
                          if (_running) ...[
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                minHeight: 5,
                                value: progress.total > 1 ? progress.current / progress.total : null,
                                backgroundColor: colors.surfaceAlt,
                                color: AppColors.accent,
                              ),
                            ),
                            if (progress.total > 1) ...[
                              const SizedBox(height: 6),
                              Text('${progress.current} из ${progress.total}',
                                  style: TextStyle(fontSize: 13, color: colors.muted)),
                            ],
                          ],
                        ],
                      ),
                    ),
                  if (_done && _error == null)
                    const GroupedRow(
                      title: 'Импорт завершён',
                      icon: CupertinoIcons.checkmark_alt,
                      iconColor: AppColors.good,
                      chevron: false,
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.again)),
                    ),
                  if (progress == null && _running)
                    const Padding(padding: EdgeInsets.all(AppSpacing.md), child: CupertinoActivityIndicator()),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
