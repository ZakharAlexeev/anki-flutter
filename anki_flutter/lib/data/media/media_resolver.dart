import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Anki card fields reference media as bare filenames (`<img src="pic.jpg">`,
/// `[sound:clip.mp3]`), not URLs or asset paths - flutter_html has no idea
/// where "pic.jpg" lives, so left alone every image renders as a broken-image
/// icon and every `[sound:...]` marker shows up as literal bracket text.
///
/// This rewrites a rendered card's HTML right before display: local `<img>`
/// sources are inlined as base64 `data:` URIs read from this app's imported
/// media directory (the same one `apkg_importer.dart`/`apkg_exporter.dart`
/// read/write), which flutter_html already knows how to render out of the
/// box. `[sound:name]` isn't real HTML at all, so it becomes a small visible
/// "🔊 name" chip - not full playback (that needs an audio-player plugin
/// across every target platform, out of scope here), but at least honest
/// about there being an attachment instead of silently dropping it.
class MediaResolver {
  static final _imgSrc = RegExp('''(<img\\b[^>]*\\bsrc\\s*=\\s*["'])([^"']+)(["'])''', caseSensitive: false);
  static final _sound = RegExp(r'\[sound:([^\]]+)\]');
  static final _hasScheme = RegExp(r'^(https?|data|asset):');

  static const _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    // Not svg: flutter_html's base64-image matcher explicitly excludes
    // image/svg+xml (see ImageBuiltIn._matchesBase64Image upstream), so an
    // inlined SVG data URI would go unrendered rather than showing anything.
  };

  Future<String> resolve(String html) async {
    if (!html.contains('<img') && !html.contains('[sound:')) return html;

    final withAudioChips = html.replaceAllMapped(_sound, (m) {
      final name = m.group(1)!;
      return '<span title="$name">\u{1F50A} $name</span>';
    });

    final matches = _imgSrc.allMatches(withAudioChips).toList();
    if (matches.isEmpty) return withAudioChips;

    final appDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'media'));
    if (!await mediaDir.exists()) return withAudioChips;

    final buffer = StringBuffer();
    var last = 0;
    for (final m in matches) {
      buffer.write(withAudioChips.substring(last, m.start));
      final src = m.group(2)!;
      final dataUri = _hasScheme.hasMatch(src) ? null : await _asDataUri(mediaDir, src);
      buffer.write(dataUri == null ? m.group(0) : '${m.group(1)}$dataUri${m.group(3)}');
      last = m.end;
    }
    buffer.write(withAudioChips.substring(last));
    return buffer.toString();
  }

  Future<String?> _asDataUri(Directory mediaDir, String src) async {
    final ext = p.extension(src).replaceFirst('.', '').toLowerCase();
    final mime = _mimeByExtension[ext];
    if (mime == null) return null;
    final file = File(p.join(mediaDir.path, p.basename(src)));
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}
