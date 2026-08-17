import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:zstandard/zstandard.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../db/database.dart';
import 'proto_reader.dart';

class ImportException implements Exception {
  final String message;
  ImportException(this.message);
  @override
  String toString() => message;
}

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
/// Not supported: filtered/dynamic decks (`odid`/`odue`), out of scope for
/// this app entirely.
class ApkgImporter {
  ApkgImporter(this._db);

  final AppDatabase _db;

  Stream<ImportProgress> import(String apkgPath) async* {
    yield const ImportProgress('Распаковка архива', 0, 1);
    final bytes = await File(apkgPath).readAsBytes();
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
      sqliteBytes = await Zstandard().decompress(entry21b.content);
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

    var summary = const ImportSummary(decks: 0, notetypes: 0, notes: 0, cards: 0, mediaFiles: 0);
    try {
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
        yield const ImportProgress('Чтение метаданных коллекции', 0, 1);
        final colRow = src.select('SELECT crt, conf, models, decks, dconf FROM col LIMIT 1').first;
        final sourceCrt = colRow['crt'] as int;

        // Anki 2.1.28+ (schema v18) moved notetype/deck/deck-config
        // definitions out of col.models/decks/dconf JSON into dedicated
        // tables, storing each definition as a serialized protobuf message
        // (see proto_reader.dart). col.conf's `rollover` setting moved into
        // the generic `config` key/value table too; that's a minor cosmetic
        // setting (only affects day-boundary edge cases), so the v18 path
        // below just keeps our own default rather than chasing it down.
        final isNewSchema = src
                .select("SELECT count(*) AS c FROM sqlite_master WHERE type='table' AND name='notetypes'")
                .first['c'] as int >
            0;
        final sourceRollover = isNewSchema
            ? 4
            : ((jsonDecode(colRow['conf'] as String) as Map<String, dynamic>)['rollover'] as num?)?.toInt() ?? 4;

        final destMeta = await _db.select(_db.collectionMeta).getSingle();
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
        yield const ImportProgress('Настройки колод', 0, 1);
        if (isNewSchema) {
          final dconfRows = src.select('SELECT id, name, config FROM deck_config');
          for (final row in dconfRows) {
            final id = row['id'] as int;
            final cfg = ProtoMessage.parse(row['config'] as Uint8List);
            final learnSteps = cfg.getPackedFloats(1);
            final relearnSteps = cfg.getPackedFloats(2);

            await _db.into(_db.deckConfigs).insertOnConflictUpdate(DeckConfigsCompanion(
                  id: Value(id),
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
            deckConfigIdMap[id] = id;
          }
        } else {
          final dconf = jsonDecode(colRow['dconf'] as String) as Map<String, dynamic>;
          for (final entry in dconf.entries) {
            final id = int.parse(entry.key);
            final def = entry.value as Map<String, dynamic>;
            final newBlock = (def['new'] as Map?)?.cast<String, dynamic>() ?? const {};
            final revBlock = (def['rev'] as Map?)?.cast<String, dynamic>() ?? const {};
            final lapseBlock = (def['lapse'] as Map?)?.cast<String, dynamic>() ?? const {};
            final ints = (newBlock['ints'] as List?)?.cast<num>() ?? const [1, 4];
            final delays = (newBlock['delays'] as List?)?.cast<num>() ?? const [1, 10];
            final lapseDelays = (lapseBlock['delays'] as List?)?.cast<num>() ?? const [10];

            await _db.into(_db.deckConfigs).insertOnConflictUpdate(DeckConfigsCompanion(
                  id: Value(id),
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
            deckConfigIdMap[id] = id;
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
          await _db.into(_db.decks).insertOnConflictUpdate(DecksCompanion(
                id: Value(sourceId),
                name: Value(name),
                deckConfigId: Value(configId),
              ));
          deckIdMap[sourceId] = sourceId;
        }

        yield const ImportProgress('Колоды', 0, 1);
        var deckCount = 0;
        if (isNewSchema) {
          final deckRows = src.select('SELECT id, name, kind FROM decks');
          for (final row in deckRows) {
            final id = row['id'] as int;
            final kind = ProtoMessage.parse(row['kind'] as Uint8List);
            if (kind.has(2)) continue; // filtered deck: out of scope
            final normal = kind.getMessage(1);
            final configId = deckConfigIdMap[normal?.getInt(1)] ?? fallbackConfigId;
            await upsertDeck(id, (row['name'] as String?) ?? 'Imported', configId);
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
          String name,
          String css,
          List<(int ord, String name)> fields,
          List<(int ord, String name, String qfmt, String afmt)> templates,
        ) async {
          final existing = await (_db.select(_db.notetypes)..where((n) => n.name.equals(name))).getSingleOrNull();
          if (existing != null) {
            notetypeIdMap[sourceId] = existing.id;
            return;
          }
          await _db.into(_db.notetypes).insertOnConflictUpdate(
                NotetypesCompanion(id: Value(sourceId), name: Value(name), css: Value(css)),
              );
          await (_db.delete(_db.notetypeFields)..where((f) => f.notetypeId.equals(sourceId))).go();
          await (_db.delete(_db.notetypeTemplates)..where((t) => t.notetypeId.equals(sourceId))).go();
          for (final f in fields) {
            await _db.into(_db.notetypeFields).insert(
                  NotetypeFieldsCompanion.insert(notetypeId: sourceId, name: f.$2, ord: f.$1),
                );
          }
          for (final t in templates) {
            await _db.into(_db.notetypeTemplates).insert(NotetypeTemplatesCompanion.insert(
                  notetypeId: sourceId,
                  name: t.$2,
                  ord: t.$1,
                  questionFormat: Value(t.$3),
                  answerFormat: Value(t.$4),
                ));
          }
          notetypeIdMap[sourceId] = sourceId;
        }

        yield const ImportProgress('Типы карточек', 0, 1);
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

        yield const ImportProgress('Заметки', 0, 1);
        final noteRows = src.select('SELECT id, mid, flds, tags FROM notes');
        var noteCount = 0;
        for (final row in noteRows) {
          final fields = (row['flds'] as String).split('\x1f');
          final sourceMid = row['mid'] as int;
          await _db.into(_db.notes).insertOnConflictUpdate(NotesCompanion(
                id: Value(row['id'] as int),
                notetypeId: Value(notetypeIdMap[sourceMid] ?? sourceMid),
                fieldsJson: Value(jsonEncode(fields)),
                tags: Value(((row['tags'] as String?) ?? '').trim()),
              ));
          noteCount++;
          if (noteCount % 200 == 0) yield ImportProgress('Заметки', noteCount, noteRows.length);
        }

        yield const ImportProgress('Карточки', 0, 1);
        final cardRows = src.select(
          'SELECT id, nid, did, ord, type, queue, due, ivl, factor, reps, lapses FROM cards',
        );
        var cardCount = 0;
        for (final row in cardRows) {
          final sourceDid = row['did'] as int;
          final deckId = deckIdMap[sourceDid];
          if (deckId == null) continue; // card belongs to a filtered deck we skipped: out of scope

          final queueInt = row['queue'] as int;
          final queue = _mapQueue(queueInt);
          final ivl = row['ivl'] as int;
          var ease = row['factor'] as int;
          if (ease == 0) ease = 2500;

          int due;
          switch (queue) {
            case CardQueue.review:
              due = reprojectDay(row['due'] as int);
              break;
            case CardQueue.suspended:
              due = ivl > 0 ? reprojectDay(row['due'] as int) : 0;
              break;
            case CardQueue.learning:
            case CardQueue.relearning:
              due = resolveLearningDue(row['due'] as int);
              break;
            case CardQueue.newCard:
              due = 0;
              break;
          }

          await _db.into(_db.cards).insertOnConflictUpdate(CardsCompanion(
                id: Value(row['id'] as int),
                noteId: Value(row['nid'] as int),
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
          cardCount++;
          if (cardCount % 200 == 0) yield ImportProgress('Карточки', cardCount, cardRows.length);
        }

        yield const ImportProgress('История повторений', 0, 1);
        final revRows = src.select(
          'SELECT id, cid, ease, ivl, lastIvl, factor, time FROM revlog WHERE ease != 0',
        );
        for (final row in revRows) {
          final factor = row['factor'] as int;
          final ivl = row['ivl'] as int;
          final lastIvl = row['lastIvl'] as int;
          await _db.into(_db.revLog).insertOnConflictUpdate(RevLogCompanion(
                cardId: Value(row['cid'] as int),
                reviewedAt: Value((row['id'] as int) ~/ 1000),
                rating: Value(row['ease'] as int),
                ivlBefore: Value(lastIvl < 0 ? 0 : lastIvl),
                ivlAfter: Value(ivl < 0 ? 0 : ivl),
                easeAfter: Value(factor == 0 ? 2500 : factor),
                timeTakenMs: Value(row['time'] as int),
              ));
        }

        yield const ImportProgress('Медиафайлы', 0, 1);
        final mediaCount = await _importMedia(archive);

        summary = ImportSummary(
          decks: deckCount,
          notetypes: notetypeCount,
          notes: noteCount,
          cards: cardCount,
          mediaFiles: mediaCount,
        );
      } finally {
        src.close();
      }
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }

    yield ImportProgress(
      'Готово: ${summary.decks} колод, ${summary.notes} заметок, ${summary.cards} карточек, ${summary.mediaFiles} медиафайлов',
      1,
      1,
    );
  }

  Future<int> _importMedia(Archive archive) async {
    ArchiveFile? find(String name) {
      for (final f in archive.files) {
        if (f.name == name) return f;
      }
      return null;
    }

    final mediaIndex = find('media');
    if (mediaIndex == null) return 0;

    // Like collection.anki21b, the media index is zstd-compressed in the
    // current export format (still plain JSON once decompressed - just a
    // {"<archive entry name>": "<real filename>"} map, same as the legacy
    // format). A collection with no media compresses down to zero bytes.
    var indexBytes = mediaIndex.content;
    if (indexBytes.length >= 4 &&
        indexBytes[0] == 0x28 &&
        indexBytes[1] == 0xB5 &&
        indexBytes[2] == 0x2F &&
        indexBytes[3] == 0xFD) {
      indexBytes = await Zstandard().decompress(indexBytes) ?? Uint8List(0);
    }
    if (indexBytes.isEmpty) return 0;

    final Map<String, dynamic> map;
    try {
      map = jsonDecode(utf8.decode(indexBytes)) as Map<String, dynamic>;
    } on FormatException {
      // Unrecognised media index shape - not worth failing the whole
      // import over (notes/cards already imported fine); just skip media.
      return 0;
    }
    final appDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    await mediaDir.create(recursive: true);

    var count = 0;
    for (final entry in map.entries) {
      final file = archive.files.cast<ArchiveFile?>().firstWhere((f) => f?.name == entry.key, orElse: () => null);
      if (file == null) continue;
      final destPath = p.join(mediaDir.path, entry.value as String);
      await File(destPath).writeAsBytes(file.content as List<int>, flush: true);
      count++;
    }
    return count;
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
