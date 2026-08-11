import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/ui/study/study_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// End-to-end coverage of the create-a-card -> study-it path: seeds a fresh
/// DB the way `main.dart` does, creates a real "Basic" note, then drives the
/// actual [StudyScreen] (template rendering, HTML display, answer buttons)
/// through a full Again -> Good cycle and checks the persisted scheduling
/// state matches what the scheduler unit tests already proved the formulas
/// produce.
void main() {
  late AppDatabase db;
  late DeckRepository decks;
  late NotetypeRepository notetypes;
  late NoteRepository notes;
  late StudyRepository study;
  late int deckId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    decks = DeckRepository(db);
    notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    notes = NoteRepository(db, decks, notetypes);
    study = StudyRepository(db);

    final defaultDeck = (await db.select(db.decks).get()).single;
    deckId = defaultDeck.id;
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<DeckRepository>.value(value: decks),
        Provider<NotetypeRepository>.value(value: notetypes),
        Provider<NoteRepository>.value(value: notes),
        Provider<StudyRepository>.value(value: study),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('creating a Basic note and studying it drives the card through learning into review', (tester) async {
    final basic = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic');
    await notes.createNote(notetypeId: basic.id, deckId: deckId, fields: ['Question', 'Answer']);

    var due = await study.dueQueue(deckId);
    expect(due, hasLength(1));
    expect(due.single.queue, CardQueue.newCard);

    await tester.pumpWidget(wrap(StudyScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();

    // The question side renders before the answer is revealed.
    expect(find.text('Показать ответ'), findsOneWidget);
    expect(find.textContaining('Question'), findsOneWidget);
    expect(find.textContaining('Answer'), findsNothing);

    await tester.tap(find.text('Показать ответ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Answer'), findsOneWidget);
    expect(find.text('Хорошо'), findsOneWidget);

    // Good on a fresh card advances it to the second learning step ([1, 10]
    // minutes by default) rather than graduating it immediately.
    await tester.tap(find.text('Хорошо'));
    await tester.pumpAndSettle();

    due = await study.dueQueue(deckId);
    expect(due, isEmpty, reason: 'the 10-minute-away learning step should not be due yet');

    final afterFirstGood = (await db.select(db.cards).get()).single;
    expect(afterFirstGood.queue, CardQueue.learning);
    expect(afterFirstGood.stepIndex, 1);
    expect(afterFirstGood.reps, 1);

    // Jump forward in wall-clock time (as the study screen would on the
    // next app open) to bring the card due, then answer Good again to
    // graduate it into the review queue.
    final future = DateTime.now().add(const Duration(minutes: 15));
    due = await study.dueQueue(deckId, now: future);
    expect(due, hasLength(1));
    await study.answerCard(cardId: due.single.id, rating: Rating.good, now: future);

    final graduated = (await db.select(db.cards).get()).single;
    expect(graduated.queue, CardQueue.review);
    expect(graduated.ivl, 1); // default graduating interval
    expect(graduated.reps, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
