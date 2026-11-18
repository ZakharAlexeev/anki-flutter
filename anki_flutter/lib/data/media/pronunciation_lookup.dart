import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Finds a recorded (human) pronunciation of an English word and saves it
/// as an mp3 - first from the Oxford Learner's Dictionaries, then from
/// Wiktionary. There is deliberately no speech-synthesis fallback: if
/// neither has a recording, the word simply gets no audio.
///
/// American recordings are preferred; another English accent is used only
/// when no American one exists. Both sources only record dictionary
/// headwords, so set phrases and collocations ("heavy rain") usually have
/// no audio at all.
///
/// Pure Dart (no Flutter imports) so it can be exercised from a plain
/// `dart run` script as well as from the app.
class PronunciationLookup {
  PronunciationLookup({HttpClient Function()? httpClient}) : _newClient = httpClient ?? HttpClient.new;

  final HttpClient Function() _newClient;

  /// Identifies the app to the sites it queries. Wikimedia's User-Agent
  /// policy requires a way to contact the client's author; without one its
  /// media server answers 429 to every download.
  static const userAgent = 'AnkiPersonal/1.0 (https://github.com/ZakharAlexeev/anki-flutter)';

  static const _timeout = Duration(seconds: 12);

  /// Looks [term] up and, if a recording is found, writes it to [mediaDir]
  /// and returns the file name (for a `[sound:...]` tag). Returns null when
  /// no source has a recording. Throws [PronunciationNetworkException] if
  /// no source could be reached at all, so the caller can tell "this word
  /// has no recording" apart from "no internet".
  Future<String?> fetchInto(String term, Directory mediaDir) async {
    final variants = searchVariants(term);
    if (variants.isEmpty) return null;

    final fileName = 'pron_${slug(variants.first)}.mp3';
    final target = File('${mediaDir.path}${Platform.pathSeparator}$fileName');
    if (await target.exists()) return fileName;

    var reachedAnySource = false;
    var foundButBlocked = false;
    for (final source in [_oxford, _wiktionary]) {
      for (final variant in variants) {
        Uri? url;
        try {
          url = await source(variant);
          reachedAnySource = true;
          if (url == null) continue;
          final bytes = await _download(url);
          if (bytes == null) continue;
          await mediaDir.create(recursive: true);
          await target.writeAsBytes(bytes, flush: true);
          return fileName;
        } on _Unreachable {
          // A recording exists but its server refused or timed out: that's
          // a network problem, not "this word has no recording".
          if (url != null) foundButBlocked = true;
        }
      }
    }
    if (!reachedAnySource || foundButBlocked) throw const PronunciationNetworkException();
    return null;
  }

  // --- Oxford Learner's Dictionaries ---------------------------------------

  Future<Uri?> _oxford(String term) async {
    final search = Uri.https('www.oxfordlearnersdictionaries.com', '/search/english/', {'q': term});
    final res = await _get(search);
    if (res.status != 200) return null;
    final mp3 = oxfordAudioFromPage(utf8.decode(res.body, allowMalformed: true), term);
    return mp3 == null ? null : Uri.parse(mp3);
  }

  static final _oxHeadword = RegExp(r'<h1[^>]*class="headword"[^>]*>(.*?)</h1>', dotAll: true);
  static final _oxMp3 = RegExp(r'data-src-mp3="([^"]+\.mp3)"');

  /// The pronunciation mp3 on an Oxford entry page, but only if the page's
  /// headword is exactly [term]: a search for "check in" lands on the noun
  /// "check-in", whose stress differs, and that must not be used.
  static String? oxfordAudioFromPage(String html, String term) {
    final headword = _oxHeadword.firstMatch(html);
    if (headword == null) return null; // spell-check / "did you mean" page
    final text = headword.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '');
    if (normalize(text) != normalize(term)) return null;

