// test/unit/markdown_inline_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_inline.dart';

String joined(List<MarkdownInlineSegment> segments) =>
    segments.map((segment) => segment.text).join();

void main() {
  test('segments always cover the whole input', () {
    for (final input in const [
      '',
      'texto simple',
      'a **b** c',
      '**sin cerrar',
      '_cursiva_ y `código` y ~~tachado~~',
      '[Zentra](https://zentra.app) al final',
      '****',
      'a * b * c',
    ]) {
      expect(joined(tokenizeInline(input)), input, reason: input);
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
}
