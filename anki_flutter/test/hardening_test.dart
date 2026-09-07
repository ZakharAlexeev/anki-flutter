import 'dart:typed_data';

import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/import/archive_safety.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:anki_flutter/data/repositories/study_repository.dart';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('archive envelope validation', () {
    test('accepts a normal ZIP and rejects a truncated file', () {
      final archive = Archive()..addFile(ArchiveFile('collection.anki2', 3, [1, 2, 3]));
      final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
      expect(() => validateZipEnvelope(bytes), returnsNormally);
      expect(() => validateZipEnvelope(Uint8List.fromList([1, 2, 3])), throwsA(isA<ImportException>()));
    });

    test('rejects an entry whose declared expanded size exceeds the limit', () {
      final archive = Archive()..addFile(ArchiveFile('collection.anki2', 3, [1, 2, 3]));
      final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
      final data = ByteData.sublistView(bytes);
      var centralOffset = -1;
      for (var i = 0; i <= bytes.length - 4; i++) {
        if (data.getUint32(i, Endian.little) == 0x02014b50) {
          centralOffset = i;
          break;
        }
      }
      expect(centralOffset, greaterThanOrEqualTo(0));
      data.setUint32(centralOffset + 24, maxSingleArchiveEntryBytes + 1, Endian.little);
      expect(() => validateZipEnvelope(bytes), throwsA(isA<ImportException>()));
    });
  });

  group('data integrity fixes', () {
    late AppDatabase db;
    late DeckRepository decks;
    late NotetypeRepository notetypes;
    late NoteRepository notes;
    late int defaultDeckId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.ensureSeeded();
      decks = DeckRepository(db);
      notetypes = NotetypeRepository(db);
      await notetypes.ensureSeeded();
      notes = NoteRepository(db, decks, notetypes);
      defaultDeckId = (await db.select(db.decks).get()).firstWhere((deck) => deck.name == 'Default').id;
    });

    tearDown(() => db.close());

    test('editing one of two decks with a shared legacy config clones it', () async {
      final original = await decks.configForDeck(defaultDeckId);
      final secondDeckId = await decks.createDeck('Second', deckConfigId: original.id);

      await decks.updateDeckConfig(
        secondDeckId,
        DeckConfigsCompanion(id: Value(original.id), newPerDay: const Value(7)),
      );

      final unchanged = await decks.configForDeck(defaultDeckId);
      final edited = await decks.configForDeck(secondDeckId);
      expect(unchanged.newPerDay, 20);
      expect(edited.newPerDay, 7);
      expect(edited.id, isNot(unchanged.id));
    });

    test('editing fields creates and removes template cards together with their revlog', () async {
      final reversed = (await db.select(db.notetypes).get()).firstWhere(
        (notetype) => notetype.name == 'Basic (and reversed card)',
      );
      final noteId = await notes.createNote(
        notetypeId: reversed.id,
        deckId: defaultDeckId,
        fields: ['Front', ''],
      );
      expect(await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).get(), hasLength(1));

      await notes.updateNoteFields(noteId, ['Front', 'Back'], preferredDeckId: defaultDeckId);
      final twoCards = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).get();
      expect(twoCards, hasLength(2));
      final reverseCard = twoCards.firstWhere((card) => card.templateOrd == 1);
      await db.into(db.revLog).insert(
            RevLogCompanion.insert(
              cardId: reverseCard.id,
              reviewedAt: 1700000000,
              rating: 3,
              ivlBefore: 0,
              ivlAfter: 1,
              easeAfter: 2500,
            ),
          );

      await notes.updateNoteFields(noteId, ['Front', ''], preferredDeckId: defaultDeckId);
      final remaining = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).get();
      expect(remaining, hasLength(1));
      expect(remaining.single.templateOrd, 0);
      expect(await (db.select(db.revLog)..where((row) => row.cardId.equals(reverseCard.id))).get(), isEmpty);
    });

    test('cloze notes generate one card per cloze number and stay synchronized on edit', () async {
      final clozeId = await notetypes.createNotetype(
        name: 'Cloze',
        fieldNames: const ['Text'],
        templates: const [
          TemplateSpec(
            name: 'Cloze',
            questionFormat: '{{cloze:Text}}',
            answerFormat: '{{cloze:Text}}',
          ),
        ],
      );
      final noteId = await notes.createNote(
        notetypeId: clozeId,
        deckId: defaultDeckId,
        fields: ['{{c1::One}} and {{c2::Two}}'],
      );
      var cards = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).get();
      expect(cards.map((card) => card.templateOrd).toSet(), {0, 1});

      await notes.updateNoteFields(
        noteId,
        ['{{c2::Two}} and {{c3::Three}}'],
        preferredDeckId: defaultDeckId,
      );
      cards = await (db.select(db.cards)..where((card) => card.noteId.equals(noteId))).get();
      expect(cards.map((card) => card.templateOrd).toSet(), {1, 2});
    });

    test('card browser reads large decks in bounded pages', () async {
      final basic = (await db.select(db.notetypes).get()).firstWhere((notetype) => notetype.name == 'Basic');
      final noteId = await notes.createNote(
        notetypeId: basic.id,
        deckId: defaultDeckId,
        fields: ['Paged card', 'Answer'],
      );
      for (var i = 1; i < 105; i++) {
        await db.into(db.cards).insert(
              CardsCompanion.insert(noteId: noteId, deckId: defaultDeckId, templateOrd: i),
            );
      }

      final first = await notes.cardBrowserPage(deckId: defaultDeckId, limit: 100);
      final second = await notes.cardBrowserPage(deckId: defaultDeckId, limit: 100, offset: first.rows.length);
      expect(first.rows, hasLength(100));
      expect(first.hasMore, isTrue);
      expect(second.rows, hasLength(5));
      expect(second.hasMore, isFalse);
    });

    test('duplicate search normalizes first field and stays within note type', () async {
      final basic = (await db.select(db.notetypes).get()).firstWhere((notetype) => notetype.name == 'Basic');
      final reversed = (await db.select(db.notetypes).get()).firstWhere(
        (notetype) => notetype.name == 'Basic (and reversed card)',
      );
      await notes.createNote(
        notetypeId: basic.id,
        deckId: defaultDeckId,
        fields: ['<b>Hello</b>  world', 'One'],
      );
      await notes.createNote(
        notetypeId: basic.id,
        deckId: defaultDeckId,
        fields: ['hello world', 'Two'],
      );
      await notes.createNote(
        notetypeId: reversed.id,
        deckId: defaultDeckId,
        fields: ['HELLO WORLD', 'Different type'],
      );

      final duplicates = await notes.findDuplicates();
      final hello = duplicates.singleWhere((group) => group.normalizedValue == 'hello world');
      expect(hello.matches, hasLength(2));
      expect(hello.matches.map((match) => match.note.notetypeId).toSet(), {basic.id});
    });

    test('FSRS memory state and desired retention persist in companion tables', () async {
      final basic = (await db.select(db.notetypes).get()).firstWhere((notetype) => notetype.name == 'Basic');
      final noteId = await notes.createNote(
        notetypeId: basic.id,
        deckId: defaultDeckId,
        fields: ['FSRS', 'State'],
      );
      final card = await (db.select(db.cards)..where((row) => row.noteId.equals(noteId))).getSingle();
      await StudyRepository(db).answerCard(
        cardId: card.id,
        rating: Rating.good,
        now: DateTime.utc(2026, 1, 10, 12),
      );

      final memory = await db.customSelect(
        'SELECT stability, difficulty FROM fsrs_card_state WHERE card_id = ?',
        variables: [Variable.withInt(card.id)],
      ).getSingle();
      expect(memory.read<double>('stability'), greaterThan(0));
      expect(memory.read<double>('difficulty'), inInclusiveRange(1, 10));

      await decks.updateDesiredRetention(defaultDeckId, 0.95);
      expect(await decks.desiredRetentionForDeck(defaultDeckId), closeTo(0.95, 0.0001));
    });
  });
}
