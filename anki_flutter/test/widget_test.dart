import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the deck list with the seeded Default deck', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureSeeded();

    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    final notes = NoteRepository(db, decks, notetypes);
    final study = StudyRepository(db);

    await tester.pumpWidget(AnkiFlutterApp(db: db, decks: decks, notetypes: notetypes, notes: notes, study: study));
    await tester.pumpAndSettle();

    expect(find.text('Колоды'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    // Tear down the widget tree (and with it, drift's stream subscriptions)
    // inside the test body so the debounce timer it schedules on cancel has
    // a chance to fire before the framework's post-test invariant check.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
