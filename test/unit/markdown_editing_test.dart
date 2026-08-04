// test/unit/markdown_editing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';

void main() {
  test('enter splits a paragraph at the caret', () {
    final edit = splitBlock(
      MarkdownDocument.parse('hola mundo'),
      const DocumentCaret(blockIndex: 0, offset: 4),
    );
    expect(edit.document.serialize(), 'hola\n mundo');
    expect(edit.caret, const DocumentCaret(blockIndex: 1, offset: 0));
  });

  test('enter continues a bullet list with the same marker', () {
    final edit = splitBlock(
      MarkdownDocument.parse('- leer'),
      const DocumentCaret(blockIndex: 0, offset: 6),
    );
    expect(edit.document.serialize(), '- leer\n- ');
    expect(edit.caret, const DocumentCaret(blockIndex: 1, offset: 2));
  });

  test('enter continues a checklist unchecked', () {
    final edit = splitBlock(
      MarkdownDocument.parse('- [x] listo'),
      const DocumentCaret(blockIndex: 0, offset: 11),
    );
    expect(edit.document.serialize(), '- [x] listo\n- [ ] ');
  });

  test('enter on an empty list item leaves the list', () {
    final edit = splitBlock(
      MarkdownDocument.parse('- leer\n- '),
      const DocumentCaret(blockIndex: 1, offset: 2),
    );
    expect(edit.document.serialize(), '- leer\n');
    expect(edit.caret, const DocumentCaret(blockIndex: 1, offset: 0));
  });

  test('enter before the marker does not duplicate it', () {
    final edit = splitBlock(
      MarkdownDocument.parse('  - leer'),
      const DocumentCaret(blockIndex: 0, offset: 0),
    );
    expect(edit.document.serialize(), '\n  - leer');
    expect(edit.caret, const DocumentCaret(blockIndex: 1, offset: 0));
  });

  test('enter inside a code fence leaves the fence untouched', () {
    const source = '```dart\ncodigo\n```';
    final edit = splitBlock(
      MarkdownDocument.parse(source),
      const DocumentCaret(blockIndex: 0, offset: 4),
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 4));
  });

  test('backspace at the start merges with the previous block', () {
    final edit = mergeWithPrevious(
      MarkdownDocument.parse('## Título\ncuerpo'),
      const DocumentCaret(blockIndex: 1, offset: 0),
    );
    expect(edit.document.serialize(), '## Títulocuerpo');
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 9));
  });

  test('backspace on the first block does nothing', () {
    final document = MarkdownDocument.parse('solo');
    final edit = mergeWithPrevious(
      document,
      const DocumentCaret(blockIndex: 0, offset: 0),
    );
    expect(edit.document.serialize(), 'solo');
  });

  test('backspace never merges a code fence away', () {
    const source = '```dart\ncodigo\n```\ntexto';
    final edit = mergeWithPrevious(
      MarkdownDocument.parse(source),
      const DocumentCaret(blockIndex: 1, offset: 0),
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 1, offset: 0));
  });

  test('indent moves in steps of two spaces up to three levels', () {
    var document = MarkdownDocument.parse('- a');
    for (var expected in const ['  - a', '    - a', '      - a', '      - a']) {
      document = changeIndent(
        document,
        const DocumentCaret(blockIndex: 0, offset: 0),
        increase: true,
      ).document;
      expect(document.serialize(), expected);
    }
    document = changeIndent(
      document,
      const DocumentCaret(blockIndex: 0, offset: 0),
      increase: false,
    ).document;
    expect(document.serialize(), '    - a');
  });

  test('indent leaves unsupported lines and the caret alone', () {
    const source = '| tabla |';
    final edit = changeIndent(
      MarkdownDocument.parse(source),
      const DocumentCaret(blockIndex: 0, offset: 3),
      increase: true,
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 3));
  });
}
