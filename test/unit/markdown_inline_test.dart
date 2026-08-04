// test/unit/markdown_inline_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_inline.dart';

String joined(List<MarkdownInlineSegment> segments) =>
    segments.map((segment) => segment.text).join();

const _corpus = <String>[
  '',
  'texto simple',
  'a **b** c',
  '**sin cerrar',
  '_cursiva_ y `código` y ~~tachado~~',
  '[Zentra](https://zentra.app) al final',
  '****',
  'a * b * c',
  '`a*b*c`',
  '`**negritas dentro de código**`',
  r'Escapar con \*asterisco\* literal',
  'reporte_final_v2.md',
  'Comprar 2 * 3 * 4 unidades',
  'Nota_ importante, ver [doc](https://ej.com/guia_final)',
  '[la guía **oficial**](https://ej.com)',
  '[]()',
  '[a](b(c))',
  '**a _b_**',
  '__negritas__ y _cursiva_',
  '*',
  '_',
  '``',
  '[[[[[[',
  'emoji 👩‍👩‍👧‍👦 y acento café\u0301',
  '*a `b* c` d*',
  '**a *b** c*',
];

/// Every consumer of the tokenizer maps offsets back onto the live text field,
/// so the offsets matter as much as the styling.
void expectTotalCoverage(String input) {
  final segments = tokenizeInline(input);
  expect(joined(segments), input, reason: 'coverage for "$input"');

  var cursor = 0;
  for (final segment in segments) {
    expect(segment.start, cursor, reason: 'gap or overlap in "$input"');
    expect(segment.end - segment.start, segment.text.length,
        reason: 'length mismatch in "$input"');
    expect(input.substring(segment.start, segment.end), segment.text,
        reason: 'offsets do not point at the text in "$input"');
    cursor = segment.end;
  }
  expect(cursor, input.length, reason: 'tail left uncovered in "$input"');
}

void main() {
  test('segments always cover the whole input with exact offsets', () {
    for (final input in _corpus) {
      expectTotalCoverage(input);
    }
  });

  test('coverage survives generated marker soup', () {
    const alphabet = r'*_`~[]()\ a1';
    final random = Random(20260803);
    for (var i = 0; i < 3000; i++) {
      final length = random.nextInt(17);
      final buffer = StringBuffer();
      for (var j = 0; j < length; j++) {
        buffer.write(alphabet[random.nextInt(alphabet.length)]);
      }
      expectTotalCoverage(buffer.toString());
    }
  });

  test('marks bold markers separately from bold content', () {
    final segments = tokenizeInline('a **b** c');
    expect(segments.map((s) => s.text).toList(), ['a ', '**', 'b', '**', ' c']);
    expect(segments[1].isMarker, isTrue);
    expect(segments[2].isMarker, isFalse);
    expect(segments[2].styles, {MarkdownInlineStyle.bold});
    expect(segments[2].start, 4);
    expect(segments[2].end, 5);
  });

  test('an unclosed marker stays plain content', () {
    final segments = tokenizeInline('**sin cerrar');
    expect(segments.single.isMarker, isFalse);
    expect(segments.single.styles, isEmpty);
  });

  test('nests italic inside bold', () {
    final segments = tokenizeInline('**a _b_**');
    final content = segments.where((s) => !s.isMarker).toList();
    expect(
      content.last.styles,
      {MarkdownInlineStyle.bold, MarkdownInlineStyle.italic},
    );
  });

  test('captures the link target on the label segment', () {
    final segments = tokenizeInline('[Zentra](https://zentra.app)');
    final label = segments.firstWhere((s) => s.text == 'Zentra');
    expect(label.styles, {MarkdownInlineStyle.link});
    expect(label.href, 'https://zentra.app');
  });

  test('code content is literal, so its asterisks are not markers', () {
    final segments = tokenizeInline('`a*b*c`');
    expect(segments.map((s) => s.text).toList(), ['`', 'a*b*c', '`']);
    expect(segments[1].isMarker, isFalse);
    expect(segments[1].styles, {MarkdownInlineStyle.code});
  });

  test('a marker inside a code span cannot close an outer run', () {
    final segments = tokenizeInline('*a `b* c` d*');
    final markers = segments.where((s) => s.isMarker).toList();
    expect(markers.map((s) => s.start).toList(), [0, 3, 8, 11]);
    expect(segments.last.text, '*');
    expect(segments.last.end, 12);
  });

  test('underscores inside a word do not start italics', () {
    final segments = tokenizeInline('reporte_final_v2.md');
    expect(segments.single.text, 'reporte_final_v2.md');
    expect(segments.single.styles, isEmpty);
  });

  test('an asterisk surrounded by spaces is arithmetic, not emphasis', () {
    final segments = tokenizeInline('Comprar 2 * 3 * 4 unidades');
    expect(segments.single.isMarker, isFalse);
    expect(segments.single.styles, isEmpty);
  });

  test('a closer swallowed by a link never opens a run', () {
    final input = 'Nota_ importante, ver [doc](https://ej.com/guia_final)';
    final segments = tokenizeInline(input);
    expect(
      segments.where((s) => s.styles.contains(MarkdownInlineStyle.italic)),
      isEmpty,
    );
  });

  test('a backslash escape is a hidden marker and neutralizes the symbol', () {
    final segments = tokenizeInline(r'\*literal\*');
    expect(segments.map((s) => s.text).toList(), [r'\', '*literal', r'\', '*']);
    expect(segments[0].isMarker, isTrue);
    expect(segments[1].isMarker, isFalse);
    expect(segments[1].styles, isEmpty);
  });

  test('a link label is tokenized so its markers can be dimmed too', () {
    final segments = tokenizeInline('[la guía **oficial**](https://ej.com)');
    final bold = segments.firstWhere((s) => s.text == 'oficial');
    expect(bold.styles, {MarkdownInlineStyle.link, MarkdownInlineStyle.bold});
    expect(bold.href, 'https://ej.com');
    expect(
      segments.where((s) => s.text == '**').every((s) => s.isMarker),
      isTrue,
    );
  });

  test('an empty link label produces no zero length segment', () {
    final segments = tokenizeInline('[]()');
    expect(segments.every((s) => s.end > s.start), isTrue);
    expect(joined(segments), '[]()');
  });
}
