import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import '../theme/app_theme.dart';

/// Anki's "Browse": search/list/edit/delete/(un)suspend the notes in a deck.
/// The underlying repository methods (`cardsWithNotesForDeck`,
/// `updateNoteFields`, `deleteNote`, `setCardSuspended`) already existed but
/// had no screen calling them - this was the single biggest missing piece
/// of day-to-day deck management (fixing a typo meant deleting and
/// recreating the note).
class CardBrowserScreen extends StatefulWidget {
  const CardBrowserScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  State<CardBrowserScreen> createState() => _CardBrowserScreenState();
}

class _CardBrowserScreenState extends State<CardBrowserScreen> {
  static const _pageSize = 100;

  List<(CardEntry, Note)>? _rows;
  final _search = TextEditingController();
  Timer? _searchDebounce;
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_scheduleSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () => _load());
  }

  Future<void> _load({bool append = false}) async {
    if (append) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() => _rows = null);
    }
    final currentRows = append ? (_rows ?? const <(CardEntry, Note)>[]) : const <(CardEntry, Note)>[];
    final page = await context.read<NoteRepository>().cardBrowserPage(
          deckId: widget.deckId,
          limit: _pageSize,
          offset: currentRows.length,
          query: _search.text,
        );
    if (!mounted) return;
    setState(() {
      _rows = append ? [...currentRows, ...page.rows] : page.rows;
      _hasMore = page.hasMore;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Scaffold(
      appBar: AppBar(
        title: Text('Карточки — ${widget.deckName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Поиск по содержимому и тегам',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
        ),
      ),
      body: rows == null
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    _search.text.trim().isEmpty ? 'В этой колоде пока нет карточек' : 'Ничего не найдено',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                      itemCount: rows.length + 1 + (_hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Text('КАРТОЧКИ', style: Theme.of(context).textTheme.labelSmall),
                                const Spacer(),
                                Text(
                                  _hasMore ? '${rows.length}+' : '${rows.length}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        }
                        if (i > rows.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: _loadingMore ? null : () => _load(append: true),
                                child: Text(_loadingMore ? 'Загрузка…' : 'Показать ещё'),
                              ),
                            ),
                          );
                        }
                        final row = rows[i - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CardRow(card: row.$1, note: row.$2, onChanged: _load),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.note, required this.onChanged});

  final CardEntry card;
  final Note note;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notes = context.read<NoteRepository>();
    final fields = notes.decodeFields(note.fieldsJson);
    final preview = fields.firstWhere((f) => f.trim().isNotEmpty, orElse: () => '').replaceAll(RegExp('<[^>]*>'), '');
    final suspended = card.queue == CardQueue.suspended;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(kAppRadius),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.isEmpty ? '(пусто)' : preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (note.tags.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note.tags.trim(), style: Theme.of(context).textTheme.bodySmall),
                ],
                if (suspended) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('ПРИОСТАНОВЛЕНА', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.hard)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(suspended ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 20),
            tooltip: suspended ? 'Возобновить' : 'Приостановить',
            onPressed: () async {
              await context.read<NoteRepository>().setCardSuspended(card.id, !suspended);
              onChanged();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'Редактировать',
            onPressed: () => _edit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 19),
            tooltip: 'Удалить',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final notetypes = context.read<NotetypeRepository>();
    final notes = context.read<NoteRepository>();
    final fieldDefs = await notetypes.fieldsFor(note.notetypeId);
    if (!context.mounted) return;

    final fieldValues = notes.decodeFields(note.fieldsJson);
    final controllers = [
      for (final f in fieldDefs) TextEditingController(text: f.ord < fieldValues.length ? fieldValues[f.ord] : ''),
    ];
    final tagsController = TextEditingController(text: note.tags);

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать заметку'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < fieldDefs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextField(
                      controller: controllers[i],
                      maxLines: null,
                      decoration: InputDecoration(labelText: fieldDefs[i].name),
                    ),
                  ),
                TextField(controller: tagsController, decoration: const InputDecoration(labelText: 'Теги')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (save == true) {
      final newFields = List<String>.generate(fieldDefs.length, (i) => controllers[i].text);
      try {
        await notes.updateNoteFields(
          note.id,
          newFields,
          tags: tagsController.text.trim(),
          preferredDeckId: card.deckId,
        );
        onChanged();
      } on Object catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $error')));
        }
      }
    }
    // Not disposed here: the dialog route's closing transition can still be
    // animating (and rebuilding the TextFields bound to these controllers)
    // for a frame or two after showDialog() returns, and disposing while
    // that's in flight throws "TextEditingController used after being
    // disposed". These are short-lived, dialog-local controllers - same
    // pattern already used for the equivalent create/rename dialogs in
    // deck_list_screen.dart and notetype_manager_screen.dart.
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Заметка и все её карточки будут удалены безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NoteRepository>().deleteNote(note.id);
      onChanged();
    }
  }
}
