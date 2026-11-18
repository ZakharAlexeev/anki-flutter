import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/domain/scheduler/fsrs.dart';
import 'package:anki_flutter/domain/scheduler/scheduler.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// FSRS end to end through the real database: switching it on, answering,
/// the stored memory state and Anki-format revlog, recomputing from history
/// and undo.
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

  Future<CardEntry> onlyCard() async => (await db.select(db.cards).get()).single;

  test('a new card answered under FSRS gets the FSRS memory state and a learning revlog', () async {
    await study.setFsrsEnabled(true);
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final card = await onlyCard();

    final previews = await study.previewOutcomes(card.id);
    expect(previews[Rating.again], isA<InSecs>()); // 1-minute step
    final result = await study.answerCard(cardId: card.id, rating: Rating.good);

    final after = await onlyCard();
    final defaults = Fsrs.defaults().nextStates(null, 0.9, 0);
    expect(after.fsrsStability, defaults.good.memory.stability);
    expect(after.fsrsDifficulty, defaults.good.memory.difficulty);
    expect(after.fsrsDesiredRetention, closeTo(0.9, 1e-9));
    expect(after.lastReviewedAt, isNotNull);

    final rev = (await db.select(db.revLog).get()).single;
    expect(rev.kind, RevlogKind.learning);
    expect(rev.ivlAfter, lessThan(0), reason: 'learning steps are stored as negative seconds');
    expect(rev.easeAfter, inInclusiveRange(100, 1100), reason: 'FSRS stores shifted difficulty');

    await study.undo(result.undo);
    final restored = await onlyCard();
    expect(restored.fsrsStability, isNull);
    expect(await db.select(db.revLog).get(), isEmpty);
  });

  test('switching FSRS on derives memory states for already-studied cards', () async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final card = await onlyCard();
    final today = await study.today(DateTime.now());
    await (db.update(db.cards)..where((c) => c.id.equals(card.id))).write(CardsCompanion(
      queue: const Value(CardQueue.review),
      ivl: const Value(100),
      ease: const Value(1300),
      due: Value(today),
    ));

    await study.setFsrsEnabled(true);
    final after = await onlyCard();
    // No history: inferred from interval and ease (Anki's zero_history test).
    expect(after.fsrsStability!.round(), 100);
    expect(after.fsrsDifficulty!.round(), 10);

    final previews = await study.previewOutcomes(card.id);
    final good = previews[Rating.good] as InDays;
    expect(good.days, greaterThan(50)); // a long-stable card keeps a long interval
  });

  test('under SM-2 the memory state is cleared on answer, as in Anki', () async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Q', 'A']);
    final card = await onlyCard();
    await (db.update(db.cards)..where((c) => c.id.equals(card.id)))
        .write(const CardsCompanion(fsrsStability: Value(5), fsrsDifficulty: Value(5)));
    await study.answerCard(cardId: card.id, rating: Rating.good);
    expect((await onlyCard()).fsrsStability, isNull);
  });
}
