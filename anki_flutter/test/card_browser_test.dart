import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/ui/browser/card_browser_screen.dart';
import 'package:anki_flutter/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Covers the card browser screen added to close the audit's "no way to
/// search/edit/delete/(un)suspend an existing note" gap.
void main() {
  late AppDatabase db;
  late DeckRepository decks;
  late NotetypeRepository notetypes;
  late NoteRepository notes;
  late StudyRepository study;
  late int deckId;
  late int basicId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    decks = DeckRepository(db);
    notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    notes = NoteRepository(db, decks, notetypes);
    study = StudyRepository(db);

    deckId = await decks.createDeck('Default');
    basicId = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic').id;
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
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  testWidgets('lists both notes and search filters the list down', (tester) async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Capital of France', 'Paris']);
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Capital of Japan', 'Tokyo']);

    await tester.pumpWidget(wrap(CardBrowserScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Capital of France'), findsOneWidget);
    expect(find.textContaining('Capital of Japan'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'Japan');
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital of France'), findsNothing);
    expect(find.textContaining('Capital of Japan'), findsOneWidget);
  });

  testWidgets('tap a card to edit it, suspend and unsuspend it, then delete the note', (tester) async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Capital of Japan', 'Tokyo']);

    await tester.pumpWidget(wrap(CardBrowserScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();

    // Edit the Back field on the card's screen.
    await tester.tap(find.textContaining('Capital of Japan'));
    await tester.pumpAndSettle();
    final backField = find.widgetWithText(TextField, 'Tokyo');
    expect(backField, findsOneWidget);
    await tester.enterText(backField, 'Tokyo (東京)');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    var note = (await db.select(db.notes).get()).single;
    expect(notes.decodeFields(note.fieldsJson)[1], 'Tokyo (東京)');

    // Suspend, then unsuspend, from the card's screen.
    await tester.tap(find.textContaining('Capital of Japan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отложить карточку'));
    await tester.pumpAndSettle();
    expect((await db.select(db.cards).get()).single.queue, CardQueue.suspended);
    await tester.tap(find.text('Вернуть в повторения'));
    await tester.pumpAndSettle();
    expect((await db.select(db.cards).get()).single.queue, isNot(CardQueue.suspended));

    // Delete the note.
    await tester.tap(find.text('Удалить заметку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Capital of Japan'), findsNothing);
    expect(await db.select(db.notes).get(), isEmpty);
  });
}
