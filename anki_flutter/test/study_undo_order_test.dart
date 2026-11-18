import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Undo, leech tagging, the answer-time cap and the mixed queue order.
void main() {
  late AppDatabase db;
  late NoteRepository notes;
  late StudyRepository study;
  late int deckId;
  late int basicId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    notes = NoteRepository(db, decks, notetypes);
    study = StudyRepository(db);
    deckId = await decks.createDeck('Test');
    basicId = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic').id;
  });

  tearDown(() => db.close());

  Future<CardEntry> card(int id) => (db.select(db.cards)..where((c) => c.id.equals(id))).getSingle();

  test('undo restores the card, removes the review and gives the daily new-card slot back', () async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final before = (await db.select(db.cards).get()).single;

    final result = await study.answerCard(cardId: before.id, rating: Rating.good);
    expect((await card(before.id)).queue, CardQueue.learning);
    expect(await db.select(db.revLog).get(), hasLength(1));
    final deckAfter = await (db.select(db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    expect(deckAfter.newShownToday, 1);

    await study.undo(result.undo);
    final restored = await card(before.id);
    expect(restored.queue, CardQueue.newCard);
    expect(restored.reps, before.reps);
    expect(await db.select(db.revLog).get(), isEmpty);
    final deckRestored = await (db.select(db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    expect(deckRestored.newShownToday, 0);
  });

  test('a leech gets the "leech" tag, and undo takes the tag away again', () async {
    final noteId = await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final c = (await db.select(db.cards).get()).single;
    final today = await study.today(DateTime.now());
    await (db.update(db.cards)..where((x) => x.id.equals(c.id))).write(CardsCompanion(
      queue: const Value(CardQueue.review),
      ivl: const Value(5),
      due: Value(today),
      lapses: const Value(7),
    ));

    final result = await study.answerCard(cardId: c.id, rating: Rating.again);
    expect(result.outcome.becameLeech, isTrue);
    Future<String> tags() async => (await (db.select(db.notes)..where((n) => n.id.equals(noteId))).getSingle()).tags;
    expect(await tags(), contains('leech'));
    expect((await card(c.id)).queue, CardQueue.relearning, reason: "Anki's default leech action only tags");

    await study.undo(result.undo);
    expect(await tags(), isNot(contains('leech')));
  });

  test('answer time is capped at 60 seconds, like Anki', () async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final c = (await db.select(db.cards).get()).single;
    await study.answerCard(cardId: c.id, rating: Rating.good, timeTakenMs: 5 * 60 * 1000);
    expect((await db.select(db.revLog).get()).single.timeTakenMs, 60000);
  });

  test('new cards are spread evenly between reviews', () async {
    String kinds(List<CardEntry> q) => q.map((c) => c.queue == CardQueue.newCard ? 'N' : 'R').join();
    CardEntry fake(int id, CardQueue queue) => CardEntry(
          id: id,
          noteId: id,
          deckId: deckId,
          templateOrd: 0,
          queue: queue,
          due: 0,
          ivl: 0,
          ease: 2500,
          reps: 0,
          lapses: 0,
          stepIndex: 0,
        );
    List<CardEntry> many(int n, CardQueue q, int offset) => [for (var i = 0; i < n; i++) fake(offset + i, q)];

    expect(kinds(StudyRepository.intersperse(many(2, CardQueue.review, 0), many(1, CardQueue.newCard, 100))), 'RNR');
    expect(kinds(StudyRepository.intersperse(many(4, CardQueue.review, 0), many(1, CardQueue.newCard, 100))), 'RRNRR');
    expect(
      kinds(StudyRepository.intersperse(many(6, CardQueue.review, 0), many(2, CardQueue.newCard, 100))),
      'RRNRRNRR',
    );
    expect(kinds(StudyRepository.intersperse(const [], many(2, CardQueue.newCard, 100))), 'NN');
  });
}
