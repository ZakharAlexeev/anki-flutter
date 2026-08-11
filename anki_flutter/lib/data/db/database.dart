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
  int get schemaVersion => 1;

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
