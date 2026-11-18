import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/stats_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:anki_flutter/main.dart';
import 'package:anki_flutter/ui/theme/theme_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the More tab switches between automatic, light and dark themes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureSeeded();
    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    final theme = ThemeController();

    await tester.pumpWidget(AnkiFlutterApp(
      db: db,
      decks: decks,
      notetypes: notetypes,
      notes: NoteRepository(db, decks, notetypes),
      study: StudyRepository(db),
      stats: StatsRepository(db),
      theme: theme,
    ));
    await tester.pumpAndSettle();

    Brightness brightness() => Theme.of(tester.element(find.text('ОФОРМЛЕНИЕ'))).brightness;

    await tester.tap(find.text('Ещё'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.system);

    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.dark);
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(theme.mode, ThemeMode.light);
    expect(brightness(), Brightness.light);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
