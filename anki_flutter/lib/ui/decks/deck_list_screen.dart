import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../editor/note_editor_screen.dart';
import '../export/export_progress_dialog.dart';
import '../import/import_screen.dart';
import '../stats/stats_screen.dart';
import '../study/study_screen.dart';
import '../theme/app_theme.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckRepo = context.watch<DeckRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Колоды'),
        actions: [
          IconButton(
            icon: const Icon(Icons.query_stats_outlined, size: 20),
            tooltip: 'Статистика',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen(title: 'Все колоды'))),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined, size: 20),
            tooltip: 'Импорт .apkg',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: StreamBuilder<List<Deck>>(
        stream: deckRepo.watchDecks(),
        builder: (context, snapshot) {
          final decks = snapshot.data ?? const <Deck>[];
          if (decks.isEmpty) {
            return _EmptyState(onCreateDeck: () => _createDeck(context));
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  120, // leave room for the floating actions
                ),
                itemCount: decks.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _DeckTile(deck: decks[index]),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addDeck',
            tooltip: 'Новая колода',
            onPressed: () => _createDeck(context),
            child: const Icon(Icons.add_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'addNote',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
            icon: const Icon(Icons.note_add_outlined, size: 20),
            label: const Text('Карточка'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDeck(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая колода'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название колоды'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Создать')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<DeckRepository>().createDeck(name);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    final muted = context.appColors.muted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 40, color: muted),
            const SizedBox(height: AppSpacing.md),
            Text('Пока нет колод', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Создайте первую, чтобы начать добавлять карточки',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onCreateDeck,
              icon: const Icon(Icons.add_outlined, size: 18),
              label: const Text('Новая колода'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final study = context.read<StudyRepository>();
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<DueQueueCounts>(
      future: study.counts(deck.id),
      builder: (context, snapshot) {
        final counts = snapshot.data;

        return Material(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(kAppRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(kAppRadius),
            // Always tappable, even with nothing due - StudyScreen has its
            // own "nothing to study" state. A tile that silently ignores
            // taps whenever the due count happens to read as zero (or just
            // hasn't loaded yet) is indistinguishable from a broken app.
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => StudyScreen(deckId: deck.id, deckName: deck.name))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kAppRadius),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name, style: textTheme.titleMedium),
                        if (counts != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              _CountPill(label: 'нов.', count: counts.newCount, color: AppColors.easy),
                              const SizedBox(width: AppSpacing.sm),
                              _CountPill(label: 'изуч.', count: counts.learningCount, color: AppColors.again),
                              const SizedBox(width: AppSpacing.sm),
                              _CountPill(label: 'повт.', count: counts.reviewCount, color: AppColors.good),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colors.muted, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'stats':
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatsScreen(deckId: deck.id, title: deck.name)),
                          );
                        case 'export':
                          exportDecksToFile(context, deckIds: [deck.id], suggestedFileName: deck.name);
                        case 'delete':
                          _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'stats', child: Text('Статистика')),
                      PopupMenuItem(value: 'export', child: Text('Экспорт .apkg')),
                      PopupMenuItem(value: 'delete', child: Text('Удалить колоду')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить колоду "${deck.name}"?'),
        content: const Text('Все карточки этой колоды будут удалены безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DeckRepository>().deleteDeck(deck.id);
    }
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
