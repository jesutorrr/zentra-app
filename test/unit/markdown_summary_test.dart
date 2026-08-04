import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';

void main() {
  test('counts checklist progress', () {
    final document = MarkdownDocument.parse('- [x] a\n- [ ] b\n- [x] c');
    expect(document.checkItemCount, 3);
    expect(document.checkedCount, 2);
  });

  test('a checklist inside a code fence is not counted', () {
    final document = MarkdownDocument.parse('```\n- [x] a\n```');
    expect(document.checkItemCount, 0);
    expect(document.checkedCount, 0);
  });

  test('preview skips markers, dividers and empty blocks', () {
    expect(
      MarkdownDocument.parse('---\n\n## Examen\ntexto').previewText(),
      'Examen',
    );
    expect(
      MarkdownDocument.parse('\n\n- [ ] **leer** el capítulo').previewText(),
      'leer el capítulo',
    );
  });

  test('preview truncates without cutting mid word', () {
    final long = MarkdownDocument.parse('palabra ' * 40);
    final preview = long.previewText(maxLength: 20);
    expect(preview.length, lessThanOrEqualTo(21));
    expect(preview.endsWith('…'), isTrue);
  });

  test('preview keeps code spans and escaped markers literal', () {
    expect(
      MarkdownDocument.parse(r'usa `a * b` y \*no\* itálicas').previewText(),
      'usa a * b y *no* itálicas',
    );
  });

  test('an empty note has no preview and no plain text', () {
    final document = MarkdownDocument.parse('');
    expect(document.previewText(), '');
    expect(document.plainText(), '');
    expect(document.checkItemCount, 0);
  });

  test('a note made only of markers has no preview', () {
    expect(MarkdownDocument.parse('---\n___\n\n').previewText(), '');
    expect(MarkdownDocument.parse('- [ ] ').previewText(), '');
  });

  test('plain text drops markers across every block', () {
    expect(
      MarkdownDocument.parse('# T\n- **a**\n> _b_').plainText(),
      'T\na\nb',
    );
  });

  test('plain text folds a multi line code fence into one line', () {
    expect(
      MarkdownDocument.parse(
        '```dart\n  final a = 1;\n\n  print(a);\n```',
      ).plainText(),
      'final a = 1; print(a);',
    );
  });

  test('excerpt centers on the match', () {
    final excerpt = markdownExcerptAround(
      'inicio muy largo que no importa nada, aquí está mitosis y sigue el texto',
      'mitosis',
      radius: 10,
    );
    expect(excerpt.contains('mitosis'), isTrue);
    expect(excerpt.startsWith('…'), isTrue);
  });

  test('excerpt falls back to the start when there is no match', () {
    expect(markdownExcerptAround('hola', 'zzz'), 'hola');
  });
}
