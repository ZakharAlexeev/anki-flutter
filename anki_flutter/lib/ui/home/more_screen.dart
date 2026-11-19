import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/backup/backup_service.dart';
import '../../data/db/database.dart';
import '../backup/backups_screen.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../common/ios.dart';
import '../decks/deck_actions.dart';
import '../editor/note_editor_screen.dart';
import '../editor/notetype_manager_screen.dart';
import '../export/export_progress_dialog.dart';
import '../import/import_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Collection-wide scheduling options, as in Anki's preferences.
class _AlgorithmSection extends StatefulWidget {
  const _AlgorithmSection();

  @override
  State<_AlgorithmSection> createState() => _AlgorithmSectionState();
}

class _AlgorithmSectionState extends State<_AlgorithmSection> {
  bool _busy = false;

  Future<void> _toggleFsrs(bool on) async {
    final study = context.read<StudyRepository>();
    setState(() => _busy = true);
    try {
      await study.setFsrsEnabled(on);
      if (mounted && on) {
        showToast(context, 'FSRS включён: память карточек рассчитана по истории ответов');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = context.read<StudyRepository>();
    return StreamBuilder<CollectionMetaData>(
      stream: study.watchSchedulingOptions(),
      builder: (context, snap) {
        final o = snap.data;
        Widget toggle(bool value, ValueChanged<bool>? onChanged) => _busy && onChanged != null
            ? const CupertinoActivityIndicator()
            : CupertinoSwitch(value: value, activeTrackColor: AppColors.accent, onChanged: onChanged);
        return GroupedSection(children: [
          GroupedRow(
            title: 'FSRS',
            icon: CupertinoIcons.sparkles,
            iconColor: AppColors.easy,
            chevron: false,
            trailing: toggle(o?.fsrsEnabled ?? false, o == null || _busy ? null : _toggleFsrs),
          ),
          GroupedRow(
            title: 'Балансировка нагрузки',
            icon: CupertinoIcons.chart_bar_alt_fill,
            iconColor: AppColors.good,
            chevron: false,
            trailing: toggle(
              o?.loadBalancerEnabled ?? true,
              o == null ? null : (v) => study.setLoadBalancerEnabled(v),
            ),
          ),
          if (o?.fsrsEnabled ?? false)
            GroupedRow(
              title: 'Кратковременные шаги FSRS',
              icon: CupertinoIcons.timer,
              iconColor: AppColors.hard,
              chevron: false,
              trailing: toggle(o!.fsrsShortTermWithSteps, (v) => study.setFsrsShortTermWithSteps(v)),
            ),
        ]);
      },
    );
  }
}

/// Light / dark / follow-the-system, as an iOS segmented control.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget label(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.text),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 14, color: colors.text)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<ThemeMode>(
          groupValue: theme.mode,
          // As on iOS: the selected thumb is always lighter than its track.
          backgroundColor: dark ? colors.surface : colors.surfaceAlt,
          thumbColor: dark ? const Color(0xFF454C45) : colors.surface,
          onValueChanged: (mode) {
            if (mode != null) theme.setMode(mode);
          },
          children: {
            ThemeMode.system: label(CupertinoIcons.circle_lefthalf_fill, 'Авто'),
            ThemeMode.light: label(CupertinoIcons.sun_max, 'Светлая'),
            ThemeMode.dark: label(CupertinoIcons.moon, 'Тёмная'),
          },
        ),
      ),
    );
  }
}

/// The "More" tab: everything that isn't daily studying.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: const Text('Ещё')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SectionHeader('Оформление'),
          const _ThemePicker(),
          const SectionFooter('«Авто» — светлая днём и тёмная ночью, как в настройках телефона.'),
          const SectionHeader('Алгоритм повторений'),
          const _AlgorithmSection(),
          const SectionFooter(
            'FSRS — современный алгоритм Anki: подбирает интервалы под вашу память. '
            'Параметры и желаемая запоминаемость задаются в настройках колоды. '
            'Балансировка распределяет повторения по дням равномерно.',
          ),
          const SectionHeader('Создать'),
          GroupedSection(children: [
            GroupedRow(
              title: 'Новая карточка',
              icon: CupertinoIcons.plus,
              onTap: () => push(const NoteEditorScreen()),
            ),
            GroupedRow(
              title: 'Новая колода',
              icon: CupertinoIcons.folder_badge_plus,
              iconColor: AppColors.easy,
              chevron: false,
              onTap: () => createDeckWithPrompt(context),
            ),
            GroupedRow(
              title: 'Типы карточек',
              icon: CupertinoIcons.square_grid_2x2,
              iconColor: AppColors.hard,
              onTap: () => push(const NotetypeManagerScreen()),
            ),
          ]),
          const SectionHeader('Файлы .apkg'),
          GroupedSection(children: [
            GroupedRow(
              title: 'Импорт колоды',
              icon: CupertinoIcons.arrow_down_doc,
              iconColor: AppColors.good,
              onTap: () => push(const ImportScreen()),
            ),
            GroupedRow(
              title: 'Экспорт всех колод',
              icon: CupertinoIcons.share,
              iconColor: const Color(0xFF6F746C),
              chevron: false,
              onTap: () async {
                final decks = await context.read<DeckRepository>().watchDecks().first;
                if (!context.mounted) return;
                await exportDecksToFile(
                  context,
                  deckIds: [for (final d in decks) d.id],
                  suggestedFileName: 'Anki',
                );
              },
            ),
          ]),
          const SectionFooter('Файлы совместимы с Anki на компьютере и AnkiMobile.'),
          if (context.read<BackupService?>() != null) ...[
            const SectionHeader('Данные'),
            GroupedSection(children: [
              GroupedRow(
                title: 'Резервные копии',
                icon: CupertinoIcons.archivebox,
                iconColor: const Color(0xFF6F746C),
                onTap: () => push(const BackupsScreen()),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
