// test/unit/markdown_commands_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/domain/markdown_inline.dart';

const _caret = DocumentCaret(blockIndex: 0, offset: 0);

// Source lines the property tests run every command and every wrap over. The
// awkward ones are deliberate: a line whose text starts with three backticks
// opens a fence as soon as its marker is dropped, and a rule keeps all of its
// characters in `prefix` where a rebuild from `text` cannot see them.
const _corpus = <String>[
  '',
  'texto',
  '# Título',
  '### tres',
  '- lista',
  '1. uno',
  '- [ ] tarea',
  '- [x] hecha',
  '> cita',
  '  - anidada',
  '---',
  '***',
  '___',
  '- ```',
  '> ```',
  '1. ```',
  '- [ ] ```',
  '# ```dart',
  'usa ``` para codigo',
  '``` suelto',
  '| tabla |',
  '*',
  '`',
  '``',
  '**hola**',
  'hola **mundo** aqui',
  '```\ncodigo\n```',
  '```dart\nlinea uno\nlinea dos\n```',
];

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

/// The text [style] actually covers once the block is read back, which is what
/// tells apart a marker the tokenizer accepted from one it printed literally.
String styledTextOf(MarkdownBlock block, MarkdownInlineStyle style) =>
    tokenizeInline(block.text)
        .where((segment) => !segment.isMarker && segment.styles.contains(style))
        .map((segment) => segment.text)
        .join();

/// True when [document] parses back to exactly itself. Anything that fails
/// this looks right on screen and comes back different after a save.
bool reparsesToItself(MarkdownDocument document) {
  final reparsed = MarkdownDocument.parse(document.serialize());
  if (reparsed.blocks.length != document.blocks.length) return false;
  for (var i = 0; i < document.blocks.length; i++) {
    if (reparsed.blocks[i] != document.blocks[i]) return false;
  }
  return true;
}

/// The characters of [block] a command has to carry over. A rule holds them
/// all in `prefix` and has no text at all.
String payloadOf(MarkdownBlock block) =>
    block.type == MarkdownBlockType.divider ? block.prefix : block.text;

bool caretIsInside(DocumentEdit edit) {
  if (edit.caret.blockIndex < 0 ||
      edit.caret.blockIndex >= edit.document.blocks.length) {
    return false;
  }
  final line = edit.document.blocks[edit.caret.blockIndex].toSourceLine();
  return edit.caret.offset >= 0 && edit.caret.offset <= line.length;
}

