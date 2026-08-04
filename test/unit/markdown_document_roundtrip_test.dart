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
];

void main() {
  for (final source in _corpus) {
    test('serialize(parse(x)) == x for ${source.hashCode}', () {
      expect(MarkdownDocument.parse(source).serialize(), source);
    });

    test('parse is idempotent for ${source.hashCode}', () {
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
    expect(
      document
          .replaceBlock(0, document.blocks.first.toggleChecked())
          .replaceBlock(0, MarkdownDocument.parse('- [ ] listo').blocks.first)
          .serialize(),
      '- [ ] listo',
    );
  });

  test('block list operations keep the document immutable', () {
    final document = MarkdownDocument.parse('a\nb');
    expect(document.insertBlock(1, const MarkdownBlock.paragraph('x'))
        .serialize(), 'a\nx\nb');
    expect(document.removeBlock(0).serialize(), 'b');
    expect(document.serialize(), 'a\nb');
  });
}