    final urls = _oxMp3.allMatches(html).map((m) => m.group(1)!).toList();
    // The entry's own pronunciations come first on the page (British, then
    // American); take the American one if there is one.
    return urls.firstWhere((u) => u.contains('/us_pron'), orElse: () => urls.isEmpty ? '' : urls.first).nullIfEmpty;
  }

  // --- Wiktionary -----------------------------------------------------------

  Future<Uri?> _wiktionary(String term) async {
    final api = Uri.https('en.wiktionary.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'titles': term,
      'generator': 'images',
      'gimlimit': '500',
      'prop': 'imageinfo',
      'iiprop': 'url',
    });
    final res = await _get(api);
    if (res.status != 200) return null;
    final file = bestWiktionaryAudio(utf8.decode(res.body, allowMalformed: true), term);
    return file == null ? null : Uri.parse(mp3Version(file));
  }

  /// Picks the best English recording of [term] among the audio files on
  /// its Wiktionary page (which also lists other languages' recordings and
  /// related words). Takes the MediaWiki API's JSON reply; returns the
  /// original file URL.
  static String? bestWiktionaryAudio(String apiJson, String term) {
    final Object? decoded;
    try {
      decoded = jsonDecode(apiJson);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final query = decoded['query'];
    if (query is! Map) return null;
    final pages = query['pages'];
    if (pages is! List) return null;

    final want = normalize(term).replaceAll(' ', '-');
    String? best;
    var bestRank = 1 << 30;
    for (final page in pages.whereType<Map>()) {
      final title = page['title'];
      final info = page['imageinfo'];
      if (title is! String || !title.startsWith('File:') || info is! List || info.isEmpty) continue;
      final url = (info.first as Map?)?['url'];
      if (url is! String) continue;
      final rank = wiktionaryRank(title.substring(5), want);
      if (rank != null && rank < bestRank) {
        best = url;
        bestRank = rank;
      }
    }
    return best;
  }

  /// Lower is better; null = not an English recording of this word.
  ///  0  en-us-reluctant.ogg           American, exact
  ///  1  en-us-record-noun.ogg          American, one sense of a homograph
  ///  2  LL-Q1860 (eng)-Name-word.wav   Lingua Libre English speaker
  ///  3  en-uk-word.ogg, en-au-...      another English accent
  static int? wiktionaryRank(String fileName, String want) {
    final base = fileName.toLowerCase().replaceAll(RegExp(r'\.(ogg|oga|mp3|wav|flac|opus)$'), '');
    if (base == fileName.toLowerCase()) return null; // not audio
    final n = base.replaceAll(RegExp(r'[\s_]+'), '-');

    for (final us in ['en-us-', 'en-ame-']) {
      if (n == '$us$want') return 0;
      if (n.startsWith('$us$want-')) return 1;
    }
    if (n.startsWith('ll-q1860-(eng)-') && n.endsWith('-$want')) return 2;
    final other = RegExp(r'^en-(uk|gb|au|ca|nz|ie|za|in|sc)-').firstMatch(n);
    if (other != null) {
      final rest = n.substring(other.end);
      if (rest == want || rest.startsWith('$want-')) return 3;
    }
    if (n == 'en-$want') return 3;
    return null;
  }

  /// Wikimedia keeps recordings as Ogg, which iPhones can't play; Commons
  /// serves an mp3 transcode of every audio file next to the original.
  static String mp3Version(String originalUrl) {
    final url = originalUrl.split('?').first;
    if (url.toLowerCase().endsWith('.mp3')) return url;
    const marker = '/wikipedia/commons/';
    final i = url.indexOf(marker);
    if (i < 0) return url;
    final rest = url.substring(i + marker.length); // 0/09/En-us-reluctant.ogg
    final name = rest.split('/').last;
    return '${url.substring(0, i)}${marker}transcoded/$rest/$name.mp3';
  }

  // --- helpers --------------------------------------------------------------

  /// Spellings to try, best first: as typed, lower-cased, and without a
  /// leading infinitive "to".
  static List<String> searchVariants(String term) {
    final t = term.replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ').trim().replaceAll(RegExp(r'[.,!?;:]+$'), '');
    if (t.isEmpty) return const [];
    final out = <String>[t, t.toLowerCase()];
    final lower = t.toLowerCase();
    if (lower.startsWith('to ') && lower.length > 3) out.add(lower.substring(3));
    return out.toSet().toList();
  }

  static String normalize(String s) =>
      s.toLowerCase().replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ').trim();

  static String slug(String s) =>
      normalize(s).replaceAll(RegExp(r"[^a-z0-9']+"), '_').replaceAll("'", '').replaceAll(RegExp(r'^_+|_+$'), '');

  Future<Uint8List?> _download(Uri url) async {
    final res = await _get(url);
    if (res.status != 200 || res.body.length < 1000) return null;
    final b = res.body;
    // An mp3 starts with an ID3 tag or an MPEG frame sync; anything else
    // (an HTML error page, say) is rejected rather than saved as audio.
    final isMp3 = (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) || (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0);
    return isMp3 ? b : null;
  }

  Future<_Response> _get(Uri uri) async {
    final client = _newClient()
      ..userAgent = userAgent
      ..connectionTimeout = _timeout;
    try {
      final req = await client.getUrl(uri).timeout(_timeout);
      final res = await req.close().timeout(_timeout);
      final builder = BytesBuilder(copy: false);
      await res.forEach(builder.add).timeout(_timeout);
      if (res.statusCode == 429 || res.statusCode >= 500) throw const _Unreachable();
      return _Response(res.statusCode, builder.takeBytes());
    } on SocketException {
      throw const _Unreachable();
    } on HttpException {
      throw const _Unreachable();
    } on TimeoutException {
      throw const _Unreachable();
    } on HandshakeException {
      throw const _Unreachable();
    } finally {
      client.close(force: true);
    }
  }
}

class PronunciationNetworkException implements Exception {
  const PronunciationNetworkException();
  @override
  String toString() => 'Нет связи с Oxford и Wiktionary';
}

class _Unreachable implements Exception {
  const _Unreachable();
}

class _Response {
  const _Response(this.status, this.body);
  final int status;
  final Uint8List body;
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
