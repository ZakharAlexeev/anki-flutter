import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../repositories/note_repository.dart';
import '../repositories/notetype_repository.dart';
import 'pronunciation_lookup.dart';

enum PronunciationOutcome {
  /// A recording was found and a `[sound:...]` tag added to the note.
  added,

  /// The note already had audio; nothing to do.
  alreadyHasAudio,

  /// No field looks like an English word or phrase.
  noEnglishText,

  /// Neither Oxford nor Wiktionary has a recording of it.
  notFound,

  /// The sources couldn't be reached (offline, blocked, timed out).
  networkError,
}

/// Adds a recorded pronunciation to a note: finds the field holding the
/// English word, looks it up via [PronunciationLookup] and appends
/// `[sound:pron_word.mp3]` to that field - exactly how Anki itself stores
/// audio, so it plays on whichever side shows the word and survives .apkg
/// export to desktop Anki.
class PronunciationService {
  PronunciationService(this._db, this._notes, this._notetypes, {PronunciationLookup? lookup})
      : _lookup = lookup ?? PronunciationLookup();

  final AppDatabase _db;
  final NoteRepository _notes;
  final NotetypeRepository _notetypes;
  final PronunciationLookup _lookup;

  static final _soundTag = RegExp(r'\[sound:[^\]]+\]');

  Future<PronunciationOutcome> attachTo(int noteId) async {
    final note = await (_db.select(_db.notes)..where((n) => n.id.equals(noteId))).getSingleOrNull();
    if (note == null) return PronunciationOutcome.noEnglishText;
    final fields = _notes.decodeFields(note.fieldsJson);
    if (fields.any(_soundTag.hasMatch)) return PronunciationOutcome.alreadyHasAudio;

    final names = (await _notetypes.fieldsFor(note.notetypeId)).map((f) => f.name).toList();
    final index = englishFieldIndex(names, fields);
    if (index == null) return PronunciationOutcome.noEnglishText;

    final String? file;
    try {
      file = await _lookup.fetchInto(plainText(fields[index]), await mediaDirectory());
    } on PronunciationNetworkException {
      return PronunciationOutcome.networkError;
    }
    if (file == null) return PronunciationOutcome.notFound;

    // Re-read: the note may have been edited while the download ran.
    final fresh = await (_db.select(_db.notes)..where((n) => n.id.equals(noteId))).getSingleOrNull();
    if (fresh == null) return PronunciationOutcome.notFound;
    final current = _notes.decodeFields(fresh.fieldsJson);
    if (index >= current.length || current.any(_soundTag.hasMatch)) return PronunciationOutcome.alreadyHasAudio;
    current[index] = '${current[index].trimRight()} [sound:$file]';
    await _notes.updateNoteFields(noteId, current);
    return PronunciationOutcome.added;
  }

  /// Same folder the .apkg importer/exporter and the card renderer use.
  static Future<Directory> mediaDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(p.join(appDir.path, 'media'));
  }

  static String plainText(String html) => html
      .replaceAll(_soundTag, ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final _latinWord = RegExp(r"^[A-Za-z][A-Za-z'’\- ]*$");
  static final _englishName = RegExp(r'english|англ|word|term|expression|front|слово', caseSensitive: false);

  /// Which field holds the English word: a short, Latin-only value (no
  /// Cyrillic, at most a few words). A field *named* like an English/word
  /// field wins over position; otherwise the first match. Null if none -
  /// e.g. a Russian-only note, or a long sentence.
  static int? englishFieldIndex(List<String> fieldNames, List<String> values) {
    bool looksEnglish(String v) {
      final t = plainText(v);
      return t.isNotEmpty && t.length <= 40 && t.split(' ').length <= 4 && _latinWord.hasMatch(t);
    }

    int? first;
    for (var i = 0; i < values.length; i++) {
      if (!looksEnglish(values[i])) continue;
      if (i < fieldNames.length && _englishName.hasMatch(fieldNames[i])) return i;
      first ??= i;
    }
    return first;
  }
}
