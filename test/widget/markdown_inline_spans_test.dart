// test/widget/markdown_inline_spans_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_inline.dart';
import 'package:zentra/presentation/widgets/markdown_inline_spans.dart';

String flatten(List<InlineSpan> spans) =>
    spans.map((span) => (span as TextSpan).text ?? '').join();

/// Inputs that exercise every branch of the tokenizer: escapes, literal code
/// spans, links with tokenized labels and unbalanced delimiters.
const _corpus = <String>[
  '',
  'texto simple',
  'a **b** c',
  '**sin cerrar',
  '_cursiva_ y `código` y ~~tachado~~',
  '[Zentra](https://zentra.app) al final',
  '****',
  '`**negritas dentro de código**`',
  r'Escapar con \*asterisco\* literal',
  'reporte_final_v2.md',
  '[la guía **oficial**](https://ej.com)',
  '[]()',
  '**a _b_**',
  'emoji 👩‍👩‍👧‍👦 y acento café\u0301',
  '*a `b* c` d*',
];

void main() {
  const base = TextStyle(fontSize: 16);
  const markerColor = Color(0xFF999999);

  List<InlineSpan> build(String text, {required bool showMarkers}) =>
      buildMarkdownSpans(
        text: text,
        baseStyle: base,
        markerColor: markerColor,
        showMarkers: showMarkers,
      );

  test('showing markers keeps the source text intact', () {
    expect(flatten(build('a **b** c', showMarkers: true)), 'a **b** c');
  });

  test('hiding markers removes only the marker characters', () {
    expect(flatten(build('a **b** c', showMarkers: false)), 'a b c');
  });

  test('content keeps the same weight in both modes', () {
    TextStyle styleOf(bool showMarkers) {
      return build('**b**', showMarkers: showMarkers)
          .cast<TextSpan>()
          .firstWhere((span) => span.text == 'b')
          .style!;
    }

    expect(styleOf(true).fontWeight, FontWeight.w700);
    expect(styleOf(false).fontWeight, FontWeight.w700);
    expect(styleOf(true).fontSize, styleOf(false).fontSize);
  });

  test('markers are dimmed rather than removed when shown', () {
    final marker = build('**b**', showMarkers: true)
        .cast<TextSpan>()
        .firstWhere((span) => span.text == '**');
    expect(marker.style!.color, markerColor);
  });

  // The editing block feeds these spans straight to a TextField, so any drift
  // between the spans and the controller text would move the caret.
  test('showing markers rebuilds the input character for character', () {
    for (final input in _corpus) {
      expect(
        flatten(build(input, showMarkers: true)),
        input,
        reason: 'span text drifted for "$input"',
      );
    }
  });

  test('hiding markers drops exactly the marker segments', () {
    for (final input in _corpus) {
      final expected = tokenizeInline(input)
          .where((segment) => !segment.isMarker)
          .map((segment) => segment.text)
          .join();
      expect(
        flatten(build(input, showMarkers: false)),
        expected,
        reason: 'hidden text drifted for "$input"',
      );
    }
  });

  test('a line made only of markers still yields one span', () {
    for (final input in _corpus) {
      expect(build(input, showMarkers: false), isNotEmpty, reason: input);
      expect(build(input, showMarkers: true), isNotEmpty, reason: input);
    }
  });

  test('an escaped marker survives as literal content in both modes', () {
    expect(flatten(build(r'\*literal\*', showMarkers: true)), r'\*literal\*');
    expect(flatten(build(r'\*literal\*', showMarkers: false)), '*literal*');
    final content = build(r'\*literal\*', showMarkers: false)
        .cast<TextSpan>()
        .firstWhere((span) => span.text == '*');
    expect(content.style!.fontStyle, isNot(FontStyle.italic));
  });

  test('code spans render in a monospace family', () {
    final code = build('usa `flutter test` hoy', showMarkers: false)
        .cast<TextSpan>()
        .firstWhere((span) => span.text == 'flutter test');
    expect(
      [code.style!.fontFamily, ...?code.style!.fontFamilyFallback],
      contains('monospace'),
    );
  });

  test('a struck through link keeps both decorations', () {
    final label = build('~~[ver](https://ej.com)~~', showMarkers: false)
        .cast<TextSpan>()
        .firstWhere((span) => span.text == 'ver');
    final decoration = label.style!.decoration!;
    expect(decoration.contains(TextDecoration.underline), isTrue);
    expect(decoration.contains(TextDecoration.lineThrough), isTrue);
  });
}
