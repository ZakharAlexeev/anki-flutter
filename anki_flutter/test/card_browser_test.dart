import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/ui/browser/card_browser_screen.dart';
import 'package:anki_flutter/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
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

    final defaultDeck = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default');
    deckId = defaultDeck.id;
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
    final noteId =
        await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Capital of Japan', 'Tokyo']);

    await tester.pumpWidget(wrap(CardBrowserScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Capital of France'), findsOneWidget);
    expect(find.textContaining('Capital of Japan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Japan');
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital of France'), findsNothing);
    expect(find.textContaining('Capital of Japan'), findsOneWidget);
  });

  testWidgets('edits a field, suspends the card, then deletes the note', (tester) async {
    await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['Capital of Japan', 'Tokyo']);

    await tester.pumpWidget(wrap(CardBrowserScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Capital of Japan'), findsOneWidget);

    // Edit the Back field through the edit dialog.
    await tester.tap(find.byTooltip('Редактировать'));
    await tester.pumpAndSettle();
    final backField = find.widgetWithText(TextField, 'Tokyo');
    expect(backField, findsOneWidget);
    await tester.enterText(backField, 'Tokyo (東京)');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    var note = await (db.select(db.notes)..where((note) => note.id.equals(noteId))).getSingle();
    expect(notes.decodeFields(note.fieldsJson)[1], 'Tokyo (東京)');

    // Suspend the card via the row action.
    await tester.tap(find.byTooltip('Приостановить'));
    await tester.pumpAndSettle();
    var card = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).getSingle();
    expect(card.queue, CardQueue.suspended);

    // The tooltip flips once suspended, confirming the toggle round-trips.
    await tester.tap(find.byTooltip('Возобновить'));
    await tester.pumpAndSettle();
    card = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).getSingle();
    expect(card.queue, isNot(CardQueue.suspended));

    // Delete the note entirely.
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Capital of Japan'), findsNothing);
    expect(await (db.select(db.notes)..where((note) => note.id.equals(noteId))).get(), isEmpty);
  });
}
