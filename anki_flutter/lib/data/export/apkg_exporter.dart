import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../db/database.dart';

class ExportProgress {
  final String phase;
  final int current;
  final int total;
  const ExportProgress(this.phase, this.current, this.total);
}

/// Exports one or more decks - notes, cards, note types, deck options, and
/// crucially the actual scheduling state (interval, ease factor, due date,
/// lapses, plus the full review history) - to a `.apkg` file real Anki (or
/// this app, on another device) can import.
///
/// Writes the legacy schema-11 collection format (JSON columns on `col`)
/// rather than current Anki's schema-18/protobuf one: every version of Anki
/// still reads it as a backward-compatible fallback, and it's far simpler
/// to *write* correctly than hand-encoding the protobuf configs the way
/// `apkg_importer.dart` has to *read* them.
class ApkgExporter {
  ApkgExporter(this._db);

  final AppDatabase _db;

  Stream<ExportProgress> exportDecks(List<int> deckIds, String outputPath) async* {
    yield const ExportProgress('Подготовка', 0, 1);

    final meta = await _db.select(_db.collectionMeta).getSingle();
    final decks = await (_db.select(_db.decks)..where((d) => d.id.isIn(deckIds))).get();
    if (decks.isEmpty) throw StateError('Нет колод для экспорта');

    final cards = await (_db.select(_db.cards)..where((c) => c.deckId.isIn(deckIds))).get();
    final noteIds = cards.map((c) => c.noteId).toSet();
    final notes =
        noteIds.isEmpty ? <Note>[] : await (_db.select(_db.notes)..where((n) => n.id.isIn(noteIds))).get();
    final notetypeIds = notes.map((n) => n.notetypeId).toSet();
    final notetypes =
        notetypeIds.isEmpty ? <Notetype>[] : await (_db.select(_db.notetypes)..where((n) => n.id.isIn(notetypeIds))).get();
    final deckConfigIds = decks.map((d) => d.deckConfigId).toSet();
    final deckConfigs = await (_db.select(_db.deckConfigs)..where((c) => c.id.isIn(deckConfigIds))).get();
    final cardIds = cards.map((c) => c.id).toSet();
    final revlog =
        cardIds.isEmpty ? <RevLogData>[] : await (_db.select(_db.revLog)..where((r) => r.cardId.isIn(cardIds))).get();

    final fieldsByNotetype = <int, List<NotetypeField>>{};
    final templatesByNotetype = <int, List<NotetypeTemplate>>{};
    for (final nt in notetypes) {
      fieldsByNotetype[nt.id] = await (_db.select(_db.notetypeFields)
            ..where((f) => f.notetypeId.equals(nt.id))
            ..orderBy([(f) => OrderingTerm.asc(f.ord)]))
          .get();
      templatesByNotetype[nt.id] = await (_db.select(_db.notetypeTemplates)
            ..where((t) => t.notetypeId.equals(nt.id))
            ..orderBy([(t) => OrderingTerm.asc(t.ord)]))
          .get();
    }

    yield const ExportProgress('Сборка коллекции', 0, 1);
    final tempDir = await getTemporaryDirectory();
    final tempSqlite = File(p.join(tempDir.path, 'anki_export_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    if (await tempSqlite.exists()) await tempSqlite.delete();

    final db = sqlite.sqlite3.open(tempSqlite.path);
    List<int> sqliteBytes;
    try {
      _createSchema(db);
      _writeCol(
        db,
        meta: meta,
        decks: decks,
        deckConfigs: deckConfigs,
        notetypes: notetypes,
        fieldsByNotetype: fieldsByNotetype,
        templatesByNotetype: templatesByNotetype,
      );
      final sortFieldIndexByNotetype = {for (final nt in notetypes) nt.id: nt.sortFieldIndex};
      _writeNotes(db, notes, sortFieldIndexByNotetype);
      final configByDeck = {for (final d in decks) d.id: deckConfigs.firstWhere((c) => c.id == d.deckConfigId)};
      _writeCards(db, cards, configByDeck);
      _writeRevlog(db, revlog);
    } finally {
      db.close();
    }
    sqliteBytes = await tempSqlite.readAsBytes();
    await tempSqlite.delete();

    yield const ExportProgress('Медиафайлы', 0, 1);
    final mediaFiles = await _collectMedia(notes);

    yield const ExportProgress('Упаковка архива', 0, 1);
    final archive = Archive();
    archive.addFile(ArchiveFile('collection.anki2', sqliteBytes.length, sqliteBytes));

    final mediaIndex = <String, String>{};
    for (var i = 0; i < mediaFiles.length; i++) {
      mediaIndex['$i'] = p.basename(mediaFiles[i].path);
      final bytes = await mediaFiles[i].readAsBytes();
      archive.addFile(ArchiveFile('$i', bytes.length, bytes));
    }
    final mediaJson = utf8.encode(jsonEncode(mediaIndex));
    archive.addFile(ArchiveFile('media', mediaJson.length, mediaJson));

    final zipBytes = ZipEncoder().encodeBytes(archive);
    await File(outputPath).writeAsBytes(zipBytes, flush: true);

    yield ExportProgress(
      'Готово: ${notes.length} заметок, ${cards.length} карточек, ${mediaFiles.length} медиафайлов',
      1,
      1,
    );
  }

  void _createSchema(sqlite.Database db) {
    db.execute('''
      CREATE TABLE col (
        id integer primary key, crt integer not null, mod integer not null,
        scm integer not null, ver integer not null, dty integer not null,
        usn integer not null, ls integer not null, conf text not null,
        models text not null, decks text not null, dconf text not null,
        tags text not null
      );
      CREATE TABLE notes (
        id integer primary key, guid text not null, mid integer not null,
        mod integer not null, usn integer not null, tags text not null,
        flds text not null, sfld text not null, csum integer not null,
        flags integer not null, data text not null
      );
      CREATE TABLE cards (
        id integer primary key, nid integer not null, did integer not null,
        ord integer not null, mod integer not null, usn integer not null,
        type integer not null, queue integer not null, due integer not null,
        ivl integer not null, factor integer not null, reps integer not null,
        lapses integer not null, left integer not null, odue integer not null,
        odid integer not null, flags integer not null, data text not null
      );
      CREATE TABLE revlog (
        id integer primary key, cid integer not null, usn integer not null,
        ease integer not null, ivl integer not null, lastIvl integer not null,
        factor integer not null, time integer not null, type integer not null
      );
      CREATE TABLE graves (usn integer not null, oid integer not null, type integer not null);
      CREATE INDEX ix_notes_usn on notes (usn);
      CREATE INDEX ix_cards_usn on cards (usn);
      CREATE INDEX ix_revlog_usn on revlog (usn);
      CREATE INDEX ix_cards_nid on cards (nid);
      CREATE INDEX ix_cards_sched on cards (did, queue, due);
      CREATE INDEX ix_revlog_cid on revlog (cid);
      CREATE INDEX ix_notes_mid on notes (mid);
    ''');
  }

  void _writeCol(
    sqlite.Database db, {
    required CollectionMetaData meta,
    required List<Deck> decks,
    required List<DeckConfig> deckConfigs,
    required List<Notetype> notetypes,
    required Map<int, List<NotetypeField>> fieldsByNotetype,
    required Map<int, List<NotetypeTemplate>> templatesByNotetype,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowSec = nowMs ~/ 1000;

    final models = <String, dynamic>{};
    for (final nt in notetypes) {
      final fields = fieldsByNotetype[nt.id] ?? const [];
      final templates = templatesByNotetype[nt.id] ?? const [];
      models[nt.id.toString()] = {
        'id': nt.id,
        'name': nt.name,
        'type': 0,
        'mod': nowSec,
        'usn': 0,
        'sortf': nt.sortFieldIndex,
        'did': decks.first.id,
        'tmpls': [
          for (final t in templates)
            {
              'name': t.name,
              'ord': t.ord,
              'qfmt': t.questionFormat,
              'afmt': t.answerFormat,
              'did': null,
              'bqfmt': '',
              'bafmt': '',
              'bfont': '',
              'bsize': 0,
            },
        ],
        'flds': [
          for (final f in fields)
            {'name': f.name, 'ord': f.ord, 'sticky': false, 'rtl': false, 'font': 'Arial', 'size': 20, 'media': []},
        ],
        'css': nt.css,
        'latexPre':
            '\\documentclass[12pt]{article}\n\\special{papersize=3in,5in}\n\\usepackage[utf8]{inputenc}\n\\usepackage{amssymb,amsmath}\n\\pagestyle{empty}\n\\setlength{\\parindent}{0in}\n\\begin{document}\n',
        'latexPost': '\\end{document}',
        'req': [
          for (final t in templates) [t.ord, 'any', [0]],
        ],
      };
    }

    final decksJson = <String, dynamic>{
      for (final d in decks)
        d.id.toString(): {
          'id': d.id,
          'name': d.name,
          'mod': nowSec,
          'usn': 0,
          'lrnToday': [0, 0],
          'revToday': [0, 0],
          'newToday': [0, 0],
          'timeToday': [0, 0],
          'collapsed': d.collapsed,
          'browserCollapsed': false,
          'desc': '',
          'dyn': 0,
          'conf': d.deckConfigId,
          'extendNew': 0,
          'extendRev': 0,
        },
    };

    final dconfJson = <String, dynamic>{
      for (final c in deckConfigs)
        c.id.toString(): {
          'id': c.id,
          'name': c.name,
          'mod': nowSec,
          'usn': 0,
          'maxTaken': 60,
          'autoplay': true,
          'timer': 0,
          'replayq': true,
          'new': {
            'bury': false,
            'delays': _parseSteps(c.learningStepsMin),
            'initialFactor': c.startingEase,
            'ints': [c.graduatingIntervalDays, c.easyIntervalDays, 0],
            'order': 1,
            'perDay': c.newPerDay,
          },
          'rev': {
            'bury': false,
            'ease4': c.easyBonusPct / 100,
            'ivlFct': c.intervalModifierPct / 100,
            'maxIvl': c.maximumIntervalDays,
            'perDay': c.reviewsPerDay,
            'hardFactor': c.hardIntervalPct / 100,
          },
          'lapse': {
            'delays': _parseSteps(c.relearningStepsMin),
            'leechAction': 0,
            'leechFails': c.leechThreshold,
            'minInt': 1,
            'mult': c.newIntervalPct / 100,
          },
        },
    };

    final conf = {
      'curDeck': decks.first.id,
      'nextPos': 1,
      'estTimes': true,
      'activeDecks': [decks.first.id],
      'sortType': 'noteFld',
      'timeLim': 0,
      'sortBackwards': false,
      'addToCur': true,
      'newBury': true,
      'newSpread': 0,
      'dueCounts': true,
      'collapseTime': 1200,
      'rollover': meta.rolloverHour,
      'schedVer': 2,
    };

    db.execute(
      'INSERT INTO col (id, crt, mod, scm, ver, dty, usn, ls, conf, models, decks, dconf, tags) '
      'VALUES (1, ?, ?, ?, 11, 0, 0, 0, ?, ?, ?, ?, ?)',
      [
        meta.createdAt ~/ 1000,
        nowMs,
        nowMs,
        jsonEncode(conf),
        jsonEncode(models),
        jsonEncode(decksJson),
        jsonEncode(dconfJson),
        '{}',
      ],
    );
  }

  List<num> _parseSteps(String csv) =>
      csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).map(num.parse).toList();

  void _writeNotes(sqlite.Database db, List<Note> notes, Map<int, int> sortFieldIndexByNotetype) {
    final stmt = db.prepare(
      'INSERT INTO notes (id, guid, mid, mod, usn, tags, flds, sfld, csum, flags, data) '
      'VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?, 0, \'\')',
    );
    try {
      for (final note in notes) {
        final fields = (jsonDecode(note.fieldsJson) as List).cast<String>();
        final sortOrd = sortFieldIndexByNotetype[note.notetypeId] ?? 0;
        final rawSortField = sortOrd < fields.length ? fields[sortOrd] : (fields.isNotEmpty ? fields.first : '');
        // Anki's sfld is the sort field with HTML stripped - it's what the
        // browser sorts/displays by, not raw markup.
        final sfld = rawSortField.replaceAll(RegExp('<[^>]*>'), '').trim();
        final tags = note.tags.trim();
        stmt.execute([
          note.id,
          note.id.toRadixString(36),
          note.notetypeId,
          note.createdAt ~/ 1000,
          tags.isEmpty ? '' : ' $tags ',
          fields.join('\x1f'),
          sfld,
          _fieldChecksum(sfld),
        ]);
      }
    } finally {
      stmt.close();
    }
  }

  /// Anki's `csum`: the first 8 hex digits of the SHA-1 hash of the sort
  /// field, read as an integer - used to speed up duplicate detection. Not
  /// load-bearing for correctness (Anki re-derives it on next full sync
  /// regardless), but matching the real convention rather than a
  /// `String.hashCode` means a re-imported file's checksums line up with
  /// what real Anki would have written for the same content.
  int _fieldChecksum(String sfld) {
    final hex = sha1.convert(utf8.encode(sfld)).toString();
    return int.parse(hex.substring(0, 8), radix: 16);
  }

  void _writeCards(sqlite.Database db, List<CardEntry> cards, Map<int, DeckConfig> configByDeck) {
    final stmt = db.prepare(
      'INSERT INTO cards (id, nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data) '
      'VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, \'\')',
    );
    try {
      for (final c in cards) {
        final (type, queue) = _ankiTypeAndQueue(c);
        final left = _remainingStepsLeft(c, configByDeck[c.deckId]);
        stmt.execute([
          c.id,
          c.noteId,
          c.deckId,
          c.templateOrd,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          type,
          queue,
          c.due,
          c.ivl,
          c.ease,
          c.reps,
          c.lapses,
          left,
        ]);
      }
    } finally {
      stmt.close();
    }
  }

  /// Anki's `type` is the card's underlying kind (new/learning/review/
  /// relearning); `queue` is usually the same except suspended cards use
  /// -1. We only track one field ourselves ([CardEntry.queue] doubles as
  /// both), so a suspended card's prior type is inferred from whether it
  /// has ever graduated (ivl > 0).
  (int, int) _ankiTypeAndQueue(CardEntry c) {
    switch (c.queue) {
      case CardQueue.newCard:
        return (0, 0);
      case CardQueue.learning:
        return (1, 1);
      case CardQueue.review:
        return (2, 2);
      case CardQueue.relearning:
        return (3, 3);
      case CardQueue.suspended:
        return (c.ivl > 0 ? 2 : 0, -1);
    }
  }

  /// Anki packs `left` as `stepsRemainingToday + stepsRemainingTotal * 1000`
  /// - we don't model same-day-vs-later bury separately, so both halves use
  /// the same count: how many (re)learning steps, including the current
  /// one, are still ahead of this card. A hardcoded 1001 previously claimed
  /// every learning/relearning card had exactly 1 step left, which is wrong
  /// for any deck with more than one learning step or a card partway
  /// through them.
  int _remainingStepsLeft(CardEntry c, DeckConfig? config) {
    if (c.queue != CardQueue.learning && c.queue != CardQueue.relearning) return 0;
    if (config == null) return 1001;
    final steps = _parseSteps(c.queue == CardQueue.relearning ? config.relearningStepsMin : config.learningStepsMin);
    final remaining = max(1, steps.length - c.stepIndex);
    return remaining + remaining * 1000;
  }

  void _writeRevlog(sqlite.Database db, List<RevLogData> revlog) {
    final stmt = db.prepare(
      'INSERT INTO revlog (id, cid, usn, ease, ivl, lastIvl, factor, time, type) VALUES (?, ?, 0, ?, ?, ?, ?, ?, 1)',
    );
    try {
      for (final r in revlog) {
        stmt.execute([r.id, r.cardId, r.rating, r.ivlAfter, r.ivlBefore, r.easeAfter, r.timeTakenMs]);
      }
    } finally {
      stmt.close();
    }
  }

  Future<List<File>> _collectMedia(List<Note> notes) async {
    final appDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    if (!await mediaDir.exists()) return [];

    final referenced = <String>{};
    final srcPattern = RegExp('''src=["']([^"']+)["']''', caseSensitive: false);
    final soundPattern = RegExp(r'\[sound:([^\]]+)\]');
    for (final note in notes) {
      final fields = (jsonDecode(note.fieldsJson) as List).cast<String>();
      for (final field in fields) {
        for (final m in srcPattern.allMatches(field)) {
          referenced.add(m.group(1)!);
        }
        for (final m in soundPattern.allMatches(field)) {
          referenced.add(m.group(1)!);
        }
      }
    }

    final files = <File>[];
    for (final name in referenced) {
      final f = File(p.join(mediaDir.path, name));
      if (await f.exists()) files.add(f);
    }
    return files;
  }
}
