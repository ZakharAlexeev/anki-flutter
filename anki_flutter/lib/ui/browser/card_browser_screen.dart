import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';

/// Anki's "Browse" for one deck, as an iOS list: search on top, one row per
/// card ("word -> translation"). Tap a row to edit its note; long-press for
/// suspend / unsuspend / delete.
class CardBrowserScreen extends StatefulWidget {
  const CardBrowserScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  State<CardBrowserScreen> createState() => _CardBrowserScreenState();
}

class _CardBrowserScreenState extends State<CardBrowserScreen> {
  List<(CardEntry, Note)>? _rows;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await context.read<NoteRepository>().cardsWithNotesForDeck(widget.deckId);
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  Future<void> _open((CardEntry, Note) row) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditScreen(card: row.$1, note: row.$2)),
    );
    if (mounted) _load();
  }

  Future<void> _actions((CardEntry, Note) row) async {
    final (card, note) = row;
    final suspended = card.queue == CardQueue.suspended;
    final action = await showActionSheet<String>(
      context,
      title: _plain(context.read<NoteRepository>().decodeFields(note.fieldsJson).firstOrNull ?? ''),
      actions: [
        const SheetAction('edit', 'Изменить'),
        SheetAction('suspend', suspended ? 'Вернуть в повторения' : 'Отложить карточку'),
        const SheetAction('delete', 'Удалить заметку', destructive: true),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _open(row);
      case 'suspend':
        await context.read<NoteRepository>().setCardSuspended(card.id, !suspended);
        await _load();
      case 'delete':
        if (await confirmDeleteNote(context) && mounted) {
          await context.read<NoteRepository>().deleteNote(note.id);
          await _load();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final notes = context.read<NoteRepository>();
    final filtered = rows?.where((r) {
      if (_query.isEmpty) return true;
      final fields = notes.decodeFields(r.$2.fieldsJson);
      return fields.any((f) => _plain(f).toLowerCase().contains(_query)) || r.$2.tags.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.deckName)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: CupertinoSearchTextField(
                  controller: _search,
                  placeholder: 'Поиск по словам и тегам',
                  style: TextStyle(color: context.appColors.text),
                ),
              ),
              if (rows == null)
                const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CupertinoActivityIndicator())
              else if (filtered!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    rows.isEmpty ? 'В этой колоде пока нет карточек' : 'Ничего не найдено',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: context.appColors.muted),
                  ),
                )
              else ...[
                SectionHeader('${filtered.length} ${_cardsWord(filtered.length)}'),
                GroupedSection(children: [
                  for (final row in filtered)
                    _CardRow(card: row.$1, note: row.$2, onTap: () => _open(row), onLongPress: () => _actions(row)),
                ]),
                const SectionFooter('Удерживайте карточку, чтобы отложить или удалить её.'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _cardsWord(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'карточка';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'карточки';
    return 'карточек';
  }
}

/// Field text without HTML or `[sound:...]` tags, for previews and search.
String _plain(String html) => html
    .replaceAll(RegExp(r'\[sound:[^\]]*\]'), '')
    .replaceAll(RegExp('<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.note, required this.onTap, required this.onLongPress});

  final CardEntry card;
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fields = context.read<NoteRepository>().decodeFields(note.fieldsJson).map(_plain).toList();
    final front = fields.firstWhere((f) => f.isNotEmpty, orElse: () => '');
    final rest = fields.skip(fields.indexOf(front) + 1).where((f) => f.isNotEmpty).join(' · ');
    final suspended = card.queue == CardQueue.suspended;
    final hasAudio = note.fieldsJson.contains('[sound:');

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.sm, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    front.isEmpty ? '(пусто)' : front,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'Georgia',
                      color: suspended ? colors.muted : colors.text,
                    ),
                  ),
                  if (rest.isNotEmpty || note.tags.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [rest, if (note.tags.trim().isNotEmpty) '#${note.tags.trim().replaceAll(' ', ' #')}']
                          .where((s) => s.isNotEmpty)
                          .join('   '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (hasAudio) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(CupertinoIcons.speaker_2, size: 16, color: colors.muted),
            ],
            if (suspended) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.hard.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('отложена', style: TextStyle(fontSize: 12, color: AppColors.hard)),
              ),
            ],
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right, size: 15, color: colors.muted.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDeleteNote(BuildContext context) => showDestructiveConfirm(
      context,
      title: 'Удалить заметку?',
      message: 'Заметка, все её карточки и их история будут удалены безвозвратно.',
      confirmLabel: 'Удалить',
    );

/// Edit an existing note, in the same form style as the new-card editor:
/// one block per field, tags, then the card's actions.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, required this.card, required this.note});

  final CardEntry card;
  final Note note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  List<NotetypeField>? _fields;
  final List<TextEditingController> _controllers = [];
  late final TextEditingController _tags = TextEditingController(text: widget.note.tags);
  late bool _suspended = widget.card.queue == CardQueue.suspended;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _tags.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final defs = await context.read<NotetypeRepository>().fieldsFor(widget.note.notetypeId);
    if (!mounted) return;
    final values = context.read<NoteRepository>().decodeFields(widget.note.fieldsJson);
    setState(() {
      _fields = defs;
      _controllers.addAll([
        for (final f in defs) TextEditingController(text: f.ord < values.length ? values[f.ord] : ''),
      ]);
    });
  }

  Future<void> _save() async {
    final defs = _fields;
    if (defs == null) return;
    setState(() => _saving = true);
    await context.read<NoteRepository>().updateNoteFields(
          widget.note.id,
          [for (final c in _controllers) c.text],
          tags: _tags.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleSuspend() async {
    await context.read<NoteRepository>().setCardSuspended(widget.card.id, !_suspended);
    if (mounted) setState(() => _suspended = !_suspended);
  }

  Future<void> _delete() async {
    if (!await confirmDeleteNote(context) || !mounted) return;
    await context.read<NoteRepository>().deleteNote(widget.note.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка'),
        actions: [NavBarAction(label: 'Сохранить', busy: _saving, onPressed: fields == null ? null : _save)],
      ),
      body: fields == null
          ? const Center(child: CupertinoActivityIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      SectionHeader(fields[i].name),
                      GroupedSection(children: [GroupedTextArea(controller: _controllers[i], serif: true)]),
                    ],
                    const SectionHeader('Теги'),
                    GroupedSection(children: [
                      GroupedTextArea(controller: _tags, multiline: false, placeholder: 'через пробел'),
                    ]),
                    const SectionHeader('Карточка'),
                    GroupedSection(children: [
                      GroupedRow(
                        title: _suspended ? 'Вернуть в повторения' : 'Отложить карточку',
                        icon: _suspended ? CupertinoIcons.play_fill : CupertinoIcons.pause_fill,
                        iconColor: AppColors.hard,
                        chevron: false,
                        onTap: _toggleSuspend,
                      ),
                      GroupedRow(
                        title: 'Удалить заметку',
                        destructive: true,
                        chevron: false,
                        onTap: _delete,
                      ),
                    ]),
                    SectionFooter(
                      _suspended
                          ? 'Карточка отложена и не появляется в повторениях.'
                          : 'Отложенная карточка не появляется в повторениях, пока её не вернут.',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
