import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../browser/card_browser_screen.dart';
import '../editor/note_editor_screen.dart';
import '../export/export_progress_dialog.dart';
import '../import/import_screen.dart';
import '../stats/stats_screen.dart';
import '../study/study_screen.dart';
import '../theme/app_theme.dart';
import 'deck_settings_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckRepo = context.watch<DeckRepository>();
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            const Text('Anki Flutter'),
          ],
        ),
        actions: [
          _TopAction(
            icon: Icons.query_stats_outlined,
            tooltip: 'Статистика',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen(title: 'Все колоды'))),
          ),
          const SizedBox(width: AppSpacing.xs),
          _TopAction(
            icon: Icons.file_download_outlined,
            tooltip: 'Импорт .apkg',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
          ),
          const SizedBox(width: AppSpacing.md),
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 128),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ваши колоды', style: theme.textTheme.headlineSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Продолжайте повторение или создайте новую подборку карточек.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                      Text('${decks.length} ${_deckWord(decks.length)}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...decks.map(
                    (deck) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DeckTile(deck: deck),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'addDeck',
            tooltip: 'Новая колода',
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: AppColors.accent,
            elevation: 2,
            onPressed: () => _createDeck(context),
            child: const Icon(Icons.create_new_folder_outlined, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'addNote',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
            icon: const Icon(Icons.add_rounded, size: 21),
            label: const Text('Новая карточка'),
          ),
        ],
      ),
    );
  }

  static String _deckWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'колода';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'колоды';
    return 'колод';
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
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Например: Английские слова',
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Создать')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      try {
        await context.read<DeckRepository>().createDeck(name);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось создать колоду "$name": уже существует')),
        );
      }
    }
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appColors.border),
      ),
      child: IconButton(icon: Icon(icon, size: 20), tooltip: tooltip, onPressed: onPressed),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Container(
        width: 420,
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2138).withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.style_outlined, size: 30, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Создайте первую колоду', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Соберите карточки по теме и начните интервальное повторение.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreateDeck,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Создать колоду'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckTile extends StatefulWidget {
  const _DeckTile({required this.deck});

  final Deck deck;

  @override
  State<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<_DeckTile> {
  late Future<DueQueueCounts> _counts;

  @override
  void initState() {
    super.initState();
    _counts = context.read<StudyRepository>().counts(widget.deck.id);
  }

  @override
  void didUpdateWidget(_DeckTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck != widget.deck) {
      _counts = context.read<StudyRepository>().counts(widget.deck.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<DueQueueCounts>(
      future: _counts,
      builder: (context, snapshot) {
        final counts = snapshot.data;
        final totalDue = counts == null ? null : counts.newCount + counts.learningCount + counts.reviewCount;

        return Material(
          color: colors.surface,
          elevation: 0,
          borderRadius: BorderRadius.circular(kAppRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(kAppRadius),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => StudyScreen(deckId: deck.id, deckName: deck.name))),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kAppRadius),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B2138).withValues(alpha: 0.035),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.layers_outlined, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name, style: textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        if (counts == null)
                          Text('Загрузка…', style: textTheme.bodySmall)
                        else if (totalDue == 0)
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 15, color: AppColors.good),
                              const SizedBox(width: 6),
                              Text('На сегодня всё', style: textTheme.bodySmall?.copyWith(color: AppColors.good)),
                            ],
                          )
                        else
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _CountPill(label: 'новые', count: counts.newCount, color: AppColors.easy),
                              _CountPill(label: 'изучение', count: counts.learningCount, color: AppColors.again),
                              _CountPill(label: 'повтор', count: counts.reviewCount, color: AppColors.good),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (totalDue != null && totalDue > 0) ...[
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalDue',
                        style: textTheme.labelLarge?.copyWith(color: AppColors.accent),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colors.muted, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'stats':
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatsScreen(deckId: deck.id, title: deck.name)),
                          );
                        case 'browse':
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CardBrowserScreen(deckId: deck.id, deckName: deck.name)),
                          );
                        case 'export':
                          exportDecksToFile(context, deckIds: [deck.id], suggestedFileName: deck.name);
                        case 'settings':
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DeckSettingsScreen(deckId: deck.id, deckName: deck.name)),
                          );
                        case 'rename':
                          _rename(context);
                        case 'delete':
                          _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'browse', child: Text('Карточки')),
                      PopupMenuItem(value: 'stats', child: Text('Статистика')),
                      PopupMenuItem(value: 'export', child: Text('Экспорт .apkg')),
                      PopupMenuItem(value: 'settings', child: Text('Настройки колоды')),
                      PopupMenuItem(value: 'rename', child: Text('Переименовать')),
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

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: widget.deck.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать колоду'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название колоды'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Сохранить')),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == widget.deck.name || !context.mounted) return;
    try {
      await context.read<DeckRepository>().renameDeck(widget.deck.id, name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось переименовать: колода "$name" уже существует')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить колоду "${widget.deck.name}"?'),
        content: const Text('Все карточки этой колоды будут удалены безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.again),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DeckRepository>().deleteDeck(widget.deck.id);
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count · $label',
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}