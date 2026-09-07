import 'package:anki_flutter/data/db/database.dart';
import 'package:anki_flutter/domain/template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

NotetypeTemplate _template({required String qfmt, required String afmt}) => NotetypeTemplate(
      id: 1,
      notetypeId: 1,
      name: 'Card 1',
      ord: 0,
      questionFormat: qfmt,
      answerFormat: afmt,
    );

NotetypeField _field(int ord, String name) => NotetypeField(id: ord, notetypeId: 1, name: name, ord: ord);

void main() {
  group('field substitution', () {
    test('plain {{Field}} substitutes the field value', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{Front}}', afmt: '{{Back}}'),
        fieldDefs: [_field(0, 'Front'), _field(1, 'Back')],
        fieldValues: ['Question text', 'Answer text'],
      );
      expect(rendered.questionHtml, 'Question text');
      expect(rendered.answerHtml, 'Answer text');
    });

    test('unknown field name substitutes empty string', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{Nonexistent}}', afmt: ''),
        fieldDefs: [_field(0, 'Front')],
        fieldValues: ['x'],
      );
      expect(rendered.questionHtml, '');
    });
  });

  group('field modifiers', () {
    test('{{text:Field}} strips HTML rather than looking up a literal "text:Field" key', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{text:Front}}', afmt: ''),
        fieldDefs: [_field(0, 'Front')],
        fieldValues: ['<b>bold</b> word'],
      );
      expect(rendered.questionHtml, 'bold word');
    });

    test('{{hint:Field}} wraps a non-empty field in a <details> disclosure', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{hint:Extra}}', afmt: ''),
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: ['a clue'],
      );
      expect(rendered.questionHtml, contains('<details>'));
      expect(rendered.questionHtml, contains('a clue'));
    });

    test('{{hint:Field}} renders nothing for an empty field', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{hint:Extra}}', afmt: ''),
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: [''],
      );
      expect(rendered.questionHtml, '');
    });

    test('{{furigana:Field}} keeps the base text and drops the [reading]', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{furigana:Word}}', afmt: ''),
        fieldDefs: [_field(0, 'Word')],
        fieldValues: ['漢字[かんじ]'],
      );
      expect(rendered.questionHtml, '漢字');
    });

    test('{{kana:Field}} keeps just the [reading]', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{kana:Word}}', afmt: ''),
        fieldDefs: [_field(0, 'Word')],
        fieldValues: ['漢字[かんじ]'],
      );
      expect(rendered.questionHtml, 'かんじ');
    });
  });

  group('cloze cards', () {
    test('hides only the active deletion on the question and reveals it on the answer', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{cloze:Text}}', afmt: '{{cloze:Text}}'),
        fieldDefs: [_field(0, 'Text')],
        fieldValues: ['Paris is the {{c1::capital::city}} of {{c2::France}}.'],
      );
      expect(rendered.questionHtml, 'Paris is the <span class="cloze">[city]</span> of France.');
      expect(rendered.answerHtml, 'Paris is the <span class="cloze">capital</span> of France.');
    });

    test('card ordinal selects the corresponding cloze number', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{cloze:Text}}', afmt: '{{cloze:Text}}'),
        fieldDefs: [_field(0, 'Text')],
        fieldValues: ['{{c1::One}} and {{c2::Two}}'],
        cardOrd: 1,
      );
      expect(rendered.questionHtml, 'One and <span class="cloze">[…]</span>');
      expect(rendered.answerHtml, 'One and <span class="cloze">Two</span>');
      expect(clozeCardOrds(['{{c1::One}} and {{c2::Two}}']), {0, 1});
    });
  });

  group('special fields', () {
    test('{{Tags}}/{{Type}}/{{Deck}}/{{Card}} resolve to the values passed to renderCard', () {
      final rendered = renderCard(
        template: _template(qfmt: '{{Tags}}|{{Type}}|{{Deck}}|{{Card}}', afmt: ''),
        fieldDefs: const [],
        fieldValues: const [],
        tags: ' foo bar ',
        deckName: 'My Deck',
        notetypeName: 'Basic',
      );
      expect(rendered.questionHtml, 'foo bar|Basic|My Deck|Card 1');
    });
  });

  group('conditional sections', () {
    test('{{#Field}}...{{/Field}} shows its body only when the field is non-empty', () {
      final template = _template(qfmt: '{{#Extra}}shown{{/Extra}}', afmt: '');
      final withValue = renderCard(
        template: template,
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: ['present'],
      );
      final withoutValue = renderCard(
        template: template,
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: [''],
      );
      expect(withValue.questionHtml, 'shown');
      expect(withoutValue.questionHtml, '');
    });

    test('{{^Field}}...{{/Field}} shows its body only when the field is empty', () {
      final template = _template(qfmt: '{{^Extra}}shown{{/Extra}}', afmt: '');
      final withValue = renderCard(
        template: template,
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: ['present'],
      );
      final withoutValue = renderCard(
        template: template,
        fieldDefs: [_field(0, 'Extra')],
        fieldValues: [''],
      );
      expect(withValue.questionHtml, '');
      expect(withoutValue.questionHtml, 'shown');
    });

    test('conditional sections work for field names with spaces and non-Latin scripts', () {
      final template = _template(qfmt: '{{#Front Extra}}A{{/Front Extra}}{{#Пример}}B{{/Пример}}', afmt: '');
      final rendered = renderCard(
        template: template,
        fieldDefs: [_field(0, 'Front Extra'), _field(1, 'Пример')],
        fieldValues: ['x', 'y'],
      );
      expect(rendered.questionHtml, 'AB');
    });
  });

  group('isQuestionEmpty', () {
    test('true when the question renders to nothing once tags are stripped', () {
      final empty = isQuestionEmpty(
        template: _template(qfmt: '{{Back}}', afmt: ''),
        fieldDefs: [_field(0, 'Front'), _field(1, 'Back')],
        fieldValues: ['Front text', ''],
      );
      expect(empty, isTrue);
    });

    test('false when the question renders real content', () {
      final empty = isQuestionEmpty(
        template: _template(qfmt: '{{Front}}', afmt: ''),
        fieldDefs: [_field(0, 'Front'), _field(1, 'Back')],
        fieldValues: ['Front text', ''],
      );
      expect(empty, isFalse);
    });
  });
}
