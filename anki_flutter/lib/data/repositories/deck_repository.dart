import 'package:drift/drift.dart';

import '../db/database.dart';

class DeckRepository {
  DeckRepository(this._db);

  final AppDatabase _db;

  Stream<List<Deck>> watchDecks() => (_db.select(_db.decks)..orderBy([(d) => OrderingTerm.asc(d.name)])).watch();

  Future<Deck> deckById(int id) => (_db.select(_db.decks)..where((d) => d.id.equals(id))).getSingle();

  Future<DeckConfig> _defaultDeckConfig() async {
    final existing = await (_db.select(_db.deckConfigs)..limit(1)).getSingleOrNull();
    if (existing != null) return existing;
    final id = await _db.into(_db.deckConfigs).insert(const DeckConfigsCompanion(name: Value('Default')));
    return (_db.select(_db.deckConfigs)..where((c) => c.id.equals(id))).getSingle();
  }

  Future<int> createDeck(String name, {int? deckConfigId}) async {
    return _db.transaction(() async {
      final int configId;
      if (deckConfigId != null) {
        configId = deckConfigId;
      } else {
        final source = await _defaultDeckConfig();
        configId = await _db.into(_db.deckConfigs).insert(_copyConfig(source, name: name));
      }
      return _db.into(_db.decks).insert(DecksCompanion(name: Value(name), deckConfigId: Value(configId)));
    });
  }

  Future<void> renameDeck(int id, String newName) =>
      (_db.update(_db.decks)..where((d) => d.id.equals(id))).write(DecksCompanion(name: Value(newName)));

  /// Deletes a deck along with its cards (and their review history); any
  /// note left with no remaining cards elsewhere is deleted too, matching
  /// Anki's own deck-delete behaviour.
  Future<void> deleteDeck(int id) async {
    await _db.transaction(() async {
      final deck = await deckById(id);
      final doomedCards = await (_db.select(_db.cards)..where((c) => c.deckId.equals(id))).get();
      final orphanCandidates = doomedCards.map((c) => c.noteId).toSet();

      for (final card in doomedCards) {
        await (_db.delete(_db.revLog)..where((r) => r.cardId.equals(card.id))).go();
      }
      await (_db.delete(_db.cards)..where((c) => c.deckId.equals(id))).go();
      await (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();

      final configUsers = await (_db.select(_db.decks)..where((d) => d.deckConfigId.equals(deck.deckConfigId))).get();
      if (configUsers.isEmpty) {
        await (_db.delete(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).go();
      }

      for (final noteId in orphanCandidates) {
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

  /// Applies a settings edit only to [deckId]. Legacy databases and imported
  /// collections can share option rows, so the row is cloned on edit whenever
  /// another deck still references it.
  Future<void> updateDeckConfig(int deckId, DeckConfigsCompanion patch) async {
    await _db.transaction(() async {
      final deck = await deckById(deckId);
      final current = await configForDeck(deckId);
      final merged = current.copyWithCompanion(patch);
      final users = await (_db.select(_db.decks)..where((d) => d.deckConfigId.equals(current.id))).get();
      if (users.length > 1) {
        final newId = await _db.into(_db.deckConfigs).insert(_copyConfig(merged, name: deck.name));
        await (_db.update(_db.decks)..where((d) => d.id.equals(deckId)))
            .write(DecksCompanion(deckConfigId: Value(newId)));
      } else {
        await (_db.update(_db.deckConfigs)..where((c) => c.id.equals(current.id))).write(patch);
      }
    });
  }

  DeckConfigsCompanion _copyConfig(DeckConfig source, {required String name}) => DeckConfigsCompanion.insert(
        name: name,
        learningStepsMin: Value(source.learningStepsMin),
        relearningStepsMin: Value(source.relearningStepsMin),
        graduatingIntervalDays: Value(source.graduatingIntervalDays),
        easyIntervalDays: Value(source.easyIntervalDays),
        startingEase: Value(source.startingEase),
        easyBonusPct: Value(source.easyBonusPct),
        intervalModifierPct: Value(source.intervalModifierPct),
        hardIntervalPct: Value(source.hardIntervalPct),
        newIntervalPct: Value(source.newIntervalPct),
        leechThreshold: Value(source.leechThreshold),
        maximumIntervalDays: Value(source.maximumIntervalDays),
        minEase: Value(source.minEase),
        newPerDay: Value(source.newPerDay),
        reviewsPerDay: Value(source.reviewsPerDay),
      );
}
