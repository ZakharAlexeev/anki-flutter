import 'dart:convert';
import 'dart:io';

import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/export/apkg_exporter.dart';
import 'package:anki_flutter/data/import/apkg_importer.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the whole point of the export feature: a card's actual scheduling
/// state - not just its front/back text - survives a round trip out to a
/// real `.apkg` file and back in, exactly like exporting "with scheduling"
/// from Anki itself does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('apkg_roundtrip_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('exported .apkg re-imports with interval, ease, lapses and review history intact', () async {
    final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
    await sourceDb.ensureSeeded();
    final decks = DeckRepository(sourceDb);
    final notetypes = NotetypeRepository(sourceDb);
    await notetypes.ensureSeeded();
    final notes = NoteRepository(sourceDb, decks, notetypes);

    final deck = (await sourceDb.select(sourceDb.decks).get()).firstWhere((deck) => deck.name == 'Default');
    final basic = (await sourceDb.select(sourceDb.notetypes).get()).firstWhere((n) => n.name == 'Basic');
    await notes.createNote(notetypeId: basic.id, deckId: deck.id, fields: ['Capital of France?', 'Paris']);

    // Simulate a card that's been studied for a while: a mature review card
    // with a lapse in its past, plus one recorded review in the log.
    final card = await (sourceDb.select(sourceDb.cards)..where((card) => card.deckId.equals(deck.id))).getSingle();
    await (sourceDb.update(sourceDb.cards)..where((c) => c.id.equals(card.id))).write(
      const CardsCompanion(
        queue: Value(CardQueue.review),
        ivl: Value(47),
        ease: Value(2280),
        reps: Value(6),
        lapses: Value(1),
        due: Value(500),
      ),
    );
    await sourceDb.into(sourceDb.revLog).insert(
          RevLogCompanion.insert(
            cardId: card.id,
            reviewedAt: 1700000000,
            rating: 3,
            ivlBefore: 20,
            ivlAfter: 47,
            easeAfter: 2280,
          ),
        );

    final exportPath = '${tempDir.path}/export_test.apkg';
    final progressLog = <String>[];
    await for (final p in ApkgExporter(sourceDb).exportDecks([deck.id], exportPath)) {
      progressLog.add(p.phase);
    }
    expect(File(exportPath).existsSync(), isTrue);
    await sourceDb.close();

    final destDb = AppDatabase.forTesting(NativeDatabase.memory());
    await destDb.ensureSeeded();
    await for (final _ in ApkgImporter(destDb).import(exportPath)) {}

    final importedDeck = (await destDb.select(destDb.decks).get()).firstWhere((deck) => deck.name == 'Default');
    final importedCards = await (destDb.select(destDb.cards)
          ..where((card) => card.deckId.equals(importedDeck.id)))
        .get();
    expect(importedCards, hasLength(1));
    final imported = importedCards.single;
    expect(imported.queue, CardQueue.review);
    expect(imported.ivl, 47);
    expect(imported.ease, 2280);
    expect(imported.reps, 6);
    expect(imported.lapses, 1);

    final importedNoteIds = importedCards.map((card) => card.noteId).toSet();
    final importedNotes = await (destDb.select(destDb.notes)..where((note) => note.id.isIn(importedNoteIds))).get();
    expect(importedNotes, hasLength(1));
    expect(importedNotes.single.fieldsJson, contains('Paris'));

    final importedRevlog = await destDb.select(destDb.revLog).get();
    expect(importedRevlog, hasLength(1));
    expect(importedRevlog.single.ivlAfter, 47);

    await destDb.close();
  });

  test('export never packages a media reference outside the app media directory', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureSeeded();
    final decks = DeckRepository(db);
    final notetypes = NotetypeRepository(db);
    await notetypes.ensureSeeded();
    final notes = NoteRepository(db, decks, notetypes);
    final deck = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default');
    final basic = (await db.select(db.notetypes).get()).firstWhere((notetype) => notetype.name == 'Basic');

    final mediaDir = Directory('${tempDir.path}/media');
    await mediaDir.create();
    await File('${tempDir.path}/private.txt').writeAsString('must not be exported');
    await notes.createNote(
      notetypeId: basic.id,
      deckId: deck.id,
      fields: ['Secret attachment <img src="../private.txt">', 'Answer'],
    );

    final exportPath = '${tempDir.path}/safe_export.apkg';
    await for (final _ in ApkgExporter(db).exportDecks([deck.id], exportPath)) {}
    final archive = ZipDecoder().decodeBytes(await File(exportPath).readAsBytes());
    final mediaEntry = archive.files.firstWhere((file) => file.name == 'media');
    final mediaIndex = jsonDecode(utf8.decode(mediaEntry.content as List<int>)) as Map<String, dynamic>;
    expect(mediaIndex, isEmpty);
    expect(archive.files.map((file) => file.name), isNot(contains('private.txt')));

    await db.close();
  });
}
