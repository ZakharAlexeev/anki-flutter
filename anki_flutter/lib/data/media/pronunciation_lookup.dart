import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Finds a recorded (human) pronunciation of an English word and saves it
/// as an mp3 - first from the Oxford Learner's Dictionaries, then from
/// Wiktionary. There is deliberately no speech-synthesis fallback: if
/// neither has a recording, the word simply gets no audio.
///
/// Recordings in the chosen [Accent] (British by default) are preferred;
/// another English accent is used only when none exists. Both sources only record dictionary
/// headwords, so set phrases and collocations ("heavy rain") usually have
/// no audio at all.
///
/// Pure Dart (no Flutter imports) so it can be exercised from a plain
/// `dart run` script as well as from the app.
class PronunciationLookup {
  PronunciationLookup({HttpClient Function()? httpClient}) : _newClient = httpClient ?? HttpClient.new;

  final HttpClient Function() _newClient;

  /// How the app introduces itself. The two sources want different things:
  /// Wikimedia's User-Agent policy requires a contact link (without one its
  /// media server answers 429 to every download), while Oxford's bot filter
  /// answers 403 to any client whose User-Agent contains a link. So the
  /// contact goes to Wikimedia only.
  static const userAgent = 'AnkiPersonal/1.0 (personal flashcard app)';
  static const wikimediaUserAgent = 'AnkiPersonal/1.0 (https://github.com/ZakharAlexeev/anki-flutter)';

  static String userAgentFor(Uri uri) {
    final host = uri.host.toLowerCase();
    final wikimedia = host.endsWith('wikimedia.org') || host.endsWith('wiktionary.org');
    return wikimedia ? wikimediaUserAgent : userAgent;
  }

  static const _timeout = Duration(seconds: 12);

  /// Looks [term] up and, if a recording is found, writes it to [mediaDir]
  /// and returns it (the file name is for a `[sound:...]` tag). Returns
  /// null when no source has a recording. Throws
  /// [PronunciationNetworkException] if no source could be reached at all,
  /// so the caller can tell "this word has no recording" apart from "no
  /// internet".
  ///
  /// Recordings in [accent] win over any other accent, from either source:
  /// Oxford in that accent, then Wiktionary in that accent, then Oxford's
  /// other accent, then any English recording on Wiktionary.
  Future<FetchedPronunciation?> fetchInto(String term, Directory mediaDir, {Accent accent = Accent.british}) async {
    final variants = searchVariants(term);
    if (variants.isEmpty) return null;

    final word = slug(variants.first);
    final want = accent.label;
    // Named by source and accent, so a recording in another accent (or one
    // saved while a source was unavailable) never stands in for a better
    // one on later cards.
    File fileFor(String source, String label) =>
        File('${mediaDir.path}${Platform.pathSeparator}pron_${source}_${label}_$word.mp3');
    for (final source in ['ox', 'wk']) {
      final cached = fileFor(source, want);
      if (await cached.exists()) return FetchedPronunciation(_fileName(cached), preferredAccent: true);
    }

    var reachedAnySource = false;
    var foundButBlocked = false;
    for (final variant in variants) {
      final candidates = <({Uri url, String source, String label})>[];
      Map<String, String> ox = const {};
      ({String url, String label})? wk;
      try {
        ox = await _oxford(variant);
        reachedAnySource = true;
      } on _Unreachable {
        // Try Wiktionary; Oxford is down or refusing us.
      }
      try {
        wk = await _wiktionary(variant, accent);
        reachedAnySource = true;
      } on _Unreachable {
        // Oxford's answer (if any) still counts.
      }
      final other = accent == Accent.british ? 'us' : 'uk';
      if (ox[want] != null) candidates.add((url: Uri.parse(ox[want]!), source: 'ox', label: want));
      if (wk != null && wk.label == want) candidates.add((url: Uri.parse(wk.url), source: 'wk', label: wk.label));
      if (ox[other] != null) candidates.add((url: Uri.parse(ox[other]!), source: 'ox', label: other));
      if (wk != null && wk.label != want) candidates.add((url: Uri.parse(wk.url), source: 'wk', label: wk.label));

      for (final c in candidates) {
        try {
          final bytes = await _download(c.url);
          if (bytes == null) continue;
          await mediaDir.create(recursive: true);
          final target = fileFor(c.source, c.label);
          await target.writeAsBytes(bytes, flush: true);
          return FetchedPronunciation(_fileName(target), preferredAccent: c.label == want);
        } on _Unreachable {
          // A recording exists but its server refused or timed out: that's
          // a network problem, not "this word has no recording".
          foundButBlocked = true;
        }
      }
    }
    if (!reachedAnySource || foundButBlocked) throw const PronunciationNetworkException();
    return null;
  }

  static String _fileName(File f) => f.uri.pathSegments.last;

  // --- Oxford Learner's Dictionaries ---------------------------------------

  /// The entry's recordings by accent ('uk' / 'us').
  Future<Map<String, String>> _oxford(String term) async {
    final search = Uri.https('www.oxfordlearnersdictionaries.com', '/search/english/', {'q': term});
    final res = await _get(search);
    if (res.status != 200) return const {};
    return oxfordAudioUrls(utf8.decode(res.body, allowMalformed: true), term);
  }

  static final _oxHeadword = RegExp(r'<h1[^>]*class="headword"[^>]*>(.*?)</h1>', dotAll: true);
  static final _oxMp3 = RegExp(r'data-src-mp3="([^"]+\.mp3)"');

