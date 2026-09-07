import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/stats_repository.dart';
import 'package:anki_flutter/domain/scheduler/day_calendar.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boundary coverage for [StatsRepository]'s bucketing logic - the interval
/// histogram edges, the forecast/review-history day windows, and the
/// mature-card threshold are all easy to get off-by-one on, and nothing
/// previously exercised them directly.
void main() {
  late AppDatabase db;
  late StatsRepository stats;
  late int deckId;
  late int noteId;
  late DateTime createdAt;
  late DateTime now;
  late int today;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    final notes = NoteRepository(db, decks, notetypes);
    stats = StatsRepository(db);

    final deck = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default');
    deckId = deck.id;
    final basic = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic');
    await notes.createNote(notetypeId: basic.id, deckId: deckId, fields: ['Q', 'A']);
    final seedCard = await (db.select(db.cards)..where((card) => card.deckId.equals(deckId))).getSingle();
    noteId = seedCard.noteId;

    // Noon avoids any ambiguity with the default 4am rollover hour.
    createdAt = DateTime(2026, 1, 1, 12, 0);
    await (db.update(db.collectionMeta)..where((m) => m.id.equals(1)))
        .write(CollectionMetaCompanion(createdAt: Value(createdAt.millisecondsSinceEpoch)));
    now = DateTime(2026, 3, 1, 12, 0);
    today = dayNumber(now, createdAt, rolloverHour: 4);

    // Each test adds exactly the cards it wants to reason about.
    await (db.delete(db.cards)..where((c) => c.id.equals(seedCard.id))).go();
  });

  tearDown(() async => db.close());

  Future<int> addCard({required CardQueue queue, int ivl = 0, int ease = 2500, int due = 0}) {
    return db.into(db.cards).insert(CardsCompanion.insert(
          noteId: noteId,
          deckId: deckId,
          templateOrd: 0,
          queue: Value(queue),
          ivl: Value(ivl),
          ease: Value(ease),
          due: Value(due),
        ));
  }

  group('interval histogram', () {
    test('bucket edges: ivl 1/2/365/366 land in 0-1d / 2-3d / 6-12mo / 1y+', () async {
      await addCard(queue: CardQueue.review, ivl: 1);
      await addCard(queue: CardQueue.review, ivl: 2);
      await addCard(queue: CardQueue.review, ivl: 365);
      await addCard(queue: CardQueue.review, ivl: 366);

      final result = await stats.load(deckId: deckId, now: now);
      final byLabel = {for (final b in result.intervalHistogram) b.label: b.count};
      expect(byLabel['0-1д'], 1);
      expect(byLabel['2-3д'], 1);
      expect(byLabel['6-12мес'], 1);
      expect(byLabel['1г+'], 1);
    });

    test('non-review cards are excluded', () async {
      await addCard(queue: CardQueue.newCard, ivl: 0);
      await addCard(queue: CardQueue.learning, ivl: 0);
      final result = await stats.load(deckId: deckId, now: now);
      expect(result.intervalHistogram.every((b) => b.count == 0), isTrue);
    });
  });

  group('forecast', () {
    test('due today and due 29 days out are the first/last included offsets', () async {
      await addCard(queue: CardQueue.review, due: today);
      await addCard(queue: CardQueue.review, due: today + 29);
      await addCard(queue: CardQueue.review, due: today + 30); // one day past the 30-day window
      await addCard(queue: CardQueue.review, due: today - 1); // overdue, not a forecast entry

      final result = await stats.load(deckId: deckId, now: now);
      expect(result.forecast, hasLength(30));
      final byOffset = {for (final d in result.forecast) d.dayOffset: d.count};
      expect(byOffset[0], 1);
      expect(byOffset[29], 1);
      expect(result.forecast.fold<int>(0, (a, b) => a + b.count), 2);
    });
  });

  group('review history', () {
    test('29 days back is included; 30 days back and future reviews are not', () async {
      await addCard(queue: CardQueue.review, ivl: 5);
      final card = await (db.select(db.cards)..where((entry) => entry.deckId.equals(deckId))).getSingle();

      Future<void> logAt(DateTime when) => db.into(db.revLog).insert(RevLogCompanion.insert(
            cardId: card.id,
            reviewedAt: when.millisecondsSinceEpoch ~/ 1000,
            rating: 3,
            ivlBefore: 0,
            ivlAfter: 5,
            easeAfter: 2500,
          ));

      await logAt(dayStart(today, createdAt, rolloverHour: 4));
      await logAt(dayStart(today - 29, createdAt, rolloverHour: 4));
      await logAt(dayStart(today - 30, createdAt, rolloverHour: 4));
      await logAt(dayStart(today + 1, createdAt, rolloverHour: 4));

      final result = await stats.load(deckId: deckId, now: now);
      expect(result.reviewHistory, hasLength(30));
      final byOffset = {for (final d in result.reviewHistory) d.dayOffset: d.count};
      expect(byOffset[0], 1);
      expect(byOffset[-29], 1);
      expect(result.reviewHistory.fold<int>(0, (a, b) => a + b.count), 2);
    });
  });

  group('today stats', () {
    test('counts only reviews within the rollover window and computes accuracy', () async {
      await addCard(queue: CardQueue.review, ivl: 5);
      final card = await (db.select(db.cards)..where((entry) => entry.deckId.equals(deckId))).getSingle();
      final todayStart = dayStart(today, createdAt, rolloverHour: 4);

      await db.into(db.revLog).insert(RevLogCompanion.insert(
            cardId: card.id,
            reviewedAt: todayStart.millisecondsSinceEpoch ~/ 1000,
            rating: 3,
            ivlBefore: 0,
            ivlAfter: 5,
            easeAfter: 2500,
            timeTakenMs: const Value(4000),
          ));
      await db.into(db.revLog).insert(RevLogCompanion.insert(
            cardId: card.id,
            reviewedAt: todayStart.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
            rating: 1,
            ivlBefore: 5,
            ivlAfter: 1,
            easeAfter: 2300,
            timeTakenMs: const Value(6000),
          ));
      await db.into(db.revLog).insert(RevLogCompanion.insert(
            cardId: card.id,
            reviewedAt: todayStart.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/ 1000,
            rating: 3,
            ivlBefore: 0,
            ivlAfter: 1,
            easeAfter: 2500,
          ));

      final result = await stats.load(deckId: deckId, now: now);
      expect(result.today.reviewCount, 2);
      expect(result.today.againCount, 1);
      expect(result.today.accuracyPct, 50);
      expect(result.today.minutesStudied, 0); // (4000+6000)ms / 60000 rounds down to 0
    });
  });

  group('mature count', () {
    test("21-day interval is Anki's mature threshold, 20 is not", () async {
      await addCard(queue: CardQueue.review, ivl: 21);
      await addCard(queue: CardQueue.review, ivl: 20);
      final result = await stats.load(deckId: deckId, now: now);
      expect(result.matureCount, 1);
    });
  });

  test('ease histogram reports Anki permille values as percentages', () async {
    await addCard(queue: CardQueue.review, ivl: 10, ease: 2500);
    final result = await stats.load(deckId: deckId, now: now);
    expect(result.easeHistogram, hasLength(1));
    expect(result.easeHistogram.single.label, '250%');
    expect(result.easeHistogram.single.count, 1);
  });
}
