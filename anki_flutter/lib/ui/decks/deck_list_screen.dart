import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../editor/note_editor_screen.dart';
import '../import/import_screen.dart';
import '../study/study_screen.dart';

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
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Импорт .apkg',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Deck>>(
        stream: deckRepo.watchDecks(),
        builder: (context, snapshot) {
          final decks = snapshot.data ?? const <Deck>[];
          if (decks.isEmpty) {
            return const Center(child: Text('Пока нет колод — создайте первую кнопкой ниже.'));
          }
          return ListView.separated(
            itemCount: decks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _DeckTile(deck: decks[index]),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addNote',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Карточка'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'addDeck',
            onPressed: () => _createDeck(context),
            child: const Icon(Icons.create_new_folder_outlined),
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
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Название колоды')),
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

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final study = context.read<StudyRepository>();
    return FutureBuilder<DueQueueCounts>(
      future: study.counts(deck.id),
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return ListTile(
          title: Text(deck.name),
          subtitle: counts == null
              ? null
              : Row(
                  children: [
                    _countChip(counts.newCount, Colors.blue),
                    const SizedBox(width: 8),
                    _countChip(counts.learningCount, Colors.red),
                    const SizedBox(width: 8),
                    _countChip(counts.reviewCount, Colors.green),
                  ],
                ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Удалить колоду')),
            ],
          ),
          onTap: (counts?.total ?? 0) == 0
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudyScreen(deckId: deck.id, deckName: deck.name))),
        );
      },
    );
  }

  Widget _countChip(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold));
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
