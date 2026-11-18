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
  int get schemaVersion => 5;

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
          if (from < 3) await _removeStarterDecks();
          if (from < 4) await m.addColumn(deckConfigs, deckConfigs.leechSuspends);
          if (from < 5) {
            // FSRS: card memory state, Anki revlog kinds, preset options and
            // collection switches.
            for (final c in [cards.fsrsStability, cards.fsrsDifficulty, cards.fsrsDesiredRetention, cards.fsrsDecay]) {
              await m.addColumn(cards, c);
            }
            await m.addColumn(revLog, revLog.kind);
            // Older rows weren't typed: a review that started from no
            // interval was a learning step, anything else a review.
            await customStatement('UPDATE rev_log SET kind = CASE WHEN ivl_before = 0 THEN 0 ELSE 1 END');
            for (final c in [
              deckConfigs.minimumLapseInterval,
              deckConfigs.fsrsParams,
              deckConfigs.desiredRetention,
              deckConfigs.historicalRetention,
              deckConfigs.ignoreRevlogsBeforeDate,
              deckConfigs.easyDaysPercentages,
            ]) {
              await m.addColumn(deckConfigs, c);
            }
            for (final c in [
              collectionMeta.fsrsEnabled,
              collectionMeta.loadBalancerEnabled,
              collectionMeta.fsrsShortTermWithSteps,
            ]) {
              await m.addColumn(collectionMeta, c);
            }
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

  /// Ensures a single [CollectionMeta] row and a default deck config exist.
  /// Safe to call on every startup. No decks are created: a fresh install
  /// starts empty and the user makes their own.
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
      if (anyDeckConfig == null) {
        await into(deckConfigs).insert(const DeckConfigsCompanion(name: Value('Default')));
      }
    });
  }

  /// One-off cleanup (schema v3) of the starter content older versions
  /// created on first launch: the "Default" deck and the "Английский"
  /// vocabulary deck with its note type. Runs exactly once, as a migration,
  /// so a deck the user later creates with one of these names is never
  /// touched. The starter vocabulary (tagged `seed::english`) is deleted
  /// with its review history; a deck is only dropped once it is empty, so
  /// cards the user added to it themselves survive.
  Future<void> _removeStarterDecks() async {
    const seedNotes = "SELECT id FROM notes WHERE tags = 'seed::english'";
    await customStatement('DELETE FROM rev_log WHERE card_id IN (SELECT id FROM cards WHERE note_id IN ($seedNotes))');
    await customStatement('DELETE FROM cards WHERE note_id IN ($seedNotes)');
    await customStatement("DELETE FROM notes WHERE tags = 'seed::english'");

    for (final name in ['Английский', 'Default']) {
      await customStatement(
        'DELETE FROM decks WHERE name = ? AND NOT EXISTS (SELECT 1 FROM cards WHERE cards.deck_id = decks.id)',
        [name],
      );
    }

    const vocabType = "SELECT id FROM notetypes WHERE name = 'English Vocabulary RU→EN' "
        'AND NOT EXISTS (SELECT 1 FROM notes WHERE notes.notetype_id = notetypes.id)';
    await customStatement('DELETE FROM notetype_templates WHERE notetype_id IN ($vocabType)');
    await customStatement('DELETE FROM notetype_fields WHERE notetype_id IN ($vocabType)');
    await customStatement(
      "DELETE FROM notetypes WHERE name = 'English Vocabulary RU→EN' "
      'AND NOT EXISTS (SELECT 1 FROM notes WHERE notes.notetype_id = notetypes.id)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'anki_flutter');
}
