import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/import/apkg_importer.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт .apkg')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выберите файл колоды Anki (.apkg или .colpkg), экспортированный '
              'из настольного или мобильного приложения Anki.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _running ? null : _pickAndImport,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Выбрать файл'),
            ),
            const SizedBox(height: 24),
            if (_running) const LinearProgressIndicator(),
            if (_progress != null) ...[
              const SizedBox(height: 12),
              Text(_progress!.phase),
              if (_progress!.total > 1)
                Text('${_progress!.current} / ${_progress!.total}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_done && _error == null) ...[
              const SizedBox(height: 12),
              const Text('Импорт завершён.'),
            ],
          ],
        ),
      ),
    );
  }
}
