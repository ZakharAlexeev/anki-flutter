import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../../domain/template_renderer.dart' as renderer;
import '../db/database.dart';
import 'deck_repository.dart';
import 'notetype_repository.dart';

class CardBrowserPage {
  const CardBrowserPage({required this.rows, required this.hasMore});

  final List<(CardEntry, Note)> rows;
  final bool hasMore;
}

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

  /// A bounded page for the card browser. Search is applied in SQLite so a
  /// large deck is not copied into Dart merely to show its first screen.
  Future<CardBrowserPage> cardBrowserPage({
    required int deckId,
    required int limit,
    int offset = 0,
    String query = '',
  }) async {
    final select = _db.select(_db.cards).join([
      innerJoin(_db.notes, _db.notes.id.equalsExp(_db.cards.noteId)),
    ])
      ..where(_db.cards.deckId.equals(deckId));
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      final pattern = '%$normalizedQuery%';
      select.where(_db.notes.fieldsJson.like(pattern) | _db.notes.tags.like(pattern));
    }
    select
      ..orderBy([OrderingTerm.desc(_db.cards.id)])
      ..limit(limit + 1, offset: offset);
    final result = await select.get();
    final hasMore = result.length > limit;
    final visible = hasMore ? result.take(limit) : result;
    return CardBrowserPage(
      rows: visible.map((row) => (row.readTable(_db.cards), row.readTable(_db.notes))).toList(),
      hasMore: hasMore,
    );
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

      final templates = await _notetypes.templatesFor(notetypeId);
      final fieldDefs = await _notetypes.fieldsFor(notetypeId);
      final eligible = _eligibleCardOrds(templates, fieldDefs, fields);
      if (eligible.isEmpty) {
        throw StateError('Заполните поле, используемое на лицевой стороне карточки.');
      }
      final config = await _decks.configForDeck(deckId);
      for (final templateOrd in eligible) {
        await _db.into(_db.cards).insert(CardsCompanion.insert(
              noteId: noteId,
              deckId: deckId,
              templateOrd: templateOrd,
              ease: Value(config.startingEase),
            ));
      }
      return noteId;
    });
  }

  Future<void> updateNoteFields(
    int noteId,
    List<String> fields, {
    String? tags,
    int? preferredDeckId,
  }) async {
    await _db.transaction(() async {
      final note = await (_db.select(_db.notes)..where((n) => n.id.equals(noteId))).getSingle();
      final templates = await _notetypes.templatesFor(note.notetypeId);
      final fieldDefs = await _notetypes.fieldsFor(note.notetypeId);
      final eligible = _eligibleCardOrds(templates, fieldDefs, fields);
      if (eligible.isEmpty) {
        throw StateError('После изменения не останется ни одной карточки. Заполните лицевую сторону.');
      }

      final cards = await (_db.select(_db.cards)..where((c) => c.noteId.equals(noteId))).get();
      final targetDeckId = preferredDeckId ?? (cards.isEmpty ? null : cards.first.deckId);
      if (targetDeckId == null) throw StateError('Не удалось определить колоду для карточки.');

      await (_db.update(_db.notes)..where((n) => n.id.equals(noteId))).write(NotesCompanion(
        fieldsJson: Value(encodeFields(fields)),
        tags: tags == null ? const Value.absent() : Value(tags),
      ));

      for (final card in cards.where((card) => !eligible.contains(card.templateOrd))) {
        await _deleteCard(card.id);
      }
      final existingOrds = cards.where((card) => eligible.contains(card.templateOrd)).map((card) => card.templateOrd).toSet();
      final config = await _decks.configForDeck(targetDeckId);
      for (final templateOrd in eligible.difference(existingOrds)) {
        await _db.into(_db.cards).insert(CardsCompanion.insert(
              noteId: noteId,
              deckId: targetDeckId,
              templateOrd: templateOrd,
              ease: Value(config.startingEase),
            ));
      }
    });
  }

  Set<int> _eligibleCardOrds(
    List<NotetypeTemplate> templates,
    List<NotetypeField> fieldDefs,
    List<String> fields,
  ) {
    final result = <int>{};
    for (final template in templates) {
      if (renderer.isClozeTemplate(template)) {
        for (final cardOrd in renderer.clozeCardOrds(fields)) {
          if (!renderer.isQuestionEmpty(
            template: template,
            fieldDefs: fieldDefs,
            fieldValues: fields,
            cardOrd: cardOrd,
          )) {
            result.add(cardOrd);
          }
        }
      } else if (!renderer.isQuestionEmpty(
        template: template,
        fieldDefs: fieldDefs,
        fieldValues: fields,
      )) {
        result.add(template.ord);
      }
    }
    return result;
  }

  Future<void> deleteNote(int noteId) async {
    await _db.transaction(() async {
      final cardIds = await (_db.selectOnly(_db.cards)
            ..addColumns([_db.cards.id])
            ..where(_db.cards.noteId.equals(noteId)))
          .map((row) => row.read(_db.cards.id)!)
          .get();
      for (final cardId in cardIds) {
        await _deleteCard(cardId);
      }
      await (_db.delete(_db.notes)..where((n) => n.id.equals(noteId))).go();
    });
  }

  Future<void> _deleteCard(int cardId) async {
    await (_db.delete(_db.revLog)..where((r) => r.cardId.equals(cardId))).go();
    await (_db.delete(_db.cards)..where((c) => c.id.equals(cardId))).go();
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
