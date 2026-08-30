import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:zstandard/zstandard.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../db/database.dart';
import 'archive_safety.dart';
import 'media_import_plan.dart';
import 'proto_reader.dart';

export 'archive_safety.dart' show ImportException;

class ImportProgress {
  final String phase;
  final int current;
  final int total;
  const ImportProgress(this.phase, this.current, this.total);
}

class ImportSummary {
  final int decks;
  final int notetypes;
  final int notes;
  final int cards;
  final int mediaFiles;
  const ImportSummary({
    required this.decks,
    required this.notetypes,
    required this.notes,
    required this.cards,
    required this.mediaFiles,
  });
}

/// Imports a `.apkg`/`.colpkg` file (an Anki export) into the local
/// database. Supports both collection schemas Anki has used:
///
/// - Legacy (schema v11 and earlier, `collection.anki2`/`.anki21`): deck,
///   deck-config and notetype definitions live as JSON in `col.decks`/
///   `col.dconf`/`col.models`.
/// - Current (schema v18+, `collection.anki21b`, zstd-compressed): those
///   definitions moved into dedicated tables (`decks`, `deck_config`,
///   `notetypes`/`fields`/`templates`), each row storing its config as a
///   serialized protobuf message instead of JSON (see `proto_reader.dart`).
///
/// Note: modern Anki (2.1.50+) exports a *stub* `collection.anki2` next to
/// the real `collection.anki21b` - a single placeholder note telling old
/// Anki clients to upgrade - purely for backward-compat detection, not
/// usable data. So `collection.anki21b` must be preferred whenever present,
/// not used as a last resort.
///
/// Cards temporarily placed in filtered/dynamic decks are restored to their
/// original deck and due value (`odid`/`odue`). The filtered deck definition
/// itself is intentionally not imported because the app has no custom-study
/// UI yet.
class ApkgImporter {
  ApkgImporter(this._db);

  final AppDatabase _db;

