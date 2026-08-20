import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../../domain/template_renderer.dart' as renderer;
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
      final fieldDefs = await _notetypes.fieldsFor(notetypeId);
      for (final template in templates) {
        // Matches Anki: a template whose question renders to nothing for
        // these field values (e.g. the reverse side of "Basic and reversed"
        // when Back is left blank) doesn't get a card at all, rather than
        // leaving a blank "(пусто)" entry to review forever.
        if (renderer.isQuestionEmpty(template: template, fieldDefs: fieldDefs, fieldValues: fields)) {
          continue;
        }
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
      final cardIds = await (_db.selectOnly(_db.cards)
            ..addColumns([_db.cards.id])
            ..where(_db.cards.noteId.equals(noteId)))
          .map((row) => row.read(_db.cards.id)!)
          .get();
      for (final cardId in cardIds) {
        await (_db.delete(_db.revLog)..where((r) => r.cardId.equals(cardId))).go();
      }
      await (_db.delete(_db.cards)..where((c) => c.noteId.equals(noteId))).go();
      await (_db.delete(_db.notes)..where((n) => n.id.equals(noteId))).go();
    });
  }

  Future<void> setCardSuspended(int cardId, bool suspended) async {
    if (suspended) {
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId)))
          .write(const CardsCompanion(queue: Value(CardQueue.suspended)));
      return;
    }

    // Restoring a suspended card: send it back to review (if it had already
    // graduated) or new (otherwise) is the simplest safe default - matches
    // Anki's "unsuspend" for cards whose prior in-progress learning state we
    // don't try to reconstruct. Crucially, `due` also has to be reset to
    // match: a card suspended while it was mid-relearning still carries an
    // *epoch-seconds* due timestamp (e.g. ~1.7e9), which as a *day-number*
    // (what `due` means once queue is review again) is roughly 4.6 million
    // years out - the card would never come due again.
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    if (entry.ivl > 0) {
      final meta = await _db.select(_db.collectionMeta).getSingle();
      final today = dayNumber(
        DateTime.now(),
        DateTime.fromMillisecondsSinceEpoch(meta.createdAt),
        rolloverHour: meta.rolloverHour,
      );
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId)))
          .write(CardsCompanion(queue: const Value(CardQueue.review), due: Value(today)));
    } else {
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId)))
          .write(const CardsCompanion(queue: Value(CardQueue.newCard), due: Value(0)));
    }
  }
}