  /// The British and American pronunciation mp3s on an Oxford entry page
  /// (keys 'uk' and 'us'), but only if the page's headword is exactly
  /// [term]: a search for "check in" lands on the noun "check-in", whose
  /// stress differs, and that must not be used.
  static Map<String, String> oxfordAudioUrls(String html, String term) {
    final headword = _oxHeadword.firstMatch(html);
    if (headword == null) return const {}; // spell-check / "did you mean" page
    final text = headword.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '');
    if (normalize(text) != normalize(term)) return const {};

    // The entry's own pronunciations come first on the page; later ones
    // belong to idioms and other sections.
    final out = <String, String>{};
    for (final m in _oxMp3.allMatches(html)) {
      final url = m.group(1)!;
      if (url.contains('/uk_pron')) out.putIfAbsent('uk', () => url);
      if (url.contains('/us_pron')) out.putIfAbsent('us', () => url);
    }
    return out;
  }

  // --- Wiktionary -----------------------------------------------------------

  Future<({String url, String label})?> _wiktionary(String term, Accent accent) async {
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
    final best = bestWiktionaryAudio(utf8.decode(res.body, allowMalformed: true), term, accent: accent);
    return best == null ? null : (url: mp3Version(best.url), label: best.label);
  }

  /// Picks the best English recording of [term] among the audio files on
  /// its Wiktionary page (which also lists other languages' recordings and
  /// related words), preferring [accent]. Takes the MediaWiki API's JSON
  /// reply; returns the original file URL and its accent label ('uk', 'us'
  /// or 'en' for other/unknown English accents).
  static ({String url, String label})? bestWiktionaryAudio(String apiJson, String term, {Accent accent = Accent.british}) {
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
    ({String url, String label})? best;
    var bestRank = 1 << 30;
    for (final page in pages.whereType<Map>()) {
      final title = page['title'];
      final info = page['imageinfo'];
      if (title is! String || !title.startsWith('File:') || info is! List || info.isEmpty) continue;
      final url = (info.first as Map?)?['url'];
      if (url is! String) continue;
      final kind = wiktionaryKind(title.substring(5), want);
      if (kind == null) continue;
      final rank = _groupOrder[accent]!.indexOf(kind.group) * 2 + (kind.exact ? 0 : 1);
      if (rank < bestRank) {
        best = (url: url, label: _labelOf(kind.group));
        bestRank = rank;
      }
    }
    return best;
  }

  /// Which English recording a Commons file name is, if it is one of
  /// [want] (the term with spaces as hyphens): its accent group and whether
  /// it is the plain word (exact) or one sense of a homograph
  /// (`en-us-record-noun`).
  ///
  /// Groups: `uk` (en-uk, en-gb, en-rp), `us` (en-us, en-ame), `ca`,
  /// `commonwealth` (au, nz, ie, za, in, sc), `ll` (Lingua Libre English
  /// speakers, accent unknown), `en` (plain en-word).
  static ({String group, bool exact})? wiktionaryKind(String fileName, String want) {
    final lower = fileName.toLowerCase();
    final base = lower.replaceAll(RegExp(r'\.(ogg|oga|mp3|wav|flac|opus)$'), '');
    if (base == lower) return null; // not audio
    final n = base.replaceAll(RegExp(r'[\s_]+'), '-');

    if (n.startsWith('ll-q1860-(eng)-') && n.endsWith('-$want')) return (group: 'll', exact: true);
    if (n == 'en-$want') return (group: 'en', exact: true);
    final m = RegExp(r'^en-(us|ame|uk|gb|rp|ca|au|nz|ie|za|in|sc)-').firstMatch(n);
    if (m == null) return null;
    final rest = n.substring(m.end);
    final exact = rest == want;
    if (!exact && !rest.startsWith('$want-')) return null;
    final group = switch (m.group(1)) {
      'us' || 'ame' => 'us',
      'uk' || 'gb' || 'rp' => 'uk',
      'ca' => 'ca',
      _ => 'commonwealth',
    };
    return (group: group, exact: exact);
  }

  /// Preference order of accent groups for each accent.
  static const _groupOrder = {
    Accent.british: ['uk', 'commonwealth', 'll', 'en', 'ca', 'us'],
    Accent.american: ['us', 'ca', 'll', 'en', 'commonwealth', 'uk'],
  };

  static String _labelOf(String group) => switch (group) {
        'uk' => 'uk',
        'us' => 'us',
        _ => 'en',
      };

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
      ..userAgent = userAgentFor(uri)
      ..connectionTimeout = _timeout;
    try {
      final req = await client.getUrl(uri).timeout(_timeout);
      final res = await req.close().timeout(_timeout);
      final builder = BytesBuilder(copy: false);
      await res.forEach(builder.add).timeout(_timeout);
      // Refused (403 bot filter, 429 rate limit) or broken: the source is
      // unavailable, which is different from "no recording of this word".
      if (res.statusCode == 403 || res.statusCode == 429 || res.statusCode >= 500) throw const _Unreachable();
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

/// Which English pronunciation to prefer.
enum Accent {
  british('uk'),
  american('us');

  const Accent(this.label);

  /// Short tag used in file names ('uk' / 'us').
  final String label;
}

/// A saved recording: its media file name, and whether it is in the
/// accent that was asked for (false when only another accent existed).
class FetchedPronunciation {
  const FetchedPronunciation(this.fileName, {required this.preferredAccent});
  final String fileName;
  final bool preferredAccent;
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

