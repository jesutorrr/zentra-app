// test/unit/markdown_document_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';

void main() {
  test('parses every supported block type', () {
    final document = MarkdownDocument.parse(
      '## Examen\n'
      'Repasar con calma.\n'
      '- viñeta\n'
      '1. numerada\n'
      '- [ ] pendiente\n'
      '- [x] listo\n'
      '> cita\n'
      '---',
    );

    expect(
      document.blocks.map((block) => block.type).toList(),
      const [
        MarkdownBlockType.heading,
        MarkdownBlockType.paragraph,
        MarkdownBlockType.bulletItem,
        MarkdownBlockType.numberedItem,
        MarkdownBlockType.checkItem,
        MarkdownBlockType.checkItem,
        MarkdownBlockType.quote,
        MarkdownBlockType.divider,
      ],
    );
    expect(document.blocks.first.headingLevel, 2);
    expect(document.blocks.first.text, 'Examen');
    expect(document.blocks[4].checked, isFalse);
    expect(document.blocks[5].checked, isTrue);
  });

  test('keeps the literal source prefix instead of normalizing it', () {
    final document = MarkdownDocument.parse('*   viñeta con asterisco');
    expect(document.blocks.single.prefix, '*   ');
    expect(document.blocks.single.text, 'viñeta con asterisco');
  });

  test('stores unsupported syntax as raw without touching it', () {
    final document = MarkdownDocument.parse(
      '| a | b |\n'
      '#### encabezado fuera de alcance\n'
      '![img](x.png)',
    );
    expect(
      document.blocks.map((block) => block.type).toList(),
      const [
        MarkdownBlockType.raw,
        MarkdownBlockType.raw,
        MarkdownBlockType.raw,
      ],
    );
    expect(document.blocks.first.text, '| a | b |');
  });

  test('parses a closed and an unterminated code fence', () {
    final closed = MarkdownDocument.parse('```dart\nvar a = 1;\n```');
    expect(closed.blocks.single.type, MarkdownBlockType.codeFence);
    expect(closed.blocks.single.language, 'dart');
    expect(closed.blocks.single.codeLines, ['var a = 1;']);
    expect(closed.blocks.single.fenceClosed, isTrue);

    final open = MarkdownDocument.parse('```\nsin cerrar');
    expect(open.blocks.single.fenceClosed, isFalse);
    expect(open.blocks.single.codeLines, ['sin cerrar']);
  });

  test('keeps the closing fence line verbatim', () {
    final document = MarkdownDocument.parse('````dart\nvar a = 1;\n  ````   ');
    expect(document.blocks.single.fenceClose, '  ````   ');
  });

  test('keeps carriage returns inside the line instead of dropping them', () {
    final document = MarkdownDocument.parse('- uno\r\n- dos\r\n');
    expect(document.blocks.first.type, MarkdownBlockType.bulletItem);
    expect(document.blocks.first.text, 'uno\r');
    expect(document.blocks[1].text, 'dos\r');
  });

  test('an empty note still has one editable block', () {
    expect(MarkdownDocument.parse('').blocks.single.type,
        MarkdownBlockType.paragraph);
  });

  test('computes indent level with a ceiling of three', () {
    expect(MarkdownDocument.parse('- a').blocks.single.indentLevel, 0);
    expect(MarkdownDocument.parse('  - a').blocks.single.indentLevel, 1);
    expect(MarkdownDocument.parse('\t- a').blocks.single.indentLevel, 1);
    expect(
        MarkdownDocument.parse('            - a').blocks.single.indentLevel, 3);
  });
}
