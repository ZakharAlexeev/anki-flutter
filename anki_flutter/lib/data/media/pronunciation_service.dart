import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../repositories/note_repository.dart';
import '../repositories/notetype_repository.dart';
import 'pronunciation_lookup.dart';

export 'pronunciation_lookup.dart' show Accent;

enum PronunciationOutcome {
  /// A recording was found and a `[sound:...]` tag added to the note.
  added,

  /// The app's earlier recording was replaced with one in the chosen accent.
  replaced,

  /// The note already had audio (its own, or the app's when only adding).
  alreadyHasAudio,

  /// No field looks like an English word or phrase.
  noEnglishText,

  /// Neither Oxford nor Wiktionary has a recording of it.
  notFound,

  /// The sources couldn't be reached (offline, blocked, timed out).
  networkError,
}

/// Running totals while voicing a deck.
class VoiceDeckProgress {
  int done = 0;
  int total = 0;
  int added = 0;
  int replaced = 0;
  int otherAccent = 0; // got audio, but not in the chosen accent
  int skipped = 0; // own audio, already voiced, or no English word
  int notFound = 0;
  int networkErrors = 0;
}

/// Adds recorded pronunciations to notes: finds the field holding the
/// English word, looks it up via [PronunciationLookup] in the chosen accent
/// and appends `[sound:pron_...mp3]` to that field - exactly how Anki
/// stores audio, so it plays wherever the word is shown and survives .apkg
/// export to desktop Anki.
///
/// Only the app's own recordings (files named `pron_...`) are ever
/// replaced; audio that came with an imported deck is left alone.
class PronunciationService {
  PronunciationService(
    this._db,
    this._notes,
    this._notetypes, {
    PronunciationLookup? lookup,
    Future<Directory> Function()? mediaDir,
  })  : _lookup = lookup ?? PronunciationLookup(),
        _mediaDir = mediaDir ?? mediaDirectory;

  final AppDatabase _db;
  final NoteRepository _notes;
  final NotetypeRepository _notetypes;
  final PronunciationLookup _lookup;
  final Future<Directory> Function() _mediaDir;

  static final _soundTag = RegExp(r'\[sound:([^\]]+)\]');
  static bool _isOwn(String file) => file.startsWith('pron_');

  // --- accent setting ------------------------------------------------------

  static Accent? _accentCache;

