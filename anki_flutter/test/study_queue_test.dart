import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for a reported bug: in a deck with many cards, answering
/// anything but "Easy" made the *same* card reappear as the very next card,
/// over and over, instead of cycling through the rest of the deck. Root
/// cause was [StudyRepository.dueQueue] always listing every learning-queue
/// card first - including one whose step delay (1-10 minutes) hadn't even
/// elapsed yet - so it jumped the queue ahead of everything else.
void main() {
  late AppDatabase db;
  late DeckRepository decks;
  late NoteRepository notes;
  late StudyRepository study;
  late int deckId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    notes = NoteRepository(db, decks, notetypes);
    study = StudyRepository(db);

    final deck = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default');
    deckId = deck.id;
  });

  tearDown(() async => db.close());

  test('answering Again on one card of many does not immediately resurface it', () async {
    final basic = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic');
    // The deck's default newPerDay limit is 20 - well above 1, which is all
    // that's needed to prove the answered card no longer jumps the queue.
    for (var i = 0; i < 40; i++) {
      await notes.createNote(notetypeId: basic.id, deckId: deckId, fields: ['Q$i', 'A$i']);
    }

    final now = DateTime.now();
    final initialQueue = await study.dueQueue(deckId, now: now);
    expect(initialQueue, hasLength(20));
    final firstCard = initialQueue.first;

    await study.answerCard(cardId: firstCard.id, rating: Rating.again, now: now);

    // The answered card's next learning step is 1 minute out - well within
    // dueQueue's 20-minute look-ahead window, so it's still in the queue,
    // but the other, untouched new cards should all come before it now.
    final requeued = await study.dueQueue(deckId, now: now);
    expect(requeued, hasLength(20));
    expect(requeued.first.id, isNot(firstCard.id));
    expect(requeued.last.id, firstCard.id);
  });

  test('a learning step that has already elapsed does resurface immediately', () async {
    final basic = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic');
    for (var i = 0; i < 5; i++) {
      await notes.createNote(notetypeId: basic.id, deckId: deckId, fields: ['Q$i', 'A$i']);
    }

    final now = DateTime.now();
    final firstCard = (await study.dueQueue(deckId, now: now)).first;
    await study.answerCard(cardId: firstCard.id, rating: Rating.again, now: now);

    // Simulate two minutes passing - past the 1-minute "Again" step delay.
    final later = now.add(const Duration(minutes: 2));
    final requeued = await study.dueQueue(deckId, now: later);
    expect(requeued.first.id, firstCard.id);
  });
}
