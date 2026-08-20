import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/scheduler/models.dart' show CardQueue;
import 'tables.dart';

export '../../domain/scheduler/models.dart' show CardQueue, Rating, CardSchedState;

part 'database.g.dart';

@DriftDatabase(tables: [
  DeckConfigs,
  Decks,
  Notetypes,
  NotetypeFields,
  NotetypeTemplates,
  Notes,
  Cards,
  RevLog,
  CollectionMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(decks, decks.newShownToday);
            await m.addColumn(decks, decks.newShownDay);
            await m.addColumn(decks, decks.reviewsShownToday);
            await m.addColumn(decks, decks.reviewsShownDay);

            // v1 accidentally stored createdAt in *microseconds* (reusing
            // the ID generator) instead of milliseconds. A real millisecond
            // "now" is ~13 digits; a microsecond value misread as millis is
            // ~16, comfortably past this threshold (year ~5138 in millis).
            const microsecondThreshold = 100000000000000; // 1e14
            await customStatement(
              'UPDATE collection_meta SET created_at = created_at / 1000 WHERE created_at > $microsecondThreshold',
            );
            await customStatement(
              'UPDATE notes SET created_at = created_at / 1000 WHERE created_at > $microsecondThreshold',
            );
          }
        },
        beforeOpen: (details) async {
          // SQLite defaults foreign-key enforcement to OFF for backwards
          // compatibility - without this, deleting a deck/notetype out from
          // under a card would silently leave a dangling reference instead
          // of erroring, masking bugs in the cleanup code that's supposed
          // to delete dependents first (see deck_repository.dart,
          // notetype_repository.dart, note_repository.dart).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Ensures a single [CollectionMeta] row and a default [DeckConfigs] +
  /// "Default" deck exist, mirroring a fresh Anki profile. Safe to call on
  /// every startup.
  Future<void> ensureSeeded() async {
    await transaction(() async {
      // getSingleOrNull() throws if more than one row comes back, so every
      // "does this table already have anything in it" check here is capped
      // with limit(1) - otherwise this crashes on every startup after the
      // first, once these tables legitimately hold more than one row.
      final metaExists = await (select(collectionMeta)..limit(1)).getSingleOrNull();
      if (metaExists == null) {
        await into(collectionMeta).insert(const CollectionMetaCompanion(id: Value(1)));
      }

      final anyDeckConfig = await (select(deckConfigs)..limit(1)).getSingleOrNull();
      var deckConfigId = anyDeckConfig?.id;
      deckConfigId ??= await into(deckConfigs).insert(const DeckConfigsCompanion(name: Value('Default')));

      final anyDeck = await (select(decks)..limit(1)).getSingleOrNull();
      if (anyDeck == null) {
        await into(decks).insert(DecksCompanion(name: const Value('Default'), deckConfigId: Value(deckConfigId)));
      }
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'anki_flutter');
}
