import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/media/pronunciation_service.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';
import 'notetype_manager_screen.dart';

/// Create-a-note screen, laid out like an iOS form (Contacts, Reminders):
/// where the card goes (deck, note type), one borderless block per field,
/// tags, and "Добавить" in the navigation bar. After saving, the cursor
/// returns to the first field so words can be added one after another.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  // Remembered for the app session, so adding many cards in a row doesn't
  // mean re-picking the deck each time.
  static int? _lastDeckId;
  static int? _lastNotetypeId;

  Notetype? _notetype;
  Deck? _deck;
  List<NotetypeField> _fields = const [];
  final Map<int, TextEditingController> _fieldControllers = {};
  final Map<int, FocusNode> _focus = {};
  final _tagsController = TextEditingController();
  bool _saving = false;
  int _added = 0;

  @override
  void dispose() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectNotetype(Notetype nt) async {
    final fields = await context.read<NotetypeRepository>().fieldsFor(nt.id);
    // Keep what was typed into fields whose names survive the switch.
    final previous = {for (final f in _fields) f.name: _fieldControllers[f.ord]?.text ?? ''};
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _fieldControllers.clear();
    _focus.clear();
    for (final f in fields) {
      _fieldControllers[f.ord] = TextEditingController(text: previous[f.name] ?? '');
      _focus[f.ord] = FocusNode();
    }
    _lastNotetypeId = nt.id;
    if (!mounted) return;
    setState(() {
      _notetype = nt;
      _fields = fields;
    });
  }

  bool get _hasContent => _fieldControllers.values.any((c) => c.text.trim().isNotEmpty);

  Future<void> _save() async {
    final notetype = _notetype;
    final deck = _deck;
    if (notetype == null || deck == null || !_hasContent || _saving) return;

    final fieldValues = List<String>.generate(_fields.length, (i) => _fieldControllers[i]?.text ?? '');
    setState(() => _saving = true);
    final noteId = await context.read<NoteRepository>().createNote(
          notetypeId: notetype.id,
          deckId: deck.id,
          fields: fieldValues,
          tags: _tagsController.text.trim(),
        );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _saving = false;
      _added++;
    });
    for (final c in _fieldControllers.values) {
      c.clear();
    }
    if (_fields.isNotEmpty) _focus[_fields.first.ord]?.requestFocus();

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Карточка добавлена'), duration: Duration(seconds: 1)));

    // The pronunciation is fetched in the background (~1 s per word), so
    // saving stays instant.
    context.read<PronunciationService>().attachTo(noteId).then((outcome) {
      final message = switch (outcome) {
        PronunciationOutcome.added => 'Произношение добавлено',
        PronunciationOutcome.notFound => 'В словарях нет записи произношения',
        PronunciationOutcome.networkError => 'Не удалось скачать произношение: нет связи',
        PronunciationOutcome.alreadyHasAudio || PronunciationOutcome.noEnglishText => null,
      };
      if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _pickDeck(List<Deck> decks) async {
    final id = await showActionSheet<int>(
      context,
      title: 'Колода',
      actions: [for (final d in decks) SheetAction(d.id, d.name)],
    );
    if (id == null) return;
    final deck = decks.firstWhere((d) => d.id == id);
    _lastDeckId = deck.id;
    setState(() => _deck = deck);
  }

  Future<void> _pickNotetype(List<Notetype> types) async {
    const manage = -1;
    final id = await showActionSheet<int>(
      context,
      title: 'Тип карточки',
      actions: [
        for (final t in types) SheetAction(t.id, t.name),
        const SheetAction(manage, 'Управлять типами…'),
      ],
    );
    if (id == null || !mounted) return;
    if (id == manage) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotetypeManagerScreen()));
      return;
    }
    await _selectNotetype(types.firstWhere((t) => t.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final notetypeRepo = context.watch<NotetypeRepository>();
    final deckRepo = context.watch<DeckRepository>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
      },
      child: StreamBuilder<List<Notetype>>(
        stream: notetypeRepo.watchNotetypes(),
        builder: (context, ntSnapshot) {
          final notetypes = ntSnapshot.data ?? const <Notetype>[];
          if (_notetype == null && notetypes.isNotEmpty) {
            final initial = notetypes.firstWhere((n) => n.id == _lastNotetypeId, orElse: () => notetypes.first);
            _notetype = initial;
            WidgetsBinding.instance.addPostFrameCallback((_) => _selectNotetype(initial));
          }

          return StreamBuilder<List<Deck>>(
            stream: deckRepo.watchDecks(),
            builder: (context, deckSnapshot) {
              final decks = deckSnapshot.data ?? const <Deck>[];
              if (_deck == null && decks.isNotEmpty) {
                _deck = decks.firstWhere((d) => d.id == _lastDeckId, orElse: () => decks.first);
              }

              return Scaffold(
                appBar: AppBar(
                  title: Text(_added == 0 ? 'Новая карточка' : 'Добавлено: $_added'),
                  actions: [
                    ListenableBuilder(
                      listenable: Listenable.merge(_fieldControllers.values.toList()),
                      builder: (context, _) => NavBarAction(
                        label: 'Добавить',
                        busy: _saving,
                        onPressed: _deck != null && _hasContent ? _save : null,
                      ),
                    ),
                  ],
                ),
                body: notetypes.isEmpty
                    ? Center(child: Text('Сначала создайте тип карточки', style: Theme.of(context).textTheme.bodySmall))
                    : _form(notetypes, decks),
              );
            },
          );
        },
      ),
    );
  }

  Widget _form(List<Notetype> notetypes, List<Deck> decks) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const SectionHeader('Куда'),
            GroupedSection(children: [
              GroupedPickerRow(
                label: 'Колода',
                value: _deck?.name ?? 'Нет колод',
                icon: CupertinoIcons.rectangle_stack,
                onTap: decks.isEmpty ? null : () => _pickDeck(decks),
              ),
              GroupedPickerRow(
                label: 'Тип',
                value: _notetype?.name ?? '',
                icon: CupertinoIcons.square_grid_2x2,
                iconColor: AppColors.hard,
                onTap: () => _pickNotetype(notetypes),
              ),
            ]),
            for (var i = 0; i < _fields.length; i++) ...[
              SectionHeader(_fields[i].name),
              GroupedSection(children: [
                GroupedTextArea(
                  controller: _fieldControllers[_fields[i].ord]!,
                  focusNode: _focus[_fields[i].ord],
                  autofocus: i == 0,
                  serif: true,
                  placeholder: i == 0 ? 'Слово или вопрос' : (i == 1 ? 'Перевод или ответ' : null),
                ),
              ]),
            ],
            const SectionHeader('Теги'),
            GroupedSection(children: [
              GroupedTextArea(
                controller: _tagsController,
                multiline: false,
                placeholder: 'через пробел, например: глаголы b2',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ]),
            const SectionFooter(
              'Произношение английского слова добавится само, если оно есть в Oxford или Wiktionary. '
              'На компьютере сохранить можно сочетанием Ctrl+Enter.',
            ),
          ],
        ),
      ),
    );
  }
}
