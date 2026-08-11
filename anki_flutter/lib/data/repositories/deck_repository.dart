import 'package:drift/drift.dart';

import '../db/database.dart';

class DeckRepository {
  DeckRepository(this._db);

  final AppDatabase _db;

  Stream<List<Deck>> watchDecks() => (_db.select(_db.decks)..orderBy([(d) => OrderingTerm.asc(d.name)])).watch();

  Future<Deck> deckById(int id) => (_db.select(_db.decks)..where((d) => d.id.equals(id))).getSingle();

  Future<int> _defaultDeckConfigId() async {
    final existing = await _db.select(_db.deckConfigs).getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.deckConfigs).insert(const DeckConfigsCompanion(name: Value('Default')));
  }

  Future<int> createDeck(String name, {int? deckConfigId}) async {
    final configId = deckConfigId ?? await _defaultDeckConfigId();
    return _db.into(_db.decks).insert(DecksCompanion(name: Value(name), deckConfigId: Value(configId)));
  }

  Future<void> renameDeck(int id, String newName) =>
      (_db.update(_db.decks)..where((d) => d.id.equals(id))).write(DecksCompanion(name: Value(newName)));

  /// Deletes a deck along with its cards; any note left with no remaining
  /// cards elsewhere is deleted too, matching Anki's own deck-delete
  /// behaviour.
  Future<void> deleteDeck(int id) async {
    await _db.transaction(() async {
      final orphanCandidates = await (_db.selectOnly(_db.cards)
            ..addColumns([_db.cards.noteId])
            ..where(_db.cards.deckId.equals(id)))
          .map((row) => row.read(_db.cards.noteId)!)
          .get();

      await (_db.delete(_db.cards)..where((c) => c.deckId.equals(id))).go();
      await (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();

      for (final noteId in orphanCandidates.toSet()) {
        final remaining = await (_db.select(_db.cards)..where((c) => c.noteId.equals(noteId))).get();
        if (remaining.isEmpty) {
          await (_db.delete(_db.notes)..where((n) => n.id.equals(noteId))).go();
        }
      }
    });
  }

  Future<DeckConfig> configForDeck(int deckId) async {
    final deck = await deckById(deckId);
    return (_db.select(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).getSingle();
  }

  Future<void> updateDeckConfig(DeckConfigsCompanion patch) =>
      (_db.update(_db.deckConfigs)..where((c) => c.id.equals(patch.id.value))).write(patch);
}
