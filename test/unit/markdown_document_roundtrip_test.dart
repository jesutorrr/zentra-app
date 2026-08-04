import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';

const _corpus = <String>[
  '',
  'Una sola línea',
  'Con salto final\n',
  '## Examen de biología\n\nRepasar **mitosis** y _meiosis_.\n',
  '- [ ] leer\n- [x] resumir\n- [ ] repasar',
  '*   asterisco con espacios\n1) numerada con paréntesis',
  '  - anidada uno\n    - anidada dos\n      - anidada tres',
  '> cita\n>\n> segunda línea',
  '```dart\nvar a = 1;\nif (a > 0) {}\n```\ntexto después',
  '```\nfence sin cerrar',
  '| tabla | fuera |\n|---|---|\n| de | alcance |',
  '#### encabezado nivel cuatro\n<div>html</div>\n![img](x.png)',
  '---\n***\n___',
  'Texto con # numeral a media línea y - guion suelto',
  '- espacios al final   \n## encabezado con cola  \n',
  '````dart\nvar a = 1;\n  ````   \ndespués',
  '```\n```\n```\ntres cercas seguidas',
  '- [ ] uno\r\n- [x] dos\r\n## crlf\r\n',
  '\t- viñeta con tabulador\n\t\t1. numerada anidada',
  '\n',
  '\n\n\n',
  '   \n\t\t\n  \t  ',
  'a\rb',
  '- 🇲🇽 bandera\n- 👩‍👩‍👧‍👦 familia\n- café\u0301 combinante\n- مرحبا',
  '```\ncode\n`````',
  '   ```\ncode\n   ```',
  '- [ ]\n- [x]',
];

void main() {
  for (var i = 0; i < _corpus.length; i++) {
    final source = _corpus[i];

    test('serialize(parse(x)) == x for corpus[$i]', () {
      expect(MarkdownDocument.parse(source).serialize(), source);
    });

    test('parse is idempotent for corpus[$i]', () {
      final once = MarkdownDocument.parse(source);
      final twice = MarkdownDocument.parse(once.serialize());
      expect(twice.blocks, once.blocks);
    });
  }

  test('toggling a checkbox is the only rewrite of the source', () {
    final document = MarkdownDocument.parse('- [ ]  pendiente');
    final toggled = document.replaceBlock(
      0,
      document.blocks.first.toggleChecked(),
    );
    expect(toggled.serialize(), '- [x]  pendiente');
    expect(
      MarkdownDocument.parse(toggled.serialize())
          .replaceBlock(0, toggled.blocks.first.toggleChecked())
          .serialize(),
      '- [ ]  pendiente',
    );
  });

  test('uppercase X is the single permitted normalization', () {
    final document = MarkdownDocument.parse('- [X] listo');
    expect(document.blocks.first.checked, isTrue);

    final unchecked = document.replaceBlock(
      0,
      document.blocks.first.toggleChecked(),
    );
    expect(unchecked.serialize(), '- [ ] listo');

    // Re-checking lands on lowercase x: the one rewrite the system allows.
    expect(
      unchecked
          .replaceBlock(0, unchecked.blocks.first.toggleChecked())
          .serialize(),
      '- [x] listo',
    );

    // An untouched document keeps its uppercase X.
    const source = '## Título  \n- [X] listo\n\ttab\n```\ncode\n```';
    expect(MarkdownDocument.parse(source).serialize(), source);
  });

  test('a check item without a box in its prefix refuses to toggle', () {
    const orphan = MarkdownBlock(
      type: MarkdownBlockType.checkItem,
      prefix: '- ',
      text: 'sin corchete',
    );
    expect(orphan.toggleChecked(), orphan);
  });

  test('copyWith can reopen a fence by clearing its closing line', () {
    final fence = MarkdownDocument.parse('```\ncode\n```').blocks.single;
    expect(fence.fenceClosed, isTrue);
    expect(fence.copyWith(fenceClose: null).fenceClosed, isFalse);
    expect(fence.copyWith(text: 'irrelevante').fenceClose, '```');
  });

  test('block list operations keep the document immutable', () {
    final document = MarkdownDocument.parse('a\nb');
    final results = [
      document.replaceBlock(0, const MarkdownBlock.paragraph('z')),
      document.insertBlock(1, const MarkdownBlock.paragraph('x')),
      document.removeBlock(0),
    ];

    expect(
      results.map((next) => next.serialize()).toList(),
      ['z\nb', 'a\nx\nb', 'b'],
    );
    expect(document.serialize(), 'a\nb');

    for (final next in results) {
      expect(
        () => next.blocks.add(const MarkdownBlock.paragraph()),
        throwsUnsupportedError,
      );
    }
  });

  test('removing an out of range block throws instead of silently resetting',
      () {
    expect(
      () => MarkdownDocument.parse('sola').removeBlock(99),
      throwsRangeError,
    );
  });
}
