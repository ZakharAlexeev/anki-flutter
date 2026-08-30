import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for a real crash: `main.dart` runs the seeding calls on
/// *every* app startup, not just the first. `getSingleOrNull()` throws if a
/// query returns more than one row, so any "does this table already have
/// something in it" check that forgot to `limit(1)` would work on a brand
/// new database (0 rows) but crash the app on its second-ever launch, once
/// the first run's seed data (2 note types, a deck, a deck config) was
/// already there. Caught via `flutter build windows` + running the built
/// exe a second time against its persisted database file.
void main() {
  test('AppDatabase.ensureSeeded and NotetypeRepository.ensureSeeded survive being called repeatedly', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final notetypes = NotetypeRepository(db);
    final decks = DeckRepository(db);

    // Simulate three app launches against the same (persisted) database.
    for (var i = 0; i < 3; i++) {
      await db.ensureSeeded();
      await notetypes.ensureSeeded();
    }

    final notetypeRows = await db.select(db.notetypes).get();
    final deckConfigRowsAfterSeeding = await db.select(db.deckConfigs).get();
    final deckRows = await db.select(db.decks).get();
    expect(deckRows.where((deck) => deck.name == 'Default'), hasLength(1));
    expect(deckRows.where((deck) => deck.name == 'Английский'), hasLength(1));
    expect(notetypeRows, hasLength(3), reason: 'ensureSeeded must not duplicate the seeded note types');
    expect(deckConfigRowsAfterSeeding, hasLength(1), reason: 'ensureSeeded must not duplicate the default deck config');

    // DeckRepository's own default-config lookup has the same "does this
    // table already have something" shape - exercise it repeatedly too, and
    // confirm it remains stable while each new deck receives an independent
    // copy of the defaults.
    for (var i = 0; i < 3; i++) {
      await decks.createDeck('Extra $i');
    }

    expect(await db.select(db.decks).get(), hasLength(5)); // Default + English + 3 extra
    expect(await db.select(db.deckConfigs).get(), hasLength(4));
  });
}
