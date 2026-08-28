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
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Колоды'),
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Новая колода',
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: () => _createDeck(context),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Другие действия',
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              switch (value) {
                case 'stats':
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const StatsScreen(title: 'Все колоды')));
                case 'import':
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.query_stats_outlined),
                  title: Text('Статистика'),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Импорт .apkg'),
                ),
              ),
            ],
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

          return SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 112),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сегодня', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text(
                            '${decks.length} ${_deckWord(decks.length)} · выберите, чтобы начать повторение',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(kAppRadius),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < decks.length; i++) ...[
                            _DeckRow(deck: decks[i]),
                            if (i != decks.length - 1)
                              Divider(indent: AppSpacing.md, endIndent: AppSpacing.md, color: colors.border),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addNote',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Карточка'),
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
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style_outlined, size: 42, color: colors.muted),
                const SizedBox(height: AppSpacing.lg),
                Text('Создайте первую колоду', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Соберите карточки по одной теме и начните интервальное повторение.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onCreateDeck,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Создать колоду'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckRow extends StatefulWidget {
  const _DeckRow({required this.deck});

  final Deck deck;

  @override
  State<_DeckRow> createState() => _DeckRowState();
}

class _DeckRowState extends State<_DeckRow> {
  late Future<DueQueueCounts> _counts;

  @override
  void initState() {
    super.initState();
    _counts = context.read<StudyRepository>().counts(widget.deck.id);
  }

  @override
  void didUpdateWidget(_DeckRow oldWidget) {
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
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => StudyScreen(deckId: deck.id, deckName: deck.name))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 18, 6, 18),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 46,
                    decoration: BoxDecoration(
                      color: totalDue == 0 ? AppColors.good : AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 7),
                        if (counts == null)
                          Text('Загрузка…', style: textTheme.bodySmall)
                        else if (totalDue == 0)
                          Text('На сегодня всё', style: textTheme.bodySmall?.copyWith(color: AppColors.good))
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _CountLabel(label: 'новые', count: counts.newCount, color: AppColors.easy),
                              _CountLabel(label: 'учим', count: counts.learningCount, color: AppColors.hard),
                              _CountLabel(label: 'повтор', count: counts.reviewCount, color: AppColors.good),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (totalDue != null && totalDue > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$totalDue', style: textTheme.titleMedium?.copyWith(color: AppColors.accent)),
                        Text('осталось', style: textTheme.bodySmall),
                      ],
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colors.muted, size: 21),
                    tooltip: 'Действия с колодой',
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
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
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

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text('$count $label', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
