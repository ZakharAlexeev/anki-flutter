import '../data/db/database.dart';

/// Renders Anki-style question/answer templates: `{{FieldName}}`
/// substitution, `{{FrontSide}}` on the answer side, and conditional
/// sections `{{#Field}}...{{/Field}}` / `{{^Field}}...{{/Field}}`.
///
/// Not implemented: cloze (`{{cloze:Field}}`) and field modifiers
/// (`{{furigana:Field}}` etc.) - out of scope for the first version, plain
/// field substitution covers the common Basic-style note types.
class RenderedCard {
  final String questionHtml;
  final String answerHtml;

  const RenderedCard(this.questionHtml, this.answerHtml);
}

RenderedCard renderCard({
  required NotetypeTemplate template,
  required List<NotetypeField> fieldDefs,
  required List<String> fieldValues,
}) {
  final values = <String, String>{};
  for (final f in fieldDefs) {
    values[f.name] = f.ord < fieldValues.length ? fieldValues[f.ord] : '';
  }

  final question = _renderFormat(template.questionFormat, values);
  final answerValues = {...values, 'FrontSide': question};
  final answer = _renderFormat(template.answerFormat, answerValues);
  return RenderedCard(question, answer);
}

String _renderFormat(String format, Map<String, String> values) {
  final withConditionals = _resolveConditionals(format, values);
  return withConditionals.replaceAllMapped(RegExp(r'\{\{([^#^/}]+)\}\}'), (m) {
    final key = m.group(1)!.trim();
    return values[key] ?? '';
  });
}

String _resolveConditionals(String input, Map<String, String> values) {
  final pattern = RegExp(r'\{\{([#^])(\w+)\}\}([\s\S]*?)\{\{/\2\}\}');
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
