import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/notetype_repository.dart';
import 'notetype_manager_screen.dart';

/// Create-a-note screen: pick a note type + deck, fill in the note type's
/// fields, save. One card is generated per template of the chosen note type
/// (see [NoteRepository.createNote]).
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  Notetype? _notetype;
  Deck? _deck;
  List<NotetypeField> _fields = const [];
  final Map<int, TextEditingController> _fieldControllers = {};
  final _tagsController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _onNotetypeChanged(Notetype? nt) async {
    if (nt == null) return;
    final fields = await context.read<NotetypeRepository>().fieldsFor(nt.id);
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    _fieldControllers.clear();
    for (final f in fields) {
      _fieldControllers[f.ord] = TextEditingController();
    }
    setState(() {
      _notetype = nt;
      _fields = fields;
    });
  }

  Future<void> _save() async {
    final notetype = _notetype;
    final deck = _deck;
    if (notetype == null || deck == null) return;

    final fieldValues = List<String>.generate(_fields.length, (i) => _fieldControllers[i]?.text ?? '');
    if (fieldValues.every((v) => v.trim().isEmpty)) return;

    setState(() => _saving = true);
    await context.read<NoteRepository>().createNote(
          notetypeId: notetype.id,
          deckId: deck.id,
          fields: fieldValues,
          tags: _tagsController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    for (final c in _fieldControllers.values) {
      c.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Карточка добавлена')));
  }

  @override
  Widget build(BuildContext context) {
    final notetypeRepo = context.watch<NotetypeRepository>();
    final deckRepo = context.watch<DeckRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая карточка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Типы карточек',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotetypeManagerScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Notetype>>(
        stream: notetypeRepo.watchNotetypes(),
        builder: (context, ntSnapshot) {
          final notetypes = ntSnapshot.data ?? const <Notetype>[];
          if (notetypes.isEmpty) {
            return const Center(child: Text('Сначала создайте тип карточки'));
          }
          _notetype ??= notetypes.first;
          if (_fields.isEmpty && _fieldControllers.isEmpty) {
            // First build after notetypes arrive: load fields once.
            WidgetsBinding.instance.addPostFrameCallback((_) => _onNotetypeChanged(_notetype));
          }

          return StreamBuilder<List<Deck>>(
            stream: deckRepo.watchDecks(),
            builder: (context, deckSnapshot) {
              final decks = deckSnapshot.data ?? const <Deck>[];
              _deck ??= decks.isNotEmpty ? decks.first : null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<Notetype>(
                    initialValue: notetypes.contains(_notetype) ? _notetype : notetypes.first,
                    decoration: const InputDecoration(labelText: 'Тип карточки'),
                    items: [for (final nt in notetypes) DropdownMenuItem(value: nt, child: Text(nt.name))],
                    onChanged: _onNotetypeChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Deck>(
                    initialValue: decks.contains(_deck) ? _deck : (decks.isNotEmpty ? decks.first : null),
                    decoration: const InputDecoration(labelText: 'Колода'),
                    items: [for (final d in decks) DropdownMenuItem(value: d, child: Text(d.name))],
                    onChanged: (d) => setState(() => _deck = d),
                  ),
                  const SizedBox(height: 20),
                  for (final field in _fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _fieldControllers[field.ord],
                        maxLines: null,
                        decoration: InputDecoration(labelText: field.name, border: const OutlineInputBorder()),
                      ),
                    ),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Теги (через пробел)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: (_deck == null || _saving) ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _saving ? const CircularProgressIndicator() : const Text('Сохранить'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