void main() {
  test('heading cycles paragraph, h1, h2, h3 and back', () {
    expect(cycle('texto', NoteBlockCommand.heading), '# texto');
    expect(cycle('# texto', NoteBlockCommand.heading), '## texto');
    expect(cycle('## texto', NoteBlockCommand.heading), '### texto');
    expect(cycle('### texto', NoteBlockCommand.heading), 'texto');
  });

  test('a command applied twice returns to paragraph', () {
    const marked = <NoteBlockCommand, String>{
      NoteBlockCommand.bullet: '- texto',
      NoteBlockCommand.checklist: '- [ ] texto',
      NoteBlockCommand.quote: '> texto',
    };
    marked.forEach((command, source) {
      final once = applyBlockCommand(
        MarkdownDocument.parse('texto'),
        _caret,
        command,
      );
      expect(once.document.serialize(), source, reason: '$command');
      final twice = applyBlockCommand(once.document, once.caret, command);
      expect(twice.document.serialize(), 'texto', reason: '$command');
    });
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

  test('the divider reuses the empty line already under the block', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('texto\n'),
      _caret,
      NoteBlockCommand.divider,
    );
    expect(edit.document.serialize(), 'texto\n---\n');
    expect(edit.document.blocks.length, 3);
    expect(edit.caret, const DocumentCaret(blockIndex: 2, offset: 0));
  });

  test('the divider lands under the block the caret is on', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('uno\ndos\ntres'),
      const DocumentCaret(blockIndex: 1, offset: 3),
      NoteBlockCommand.divider,
    );
    expect(edit.document.serialize(), 'uno\ndos\n---\n\ntres');
    expect(edit.caret, const DocumentCaret(blockIndex: 3, offset: 0));
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
    final document = MarkdownDocument.parse('# Título');
    final fenced = applyBlockCommand(document, _caret, NoteBlockCommand.code);
    expect(fenced.document.serialize(), '```\n# Título\n```');
    final plain = applyBlockCommand(
      fenced.document,
      fenced.caret,
      NoteBlockCommand.code,
    );
    expect(plain.document.serialize(), '# Título');
    expect(plain.document.blocks.first, document.blocks.first);
  });

  test('the code command refuses to unwrap a fence it did not write', () {
    // Folding the code lines into one would delete the newlines and the
    // language, and no command puts either back.
    const sources = <String>[
      '```dart\nlinea uno\nlinea dos\n```',
      '```dart\ncodigo\n```',
      '```\nuno\ndos\n```',
    ];
    for (final source in sources) {
      final edit = applyBlockCommand(
        MarkdownDocument.parse(source),
        _caret,
        NoteBlockCommand.code,
      );
      expect(edit.document.serialize(), source, reason: source);
    }
  });

  test('the code command fences an unsupported line verbatim', () {
    const source = '| tabla |';
    final fenced = applyBlockCommand(
      MarkdownDocument.parse(source),
      _caret,
      NoteBlockCommand.code,
    );
    expect(fenced.document.serialize(), '```\n| tabla |\n```');
    final plain = applyBlockCommand(
      fenced.document,
      fenced.caret,
      NoteBlockCommand.code,
    );
    expect(plain.document.serialize(), source);
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

  test('a refused command still pulls a stale caret back into the line', () {
    final raw = applyBlockCommand(
      MarkdownDocument.parse('| tabla |'),
      const DocumentCaret(blockIndex: 0, offset: 99),
      NoteBlockCommand.heading,
    );
    expect(raw.caret, const DocumentCaret(blockIndex: 0, offset: 9));

    const fenceSource = '```\ncodigo\n```';
    final fence = applyBlockCommand(
      MarkdownDocument.parse(fenceSource),
      const DocumentCaret(blockIndex: 0, offset: 99),
      NoteBlockCommand.bullet,
    );
    expect(fence.caret.offset, fenceSource.length);
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

  test('a command on an indented item keeps the indentation', () {
    final edit = applyBlockCommand(
      MarkdownDocument.parse('    - anidada'),
      _caret,
      NoteBlockCommand.bullet,
    );
    expect(edit.document.serialize(), '    anidada');
    // The caret cannot fall in front of the indentation the line keeps.
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 4));
  });

  test('a block command never opens a fence that swallows what follows', () {
    const cases = <String, NoteBlockCommand>{
      '- ```': NoteBlockCommand.bullet,
      '> ```': NoteBlockCommand.quote,
      '1. ```': NoteBlockCommand.numbered,
      '- [ ] ```': NoteBlockCommand.checklist,
    };
    cases.forEach((line, command) {
      final source = '$line\nsegunda\ntercera';
      final edit = applyBlockCommand(
        MarkdownDocument.parse(source),
        _caret,
        command,
      );
      expect(edit.document.serialize(), source, reason: line);
      expect(edit.document.blocks.length, 3, reason: line);
    });
  });

  test('a second tap cannot open the fence the first one left behind', () {
    const source = '# ```dart\nsegunda\ntercera';
    const bulleted = '- ```dart\nsegunda\ntercera';
    final first = applyBlockCommand(
      MarkdownDocument.parse(source),
      _caret,
      NoteBlockCommand.bullet,
    );
    expect(first.document.serialize(), bulleted);
    final second = applyBlockCommand(
      first.document,
      first.caret,
      NoteBlockCommand.bullet,
    );
    expect(second.document.serialize(), bulleted);
    expect(second.document.blocks.length, 3);
  });

  test('a block command never deletes the rule a divider is made of', () {
    const commands = <NoteBlockCommand>[
      NoteBlockCommand.heading,
      NoteBlockCommand.bullet,
      NoteBlockCommand.numbered,
      NoteBlockCommand.checklist,
      NoteBlockCommand.quote,
    ];
    for (final rule in const ['---', '***', '___']) {
      for (final command in commands) {
        final edit = applyBlockCommand(
          MarkdownDocument.parse(rule),
          _caret,
          command,
        );
        expect(
          edit.document.serialize(),
          endsWith(rule),
          reason: '$command on $rule',
        );
      }
    }
  });

  test('the bullet command puts a rule back the way it found it', () {
    final marked = applyBlockCommand(
      MarkdownDocument.parse('---'),
      _caret,
      NoteBlockCommand.bullet,
    );
    expect(marked.document.serialize(), '- ---');
    final back = applyBlockCommand(
      marked.document,
      marked.caret,
      NoteBlockCommand.bullet,
    );
    expect(back.document.serialize(), '---');
    expect(back.document.blocks.first.type, MarkdownBlockType.divider);
  });

  test('every command leaves a document that parses back to itself', () {
    final failures = <String>[];
    for (final line in _corpus) {
      final document = MarkdownDocument.parse('$line\nsegunda\ntercera');
      final block = document.blocks.first;
      final payload = payloadOf(block);
      final length = block.toSourceLine().length;
      for (final command in NoteBlockCommand.values) {
        for (final offset in <int>{0, 1, length ~/ 2, length, length + 5}) {
          final where = '$command on "$line" at $offset';
          final edit = applyBlockCommand(
            document,
            DocumentCaret(blockIndex: 0, offset: offset),
            command,
          );
          if (!reparsesToItself(edit.document)) {
            failures.add('$where does not survive a reparse');
          }
          if (payload.isNotEmpty &&
              !edit.document.serialize().contains(payload)) {
            failures.add('$where dropped "$payload"');
          }
          if (!caretIsInside(edit)) {
            failures.add('$where left the caret at ${edit.caret}');
          }
        }
      }
    }
    expect(failures, isEmpty);
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

  test('a backwards selection wraps the same range as a forward one', () {
    final forward = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      5,
      10,
      MarkdownInlineStyle.bold,
    );
    final backward = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      10,
      5,
      MarkdownInlineStyle.bold,
    );
    expect(backward.document.serialize(), forward.document.serialize());
    expect(backward.caret, forward.caret);
  });

  test('wrapping in italics reads back as italics inside a word', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('holamundo'),
      0,
      4,
      9,
      MarkdownInlineStyle.italic,
    );
    expect(edit.document.serialize(), 'hola*mundo*');
    expect(
      styledTextOf(edit.document.blocks.first, MarkdownInlineStyle.italic),
      'mundo',
    );
  });

  test('wrapping in code and in strikethrough reads back too', () {
    final code = wrapSelection(
      MarkdownDocument.parse('corre npm test'),
      0,
      6,
      14,
      MarkdownInlineStyle.code,
    );
    expect(code.document.serialize(), 'corre `npm test`');
    expect(
      styledTextOf(code.document.blocks.first, MarkdownInlineStyle.code),
      'npm test',
    );

    final struck = wrapSelection(
      MarkdownDocument.parse('idea vieja'),
      0,
      5,
      10,
      MarkdownInlineStyle.strikethrough,
    );
    expect(struck.document.serialize(), 'idea ~~vieja~~');
    expect(
      styledTextOf(
        struck.document.blocks.first,
        MarkdownInlineStyle.strikethrough,
      ),
      'vieja',
    );
  });

  test('a selection that swallows the space still reads back as a style', () {
    // A double tap on a word takes the trailing space with it, and the
    // tokenizer refuses a marker that touches one.
    final trailing = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      0,
      5,
      MarkdownInlineStyle.bold,
    );
    expect(trailing.document.serialize(), '**hola** mundo');
    expect(
      styledTextOf(trailing.document.blocks.first, MarkdownInlineStyle.bold),
      'hola',
    );

    final leading = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      4,
      10,
      MarkdownInlineStyle.italic,
    );
    expect(leading.document.serialize(), 'hola *mundo*');
  });

  test('a tab is shrunk out of the selection like a space', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('hola\tmundo'),
      0,
      4,
      10,
      MarkdownInlineStyle.italic,
    );
    expect(edit.document.serialize(), 'hola\t*mundo*');
  });

  test('a selection of nothing but spaces is a clean no-op', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      4,
      5,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), 'hola mundo');
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 5));
  });

  test('italics over a bold word keeps the bold', () {
    final inside = wrapSelection(
      MarkdownDocument.parse('**hola**'),
      0,
      2,
      6,
      MarkdownInlineStyle.italic,
    );
    expect(inside.document.serialize(), '***hola***');
    expect(
      stylesOf(inside.document.blocks.first),
      {MarkdownInlineStyle.bold, MarkdownInlineStyle.italic},
    );

    // Selecting the markers along with the word must not read as an italic
    // span waiting to be toggled off either.
    final whole = wrapSelection(
      MarkdownDocument.parse('**hola**'),
      0,
      0,
      8,
      MarkdownInlineStyle.italic,
    );
    expect(whole.document.serialize(), '***hola***');
    expect(
      stylesOf(whole.document.blocks.first),
      {MarkdownInlineStyle.bold, MarkdownInlineStyle.italic},
    );
  });

  test('bold over an italic word keeps the italics', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('*hola*'),
      0,
      1,
      5,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), '***hola***');
    expect(
      stylesOf(edit.document.blocks.first),
      {MarkdownInlineStyle.bold, MarkdownInlineStyle.italic},
    );
  });

  test('a wrap never opens a fence that swallows what follows', () {
    for (final line in const ['`', '``']) {
      final source = '$line\nsegunda\ntercera';
      final edit = wrapSelection(
        MarkdownDocument.parse(source),
        0,
        0,
        1,
        MarkdownInlineStyle.code,
      );
      expect(edit.document.serialize(), source, reason: line);
      expect(edit.document.blocks.length, 3, reason: line);
    }
  });

  test('a wrap refuses to turn the whole line into a rule', () {
    // `***` round trips, but the asterisk the user typed would have become a
    // horizontal rule with nothing left to select and toggle back.
    final edit = wrapSelection(
      MarkdownDocument.parse('*'),
      0,
      0,
      1,
      MarkdownInlineStyle.italic,
    );
    expect(edit.document.serialize(), '*');
    expect(edit.document.blocks.first.type, MarkdownBlockType.paragraph);
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

  test('wrapping leaves an unsupported line alone', () {
    const source = '| tabla |';
    final edit = wrapSelection(
      MarkdownDocument.parse(source),
      0,
      2,
      7,
      MarkdownInlineStyle.bold,
    );
    expect(edit.document.serialize(), source);
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 7));
  });

  test('a link needs a target, not a pair of markers', () {
    final edit = wrapSelection(
      MarkdownDocument.parse('hola mundo'),
      0,
      0,
      4,
      MarkdownInlineStyle.link,
    );
    expect(edit.document.serialize(), 'hola mundo');
    expect(edit.caret, const DocumentCaret(blockIndex: 0, offset: 4));
  });

  test('a caret on a block that is not there changes nothing', () {
    final document = MarkdownDocument.parse('uno\ndos');
    final command = applyBlockCommand(
      document,
      const DocumentCaret(blockIndex: 7, offset: 0),
      NoteBlockCommand.bullet,
    );
    expect(command.document.serialize(), 'uno\ndos');
    expect(command.caret, const DocumentCaret(blockIndex: 7, offset: 0));

    final wrap = wrapSelection(document, 7, 0, 3, MarkdownInlineStyle.bold);
    expect(wrap.document.serialize(), 'uno\ndos');
    expect(wrap.caret, const DocumentCaret(blockIndex: 1, offset: 0));
  });

  test('every wrap leaves a document that parses back to itself', () {
    final failures = <String>[];
    for (final line in _corpus) {
      final document = MarkdownDocument.parse('$line\nsegunda\ntercera');
      final length = document.blocks.first.toSourceLine().length;
      for (final style in MarkdownInlineStyle.values) {
        for (var start = 0; start <= length; start++) {
          for (var end = start; end <= length; end++) {
            final edit = wrapSelection(document, 0, start, end, style);
            if (!reparsesToItself(edit.document)) {
              failures.add('$style over "$line" $start..$end');
            }
          }
        }
      }
    }
    expect(failures, isEmpty);
  });

  test('the markers a wrap inserts always read back as that style', () {
    const line = 'hola mundo aqui';
    final document = MarkdownDocument.parse(line);
    const styles = <MarkdownInlineStyle>[
      MarkdownInlineStyle.bold,
      MarkdownInlineStyle.italic,
      MarkdownInlineStyle.code,
      MarkdownInlineStyle.strikethrough,
    ];
    final failures = <String>[];
    for (final style in styles) {
      for (var start = 0; start <= line.length; start++) {
        for (var end = start; end <= line.length; end++) {
          final slice = line.substring(start, end);
          // Only a code span may hug a space, so every other style wraps the
          // content the selection was reaching for rather than the spaces
          // around it.
          final expected =
              style == MarkdownInlineStyle.code ? slice : slice.trim();
          final edit = wrapSelection(document, 0, start, end, style);
          final block = edit.document.blocks.first;
          final where = '$style over $start..$end';
          if (expected.isEmpty) {
            if (block.toSourceLine() != line) {
              failures.add('$where should have left the line alone');
            }
            continue;
          }
          final read = styledTextOf(block, style);
          if (read != expected) {
            failures.add(
              '$where wrote "${block.toSourceLine()}" and reads "$read"',
            );
          }
        }
      }
    }
    expect(failures, isEmpty);
  });

  test('reports the active command of every block kind', () {
    const kinds = <String, NoteBlockCommand>{
      '# Título': NoteBlockCommand.heading,
      '- lista': NoteBlockCommand.bullet,
      '1. uno': NoteBlockCommand.numbered,
      '- [ ] tarea': NoteBlockCommand.checklist,
      '> cita': NoteBlockCommand.quote,
      '```\ncodigo\n```': NoteBlockCommand.code,
    };
    kinds.forEach((source, command) {
      expect(
        activeCommandFor(MarkdownDocument.parse(source).blocks.first),
        command,
        reason: source,
      );
    });
    expect(activeCommandFor(MarkdownDocument.parse('a').blocks.first), isNull);
    // A rule is inserted, never toggled, so no button owns it.
    expect(
      activeCommandFor(MarkdownDocument.parse('---').blocks.first),
      isNull,
    );
  });
}
