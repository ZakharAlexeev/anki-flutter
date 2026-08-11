import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../domain/scheduler/day_calendar.dart';
import '../db/database.dart';

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
/// database. Reads the legacy JSON columns (`col.models`/`decks`/`dconf`)
/// that every Anki version still populates for backward compatibility, so
/// this works against both the old `collection.anki2` and current
/// `collection.anki21` formats.
///
/// Not supported: the newer zstd-compressed `collection.anki21b` container
/// (no pure-Dart zstd decoder available) - ask the user to re-export with
/// Anki's "Support older Anki versions" option; and filtered/dynamic decks
/// (`odid`/`odue`), which are out of scope for this app entirely.
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

    final entry21 = find('collection.anki21');
    final entry2 = find('collection.anki2');
    final entry21b = find('collection.anki21b');

    final sqliteBytes = (entry21 ?? entry2)?.content;
    if (sqliteBytes == null) {
      if (entry21b != null) {
        throw ImportException(
          'Этот .apkg использует новый сжатый формат (zstd), который пока не '
          'поддерживается. В Anki при экспорте включите опцию "Support older '
          'Anki versions (slower/larger files)" и повторите импорт.',
        );
      }
      throw ImportException('В архиве не найдена база коллекции Anki (collection.anki2/anki21).');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'anki_import_${DateTime.now().microsecondsSinceEpoch}.sqlite'));
    await tempFile.writeAsBytes(sqliteBytes, flush: true);

    var summary = const ImportSummary(decks: 0, notetypes: 0, notes: 0, cards: 0, mediaFiles: 0);
    try {
      final src = sqlite.sqlite3.open(tempFile.path, mode: sqlite.OpenMode.readOnly);
      try {
        yield const ImportProgress('Чтение метаданных коллекции', 0, 1);
        final colRow = src.select('SELECT crt, conf, models, decks, dconf FROM col LIMIT 1').first;
        final sourceCrt = colRow['crt'] as int;
        final conf = jsonDecode(colRow['conf'] as String) as Map<String, dynamic>;
        final sourceRollover = (conf['rollover'] as num?)?.toInt() ?? 4;

        final destMeta = await _db.select(_db.collectionMeta).getSingle();
        final destCreated = DateTime.fromMillisecondsSinceEpoch(destMeta.createdAt);
        final sourceCreated = DateTime.fromMillisecondsSinceEpoch(sourceCrt * 1000);

        int reprojectDay(int sourceDueDay) {
          final approxDate =
              sourceCreated.add(Duration(days: sourceDueDay, hours: sourceRollover));
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
        final fallbackConfigId = deckConfigIdMap.values.isNotEmpty
            ? deckConfigIdMap.values.first
            : await _db.into(_db.deckConfigs).insert(const DeckConfigsCompanion(name: Value('Imported default')));

        yield const ImportProgress('Колоды', 0, 1);
        final decksJson = jsonDecode(colRow['decks'] as String) as Map<String, dynamic>;
        var deckCount = 0;
        for (final entry in decksJson.entries) {
          final id = int.parse(entry.key);
          final def = entry.value as Map<String, dynamic>;
          if ((def['dyn'] as num?)?.toInt() == 1) continue; // filtered decks: out of scope
          final configId = deckConfigIdMap[(def['conf'] as num?)?.toInt()] ?? fallbackConfigId;
          await _db.into(_db.decks).insertOnConflictUpdate(DecksCompanion(
                id: Value(id),
                name: Value((def['name'] as String? ?? 'Imported').replaceAll('\x1f', '::')),
                deckConfigId: Value(configId),
              ));
          deckCount++;
        }

        yield const ImportProgress('Типы карточек', 0, 1);
        final modelsJson = jsonDecode(colRow['models'] as String) as Map<String, dynamic>;
        final fieldOrdByNotetype = <int, Map<int, String>>{};
        var notetypeCount = 0;
        for (final entry in modelsJson.entries) {
          final id = int.parse(entry.key);
          final def = entry.value as Map<String, dynamic>;
          await _db.into(_db.notetypes).insertOnConflictUpdate(NotetypesCompanion(
                id: Value(id),
                name: Value((def['name'] as String?) ?? 'Imported'),
                css: Value((def['css'] as String?) ?? ''),
              ));
          await (_db.delete(_db.notetypeFields)..where((f) => f.notetypeId.equals(id))).go();
          await (_db.delete(_db.notetypeTemplates)..where((t) => t.notetypeId.equals(id))).go();

          final fields = (def['flds'] as List).cast<Map<String, dynamic>>();
          final fieldNames = <int, String>{};
          for (final f in fields) {
            final ord = (f['ord'] as num).toInt();
            final name = f['name'] as String;
            fieldNames[ord] = name;
            await _db.into(_db.notetypeFields).insert(
                  NotetypeFieldsCompanion.insert(notetypeId: id, name: name, ord: ord),
                );
          }
          fieldOrdByNotetype[id] = fieldNames;

          final templates = (def['tmpls'] as List).cast<Map<String, dynamic>>();
          for (final t in templates) {
            await _db.into(_db.notetypeTemplates).insert(NotetypeTemplatesCompanion.insert(
                  notetypeId: id,
                  name: (t['name'] as String?) ?? 'Card',
                  ord: (t['ord'] as num).toInt(),
                  questionFormat: Value((t['qfmt'] as String?) ?? ''),
                  answerFormat: Value((t['afmt'] as String?) ?? ''),
                ));
          }
          notetypeCount++;
        }

        yield const ImportProgress('Заметки', 0, 1);
        final noteRows = src.select('SELECT id, mid, flds, tags FROM notes');
        var noteCount = 0;
        for (final row in noteRows) {
          final fields = (row['flds'] as String).split('');
          await _db.into(_db.notes).insertOnConflictUpdate(NotesCompanion(
                id: Value(row['id'] as int),
                notetypeId: Value(row['mid'] as int),
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
                deckId: Value(row['did'] as int),
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

    final map = jsonDecode(utf8.decode(mediaIndex.content as List<int>)) as Map<String, dynamic>;
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
