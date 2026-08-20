import '../data/db/database.dart';

/// Renders Anki-style question/answer templates: `{{FieldName}}`
/// substitution, `{{FrontSide}}` on the answer side, conditional sections
/// `{{#Field}}...{{/Field}}` / `{{^Field}}...{{/Field}}`, the common field
/// modifiers (`{{text:Field}}`, `{{furigana:Field}}`, `{{hint:Field}}`), and
/// the special fields `{{Tags}}`/`{{Type}}`/`{{Deck}}`/`{{Card}}`.
///
/// Not implemented: cloze (`{{cloze:Field}}`) - out of scope for this
/// version, plain field substitution covers ordinary (non-cloze) note types.
class RenderedCard {
  final String questionHtml;
  final String answerHtml;
  final String css;

  const RenderedCard(this.questionHtml, this.answerHtml, this.css);
}

RenderedCard renderCard({
  required NotetypeTemplate template,
  required List<NotetypeField> fieldDefs,
  required List<String> fieldValues,
  String css = '',
  String tags = '',
  String deckName = '',
  String notetypeName = '',
}) {
  final values = <String, String>{};
  for (final f in fieldDefs) {
    values[f.name] = f.ord < fieldValues.length ? fieldValues[f.ord] : '';
  }
  // Anki's special fields, available in every template regardless of note type.
  values['Tags'] = tags.trim();
  values['Type'] = notetypeName;
  values['Deck'] = deckName;
  values['Card'] = template.name;

  final question = _renderFormat(template.questionFormat, values);
  final answerValues = {...values, 'FrontSide': question};
  final answer = _renderFormat(template.answerFormat, answerValues);
  return RenderedCard(question, answer, css);
}

/// True if [template]'s question side would render to nothing (once tags
/// are stripped) for these field values - Anki doesn't generate a card in
/// that case (e.g. the reverse side of "Basic and reversed" when Back is
/// left empty), so callers should skip creating the card too rather than
/// leaving a blank "(пусто)" entry in the review queue.
bool isQuestionEmpty({
  required NotetypeTemplate template,
  required List<NotetypeField> fieldDefs,
  required List<String> fieldValues,
}) {
  final rendered = renderCard(template: template, fieldDefs: fieldDefs, fieldValues: fieldValues);
  final stripped = rendered.questionHtml.replaceAll(RegExp('<[^>]*>'), '').trim();
  return stripped.isEmpty;
}

String _renderFormat(String format, Map<String, String> values) {
  final withConditionals = _resolveConditionals(format, values);
  return withConditionals.replaceAllMapped(RegExp(r'\{\{([^#^/}]+)\}\}'), (m) {
    final raw = m.group(1)!.trim();
    return _resolveField(raw, values);
  });
}

/// Resolves one `{{...}}` placeholder's inner text, handling the field
/// modifier prefixes Anki supports (`{{text:Field}}`, `{{furigana:Field}}`,
/// `{{kanji:Field}}`, `{{kana:Field}}`, `{{hint:Field}}`). The prefix is
/// separated from the field name by the *last* colon, since field names
/// themselves may legitimately contain one.
String _resolveField(String raw, Map<String, String> values) {
  final colon = raw.lastIndexOf(':');
  if (colon == -1) return values[raw] ?? '';

  final modifier = raw.substring(0, colon);
  final fieldName = raw.substring(colon + 1);
  final value = values[fieldName] ?? '';

  switch (modifier) {
    case 'text':
      // Plain text: strip HTML formatting, same as Anki's {{text:}}.
      return value.replaceAll(RegExp('<[^>]*>'), '');
    case 'furigana':
      return _rubyText(value, keepReading: false);
    case 'kana':
    case 'kanji':
      return _rubyText(value, keepReading: true);
    case 'hint':
      if (value.trim().isEmpty) return '';
      return '<details><summary>Показать подсказку</summary>$value</details>';
    default:
      // Unknown/unsupported modifier (or the field name itself just
      // contains a colon): fall back to the field the last segment names,
      // which is still correct far more often than rendering nothing.
      return values[fieldName] ?? values[raw] ?? '';
  }
}

/// Anki's furigana syntax writes readings inline as `base[reading]` (e.g.
/// `漢字[かんじ]`). With [keepReading] false this returns just the base text
/// (the `{{furigana:}}` modifier); true returns just the reading (`{{kana:}}`
/// / `{{kanji:}}`).
String _rubyText(String value, {required bool keepReading}) {
  final pattern = RegExp(r'([^\s\[\]]+)\[([^\]]+)\]');
  return value.replaceAllMapped(pattern, (m) => keepReading ? m.group(2)! : m.group(1)!);
}

String _resolveConditionals(String input, Map<String, String> values) {
  // The field name is "anything up to the closing }}", not just \w+ - Anki
  // field names can contain spaces, punctuation, or non-Latin scripts (e.g.
  // `{{#Пример}}`, `{{#Front Extra}}`), and \w+ silently failed to match any
  // of those, leaving the conditional markup un-rendered instead of hiding
  // or showing the section.
  final pattern = RegExp(r'\{\{([#^])([^}]+)\}\}([\s\S]*?)\{\{/\2\}\}');
  var result = input;
  String previous;
  do {
    previous = result;
    result = result.replaceAllMapped(pattern, (m) {
      final negate = m.group(1) == '^';
      final field = m.group(2)!;
      final body = m.group(3)!;
      final hasValue = (values[field] ?? '').trim().isNotEmpty;
      final show = negate ? !hasValue : hasValue;
      return show ? body : '';
    });
  } while (result != previous);
  return result;
}
