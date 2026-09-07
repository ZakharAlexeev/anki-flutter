import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/ui/decks/deck_settings_screen.dart';
import 'package:anki_flutter/ui/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Covers the deck settings screen added to close the audit's "no UI for
/// DeckConfigs" gap - `DeckRepository.updateDeckConfig` already existed but
/// nothing called it outside of .apkg import.
void main() {
  late AppDatabase db;
  late DeckRepository decks;
  late int deckId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    decks = DeckRepository(db);

    final deck = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default');
    deckId = deck.id;
  });

  tearDown(() async => db.close());

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<DeckRepository>.value(value: decks),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  testWidgets('loads the current config into the form and persists an edit on save', (tester) async {
    // The form has 14 fields in a ListView - a normal test viewport clips
    // it, and ListView only builds the on-screen ones into the element
    // tree. Enlarging the surface avoids needing to scroll mid-test.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(DeckSettingsScreen(deckId: deckId, deckName: 'Default')));
    await tester.pumpAndSettle();

    // Defaults from DeckConfigs: newPerDay 20, reviewsPerDay 200.
    expect(find.widgetWithText(TextField, '20'), findsOneWidget);
    expect(find.widgetWithText(TextField, '200'), findsOneWidget);

    final newPerDayField = find.widgetWithText(TextField, '20');
    await tester.enterText(newPerDayField, '15');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final config = await decks.configForDeck(deckId);
    expect(config.newPerDay, 15);
  });
}
