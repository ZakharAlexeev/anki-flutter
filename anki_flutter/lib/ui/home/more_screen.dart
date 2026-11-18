import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/deck_repository.dart';
import '../common/ios.dart';
import '../decks/deck_actions.dart';
import '../editor/note_editor_screen.dart';
import '../editor/notetype_manager_screen.dart';
import '../export/export_progress_dialog.dart';
import '../import/import_screen.dart';
import '../theme/app_theme.dart';

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
        ],
      ),
    );
  }
}