  Stream<ImportProgress> import(String apkgPath) async* {
    yield const ImportProgress('Распаковка архива', 0, 1);
    final sourceFile = File(apkgPath);
    if (await sourceFile.length() > maxApkgBytes) {
      throw ImportException('Архив больше 256 МБ. Разделите коллекцию на несколько файлов.');
    }
    final bytes = await sourceFile.readAsBytes();
    validateZipEnvelope(bytes);
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? find(String name) {
      for (final f in archive.files) {
        if (f.name == name) return f;
      }
      return null;
    }

    final entry21b = find('collection.anki21b');
    final entry21 = find('collection.anki21');
    final entry2 = find('collection.anki2');

    Uint8List? sqliteBytes;
    if (entry21b != null) {
      yield const ImportProgress('Распаковка коллекции (zstd)', 0, 1);
      final compressed = Uint8List.fromList(entry21b.content as List<int>);
      final declaredSize = zstdDeclaredContentSize(compressed);
      if (declaredSize == null || declaredSize > maxSingleArchiveEntryBytes) {
        throw ImportException('Коллекция имеет неизвестный или слишком большой размер после распаковки.');
      }
      sqliteBytes = await Zstandard().decompress(compressed);
      if (sqliteBytes == null) {
        throw ImportException('Не удалось распаковать коллекцию (повреждённый zstd-поток).');
      }
    } else {
      sqliteBytes = (entry21 ?? entry2)?.content;
    }

    if (sqliteBytes == null) {
      throw ImportException('В архиве не найдена база коллекции Anki (collection.anki2/anki21/anki21b).');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'anki_import_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    await tempFile.writeAsBytes(sqliteBytes, flush: true);

    MediaImportPlan? preparedMedia;
    ImportSummary summary;
    try {
      yield const ImportProgress('Проверка медиафайлов', 0, 1);
      final mediaPlan = await MediaImportPlan.prepare(archive);
      preparedMedia = mediaPlan;
      final src = sqlite.sqlite3.open(tempFile.path, mode: sqlite.OpenMode.readOnly);
      // Anki's schema v18+ tables declare `COLLATE unicase` on several text
      // columns. Recent sqlite3 versions refuse to even *prepare* a
      // statement touching such a column unless a collation of that name is
      // registered - regardless of whether the query actually needs to
      // compare by it - so this is required just to read the tables at all.
      // We only ever read rows here (never sort/compare by these columns
      // ourselves), so a simple case-insensitive stand-in is sufficient.
      src.createCollation(
        name: 'unicase',
        function: (a, b) => (a ?? '').toLowerCase().compareTo((b ?? '').toLowerCase()),
      );
      try {
        yield const ImportProgress('Запись в базу данных', 0, 1);
        final destMeta = await _db.select(_db.collectionMeta).getSingle();
        // Everything that touches the database happens inside one
        // transaction: if anything throws partway through (a malformed
        // row, a constraint violation), the whole import rolls back
        // instead of leaving a half-imported collection - some decks/notes
        // committed, others not - that's awkward to detect or clean up
        // after the fact. The trade-off is coarser progress reporting
        // during this phase (Dart's `yield` can't cross into the
        // transaction callback), which is a fine price for atomicity.
        ImportSummary dbSummary;
        try {
          dbSummary = await _db.transaction(() async {
            final result = await _readAndWrite(src, destMeta, mediaPlan);
            await mediaPlan.commit();
            return result;
          });
        } catch (_) {
          await mediaPlan.rollbackFiles();
          rethrow;
        }

        summary = ImportSummary(
          decks: dbSummary.decks,
          notetypes: dbSummary.notetypes,
          notes: dbSummary.notes,
          cards: dbSummary.cards,
          mediaFiles: mediaPlan.mediaCount,
        );
      } finally {
        src.close();
      }
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
      if (preparedMedia != null) await preparedMedia.cleanup();
    }

    yield ImportProgress(
      'Готово: ${summary.decks} колод, ${summary.notes} заметок, ${summary.cards} карточек, ${summary.mediaFiles} медиафайлов',
      1,
      1,
    );
  }

  Future<ImportSummary> _readAndWrite(
    sqlite.Database src,
    CollectionMetaData destMeta,
    MediaImportPlan mediaPlan,
  ) async {
    final colRow = src.select('SELECT crt, conf, models, decks, dconf FROM col LIMIT 1').first;
    final sourceCrt = colRow['crt'] as int;

    // Anki 2.1.28+ (schema v18) moved notetype/deck/deck-config
    // definitions out of col.models/decks/dconf JSON into dedicated
    // tables, storing each definition as a serialized protobuf message
    // (see proto_reader.dart). col.conf's `rollover` setting moved into
    // the generic `config` key/value table too, still as a plain
    // JSON-encoded value (unlike the notetype/deck configs).
    final isNewSchema = src
            .select("SELECT count(*) AS c FROM sqlite_master WHERE type='table' AND name='notetypes'")
            .first['c'] as int >
        0;
    int readV18Rollover() {
      try {
        final row = src.select("SELECT val FROM config WHERE key = 'rollover' LIMIT 1");
        if (row.isEmpty) return 4;
        final decoded = jsonDecode(utf8.decode(row.first['val'] as List<int>));
        return (decoded as num?)?.toInt() ?? 4;
      } catch (_) {
        // Unexpected encoding for this Anki version: the rollover hour
        // only affects which side of midnight-ish a review counts as
        // "today", so falling back to Anki's own default is harmless.
        return 4;
      }
    }

    final sourceRollover = isNewSchema
        ? readV18Rollover()
        : ((jsonDecode(colRow['conf'] as String) as Map<String, dynamic>)['rollover'] as num?)?.toInt() ?? 4;

    final destCreated = DateTime.fromMillisecondsSinceEpoch(destMeta.createdAt);
    final sourceCreated = DateTime.fromMillisecondsSinceEpoch(sourceCrt * 1000);

    int reprojectDay(int sourceDueDay) {
      final approxDate = sourceCreated.add(Duration(days: sourceDueDay, hours: sourceRollover));
      return dayNumber(approxDate, destCreated, rolloverHour: destMeta.rolloverHour);
    }

    int resolveLearningDue(int rawDue) {
      // Anki stores epoch-seconds for same-day learning steps but a
      // small day-number for steps due on a future day; anything under
      // this threshold can't be a real epoch-seconds timestamp.
      const epochSecondsFloor = 100000000; // ~1973
      if (rawDue >= epochSecondsFloor) return rawDue;
      final day = reprojectDay(rawDue);
      final approx = destCreated.add(Duration(days: day, hours: destMeta.rolloverHour));
      return approx.millisecondsSinceEpoch ~/ 1000;
    }

    final deckConfigIdMap = <int, int>{};
    if (isNewSchema) {
      final dconfRows = src.select('SELECT id, name, config FROM deck_config');
      for (final row in dconfRows) {
        final sourceId = row['id'] as int;
        final localId = _importedId(sourceCrt, 'deck-config', sourceId);
        final cfg = ProtoMessage.parse(row['config'] as Uint8List);
        final learnSteps = cfg.getPackedFloats(1);
        final relearnSteps = cfg.getPackedFloats(2);

        await _db.into(_db.deckConfigs).insertOnConflictUpdate(DeckConfigsCompanion(
              id: Value(localId),
              name: Value((row['name'] as String?) ?? 'Imported'),
              learningStepsMin: Value(learnSteps.isEmpty ? '1,10' : learnSteps.map((e) => e.round()).join(',')),
              relearningStepsMin: Value(relearnSteps.isEmpty ? '10' : relearnSteps.map((e) => e.round()).join(',')),
              graduatingIntervalDays: Value(cfg.getInt(18) ?? 1),
              easyIntervalDays: Value(cfg.getInt(19) ?? 4),
              startingEase: Value(((cfg.getFloat32(11) ?? 2.5) * 1000).round()),
              easyBonusPct: Value(((cfg.getFloat32(12) ?? 1.3) * 100).round()),
              intervalModifierPct: Value(((cfg.getFloat32(15) ?? 1.0) * 100).round()),
              hardIntervalPct: Value(((cfg.getFloat32(13) ?? 1.2) * 100).round()),
              newIntervalPct: Value(((cfg.getFloat32(14) ?? 0.0) * 100).round()),
              leechThreshold: Value(cfg.getInt(22) ?? 8),
              maximumIntervalDays: Value(cfg.getInt(16) ?? 36500),
              newPerDay: Value(cfg.getInt(9) ?? 20),
              reviewsPerDay: Value(cfg.getInt(10) ?? 200),
            ));
        deckConfigIdMap[sourceId] = localId;
      }
    } else {
      final dconf = jsonDecode(colRow['dconf'] as String) as Map<String, dynamic>;
      for (final entry in dconf.entries) {
        final sourceId = int.parse(entry.key);
        final localId = _importedId(sourceCrt, 'deck-config', sourceId);
        final def = entry.value as Map<String, dynamic>;
        final newBlock = (def['new'] as Map?)?.cast<String, dynamic>() ?? const {};
        final revBlock = (def['rev'] as Map?)?.cast<String, dynamic>() ?? const {};
        final lapseBlock = (def['lapse'] as Map?)?.cast<String, dynamic>() ?? const {};
        final ints = (newBlock['ints'] as List?)?.cast<num>() ?? const [1, 4];
        final delays = (newBlock['delays'] as List?)?.cast<num>() ?? const [1, 10];
        final lapseDelays = (lapseBlock['delays'] as List?)?.cast<num>() ?? const [10];

        await _db.into(_db.deckConfigs).insertOnConflictUpdate(DeckConfigsCompanion(
              id: Value(localId),
              name: Value((def['name'] as String?) ?? 'Imported'),
              learningStepsMin: Value(delays.map((e) => e.round()).join(',')),
              relearningStepsMin: Value(lapseDelays.map((e) => e.round()).join(',')),
              graduatingIntervalDays: Value(ints.isNotEmpty ? ints[0].round() : 1),
              easyIntervalDays: Value(ints.length > 1 ? ints[1].round() : 4),
              startingEase: Value(((newBlock['initialFactor'] as num?) ?? 2500).round()),
              easyBonusPct: Value((((revBlock['ease4'] as num?) ?? 1.3) * 100).round()),
              intervalModifierPct: Value((((revBlock['ivlFct'] as num?) ?? 1.0) * 100).round()),
              hardIntervalPct: Value((((revBlock['hardFactor'] as num?) ?? 1.2) * 100).round()),
              newIntervalPct: Value((((lapseBlock['mult'] as num?) ?? 0.0) * 100).round()),
              leechThreshold: Value(((lapseBlock['leechFails'] as num?) ?? 8).round()),
              maximumIntervalDays: Value(((revBlock['maxIvl'] as num?) ?? 36500).round()),
              newPerDay: Value(((newBlock['perDay'] as num?) ?? 20).round()),
              reviewsPerDay: Value(((revBlock['perDay'] as num?) ?? 200).round()),
            ));
        deckConfigIdMap[sourceId] = localId;
      }
    }
    final fallbackConfigId = deckConfigIdMap.values.isNotEmpty
        ? deckConfigIdMap.values.first
        : await _db.into(_db.deckConfigs).insert(const DeckConfigsCompanion(name: Value('Imported default')));

    // Deck names are globally unique in our schema, and every Anki
    // collection has a deck literally named "Default" with id 1 - which
    // collides with the "Default" deck this app itself creates on first
    // launch. Anki's own importer merges decks by name, so we do too:
    // an existing local deck with the same name is reused (by remapping
    // the source id to it) rather than fought over on insert.
    final deckIdMap = <int, int>{};
    Future<void> upsertDeck(int sourceId, String name, int configId) async {
      final existing = await (_db.select(_db.decks)..where((d) => d.name.equals(name))).getSingleOrNull();
      if (existing != null) {
        deckIdMap[sourceId] = existing.id;
        return;
      }
      final localId = _importedId(sourceCrt, 'deck', sourceId);
      await _db.into(_db.decks).insertOnConflictUpdate(DecksCompanion(
            id: Value(localId),
            name: Value(name),
            deckConfigId: Value(configId),
          ));
      deckIdMap[sourceId] = localId;
    }

    var deckCount = 0;
    if (isNewSchema) {
      final deckRows = src.select('SELECT id, name, kind FROM decks');
      for (final row in deckRows) {
        final id = row['id'] as int;
        final kind = ProtoMessage.parse(row['kind'] as Uint8List);
        if (kind.has(2)) continue; // filtered deck: out of scope
        final normal = kind.getMessage(1);
        final configId = deckConfigIdMap[normal?.getInt(1)] ?? fallbackConfigId;
        // Schema v18 still separates nested-deck name components with
        // \x1f internally too (only the *displayed* form uses "::") -
        // this path just wasn't converting it, so a nested deck from a
        // fresh Anki export came through as "Parent\x1fChild" with a
        // literal control character in the name instead of "Parent::Child".
        await upsertDeck(id, ((row['name'] as String?) ?? 'Imported').replaceAll('\x1f', '::'), configId);
        deckCount++;
      }
    } else {
      final decksJson = jsonDecode(colRow['decks'] as String) as Map<String, dynamic>;
      for (final entry in decksJson.entries) {
        final id = int.parse(entry.key);
        final def = entry.value as Map<String, dynamic>;
        if ((def['dyn'] as num?)?.toInt() == 1) continue; // filtered decks: out of scope
        final configId = deckConfigIdMap[(def['conf'] as num?)?.toInt()] ?? fallbackConfigId;
        await upsertDeck(id, (def['name'] as String? ?? 'Imported').replaceAll('\x1f', '::'), configId);
        deckCount++;
      }
    }

    // As with decks, an imported notetype whose name matches one that
    // already exists locally (extremely common - "Basic" is Anki's own
    // stock notetype, present in nearly every collection) is merged by
    // reusing the local definition rather than creating a confusing
    // duplicate.
    final notetypeIdMap = <int, int>{};
    Future<void> upsertNotetype(
      int sourceId,
      String requestedName,
      String css,
      List<(int ord, String name)> fields,
      List<(int ord, String name, String qfmt, String afmt)> templates,
    ) async {
      var name = requestedName;
      final existing = await (_db.select(_db.notetypes)..where((n) => n.name.equals(name))).getSingleOrNull();
      if (existing != null) {
        // Same name doesn't mean same shape: a local "Basic" (Front,
        // Back) and an imported "Basic" (Front, Back, Example) are both
        // named "Basic" but disagree on fields, so reusing the local
        // definition would insert notes whose field list doesn't match
        // what their (local) templates expect - some fields lost, others
        // shifted. Only merge when the field names/order and template
        // count genuinely match; otherwise import as a distinctly-named
        // note type instead of silently corrupting the existing one.
        final existingFields = await (_db.select(_db.notetypeFields)
              ..where((f) => f.notetypeId.equals(existing.id))
              ..orderBy([(f) => OrderingTerm.asc(f.ord)]))
            .get();
        final existingTemplateCount = await (_db.selectOnly(_db.notetypeTemplates)
              ..addColumns([_db.notetypeTemplates.id])
              ..where(_db.notetypeTemplates.notetypeId.equals(existing.id)))
            .get();
        final sameShape = existingFields.length == fields.length &&
            templates.length == existingTemplateCount.length &&
            Iterable.generate(fields.length).every((i) => existingFields[i].name == fields[i].$2);
        if (sameShape) {
          notetypeIdMap[sourceId] = existing.id;
          return;
        }
        name = '$requestedName (imported)';
      }
      final localId = _importedId(sourceCrt, 'notetype', sourceId);
      await _db.into(_db.notetypes).insertOnConflictUpdate(
            NotetypesCompanion(id: Value(localId), name: Value(name), css: Value(css)),
          );
      await (_db.delete(_db.notetypeFields)..where((f) => f.notetypeId.equals(localId))).go();
      await (_db.delete(_db.notetypeTemplates)..where((t) => t.notetypeId.equals(localId))).go();
      for (final f in fields) {
        await _db.into(_db.notetypeFields).insert(
              NotetypeFieldsCompanion.insert(notetypeId: localId, name: f.$2, ord: f.$1),
            );
      }
      for (final t in templates) {
        await _db.into(_db.notetypeTemplates).insert(NotetypeTemplatesCompanion.insert(
              notetypeId: localId,
              name: t.$2,
              ord: t.$1,
              questionFormat: Value(t.$3),
              answerFormat: Value(t.$4),
            ));
      }
      notetypeIdMap[sourceId] = localId;
    }

    var notetypeCount = 0;
    if (isNewSchema) {
      final notetypeRows = src.select('SELECT id, name, config FROM notetypes');
      for (final row in notetypeRows) {
        final id = row['id'] as int;
        final cfg = ProtoMessage.parse(row['config'] as Uint8List);

        final fields = <(int, String)>[];
        for (final f in src.select('SELECT ord, name FROM fields WHERE ntid = ?', [id])) {
          fields.add((f['ord'] as int, f['name'] as String));
        }

        final templates = <(int, String, String, String)>[];
        for (final t in src.select('SELECT ord, name, config FROM templates WHERE ntid = ?', [id])) {
          final tcfg = ProtoMessage.parse(t['config'] as Uint8List);
          templates.add((t['ord'] as int, (t['name'] as String?) ?? 'Card', tcfg.getString(1), tcfg.getString(2)));
        }

        await upsertNotetype(id, (row['name'] as String?) ?? 'Imported', cfg.getString(3), fields, templates);
        notetypeCount++;
      }
    } else {
      final modelsJson = jsonDecode(colRow['models'] as String) as Map<String, dynamic>;
      for (final entry in modelsJson.entries) {
        final id = int.parse(entry.key);
        final def = entry.value as Map<String, dynamic>;

        final fields = <(int, String)>[
          for (final f in (def['flds'] as List).cast<Map<String, dynamic>>())
            ((f['ord'] as num).toInt(), f['name'] as String),
        ];
        final templates = <(int, String, String, String)>[
          for (final t in (def['tmpls'] as List).cast<Map<String, dynamic>>())
            (
              (t['ord'] as num).toInt(),
              (t['name'] as String?) ?? 'Card',
              (t['qfmt'] as String?) ?? '',
              (t['afmt'] as String?) ?? '',
            ),
        ];

        await upsertNotetype(id, (def['name'] as String?) ?? 'Imported', (def['css'] as String?) ?? '', fields, templates);
        notetypeCount++;
      }
    }

    final noteRows = src.select('SELECT id, mid, flds, tags FROM notes');
    final noteIdMap = <int, int>{};
    var noteCount = 0;
    for (final row in noteRows) {
      final sourceId = row['id'] as int;
      final localId = _importedId(sourceCrt, 'note', sourceId);
      final fields = (row['flds'] as String).split('\x1f').map(mediaPlan.rewriteReferences).toList();
      final sourceMid = row['mid'] as int;
      final notetypeId = notetypeIdMap[sourceMid];
      if (notetypeId == null) continue;
      await _db.into(_db.notes).insertOnConflictUpdate(NotesCompanion(
            id: Value(localId),
            notetypeId: Value(notetypeId),
            fieldsJson: Value(jsonEncode(fields)),
            tags: Value(((row['tags'] as String?) ?? '').trim()),
          ));
      noteIdMap[sourceId] = localId;
      noteCount++;
    }

    final cardRows = src.select(
      'SELECT id, nid, did, ord, type, queue, due, ivl, factor, reps, lapses, odid, odue FROM cards',
    );
    final cardIdMap = <int, int>{};
    var cardCount = 0;
    for (final row in cardRows) {
      final sourceId = row['id'] as int;
      final sourceOdid = row['odid'] as int;
      final sourceDid = sourceOdid == 0 ? row['did'] as int : sourceOdid;
      final deckId = deckIdMap[sourceDid];
      final noteId = noteIdMap[row['nid'] as int];
      if (deckId == null || noteId == null) continue;

      // A filtered deck temporarily replaces did/due/queue. Restore the
      // original deck and due value instead of dropping the card (and later
      // failing its revlog foreign key).
      final queueInt = sourceOdid == 0 ? row['queue'] as int : row['type'] as int;
      final queue = _mapQueue(queueInt);
      final ivl = row['ivl'] as int;
      var ease = row['factor'] as int;
      if (ease == 0) ease = 2500;

      int due;
      final rawDue = sourceOdid == 0 ? row['due'] as int : row['odue'] as int;
      switch (queue) {
        case CardQueue.review:
          due = reprojectDay(rawDue);
          break;
        case CardQueue.suspended:
          due = ivl > 0 ? reprojectDay(rawDue) : 0;
          break;
        case CardQueue.learning:
        case CardQueue.relearning:
          due = resolveLearningDue(rawDue);
          break;
        case CardQueue.newCard:
          due = 0;
          break;
      }

      final localId = _importedId(sourceCrt, 'card', sourceId);
      await _db.into(_db.cards).insertOnConflictUpdate(CardsCompanion(
            id: Value(localId),
            noteId: Value(noteId),
            deckId: Value(deckId),
            templateOrd: Value(row['ord'] as int),
            queue: Value(queue),
            due: Value(due),
            ivl: Value(ivl < 0 ? 0 : ivl),
            ease: Value(ease),
            reps: Value(row['reps'] as int),
            lapses: Value(row['lapses'] as int),
            stepIndex: const Value(0), // mid-step position not reconstructed on import
          ));
      cardIdMap[sourceId] = localId;
      cardCount++;
    }

    final revRows = src.select(
      'SELECT id, cid, ease, ivl, lastIvl, factor, time FROM revlog WHERE ease != 0',
    );
    for (final row in revRows) {
      final sourceCardId = row['cid'] as int;
      final cardId = cardIdMap[sourceCardId];
      if (cardId == null) continue;
      final sourceId = row['id'] as int;
      final factor = row['factor'] as int;
      final ivl = row['ivl'] as int;
      final lastIvl = row['lastIvl'] as int;
      // Anki's own revlog.id *is* the review's epoch-ms timestamp, so
      // it's already a stable, globally-unique key we can reuse as our
      // own row id - without this, re-importing the same file inserted
      // a fresh autoincrement row every time (id left unset) instead of
      // updating the existing one, silently doubling review history and
      // stats on every repeat import.
      await _db.into(_db.revLog).insertOnConflictUpdate(RevLogCompanion(
            id: Value(_importedId(sourceCrt, 'review', sourceId)),
            cardId: Value(cardId),
            reviewedAt: Value(sourceId ~/ 1000),
            rating: Value(row['ease'] as int),
            ivlBefore: Value(lastIvl < 0 ? 0 : lastIvl),
            ivlAfter: Value(ivl < 0 ? 0 : ivl),
            easeAfter: Value(factor == 0 ? 2500 : factor),
            timeTakenMs: Value(row['time'] as int),
          ));
    }

    return ImportSummary(decks: deckCount, notetypes: notetypeCount, notes: noteCount, cards: cardCount, mediaFiles: 0);
  }

  int _importedId(int collectionCreatedAt, String kind, int sourceId) {
    final digest = sha256.convert(utf8.encode('$collectionCreatedAt:$kind:$sourceId')).bytes;
    final data = ByteData.sublistView(Uint8List.fromList(digest));
    final value = data.getUint64(0, Endian.big) & 0x7fffffffffffffff;
    return value == 0 ? 1 : value;
  }

  CardQueue _mapQueue(int queueInt) {
    switch (queueInt) {
      case -1:
        return CardQueue.suspended;
      case 0:
        return CardQueue.newCard;
      case 1:
        return CardQueue.learning;
      case 2:
        return CardQueue.review;
      case 3:
        return CardQueue.relearning;
      default:
        return CardQueue.suspended; // buried (-2/-3) or preview (4): park it, safest default
    }
  }
}
