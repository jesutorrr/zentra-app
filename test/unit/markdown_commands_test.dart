// test/unit/markdown_commands_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/domain/markdown_inline.dart';

const _caret = DocumentCaret(blockIndex: 0, offset: 0);

String cycle(String source, NoteBlockCommand command) =>
    applyBlockCommand(MarkdownDocument.parse(source), _caret, command)
        .document
        .serialize();

Set<MarkdownInlineStyle> stylesOf(MarkdownBlock block) => tokenizeInline(
      block.text,
    )
        .where((segment) => !segment.isMarker)
        .expand((segment) => segment.styles)
        .toSet();

void main() {
  test('heading cycles paragraph, h1, h2, h3 and back', () {
    expect(cycle('texto', NoteBlockCommand.heading), '# texto');
    expect(cycle('# texto', NoteBlockCommand.heading), '## texto');
    expect(cycle('## texto', NoteBlockCommand.heading), '### texto');
    expect(cycle('### texto', NoteBlockCommand.heading), 'texto');
  });

  test('a command applied twice returns to paragraph', () {
    expect(cycle('texto', NoteBlockCommand.bullet), '- texto');
    expect(cycle('- texto', NoteBlockCommand.bullet), 'texto');
    expect(cycle('texto', NoteBlockCommand.checklist), '- [ ] texto');
    expect(cycle('- [ ] texto', NoteBlockCommand.checklist), 'texto');
    expect(cycle('texto', NoteBlockCommand.quote), '> texto');
    expect(cycle('> texto', NoteBlockCommand.quote), 'texto');
  });

  test('switching between list kinds keeps the content once', () {
    expect(cycle('- texto', NoteBlockCommand.checklist), '- [ ] texto');
    expect(cycle('- [ ] texto', NoteBlockCommand.numbered), '1. texto');
  });

  test('commands never insert at the caret position', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('Examen de bio'),
      const DocumentCaret(blockIndex: 0, offset: 7),
      NoteBlockCommand.heading,
    );
    expect(edit.document.serialize(), '# Examen de bio');
    expect(edit.caret.offset, 9);
  });

  test('divider inserts a new block below and keeps the caret there', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('texto'),
      _caret,
      NoteBlockCommand.divider,
    );
    expect(edit.document.serialize(), 'texto\n---\n');
    expect(edit.caret, const DocumentCaret(blockIndex: 2, offset: 0));
  });

  test('the code command closes the fence it opens', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('# Título\nsigue'),
      _caret,
      NoteBlockCommand.code,
    );
    final source = edit.document.serialize();
    expect(source, '```\n# Título\n```\nsigue');
    // Without a closing marker the fence would swallow every block below it
    // the next time the note is parsed.
    expect(MarkdownDocument.parse(source).blocks.length, 2);
    expect(edit.caret.blockIndex, 0);
  });

  test('the code command applied twice restores the source line', () {
    expect(cycle('# Título', NoteBlockCommand.code), '```\n# Título\n```');
    expect(cycle('```\n# Título\n```', NoteBlockCommand.code), '# Título');
  });

  test('block commands leave a code fence and its contents alone', () {
    const source = '```dart\ncodigo\n```';
    final edit = applyBlockCommand(
      MarkdownDocument.parse(source),
      const DocumentCaret(blockIndex: 0, offset: 4),
      NoteBlockCommand.bullet,
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 4));
  });

  test('block commands leave unsupported lines alone', () {
    const source = '| tabla |';
    final edit = applyBlockCommand(
      MarkdownDocument.parse(source),
      const DocumentCaret(blockIndex: 0, offset: 3),
      NoteBlockCommand.heading,
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 3));
  });

  test('the caret stays inside the block when the marker leaves', () {
    final inside = applyBlockCommand(
      MarkdownDocument.parse('- [ ] tarea'),
      const DocumentCaret(blockIndex: 0, offset: 2),
      NoteBlockCommand.checklist,
    );
    expect(inside.document.serialize(), 'tarea');
    expect(inside.caret.offset, 0);

    final beyond = applyBlockCommand(
      MarkdownDocument.parse('- [ ] tarea'),
      const DocumentCaret(blockIndex: 0, offset: 99),
      NoteBlockCommand.checklist,
    );
    expect(beyond.caret.offset, 'tarea'.length);
  });

  test('wrapping a selection adds and removes the marker', () {
    final bolded = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      5,
      10,
      MarkdownInlineStyle.bold,
    );
    expect(bolded.document.serialize(), 'hola **mundo**');
    expect(
      wrapSelection(bolded.document, 0, 7, 12, MarkdownInlineStyle.bold)
          .document
          .serialize(),
      'hola mundo',
    );
  });

  test('wrapping a selection that already holds the markers removes them', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('hola **mundo**'),
      0,
      5,
      14,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), 'hola mundo');
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 10));
  });

  test('an empty selection leaves the document untouched', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('hola'),
      0,
      2,
      2,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), 'hola');
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 2));
  });

  test('the selection is clamped to the text the block owns', () {
    final wide = wrapSelection(
      MarkdownDocument.parse('hola'),
      0,
      -3,
      99,
      MarkdownInlineStyle.bold,
    );
    expect(wide.document.serialize(), '**hola**');
    // The caret trails the wrapped content, not the closing marker.
    expect(wide.caret, const DocumentCaret(blockIndex: 0, offset: 6));

    // Swallowing the `# ` would demote the heading to a paragraph.
    final heading = wrapSelection(
      MarkdownDocument.parse('# Título'),
      0,
      0,
      8,
      MarkdownInlineStyle.bold,
    );
    expect(heading.document.serialize(), '# **Título**');
    expect(heading.document.blocks.first.type, MarkdownBlockType.heading);
  });

  test('wrapping in italics reads back as italics inside a word', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('holamundo'),
      0,
      4,
      9,
      MarkdownInlineStyle.italic,
    );
    expect(
      stylesOf(edit.document.blocks.first),
      contains(MarkdownInlineStyle.italic),
    );
  });

  test('wrapping leaves a code fence alone', () {
    const source = '```\ncodigo\n```';
    final edit = wrapSelection(
      MarkdownDocument.parse(source),
      0,
      4,
      10,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), source);
  });

  test('reports the active command of a block for the toolbar', () {
    expect(
      activeCommandFor(MarkdownDocument.parse('- [ ] a').blocks.first),
      NoteBlockCommand.checklist,
    );
    expect(activeCommandFor(MarkdownDocument.parse('a').blocks.first), isNull);
  });
}
