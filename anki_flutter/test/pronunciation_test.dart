import 'package:anki_flutter/data/media/pronunciation_lookup.dart';
import 'package:anki_flutter/data/media/pronunciation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Oxford page parsing', () {
    const page = '''
<h1 class="headword" id="reluctant_h_1" htag="h1">reluctant</h1>
<div class="sound audio_play_button pron-uk" data-src-mp3="https://ox.example/media/english/uk_pron/r/rel/reluctant__gb_2.mp3"></div>
<div class="sound audio_play_button pron-us" data-src-mp3="https://ox.example/media/english/us_pron/r/rel/reluctant__us_1.mp3"></div>
''';

    test('prefers the American recording', () {
      expect(PronunciationLookup.oxfordAudioFromPage(page, 'reluctant'), contains('/us_pron/'));
    });

    test('falls back to British when there is no American one', () {
      final ukOnly = page.replaceAll(RegExp(r'<div[^>]*pron-us[^>]*></div>'), '');
      expect(PronunciationLookup.oxfordAudioFromPage(ukOnly, 'reluctant'), contains('/uk_pron/'));
    });

    test('rejects a page for a different headword ("check in" -> noun "check-in")', () {
      final checkIn = page.replaceAll('>reluctant</h1>', '>check-in</h1>');
      expect(PronunciationLookup.oxfordAudioFromPage(checkIn, 'check in'), isNull);
    });

    test('rejects a spell-check page with no headword', () {
      expect(PronunciationLookup.oxfordAudioFromPage('<p>Did you mean…</p>', 'heavy rain'), isNull);
    });
  });

  group('Wiktionary file choice', () {
    int? rank(String file, String word) => PronunciationLookup.wiktionaryRank(file, word);

    test('American exact > American homograph sense > Lingua Libre > other accents', () {
      expect(rank('En-us-reluctant.ogg', 'reluctant'), 0);
      expect(rank('en-us-record-noun.ogg', 'record'), 1);
      expect(rank('LL-Q1860 (eng)-Somebody-thorough.wav', 'thorough'), 2);
      expect(rank('en-uk-thorough.ogg', 'thorough'), 3);
    });

    test('ignores other languages, other words and non-audio', () {
      expect(rank('Fr-record.ogg', 'record'), isNull);
      expect(rank('en-us-recorder.ogg', 'record'), isNull);
      expect(rank('Record player.jpg', 'record'), isNull);
    });

    test('multi-word titles match with spaces or underscores', () {
      // Callers pass the term with spaces turned into hyphens.
      expect(rank('en-us-check_in.ogg', 'check-in'), 0);
      expect(rank('En-us-check in.ogg', 'check-in'), 0);
    });

    test('picks the best file from an API reply', () {
      const json = '{"query":{"pages":['
          '{"title":"File:Fr-record.ogg","imageinfo":[{"url":"https://u/fr.ogg"}]},'
          '{"title":"File:en-uk-record.ogg","imageinfo":[{"url":"https://u/uk.ogg"}]},'
          '{"title":"File:en-us-record-noun.ogg","imageinfo":[{"url":"https://u/us.ogg"}]}'
          ']}}';
      expect(PronunciationLookup.bestWiktionaryAudio(json, 'record'), 'https://u/us.ogg');
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