  static Future<File> _settingsFile() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'pronunciation.json'));

  /// The accent to look for; British unless changed.
  static Future<Accent> accent() async {
    final cached = _accentCache;
    if (cached != null) return cached;
    var value = Accent.british;
    try {
      final f = await _settingsFile();
      if (await f.exists()) {
        final name = (jsonDecode(await f.readAsString()) as Map)['accent'];
        value = Accent.values.firstWhere((a) => a.name == name, orElse: () => Accent.british);
      }
    } catch (_) {
      // No storage (tests) or a damaged file: keep the default.
    }
    return _accentCache = value;
  }

  static Future<void> setAccent(Accent value) async {
    _accentCache = value;
    try {
      final f = await _settingsFile();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode({'accent': value.name}), flush: true);
    } catch (_) {
      // Applies for this session even if it couldn't be saved.
    }
  }

  // --- one note ------------------------------------------------------------

  /// Adds a pronunciation to [noteId] if it has none. With [replace], the
  /// app's own earlier recording is swapped for one in the current accent
  /// (kept as it is if no better one can be fetched).
  Future<PronunciationOutcome> attachTo(int noteId, {bool replace = false}) async {
    final result = await _attach(noteId, replace: replace);
    return result.$1;
  }

  /// [attachTo], also telling whether the saved recording is in the chosen
  /// accent.
  Future<(PronunciationOutcome, bool preferredAccent)> _attach(int noteId, {required bool replace}) async {
    final note = await (_db.select(_db.notes)..where((n) => n.id.equals(noteId))).getSingleOrNull();
    if (note == null) return (PronunciationOutcome.noEnglishText, false);
    final fields = _notes.decodeFields(note.fieldsJson);
    final sounds = [for (final f in fields) for (final m in _soundTag.allMatches(f)) m.group(1)!];
    if (sounds.any((s) => !_isOwn(s))) return (PronunciationOutcome.alreadyHasAudio, false); // imported audio
    final hasOwn = sounds.isNotEmpty;
    if (hasOwn && !replace) return (PronunciationOutcome.alreadyHasAudio, false);

    final names = (await _notetypes.fieldsFor(note.notetypeId)).map((f) => f.name).toList();
    final index = englishFieldIndex(names, fields);
    if (index == null) return (PronunciationOutcome.noEnglishText, false);

    final wanted = await accent();
    if (hasOwn && sounds.every((s) => s.contains('_${wanted.label}_'))) {
      return (PronunciationOutcome.alreadyHasAudio, true); // already in this accent
    }

    final FetchedPronunciation? fetched;
    try {
      fetched = await _lookup.fetchInto(plainText(fields[index]), await _mediaDir(), accent: wanted);
    } on PronunciationNetworkException {
      return (PronunciationOutcome.networkError, false);
    }
    if (fetched == null) return (PronunciationOutcome.notFound, false);
    // Re-voicing that only finds the same kind of recording changes nothing.
    if (hasOwn && sounds.contains(fetched.fileName)) {
      return (PronunciationOutcome.alreadyHasAudio, fetched.preferredAccent);
    }

    // Re-read: the note may have been edited while the download ran.
    final fresh = await (_db.select(_db.notes)..where((n) => n.id.equals(noteId))).getSingleOrNull();
    if (fresh == null) return (PronunciationOutcome.notFound, false);
    final current = _notes.decodeFields(fresh.fieldsJson);
    if (index >= current.length) return (PronunciationOutcome.notFound, false);
    // Drop the app's old recordings, then add the new one to the English field.
    for (var i = 0; i < current.length; i++) {
      current[i] = current[i]
          .replaceAllMapped(_soundTag, (m) => _isOwn(m.group(1)!) ? '' : m.group(0)!)
          .replaceAll(RegExp(r'\s+$'), '');
    }
    current[index] = '${current[index]} [sound:${fetched.fileName}]';
    await _notes.updateNoteFields(noteId, current);
    return (hasOwn ? PronunciationOutcome.replaced : PronunciationOutcome.added, fetched.preferredAccent);
  }

  // --- a whole deck --------------------------------------------------------

  /// Voices every note of [deckId]: adds audio where there is none, and
  /// with [replace] also re-voices the app's earlier recordings in the
  /// current accent. Reports after each note; stops early when [cancelled]
  /// returns true. Pauses briefly between lookups, to be polite to the
  /// dictionaries.
  Future<VoiceDeckProgress> voiceDeck(
    int deckId, {
    required bool replace,
    required void Function(VoiceDeckProgress) onProgress,
    bool Function()? cancelled,
    Duration pause = const Duration(milliseconds: 300),
  }) async {
    final rows = await _notes.cardsWithNotesForDeck(deckId);
    final noteIds = {for (final r in rows) r.$2.id}.toList();
    final progress = VoiceDeckProgress()..total = noteIds.length;
    onProgress(progress);
    for (final id in noteIds) {
      if (cancelled?.call() ?? false) break;
      final (outcome, preferred) = await _attach(id, replace: replace);
      switch (outcome) {
        case PronunciationOutcome.added:
          progress.added++;
          if (!preferred) progress.otherAccent++;
        case PronunciationOutcome.replaced:
          progress.replaced++;
          if (!preferred) progress.otherAccent++;
        case PronunciationOutcome.alreadyHasAudio:
        case PronunciationOutcome.noEnglishText:
          progress.skipped++;
        case PronunciationOutcome.notFound:
          progress.notFound++;
        case PronunciationOutcome.networkError:
          progress.networkErrors++;
      }
      progress.done++;
      onProgress(progress);
      final lookedUp = outcome != PronunciationOutcome.alreadyHasAudio && outcome != PronunciationOutcome.noEnglishText;
      if (lookedUp && pause > Duration.zero) await Future<void>.delayed(pause);
    }
    return progress;
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
