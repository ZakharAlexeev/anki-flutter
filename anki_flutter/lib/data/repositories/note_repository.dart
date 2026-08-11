import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'deck_repository.dart';
import 'notetype_repository.dart';

class NoteRepository {
  NoteRepository(this._db, this._decks, this._notetypes);

  final AppDatabase _db;
  final DeckRepository _decks;
  final NotetypeRepository _notetypes;

  List<String> decodeFields(String fieldsJson) => (jsonDecode(fieldsJson) as List).cast<String>();

  String encodeFields(List<String> fields) => jsonEncode(fields);

  Stream<List<Note>> watchNotesForNotetype(int notetypeId) =>
      (_db.select(_db.notes)..where((n) => n.notetypeId.equals(notetypeId))).watch();

  /// All cards for [deckId] joined with their parent note, for the browser
  /// screen.
  Future<List<(CardEntry, Note)>> cardsWithNotesForDeck(int deckId) async {
    final query = _db.select(_db.cards).join([
      innerJoin(_db.notes, _db.notes.id.equalsExp(_db.cards.noteId)),
    ])
      ..where(_db.cards.deckId.equals(deckId));
    final rows = await query.get();
    return rows.map((r) => (r.readTable(_db.cards), r.readTable(_db.notes))).toList();
  }

  /// Creates a note and one card per template of its note type, all in the
  /// given deck, using that deck's starting ease.
  Future<int> createNote({
    required int notetypeId,
    required int deckId,
    required List<String> fields,
    String tags = '',
  }) async {
    return _db.transaction(() async {
      final noteId = await _db.into(_db.notes).insert(NotesCompanion(
            notetypeId: Value(notetypeId),
            fieldsJson: Value(encodeFields(fields)),
            tags: Value(tags),
          ));

      final config = await _decks.configForDeck(deckId);
      final templates = await _notetypes.templatesFor(notetypeId);
      for (final template in templates) {
        await _db.into(_db.cards).insert(CardsCompanion.insert(
              noteId: noteId,
              deckId: deckId,
              templateOrd: template.ord,
              ease: Value(config.startingEase),
            ));
      }
      return noteId;
    });
  }

  Future<void> updateNoteFields(int noteId, List<String> fields, {String? tags}) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
      fieldsJson: Value(encodeFields(fields)),
      tags: tags == null ? const Value.absent() : Value(tags),
    ));
  }

  Future<void> deleteNote(int noteId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.cards)..where((c) => c.noteId.equals(noteId))).go();
      await (_db.delete(_db.notes)..where((n) => n.id.equals(noteId))).go();
    });
  }

  Future<void> setCardSuspended(int cardId, bool suspended) async {
    if (suspended) {
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId)))
          .write(const CardsCompanion(queue: Value(CardQueue.suspended)));
    } else {
      // Restoring a suspended card: send it back to the new queue is the
      // simplest safe default (matches Anki's "unsuspend" for cards whose
      // prior in-progress learning state we don't try to reconstruct).
      final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
      final target = entry.ivl > 0 ? CardQueue.review : CardQueue.newCard;
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId)))
          .write(CardsCompanion(queue: Value(target)));
    }
  }
}
