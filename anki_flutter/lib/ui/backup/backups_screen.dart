import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/backup/backup_service.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';

/// Backups: make one now, save one to Files (iCloud Drive or anywhere -
/// the only copy that survives deleting the app or losing the phone), and
/// restore the collection from a backup.
class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  List<BackupInfo>? _backups;
  String? _busy; // what is running, shown in place of the actions

  BackupService get _service => context.read<BackupService?>()!;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _service.list();
    if (mounted) setState(() => _backups = list);
  }

  Future<T?> _run<T>(String label, Future<T> Function() action) async {
    setState(() => _busy = label);
    try {
      return await action();
    } on BackupException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (e) {
      if (mounted) showToast(context, 'Не получилось: $e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    return null;
  }

  Future<void> _createNow() async {
    final made = await _run('Создаю копию…', () => _service.create());
    if (made != null && mounted) {
      showToast(context, 'Копия создана');
      await _reload();
    }
  }

  Future<void> _saveToFiles([BackupInfo? existing]) async {
    final backup = existing ?? await _run('Создаю копию…', () => _service.create());
    if (backup == null || !mounted) return;
    final saved = await _run('Сохраняю…', () async {
      final bytes = await backup.file.readAsBytes();
      return FilePicker.saveFile(
        dialogTitle: 'Сохранить резервную копию',
        fileName: backup.file.uri.pathSegments.last,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );
    });
    if (mounted) {
      if (saved != null) showToast(context, 'Копия сохранена');
      await _reload();
    }
  }

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    await _restore(File(path), label: 'из файла «${result!.files.single.name}»');
  }

  Future<void> _restore(File file, {required String label}) async {
    final bytes = await _run('Проверяю копию…', () => file.readAsBytes());
    if (bytes == null || !mounted) return;
    Map<String, dynamic> manifest;
    try {
      manifest = _service.inspect(bytes);
    } on BackupException catch (e) {
      showToast(context, e.message);
      return;
    }
    final cards = manifest['cards'];
    final ok = await showDestructiveConfirm(
      context,
      title: 'Восстановить коллекцию?',
      message: 'Все колоды, карточки и история будут заменены копией $label'
          '${cards is num ? ' ($cards ${_cardsWord(cards.toInt())})' : ''}. '
          'Текущее состояние сначала сохранится отдельной копией, так что это можно отменить.',
      confirmLabel: 'Восстановить',
    );
    if (!ok || !mounted) return;
    // The collection is reopened afterwards and the app returns to its home
    // screen; this screen goes away with the old collection.
    await _run('Восстанавливаю…', () => _service.restore(bytes));
  }

  Future<void> _actions(BackupInfo b) async {
    final action = await showActionSheet<String>(
      context,
      title: _formatDate(b.createdAt),
      actions: const [
        SheetAction('save', 'Сохранить в Файлы'),
        SheetAction('restore', 'Восстановить из этой копии'),
        SheetAction('delete', 'Удалить копию', destructive: true),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'save':
        await _saveToFiles(b);
      case 'restore':
        await _restore(b.file, label: 'от ${_formatDate(b.createdAt)}');
      case 'delete':
        await b.file.delete();
        await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backups = _backups;
    final busy = _busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Резервные копии')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SectionHeader('Копия'),
          if (busy != null)
            GroupedSection(children: [
              GroupedRow(title: busy, chevron: false, trailing: const CupertinoActivityIndicator()),
            ])
          else
            GroupedSection(children: [
              GroupedRow(
                title: 'Сохранить копию в Файлы',
                icon: CupertinoIcons.cloud_upload,
                iconColor: AppColors.easy,
                chevron: false,
                onTap: _saveToFiles,
              ),
              GroupedRow(
                title: 'Создать копию на устройстве',
                icon: CupertinoIcons.plus_square_on_square,
                chevron: false,
                onTap: _createNow,
              ),
              GroupedRow(
                title: 'Восстановить из файла',
                icon: CupertinoIcons.arrow_counterclockwise,
                iconColor: AppColors.hard,
                chevron: false,
                onTap: _restoreFromFile,
              ),
            ]),
          const SectionFooter(
            'В Файлах выберите iCloud Drive — тогда копия переживёт удаление приложения и потерю телефона. '
            'Делайте так хотя бы раз в неделю.',
          ),
          SectionHeader('На этом устройстве${backups == null ? '' : ' · ${backups.length}'}'),
          if (backups == null)
            const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CupertinoActivityIndicator()))
          else if (backups.isEmpty)
            const GroupedSection(children: [GroupedRow(title: 'Пока нет копий', chevron: false, muted: true)])
          else
            GroupedSection(children: [
              for (final b in backups)
                GroupedRow(
                  title: _formatDate(b.createdAt),
                  trailing: Text(
                    '${_kindLabel(b.kind)} · ${_formatSize(b.sizeBytes)}',
                    style: TextStyle(fontSize: 13, color: context.appColors.muted),
                  ),
                  onTap: busy == null ? () => _actions(b) : null,
                ),
            ]),
          const SectionFooter(
            'Автоматическая копия создаётся раз в сутки, хранятся последние ${BackupService.keepAuto}. '
            'Копии на устройстве удаляются вместе с приложением.',
          ),
        ],
      ),
    );
  }

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} МБ';
  }

  static String _kindLabel(BackupKind k) => switch (k) {
        BackupKind.auto => 'авто',
        BackupKind.manual => 'вручную',
        BackupKind.beforeRestore => 'до восстановления',
      };

  static String _cardsWord(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'карточка';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'карточки';
    return 'карточек';
  }
}
