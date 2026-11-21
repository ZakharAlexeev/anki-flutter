import 'dart:io';

import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/data/media/pronunciation_lookup.dart';
import 'package:anki_flutter/data/media/pronunciation_service.dart';
import 'package:anki_flutter/data/repositories/deck_repository.dart';
import 'package:anki_flutter/data/repositories/note_repository.dart';
import 'package:anki_flutter/data/repositories/notetype_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pretends to be the dictionaries: "finds" a recording for every word,
/// in the accent given by [found] (or none when null).
class _FakeLookup extends PronunciationLookup {
  _FakeLookup(this.found);
  Accent? found;
  int calls = 0;

  @override
  Future<FetchedPronunciation?> fetchInto(String term, Directory mediaDir, {Accent accent = Accent.british}) async {
    calls++;
    final a = found;
    if (a == null) return null;
    final name = 'pron_ox_${a.label}_${PronunciationLookup.slug(term)}.mp3';
    return FetchedPronunciation(name, preferredAccent: a == accent);
  }
}

void main() {
  group('Oxford page parsing', () {
    const page = '''
<h1 class="headword" id="reluctant_h_1" htag="h1">reluctant</h1>
<div class="sound audio_play_button pron-uk" data-src-mp3="https://ox.example/media/english/uk_pron/r/rel/reluctant__gb_2.mp3"></div>
<div class="sound audio_play_button pron-us" data-src-mp3="https://ox.example/media/english/us_pron/r/rel/reluctant__us_1.mp3"></div>
''';

    test('finds both the British and the American recording', () {
      final urls = PronunciationLookup.oxfordAudioUrls(page, 'reluctant');
      expect(urls['uk'], contains('/uk_pron/'));
      expect(urls['us'], contains('/us_pron/'));
    });

    test('rejects a page for a different headword ("check in" -> noun "check-in")', () {
      final checkIn = page.replaceAll('>reluctant</h1>', '>check-in</h1>');
      expect(PronunciationLookup.oxfordAudioUrls(checkIn, 'check in'), isEmpty);
    });

    test('rejects a spell-check page with no headword', () {
      expect(PronunciationLookup.oxfordAudioUrls('<p>Did you mean…</p>', 'heavy rain'), isEmpty);
    });
  });

  group('Wiktionary file choice', () {
    ({String group, bool exact})? kind(String file, String word) => PronunciationLookup.wiktionaryKind(file, word);

    test('recognises accents and homograph senses', () {
      expect(kind('En-us-reluctant.ogg', 'reluctant'), (group: 'us', exact: true));
      expect(kind('en-uk-record-noun.ogg', 'record'), (group: 'uk', exact: false));
      expect(kind('en-gb-thorough.ogg', 'thorough'), (group: 'uk', exact: true));
      expect(kind('LL-Q1860 (eng)-Somebody-thorough.wav', 'thorough'), (group: 'll', exact: true));
      expect(kind('en-au-thorough.ogg', 'thorough'), (group: 'commonwealth', exact: true));
    });

    test('ignores other languages, other words and non-audio', () {
      expect(kind('Fr-record.ogg', 'record'), isNull);
      expect(kind('en-us-recorder.ogg', 'record'), isNull);
      expect(kind('Record player.jpg', 'record'), isNull);
    });

    test('multi-word titles match with spaces or underscores', () {
      expect(kind('en-us-check_in.ogg', 'check-in'), (group: 'us', exact: true));
      expect(kind('En-uk-check in.ogg', 'check-in'), (group: 'uk', exact: true));
    });

    const reply = '{"query":{"pages":['
        '{"title":"File:Fr-record.ogg","imageinfo":[{"url":"https://u/fr.ogg"}]},'
        '{"title":"File:en-uk-record.ogg","imageinfo":[{"url":"https://u/uk.ogg"}]},'
        '{"title":"File:en-us-record-noun.ogg","imageinfo":[{"url":"https://u/us.ogg"}]}'
        ']}}';

    test('British is preferred by default, American when chosen', () {
      expect(PronunciationLookup.bestWiktionaryAudio(reply, 'record'), (url: 'https://u/uk.ogg', label: 'uk'));
      expect(
        PronunciationLookup.bestWiktionaryAudio(reply, 'record', accent: Accent.american),
        (url: 'https://u/us.ogg', label: 'us'),
      );
    });

    test('falls back to another accent when the chosen one is missing', () {
      const usOnly = '{"query":{"pages":[{"title":"File:en-us-go.ogg","imageinfo":[{"url":"https://u/go.ogg"}]}]}}';
      expect(PronunciationLookup.bestWiktionaryAudio(usOnly, 'go'), (url: 'https://u/go.ogg', label: 'us'));
    });

    test('mp3 transcode URL for an Ogg original', () {
      expect(
        PronunciationLookup.mp3Version(
          'https://upload.wikimedia.org/wikipedia/commons/0/09/En-us-reluctant.ogg?utm_source=x',
        ),
        'https://upload.wikimedia.org/wikipedia/commons/transcoded/0/09/En-us-reluctant.ogg/En-us-reluctant.ogg.mp3',
      );
    });
  });

  group('voicing and re-voicing notes', () {
    late AppDatabase db;
    late NoteRepository notes;
    late _FakeLookup lookup;
    late PronunciationService service;
    late int deckId;
    late int basicId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.ensureSeeded();
      final decks = DeckRepository(db);
      final notetypes = NotetypeRepository(db);
      await notetypes.ensureSeeded();
      notes = NoteRepository(db, decks, notetypes);
      lookup = _FakeLookup(Accent.british);
      service = PronunciationService(db, notes, notetypes,
          lookup: lookup, mediaDir: () async => Directory.systemTemp);
      await PronunciationService.setAccent(Accent.british);
      deckId = await decks.createDeck('Test');
      basicId = (await db.select(db.notetypes).get()).firstWhere((n) => n.name == 'Basic').id;
    });

    tearDown(() => db.close());

    Future<String> front(int noteId) async =>
        notes.decodeFields((await (db.select(db.notes)..where((n) => n.id.equals(noteId))).getSingle()).fieldsJson)[0];

    test('re-voicing swaps an American recording for a British one', () async {
      final id = await notes.createNote(
          notetypeId: basicId, deckId: deckId, fields: ['reluctant [sound:pron_ox_us_reluctant.mp3]', 'неохотный']);
      expect(await service.attachTo(id), PronunciationOutcome.alreadyHasAudio, reason: 'adding leaves voiced notes');
      expect(await service.attachTo(id, replace: true), PronunciationOutcome.replaced);
      expect(await front(id), 'reluctant [sound:pron_ox_uk_reluctant.mp3]');
      // Already British: nothing to do, and no lookup made.
      final calls = lookup.calls;
      expect(await service.attachTo(id, replace: true), PronunciationOutcome.alreadyHasAudio);
      expect(lookup.calls, calls);
    });

    test('re-voicing keeps the old recording when nothing is found', () async {
      final id = await notes.createNote(
          notetypeId: basicId, deckId: deckId, fields: ['reluctant [sound:pron_ox_us_reluctant.mp3]', 'x']);
      lookup.found = null;
      expect(await service.attachTo(id, replace: true), PronunciationOutcome.notFound);
      expect(await front(id), 'reluctant [sound:pron_ox_us_reluctant.mp3]');
    });

    test("audio that came with an imported deck is never touched", () async {
      final id = await notes.createNote(
          notetypeId: basicId, deckId: deckId, fields: ['reluctant [sound:reluctant_dict.mp3]', 'x']);
      expect(await service.attachTo(id, replace: true), PronunciationOutcome.alreadyHasAudio);
      expect(await front(id), 'reluctant [sound:reluctant_dict.mp3]');
    });

    test('voicing a deck counts what happened to each note', () async {
      await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['eager', 'нетерпеливый']);
      await notes.createNote(
          notetypeId: basicId, deckId: deckId, fields: ['thorough [sound:pron_ox_us_thorough.mp3]', 'тщательный']);
      await notes.createNote(notetypeId: basicId, deckId: deckId, fields: ['привет', 'hello world, how are you today']);
      final p = await service.voiceDeck(deckId, replace: true, onProgress: (_) {}, pause: Duration.zero);
      expect([p.total, p.done, p.added, p.replaced, p.skipped], [3, 3, 1, 1, 1]);
    });
  });

  group('which field is the English word', () {
    test('a RU→EN note: the English field, even though it comes second', () {
      expect(PronunciationService.englishFieldIndex(['Russian', 'English'], ['неохотный', 'reluctant']), 1);
    });

    test('Basic with the English word on the front', () {
      expect(PronunciationService.englishFieldIndex(['Front', 'Back'], ['reluctant', 'неохотный']), 0);
    });

    test('a field named English wins over an earlier Latin field', () {
      expect(PronunciationService.englishFieldIndex(['Note', 'English'], ['abc', 'eager']), 1);
    });

    test('no English: Russian only, or a long sentence', () {
      expect(PronunciationService.englishFieldIndex(['Front', 'Back'], ['привет', 'мир']), isNull);
      expect(
        PronunciationService.englishFieldIndex(['Front'], ['She was reluctant to leave the party early']),
        isNull,
      );
    });

    test('formatting is ignored', () {
      expect(PronunciationService.englishFieldIndex(['Front'], ['<b>reluctant</b>&nbsp;']), 0);
    });
  });

  test('the contact link goes to Wikimedia only (Oxford blocks it with 403)', () {
    String ua(String url) => PronunciationLookup.userAgentFor(Uri.parse(url));
    expect(ua('https://en.wiktionary.org/w/api.php'), contains('github.com'));
    expect(ua('https://upload.wikimedia.org/wikipedia/commons/x.mp3'), contains('github.com'));
    expect(ua('https://www.oxfordlearnersdictionaries.com/search/english/?q=go'), isNot(contains('http')));
  });

  test('search variants: as typed, lower-case, without infinitive "to"', () {
    expect(PronunciationLookup.searchVariants('To Adhere.'), ['To Adhere', 'to adhere', 'adhere']);
  });
}
