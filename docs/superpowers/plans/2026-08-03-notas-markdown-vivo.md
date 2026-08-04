# Notas con Markdown vivo — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convertir Notas en un editor de Markdown vivo de bloque enfocado, con
casillas tocables y una biblioteca legible, sin cambiar el formato de `body` ni
el esquema de la base de datos.

**Architecture:** El cuerpo de la nota sigue siendo Markdown en texto plano. Un
parser puro en `lib/domain` lo convierte en una lista de bloques de línea y lo
vuelve a serializar byte por byte. La presentación renderiza cada bloque como
widget, y el bloque donde está el cursor se convierte en un `TextField` que
muestra la línea de origen cruda con los marcadores atenuados.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, Riverpod, Drift. Sin dependencias
nuevas.

## Global Constraints

- No se agrega ninguna dependencia a `pubspec.yaml`.
- `body` sigue siendo Markdown en texto plano y `formatVersion` se queda en 1.
- No se toca el esquema de Drift, el outbox de sync ni los backups.
- Fidelidad de bytes: `serialize(parse(x)) == x` para todo el corpus.
- Idempotencia: `parse(serialize(parse(x))) == parse(x)`.
- La única normalización permitida en todo el sistema es `[X]` a `[x]`.
- Strings de interfaz en español de México. Código y comentarios en inglés.
- Objetivos táctiles nuevos de mínimo 44 puntos.
- El umbral de Dynamic Type para apilar es
  `MediaQuery.textScalerOf(context).scale(16) > 23`, el mismo del resto de la app.
- Apple Pencil está fuera de alcance. No se escribe código de Scribble ni de
  stylus.
- Checkpoint de git antes de cada tarea y commit al cerrarla.
- Al cerrar cada fase: `flutter build ios --release --no-codesign`.
- **El árbol de trabajo está sucio con trabajo de otro agente.** Nunca uses
  `git add -A`, `git add .` ni `git commit -a`. Agrega al índice únicamente los
  archivos exactos que enumera la sección Files de tu tarea. Si un test falla en
  un archivo que tu tarea no toca, repórtalo, no lo arregles.

## Inventario de llamadores de `NoteEditorScreen`

Ya está resuelto, no hace falta descubrirlo durante la ejecución. La Tarea 13
debe actualizar exactamente estos siete puntos:

| Archivo | Línea | Uso |
| --- | --- | --- |
| `lib/main.dart` | 387 | Ruta desde notificación o deep link con `noteId` |
| `lib/main.dart` | 464 | Quick action de nota nueva |
| `lib/presentation/notes_screen.dart` | 405 | Crear nota |
| `lib/presentation/notes_screen.dart` | 416 | Abrir nota existente |
| `lib/presentation/calendar_screen.dart` | 442 | Abrir nota desde el calendario |
| `integration_test/screen_reviewer_test.dart` | 701, 704, 710 | Recorrido de capturas |
| `test/widget/notes_screen_test.dart` | 185, 221 | Aserciones de navegación |

---

# Fase 1. Dominio

## Task 1: Modelo de bloque y parser

**Files:**
- Create: `lib/domain/markdown_document.dart`
- Test: `test/unit/markdown_document_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `enum MarkdownBlockType`, `class MarkdownBlock`,
  `class MarkdownDocument` con `MarkdownDocument.parse(String source)` y
  `List<MarkdownBlock> get blocks`.

- [ ] **Step 1: Write the failing test**

```dart
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
    expect(MarkdownDocument.parse('            - a').blocks.single.indentLevel, 3);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_document_test.dart`
Expected: FAIL con `Error: Couldn't resolve the package 'zentra/domain/markdown_document.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/markdown_document.dart

/// Line level blocks the note editor understands.
enum MarkdownBlockType {
  heading,
  paragraph,
  bulletItem,
  numberedItem,
  checkItem,
  quote,
  divider,
  codeFence,
  raw,
}

/// A single block of a note body.
///
/// [leading] and [prefix] hold the literal source characters so serializing a
/// parsed document never rewrites what the user typed.
class MarkdownBlock {
  final MarkdownBlockType type;
  final String leading;
  final String prefix;
  final String text;
  final bool checked;
  final int headingLevel;
  final String language;
  final List<String> codeLines;

  /// The literal closing line of a code fence, or null when the fence was
  /// never closed. Stored whole because its indentation, backtick count and
  /// trailing spaces are all part of the source and must survive a round trip.
  final String? fenceClose;

  const MarkdownBlock({
    required this.type,
    this.leading = '',
    this.prefix = '',
    this.text = '',
    this.checked = false,
    this.headingLevel = 0,
    this.language = '',
    this.codeLines = const [],
    this.fenceClose,
  });

  const MarkdownBlock.paragraph([String text = ''])
      : this(type: MarkdownBlockType.paragraph, text: text);

  bool get fenceClosed => fenceClose != null;

  /// Indentation level, capped at three. A tab counts as two spaces.
  int get indentLevel {
    var spaces = 0;
    for (final rune in leading.runes) {
      spaces += rune == 0x09 ? 2 : 1;
    }
    final level = spaces ~/ 2;
    return level > 3 ? 3 : level;
  }

  bool get isListLike =>
      type == MarkdownBlockType.bulletItem ||
      type == MarkdownBlockType.numberedItem ||
      type == MarkdownBlockType.checkItem;

  MarkdownBlock copyWith({
    MarkdownBlockType? type,
    String? leading,
    String? prefix,
    String? text,
    bool? checked,
    int? headingLevel,
    String? language,
    List<String>? codeLines,
    String? fenceClose,
  }) {
    return MarkdownBlock(
      type: type ?? this.type,
      leading: leading ?? this.leading,
      prefix: prefix ?? this.prefix,
      text: text ?? this.text,
      checked: checked ?? this.checked,
      headingLevel: headingLevel ?? this.headingLevel,
      language: language ?? this.language,
      codeLines: codeLines ?? this.codeLines,
      fenceClose: fenceClose ?? this.fenceClose,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownBlock &&
        other.type == type &&
        other.leading == leading &&
        other.prefix == prefix &&
        other.text == text &&
        other.checked == checked &&
        other.headingLevel == headingLevel &&
        other.language == language &&
        other.fenceClose == fenceClose &&
        _sameLines(other.codeLines, codeLines);
  }

  @override
  int get hashCode => Object.hash(
        type,
        leading,
        prefix,
        text,
        checked,
        headingLevel,
        language,
        fenceClose,
        Object.hashAll(codeLines),
      );

  static bool _sameLines(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// `[\s\S]*` instead of `.*` on every tail group: Dart's `.` excludes carriage
// returns, so a CRLF source would fall through to raw paragraphs. Capturing the
// `\r` as part of the tail keeps both the block type and the exact bytes.
final _leadingPattern = RegExp(r'^[ \t]*');
final _headingPattern = RegExp(r'^(#{1,3}[ \t]+)([\s\S]*)$');
final _dividerPattern = RegExp(r'^(-{3,}|\*{3,}|_{3,})[ \t]*\r?$');
final _fencePattern = RegExp('^(`{3,})([\\s\\S]*)\$');
final _checkPattern = RegExp(r'^([-*][ \t]+\[[ xX]\][ \t]+)([\s\S]*)$');
final _bulletPattern = RegExp(r'^([-*][ \t]+)([\s\S]*)$');
final _numberedPattern = RegExp(r'^(\d+[.)][ \t]+)([\s\S]*)$');
final _quotePattern = RegExp(r'^(>[ \t]?)([\s\S]*)$');
final _unsupportedPattern = RegExp(r'^(#{4,}[ \t]|\||!\[|<)');

/// A parsed note body. Blocks map one to one with source lines, except code
/// fences which span several.
class MarkdownDocument {
  final List<MarkdownBlock> blocks;

  const MarkdownDocument(this.blocks);

  factory MarkdownDocument.parse(String source) {
    if (source.isEmpty) {
      return const MarkdownDocument([MarkdownBlock.paragraph()]);
    }
    final lines = source.split('\n');
    final parsed = <MarkdownBlock>[];
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final leading = _leadingPattern.stringMatch(line) ?? '';
      final rest = line.substring(leading.length);

      final fence = _fencePattern.firstMatch(rest);
      if (fence != null) {
        final marker = fence.group(1)!;
        final codeLines = <String>[];
        String? closingLine;
        index++;
        while (index < lines.length) {
          final candidate = lines[index].trimLeft();
          if (candidate.startsWith(marker) &&
              candidate.substring(marker.length).trim().isEmpty) {
            closingLine = lines[index];
            index++;
            break;
          }
          codeLines.add(lines[index]);
          index++;
        }
        parsed.add(
          MarkdownBlock(
            type: MarkdownBlockType.codeFence,
            leading: leading,
            prefix: marker,
            language: fence.group(2)!,
            codeLines: List.unmodifiable(codeLines),
            fenceClose: closingLine,
          ),
        );
        continue;
      }

      parsed.add(_parseLine(line, leading, rest));
      index++;
    }
    return MarkdownDocument(List.unmodifiable(parsed));
  }

  static MarkdownBlock _parseLine(String line, String leading, String rest) {
    if (_unsupportedPattern.hasMatch(rest)) {
      return MarkdownBlock(type: MarkdownBlockType.raw, text: line);
    }
    final divider = _dividerPattern.firstMatch(rest);
    if (divider != null) {
      return MarkdownBlock(
        type: MarkdownBlockType.divider,
        leading: leading,
        prefix: rest,
      );
    }
    final heading = _headingPattern.firstMatch(rest);
    if (heading != null) {
      final marker = heading.group(1)!;
      return MarkdownBlock(
        type: MarkdownBlockType.heading,
        leading: leading,
        prefix: marker,
        text: heading.group(2)!,
        headingLevel: marker.trimRight().length,
      );
    }
    final check = _checkPattern.firstMatch(rest);
    if (check != null) {
      final marker = check.group(1)!;
      return MarkdownBlock(
        type: MarkdownBlockType.checkItem,
        leading: leading,
        prefix: marker,
        text: check.group(2)!,
        checked: !marker.contains('[ ]'),
      );
    }
    final bullet = _bulletPattern.firstMatch(rest);
    if (bullet != null) {
      return MarkdownBlock(
        type: MarkdownBlockType.bulletItem,
        leading: leading,
        prefix: bullet.group(1)!,
        text: bullet.group(2)!,
      );
    }
    final numbered = _numberedPattern.firstMatch(rest);
    if (numbered != null) {
      return MarkdownBlock(
        type: MarkdownBlockType.numberedItem,
        leading: leading,
        prefix: numbered.group(1)!,
        text: numbered.group(2)!,
      );
    }
    final quote = _quotePattern.firstMatch(rest);
    if (quote != null) {
      return MarkdownBlock(
        type: MarkdownBlockType.quote,
        leading: leading,
        prefix: quote.group(1)!,
        text: quote.group(2)!,
      );
    }
    return MarkdownBlock(
      type: MarkdownBlockType.paragraph,
      leading: leading,
      text: rest,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_document_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_document.dart test/unit/markdown_document_test.dart
git commit -m "feat(notas): parser de bloques Markdown que preserva el origen"
```

---

## Task 2: Serialización y garantías de ciclo completo

**Files:**
- Modify: `lib/domain/markdown_document.dart`
- Test: `test/unit/markdown_document_roundtrip_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument.parse`, `MarkdownBlock` de la Tarea 1.
- Produces: `String MarkdownDocument.serialize()`,
  `String MarkdownBlock.toSourceLine()`,
  `MarkdownBlock MarkdownBlock.toggleChecked()`,
  `MarkdownDocument.replaceBlock(int, MarkdownBlock)`,
  `MarkdownDocument.insertBlock(int, MarkdownBlock)`,
  `MarkdownDocument.removeBlock(int)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/markdown_document_roundtrip_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_document_roundtrip_test.dart`
Expected: FAIL con `The method 'serialize' isn't defined for the class 'MarkdownDocument'`.

- [ ] **Step 3: Write the implementation**

Agrega a `MarkdownBlock`:

```dart
  /// Rebuilds the exact source line or lines this block came from.
  String toSourceLine() {
    if (type == MarkdownBlockType.raw) return text;
    if (type != MarkdownBlockType.codeFence) {
      return '$leading$prefix$text';
    }
    final buffer = StringBuffer('$leading$prefix$language');
    for (final line in codeLines) {
      buffer
        ..write('\n')
        ..write(line);
    }
    if (fenceClose != null) buffer.write('\n$fenceClose');
    return buffer.toString();
  }

  /// Flips a checklist box, rewriting only the character inside the brackets.
  MarkdownBlock toggleChecked() {
    if (type != MarkdownBlockType.checkItem) return this;
    final next = !checked;
    return copyWith(
      prefix: prefix.replaceFirst(RegExp(r'\[[ xX]\]'), next ? '[x]' : '[ ]'),
      checked: next,
    );
  }
```

Agrega a `MarkdownDocument`:

```dart
  String serialize() => blocks.map((block) => block.toSourceLine()).join('\n');

  MarkdownDocument replaceBlock(int index, MarkdownBlock block) {
    final next = [...blocks]..[index] = block;
    return MarkdownDocument(List.unmodifiable(next));
  }

  MarkdownDocument insertBlock(int index, MarkdownBlock block) {
    final next = [...blocks]..insert(index, block);
    return MarkdownDocument(List.unmodifiable(next));
  }

  MarkdownDocument removeBlock(int index) {
    if (blocks.length == 1) {
      return const MarkdownDocument([MarkdownBlock.paragraph()]);
    }
    final next = [...blocks]..removeAt(index);
    return MarkdownDocument(List.unmodifiable(next));
  }
```

Nota sobre el caso vacío: `parse('')` devuelve un párrafo vacío y
`serialize()` de ese documento devuelve `''`, así que la fidelidad se mantiene.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_document_roundtrip_test.dart`
Expected: PASS, 32 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_document.dart test/unit/markdown_document_roundtrip_test.dart
git commit -m "feat(notas): serialización con fidelidad de bytes y ciclo completo probado"
```

---

## Task 3: Tokenizador inline con posiciones de origen

**Files:**
- Create: `lib/domain/markdown_inline.dart`
- Test: `test/unit/markdown_inline_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `enum MarkdownInlineStyle { bold, italic, code, strikethrough, link }`,
  `class MarkdownInlineSegment { int start; int end; String text; Set<MarkdownInlineStyle> styles; bool isMarker; String? href; }`,
  `List<MarkdownInlineSegment> tokenizeInline(String text)`.

- [ ] **Step 1: Write the failing test**

```dart
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
    expect(content.last.styles,
        {MarkdownInlineStyle.bold, MarkdownInlineStyle.italic});
  });

  test('captures the link target on the label segment', () {
    final segments = tokenizeInline('[Zentra](https://zentra.app)');
    final label = segments.firstWhere((s) => s.text == 'Zentra');
    expect(label.styles, {MarkdownInlineStyle.link});
    expect(label.href, 'https://zentra.app');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_inline_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/domain/markdown_inline.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/markdown_inline.dart

enum MarkdownInlineStyle { bold, italic, code, strikethrough, link }

/// A slice of a block's text. Concatenating [text] over all segments of a
/// tokenization always rebuilds the original input exactly.
class MarkdownInlineSegment {
  final int start;
  final int end;
  final String text;
  final Set<MarkdownInlineStyle> styles;
  final bool isMarker;
  final String? href;

  const MarkdownInlineSegment({
    required this.start,
    required this.end,
    required this.text,
    this.styles = const {},
    this.isMarker = false,
    this.href,
  });
}

const _delimiters = <String, MarkdownInlineStyle>{
  '**': MarkdownInlineStyle.bold,
  '__': MarkdownInlineStyle.bold,
  '~~': MarkdownInlineStyle.strikethrough,
  '`': MarkdownInlineStyle.code,
  '*': MarkdownInlineStyle.italic,
  '_': MarkdownInlineStyle.italic,
};

final _linkPattern = RegExp(r'\[([^\]\n]*)\]\(([^)\s]*)\)');

/// Splits [text] into styled segments, keeping the exact source offsets so the
/// editor can dim markers in place.
List<MarkdownInlineSegment> tokenizeInline(String text) {
  if (text.isEmpty) return const [];
  final segments = <MarkdownInlineSegment>[];
  final active = <MarkdownInlineStyle>{};
  final buffer = StringBuffer();
  var bufferStart = 0;
  var index = 0;

  void flush(int end) {
    if (buffer.isEmpty) return;
    segments.add(
      MarkdownInlineSegment(
        start: bufferStart,
        end: end,
        text: buffer.toString(),
        styles: Set.unmodifiable(active),
      ),
    );
    buffer.clear();
    bufferStart = end;
  }

  void addMarker(String marker, MarkdownInlineStyle style, int at) {
    segments.add(
      MarkdownInlineSegment(
        start: at,
        end: at + marker.length,
        text: marker,
        styles: {style},
        isMarker: true,
      ),
    );
  }

  while (index < text.length) {
    final link = _linkPattern.matchAsPrefix(text, index);
    if (link != null) {
      flush(index);
      final label = link.group(1)!;
      final href = link.group(2)!;
      addMarker('[', MarkdownInlineStyle.link, index);
      segments.add(
        MarkdownInlineSegment(
          start: index + 1,
          end: index + 1 + label.length,
          text: label,
          styles: {...active, MarkdownInlineStyle.link},
          href: href,
        ),
      );
      final tailStart = index + 1 + label.length;
      segments.add(
        MarkdownInlineSegment(
          start: tailStart,
          end: link.end,
          text: text.substring(tailStart, link.end),
          styles: {MarkdownInlineStyle.link},
          isMarker: true,
        ),
      );
      index = link.end;
      bufferStart = index;
      continue;
    }

    final opener = _delimiterAt(text, index);
    if (opener != null) {
      final marker = opener.key;
      final style = opener.value;
      final closeAt = text.indexOf(marker, index + marker.length);
      final opens = !active.contains(style) &&
          closeAt != -1 &&
          closeAt > index + marker.length;
      if (opens) {
        flush(index);
        addMarker(marker, style, index);
        active.add(style);
        index += marker.length;
        bufferStart = index;
        continue;
      }
      if (active.contains(style)) {
        flush(index);
        addMarker(marker, style, index);
        active.remove(style);
        index += marker.length;
        bufferStart = index;
        continue;
      }
    }

    buffer.write(text[index]);
    index++;
  }
  flush(text.length);
  return List.unmodifiable(segments);
}

MapEntry<String, MarkdownInlineStyle>? _delimiterAt(String text, int index) {
  for (final entry in _delimiters.entries) {
    if (text.startsWith(entry.key, index)) return entry;
  }
  return null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_inline_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_inline.dart test/unit/markdown_inline_test.dart
git commit -m "feat(notas): tokenizador inline con posiciones de origen"
```

---

## Task 4: Transformaciones de teclado

**Files:**
- Create: `lib/domain/markdown_editing.dart`
- Test: `test/unit/markdown_editing_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument`, `MarkdownBlock` de las Tareas 1 y 2.
- Produces: `class DocumentCaret { int blockIndex; int offset; }`,
  `class DocumentEdit { MarkdownDocument document; DocumentCaret caret; }`,
  `DocumentEdit splitBlock(MarkdownDocument, DocumentCaret)`,
  `DocumentEdit mergeWithPrevious(MarkdownDocument, DocumentCaret)`,
  `DocumentEdit changeIndent(MarkdownDocument, DocumentCaret, {required bool increase})`.

El `offset` de `DocumentCaret` se mide sobre la línea de origen completa que
devuelve `toSourceLine()`, no sobre `text`, porque es lo que ve el usuario en el
bloque activo.

- [ ] **Step 1: Write the failing test**

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_editing_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/domain/markdown_editing.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/markdown_editing.dart
import 'markdown_document.dart';

/// Where the caret sits, measured over the block's full source line.
class DocumentCaret {
  final int blockIndex;
  final int offset;

  const DocumentCaret({required this.blockIndex, required this.offset});

  @override
  bool operator ==(Object other) =>
      other is DocumentCaret &&
      other.blockIndex == blockIndex &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(blockIndex, offset);

  @override
  String toString() => 'DocumentCaret($blockIndex, $offset)';
}

/// Result of a transformation: the new document and where the caret lands.
class DocumentEdit {
  final MarkdownDocument document;
  final DocumentCaret caret;

  const DocumentEdit(this.document, this.caret);
}

/// Splits the active block at the caret, continuing lists when it makes sense.
DocumentEdit splitBlock(MarkdownDocument document, DocumentCaret caret) {
  final block = document.blocks[caret.blockIndex];
  final source = block.toSourceLine();
  final head = source.substring(0, caret.offset);
  final tail = source.substring(caret.offset);
  final continuation = _continuationPrefix(block);

  if (block.isListLike && block.text.isEmpty) {
    final cleared = MarkdownBlock(
      type: MarkdownBlockType.paragraph,
      leading: block.leading,
    );
    return DocumentEdit(
      document.replaceBlock(caret.blockIndex, cleared),
      DocumentCaret(blockIndex: caret.blockIndex, offset: block.leading.length),
    );
  }

  final headBlock = MarkdownDocument.parse(head).blocks.first;
  final tailBlock = MarkdownDocument.parse('$continuation$tail').blocks.first;
  final next = document
      .replaceBlock(caret.blockIndex, headBlock)
      .insertBlock(caret.blockIndex + 1, tailBlock);
  return DocumentEdit(
    next,
    DocumentCaret(
      blockIndex: caret.blockIndex + 1,
      offset: continuation.length,
    ),
  );
}

/// Joins the active block with the one above it, keeping both contents.
DocumentEdit mergeWithPrevious(MarkdownDocument document, DocumentCaret caret) {
  if (caret.blockIndex == 0) return DocumentEdit(document, caret);
  final previous = document.blocks[caret.blockIndex - 1];
  final current = document.blocks[caret.blockIndex];
  final previousSource = previous.toSourceLine();
  final merged = MarkdownDocument.parse('$previousSource${current.text}')
      .blocks
      .first;
  final next = document
      .replaceBlock(caret.blockIndex - 1, merged)
      .removeBlock(caret.blockIndex);
  return DocumentEdit(
    next,
    DocumentCaret(
      blockIndex: caret.blockIndex - 1,
      offset: previousSource.length,
    ),
  );
}

/// Adds or removes one indentation step of two spaces, capped at three levels.
DocumentEdit changeIndent(
  MarkdownDocument document,
  DocumentCaret caret, {
  required bool increase,
}) {
  final block = document.blocks[caret.blockIndex];
  final level = block.indentLevel;
  final nextLevel = increase ? level + 1 : level - 1;
  final clamped = nextLevel < 0 ? 0 : (nextLevel > 3 ? 3 : nextLevel);
  if (clamped == level) return DocumentEdit(document, caret);
  final leading = '  ' * clamped;
  final delta = leading.length - block.leading.length;
  return DocumentEdit(
    document.replaceBlock(caret.blockIndex, block.copyWith(leading: leading)),
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: caret.offset + delta < 0 ? 0 : caret.offset + delta,
    ),
  );
}

String _continuationPrefix(MarkdownBlock block) {
  switch (block.type) {
    case MarkdownBlockType.bulletItem:
      return '${block.leading}${block.prefix}';
    case MarkdownBlockType.checkItem:
      return '${block.leading}'
          '${block.prefix.replaceFirst(RegExp(r'\[[ xX]\]'), '[ ]')}';
    case MarkdownBlockType.numberedItem:
      return '${block.leading}${_nextNumber(block.prefix)}';
    case MarkdownBlockType.quote:
      return '${block.leading}${block.prefix}';
    default:
      return block.leading;
  }
}

String _nextNumber(String prefix) {
  final match = RegExp(r'^(\d+)([.)][ \t]+)$').firstMatch(prefix);
  if (match == null) return prefix;
  final value = int.parse(match.group(1)!) + 1;
  return '$value${match.group(2)}';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_editing_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_editing.dart test/unit/markdown_editing_test.dart
git commit -m "feat(notas): transformaciones de bloque para Enter, Backspace y sangría"
```

---

## Task 5: Comandos de bloque y envoltura inline

**Files:**
- Modify: `lib/domain/markdown_editing.dart`
- Test: `test/unit/markdown_commands_test.dart`

**Interfaces:**
- Consumes: `DocumentEdit`, `DocumentCaret` de la Tarea 4.
- Produces: `enum NoteBlockCommand { heading, bullet, numbered, checklist, quote, code, divider }`,
  `DocumentEdit applyBlockCommand(MarkdownDocument, DocumentCaret, NoteBlockCommand)`,
  `DocumentEdit wrapSelection(MarkdownDocument, int blockIndex, int start, int end, MarkdownInlineStyle style)`,
  `NoteBlockCommand? activeCommandFor(MarkdownBlock block)`.

- [ ] **Step 1: Write the failing test**

```dart
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

  test('reports the active command of a block for the toolbar', () {
    expect(
      activeCommandFor(MarkdownDocument.parse('- [ ] a').blocks.first),
      NoteBlockCommand.checklist,
    );
    expect(activeCommandFor(MarkdownDocument.parse('a').blocks.first), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_commands_test.dart`
Expected: FAIL con `The function 'applyBlockCommand' isn't defined`.

- [ ] **Step 3: Write the implementation**

Agrega a `lib/domain/markdown_editing.dart`:

```dart
import 'markdown_inline.dart';

/// Block level formatting actions exposed by the editor toolbar.
enum NoteBlockCommand { heading, bullet, numbered, checklist, quote, code, divider }

/// Applies a toolbar command to the whole active block. Commands are
/// idempotent toggles and never insert text at the caret.
DocumentEdit applyBlockCommand(
  MarkdownDocument document,
  DocumentCaret caret,
  NoteBlockCommand command,
) {
  final block = document.blocks[caret.blockIndex];

  if (command == NoteBlockCommand.divider) {
    final next = document
        .insertBlock(
          caret.blockIndex + 1,
          const MarkdownBlock(
            type: MarkdownBlockType.divider,
            prefix: '---',
          ),
        )
        .insertBlock(caret.blockIndex + 2, const MarkdownBlock.paragraph());
    return DocumentEdit(
      next,
      DocumentCaret(blockIndex: caret.blockIndex + 2, offset: 0),
    );
  }

  if (command == NoteBlockCommand.code) {
    final next = document.replaceBlock(
      caret.blockIndex,
      block.type == MarkdownBlockType.codeFence
          ? MarkdownBlock.paragraph(block.codeLines.join(' '))
          : MarkdownBlock(
              type: MarkdownBlockType.codeFence,
              prefix: '```',
              codeLines: [block.text],
            ),
    );
    return DocumentEdit(next, DocumentCaret(blockIndex: caret.blockIndex, offset: 0));
  }

  final nextPrefix = _nextPrefixFor(block, command);
  final rebuilt = MarkdownDocument.parse(
    '${block.leading}$nextPrefix${block.text}',
  ).blocks.first;
  final delta = nextPrefix.length - block.prefix.length;
  final offset = caret.offset + delta;
  return DocumentEdit(
    document.replaceBlock(caret.blockIndex, rebuilt),
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: offset < block.leading.length ? block.leading.length : offset,
    ),
  );
}

String _nextPrefixFor(MarkdownBlock block, NoteBlockCommand command) {
  switch (command) {
    case NoteBlockCommand.heading:
      if (block.type != MarkdownBlockType.heading) return '# ';
      return switch (block.headingLevel) {
        1 => '## ',
        2 => '### ',
        _ => '',
      };
    case NoteBlockCommand.bullet:
      return block.type == MarkdownBlockType.bulletItem ? '' : '- ';
    case NoteBlockCommand.numbered:
      return block.type == MarkdownBlockType.numberedItem ? '' : '1. ';
    case NoteBlockCommand.checklist:
      return block.type == MarkdownBlockType.checkItem ? '' : '- [ ] ';
    case NoteBlockCommand.quote:
      return block.type == MarkdownBlockType.quote ? '' : '> ';
    case NoteBlockCommand.code:
    case NoteBlockCommand.divider:
      return block.prefix;
  }
}

/// Which toolbar button should look selected for [block].
NoteBlockCommand? activeCommandFor(MarkdownBlock block) {
  return switch (block.type) {
    MarkdownBlockType.heading => NoteBlockCommand.heading,
    MarkdownBlockType.bulletItem => NoteBlockCommand.bullet,
    MarkdownBlockType.numberedItem => NoteBlockCommand.numbered,
    MarkdownBlockType.checkItem => NoteBlockCommand.checklist,
    MarkdownBlockType.quote => NoteBlockCommand.quote,
    MarkdownBlockType.codeFence => NoteBlockCommand.code,
    _ => null,
  };
}

const _inlineMarkers = <MarkdownInlineStyle, String>{
  MarkdownInlineStyle.bold: '**',
  MarkdownInlineStyle.italic: '_',
  MarkdownInlineStyle.code: '`',
  MarkdownInlineStyle.strikethrough: '~~',
};

/// Wraps or unwraps a selection measured over the block's source line.
DocumentEdit wrapSelection(
  MarkdownDocument document,
  int blockIndex,
  int start,
  int end,
  MarkdownInlineStyle style,
) {
  final marker = _inlineMarkers[style];
  final block = document.blocks[blockIndex];
  if (marker == null || start == end) {
    return DocumentEdit(document, DocumentCaret(blockIndex: blockIndex, offset: end));
  }
  final source = block.toSourceLine();
  final before = source.substring(0, start);
  final selected = source.substring(start, end);
  final after = source.substring(end);

  final isWrapped =
      before.endsWith(marker) && after.startsWith(marker);
  final rebuilt = isWrapped
      ? '${before.substring(0, before.length - marker.length)}'
          '$selected${after.substring(marker.length)}'
      : '$before$marker$selected$marker$after';
  final caretEnd = isWrapped ? end - marker.length : end + marker.length;
  return DocumentEdit(
    document.replaceBlock(blockIndex, MarkdownDocument.parse(rebuilt).blocks.first),
    DocumentCaret(blockIndex: blockIndex, offset: caretEnd),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_commands_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_editing.dart test/unit/markdown_commands_test.dart
git commit -m "feat(notas): comandos de bloque idempotentes y envoltura inline"
```

---

## Task 6: Derivados para la biblioteca

**Files:**
- Modify: `lib/domain/markdown_document.dart`
- Test: `test/unit/markdown_summary_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument` de las Tareas 1 y 2.
- Produces: `int MarkdownDocument.checkItemCount`,
  `int MarkdownDocument.checkedCount`,
  `String MarkdownDocument.previewText({int maxLength = 140})`,
  `String MarkdownDocument.plainText()`,
  `String markdownExcerptAround(String body, String query, {int radius = 40})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/markdown_summary_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';

void main() {
  test('counts checklist progress', () {
    final document = MarkdownDocument.parse('- [x] a\n- [ ] b\n- [x] c');
    expect(document.checkItemCount, 3);
    expect(document.checkedCount, 2);
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

  test('plain text drops markers across every block', () {
    expect(
      MarkdownDocument.parse('# T\n- **a**\n> _b_').plainText(),
      'T\na\nb',
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_summary_test.dart`
Expected: FAIL con `The getter 'checkItemCount' isn't defined`.

- [ ] **Step 3: Write the implementation**

Agrega a `lib/domain/markdown_document.dart`:

```dart
import 'markdown_inline.dart';
```

y dentro de `MarkdownDocument`:

```dart
  int get checkItemCount => blocks
      .where((block) => block.type == MarkdownBlockType.checkItem)
      .length;

  int get checkedCount => blocks
      .where((block) => block.type == MarkdownBlockType.checkItem && block.checked)
      .length;

  /// Human readable text of every block, one per line, without markers.
  String plainText() => blocks
      .map(_visibleText)
      .where((line) => line.isNotEmpty)
      .join('\n');

  /// First meaningful line, for note cards.
  String previewText({int maxLength = 140}) {
    for (final block in blocks) {
      final line = _visibleText(block);
      if (line.isEmpty) continue;
      if (line.length <= maxLength) return line;
      final cut = line.lastIndexOf(' ', maxLength);
      return '${line.substring(0, cut <= 0 ? maxLength : cut)}…';
    }
    return '';
  }

  static String _visibleText(MarkdownBlock block) {
    switch (block.type) {
      case MarkdownBlockType.divider:
        return '';
      case MarkdownBlockType.codeFence:
        return block.codeLines.join(' ').trim();
      case MarkdownBlockType.raw:
        return block.text.trim();
      default:
        return tokenizeInline(block.text)
            .where((segment) => !segment.isMarker)
            .map((segment) => segment.text)
            .join()
            .trim();
    }
  }
```

y al final del archivo, fuera de la clase:

```dart
/// Returns the slice of [body] around the first occurrence of [query], so the
/// note card can show where the match actually is.
String markdownExcerptAround(String body, String query, {int radius = 40}) {
  final plain = MarkdownDocument.parse(body).plainText().replaceAll('\n', ' ');
  if (query.trim().isEmpty) return plain;
  final at = plain.toLowerCase().indexOf(query.trim().toLowerCase());
  if (at == -1) return plain;
  final start = at - radius < 0 ? 0 : at - radius;
  final end = at + query.length + radius > plain.length
      ? plain.length
      : at + query.length + radius;
  final prefix = start > 0 ? '…' : '';
  final suffix = end < plain.length ? '…' : '';
  return '$prefix${plain.substring(start, end)}$suffix';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_summary_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_document.dart test/unit/markdown_summary_test.dart
git commit -m "feat(notas): progreso de casillas, preview legible y extracto de búsqueda"
```

---

## Task 7: Historial de undo por documento

**Files:**
- Create: `lib/domain/markdown_undo_history.dart`
- Test: `test/unit/markdown_undo_history_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `class MarkdownUndoHistory` con `void record(String markdown)`,
  `String? undo(String current)`, `String? redo()`, `bool get canUndo`,
  `bool get canRedo`, constructor `MarkdownUndoHistory({int maxEntries = 50})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/markdown_undo_history_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_undo_history.dart';

void main() {
  test('undo returns previous snapshots in order', () {
    final history = MarkdownUndoHistory()
      ..record('a')
      ..record('ab');
    expect(history.undo('abc'), 'ab');
    expect(history.undo('ab'), 'a');
    expect(history.undo('a'), isNull);
  });

  test('redo replays what undo took away', () {
    final history = MarkdownUndoHistory()..record('a');
    expect(history.undo('ab'), 'a');
    expect(history.redo(), 'ab');
    expect(history.redo(), isNull);
  });

  test('recording after an undo clears the redo stack', () {
    final history = MarkdownUndoHistory()..record('a');
    history.undo('ab');
    history.record('otro');
    expect(history.canRedo, isFalse);
  });

  test('identical snapshots are not recorded twice', () {
    final history = MarkdownUndoHistory()
      ..record('a')
      ..record('a');
    expect(history.undo('a'), isNull);
  });

  test('history is capped at maxEntries', () {
    final history = MarkdownUndoHistory(maxEntries: 2);
    for (final value in ['a', 'b', 'c', 'd']) {
      history.record(value);
    }
    expect(history.undo('e'), 'd');
    expect(history.undo('d'), 'c');
    expect(history.undo('c'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/markdown_undo_history_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/domain/markdown_undo_history.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/markdown_undo_history.dart

/// Document level undo for the note editor.
///
/// Snapshots are serialized Markdown, not text field states, so undo survives
/// block splits, merges and toolbar commands.
class MarkdownUndoHistory {
  final int maxEntries;
  final List<String> _past = [];
  final List<String> _future = [];

  MarkdownUndoHistory({this.maxEntries = 50});

  bool get canUndo => _past.isNotEmpty;

  bool get canRedo => _future.isNotEmpty;

  /// Stores [markdown] as a restore point. Consecutive duplicates are ignored.
  void record(String markdown) {
    if (_past.isNotEmpty && _past.last == markdown) return;
    _past.add(markdown);
    if (_past.length > maxEntries) _past.removeAt(0);
    _future.clear();
  }

  /// Returns the previous snapshot, remembering [current] so redo can restore it.
  String? undo(String current) {
    if (_past.isEmpty) return null;
    final previous = _past.removeLast();
    if (previous == current) {
      if (_past.isEmpty) return null;
      _future.add(current);
      return _past.removeLast();
    }
    _future.add(current);
    return previous;
  }

  String? redo() {
    if (_future.isEmpty) return null;
    final next = _future.removeLast();
    _past.add(next);
    return next;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/markdown_undo_history_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/markdown_undo_history.dart test/unit/markdown_undo_history_test.dart
git commit -m "feat(notas): historial de undo a nivel documento"
```

- [ ] **Step 6: Cerrar Fase 1**

Run: `flutter test test/unit && flutter analyze`
Expected: sin fallos ni advertencias nuevas.

---

# Fase 2. Editor

## Task 8: Motor compartido de estilos inline

**Files:**
- Create: `lib/presentation/widgets/markdown_inline_spans.dart`
- Test: `test/widget/markdown_inline_spans_test.dart`

**Interfaces:**
- Consumes: `tokenizeInline`, `MarkdownInlineSegment`, `MarkdownInlineStyle`.
- Produces: `List<InlineSpan> buildMarkdownSpans({required String text, required TextStyle baseStyle, required Color markerColor, required bool showMarkers})`.

Este es el motor único que exige el spec: el bloque activo lo llama con
`showMarkers: true` y el bloque renderizado con `showMarkers: false`, así el
texto no brinca al entrar y salir.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/markdown_inline_spans_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/markdown_inline_spans.dart';

String flatten(List<InlineSpan> spans) =>
    spans.map((span) => (span as TextSpan).text ?? '').join();

void main() {
  const base = TextStyle(fontSize: 16);

  test('showing markers keeps the source text intact', () {
    final spans = buildMarkdownSpans(
      text: 'a **b** c',
      baseStyle: base,
      markerColor: const Color(0xFF999999),
      showMarkers: true,
    );
    expect(flatten(spans), 'a **b** c');
  });

  test('hiding markers removes only the marker characters', () {
    final spans = buildMarkdownSpans(
      text: 'a **b** c',
      baseStyle: base,
      markerColor: const Color(0xFF999999),
      showMarkers: false,
    );
    expect(flatten(spans), 'a b c');
  });

  test('content keeps the same weight in both modes', () {
    TextStyle styleOf(bool showMarkers) {
      final spans = buildMarkdownSpans(
        text: '**b**',
        baseStyle: base,
        markerColor: const Color(0xFF999999),
        showMarkers: showMarkers,
      );
      return spans
          .cast<TextSpan>()
          .firstWhere((span) => span.text == 'b')
          .style!;
    }

    expect(styleOf(true).fontWeight, FontWeight.w700);
    expect(styleOf(false).fontWeight, FontWeight.w700);
    expect(styleOf(true).fontSize, styleOf(false).fontSize);
  });

  test('markers are dimmed rather than removed when shown', () {
    final spans = buildMarkdownSpans(
      text: '**b**',
      baseStyle: base,
      markerColor: const Color(0xFF999999),
      showMarkers: true,
    );
    final marker = spans.cast<TextSpan>().firstWhere((s) => s.text == '**');
    expect(marker.style!.color, const Color(0xFF999999));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/markdown_inline_spans_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/presentation/widgets/markdown_inline_spans.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/presentation/widgets/markdown_inline_spans.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_inline.dart';

/// Builds the inline spans for a block of note text.
///
/// The active block calls this with [showMarkers] true so the user sees the
/// Markdown syntax dimmed in place. Rendered blocks call it with false. Both
/// share this function so content never shifts between the two states.
List<InlineSpan> buildMarkdownSpans({
  required String text,
  required TextStyle baseStyle,
  required Color markerColor,
  required bool showMarkers,
}) {
  final spans = <InlineSpan>[];
  for (final segment in tokenizeInline(text)) {
    if (segment.isMarker) {
      if (!showMarkers) continue;
      spans.add(
        TextSpan(text: segment.text, style: baseStyle.copyWith(color: markerColor)),
      );
      continue;
    }
    spans.add(TextSpan(text: segment.text, style: _styleFor(segment, baseStyle)));
  }
  if (spans.isEmpty) spans.add(TextSpan(text: '', style: baseStyle));
  return spans;
}

TextStyle _styleFor(MarkdownInlineSegment segment, TextStyle baseStyle) {
  var style = baseStyle;
  if (segment.styles.contains(MarkdownInlineStyle.bold)) {
    style = style.copyWith(fontWeight: FontWeight.w700);
  }
  if (segment.styles.contains(MarkdownInlineStyle.italic)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  if (segment.styles.contains(MarkdownInlineStyle.strikethrough)) {
    style = style.copyWith(decoration: TextDecoration.lineThrough);
  }
  if (segment.styles.contains(MarkdownInlineStyle.code)) {
    style = style.copyWith(fontFamily: 'monospace');
  }
  if (segment.styles.contains(MarkdownInlineStyle.link)) {
    style = style.copyWith(decoration: TextDecoration.underline);
  }
  return style;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/markdown_inline_spans_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/markdown_inline_spans.dart test/widget/markdown_inline_spans_test.dart
git commit -m "feat(notas): motor compartido de estilos inline"
```

---

## Task 9: Vista de bloque renderizado con casilla tocable

**Files:**
- Create: `lib/presentation/widgets/note_block_view.dart`
- Test: `test/widget/note_block_view_test.dart`

**Interfaces:**
- Consumes: `MarkdownBlock`, `buildMarkdownSpans`.
- Produces: `class NoteBlockView extends StatelessWidget` con parámetros
  `MarkdownBlock block`, `int? displayNumber`, `VoidCallback? onToggleCheck`,
  `ValueChanged<int>? onTapAtOffset`.
- Produces: `TextStyle noteBlockTextStyle(BuildContext context, MarkdownBlock block)`,
  usado también por el editor para que el estilo coincida.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_block_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/presentation/widgets/note_block_view.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders a heading without its marker', (tester) async {
    await tester.pumpWidget(
      host(NoteBlockView(block: MarkdownDocument.parse('## Examen').blocks.first)),
    );
    expect(find.textContaining('##'), findsNothing);
    expect(find.textContaining('Examen'), findsOneWidget);
  });

  testWidgets('checkbox reports taps and has a 44 point target',
      (tester) async {
    var toggled = 0;
    await tester.pumpWidget(
      host(
        NoteBlockView(
          block: MarkdownDocument.parse('- [ ] leer').blocks.first,
          onToggleCheck: () => toggled++,
        ),
      ),
    );
    final box = tester.getSize(find.byKey(const ValueKey('note-block-checkbox')));
    expect(box.width, greaterThanOrEqualTo(44));
    expect(box.height, greaterThanOrEqualTo(44));
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    expect(toggled, 1);
  });

  testWidgets('a checked item is struck through', (tester) async {
    await tester.pumpWidget(
      host(NoteBlockView(block: MarkdownDocument.parse('- [x] listo').blocks.first)),
    );
    final text = tester.widget<Text>(find.byKey(const ValueKey('note-block-text')));
    expect(
      (text.textSpan as TextSpan).children!.cast<TextSpan>().first.style!.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('numbered items use the display number, not the source',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteBlockView(
          block: MarkdownDocument.parse('1. uno').blocks.first,
          displayNumber: 4,
        ),
      ),
    );
    expect(find.text('4.'), findsOneWidget);
  });

  testWidgets('a divider renders a rule and no text', (tester) async {
    await tester.pumpWidget(
      host(NoteBlockView(block: MarkdownDocument.parse('---').blocks.first)),
    );
    expect(find.byKey(const ValueKey('note-block-divider')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_block_view_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/presentation/widgets/note_block_view.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/presentation/widgets/note_block_view.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_document.dart';
import '../design_tokens.dart';
import '../utils/feedback_utils.dart';
import 'markdown_inline_spans.dart';

/// Text style for a block, shared by the rendered view and the active editor
/// so switching between them never shifts the text.
TextStyle noteBlockTextStyle(BuildContext context, MarkdownBlock block) {
  final theme = Theme.of(context);
  final body = theme.textTheme.bodyLarge!.copyWith(height: 1.55);
  return switch (block.type) {
    MarkdownBlockType.heading => switch (block.headingLevel) {
        1 => theme.textTheme.headlineSmall!,
        2 => theme.textTheme.titleLarge!,
        _ => theme.textTheme.titleMedium!,
      },
    MarkdownBlockType.codeFence => body.copyWith(fontFamily: 'monospace'),
    MarkdownBlockType.quote =>
      body.copyWith(color: theme.colorScheme.onSurfaceVariant),
    _ => body,
  };
}

/// A single rendered block of a note. Not editable: the editor swaps this for
/// a text field on the block that holds the caret.
class NoteBlockView extends StatelessWidget {
  final MarkdownBlock block;
  final int? displayNumber;
  final VoidCallback? onToggleCheck;
  final ValueChanged<int>? onTapAtOffset;

  const NoteBlockView({
    required this.block,
    this.displayNumber,
    this.onToggleCheck,
    this.onTapAtOffset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (block.type == MarkdownBlockType.divider) {
      return Padding(
        key: const ValueKey('note-block-divider'),
        padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
        child: Divider(height: 1, color: colorScheme.outlineVariant),
      );
    }

    final style = noteBlockTextStyle(context, block);
    final spans = buildMarkdownSpans(
      text: block.type == MarkdownBlockType.codeFence
          ? block.codeLines.join('\n')
          : block.text,
      baseStyle: block.checked
          ? style.copyWith(
              decoration: TextDecoration.lineThrough,
              color: colorScheme.onSurfaceVariant,
            )
          : style,
      markerColor: colorScheme.onSurfaceVariant,
      showMarkers: false,
    );

    final text = Text.rich(
      TextSpan(children: spans),
      key: const ValueKey('note-block-text'),
    );

    final content = _withLeadingAffordance(context, text);
    return Semantics(
      header: block.type == MarkdownBlockType.heading,
      checked: block.type == MarkdownBlockType.checkItem ? block.checked : null,
      child: Padding(
        padding: EdgeInsets.only(
          left: block.indentLevel * context.spacing.md,
          top: context.spacing.xxs,
          bottom: context.spacing.xxs,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapAtOffset == null
              ? null
              : (details) => onTapAtOffset!(
                    _offsetForTap(context, details.localPosition, spans),
                  ),
          child: content,
        ),
      ),
    );
  }

  Widget _withLeadingAffordance(BuildContext context, Widget text) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (block.type) {
      case MarkdownBlockType.checkItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: const ValueKey('note-block-checkbox'),
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onToggleCheck == null
                    ? null
                    : () {
                        triggerHaptic(HapticType.light);
                        onToggleCheck!();
                      },
                customBorder: const CircleBorder(),
                child: Icon(
                  block.checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: block.checked
                      ? context.zentraPalette.brandTeal
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: context.spacing.sm),
                child: text,
              ),
            ),
          ],
        );
      case MarkdownBlockType.bulletItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: context.spacing.xs),
              child: Text('•', style: noteBlockTextStyle(context, block)),
            ),
            Expanded(child: text),
          ],
        );
      case MarkdownBlockType.numberedItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: context.spacing.xs),
              child: Text(
                '${displayNumber ?? 1}.',
                style: noteBlockTextStyle(context, block),
              ),
            ),
            Expanded(child: text),
          ],
        );
      case MarkdownBlockType.quote:
        return Container(
          padding: EdgeInsets.only(left: context.spacing.sm),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant, width: 3),
            ),
          ),
          child: text,
        );
      case MarkdownBlockType.codeFence:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(context.radii.small),
          ),
          child: text,
        );
      default:
        return text;
    }
  }

  /// Maps a tap inside the rendered text to an offset on the source line, so
  /// entering edit mode lands the caret where the user actually pointed.
  int _offsetForTap(
    BuildContext context,
    Offset localPosition,
    List<InlineSpan> spans,
  ) {
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: context.size?.width ?? double.infinity);
    final visibleOffset = painter.getPositionForOffset(localPosition).offset;
    painter.dispose();
    final prefixLength = block.leading.length + block.prefix.length;
    final maximum = block.toSourceLine().length;
    final candidate = prefixLength + visibleOffset;
    return candidate > maximum ? maximum : candidate;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_block_view_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/note_block_view.dart test/widget/note_block_view_test.dart
git commit -m "feat(notas): bloques renderizados con casillas tocables"
```

---

## Task 10: Editor de bloque enfocado

**Files:**
- Create: `lib/presentation/widgets/note_block_editor.dart`
- Test: `test/widget/note_block_editor_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument`, `DocumentCaret`, `splitBlock`,
  `mergeWithPrevious`, `changeIndent`, `NoteBlockView`, `noteBlockTextStyle`,
  `buildMarkdownSpans`.
- Produces: `class NoteBlockEditor extends StatefulWidget` con
  `MarkdownDocument document`, `ValueChanged<MarkdownDocument> onChanged`,
  `ValueChanged<DocumentCaret?> onCaretChanged`, `bool readOnly`,
  `NoteBlockEditorController controller`.
- Produces: `class NoteBlockEditorController` con
  `void focusBlock(int index, {int offset = 0})`,
  `DocumentCaret? get caret`, `TextSelection? get selection`.

**Nota de implementación crítica.** El teclado de software de iOS y Android no
emite eventos de tecla para Retroceso, así que un `onKeyEvent` solo funciona con
teclado físico. Para detectar Retroceso al inicio de un bloque se antepone un
espacio de ancho cero `\u200B` al contenido del campo activo. Ese carácter nunca
llega al documento: se retira al leer. Si desaparece, el usuario presionó
Retroceso en la primera posición y se funde con el bloque anterior.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_block_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/presentation/widgets/note_block_editor.dart';

void main() {
  late MarkdownDocument document;

  Widget host() => MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteBlockEditor(
              document: document,
              onChanged: (next) => setState(() => document = next),
              onCaretChanged: (_) {},
            ),
          ),
        ),
      );

  testWidgets('tapping a block turns it into a raw text field',
      (tester) async {
    document = MarkdownDocument.parse('## Examen\ncuerpo');
    await tester.pumpWidget(host());
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.textContaining('Examen'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.replaceAll('\u200B', ''), '## Examen');
  });

  testWidgets('typing rewrites only the active block', (tester) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '\u200B# uno');
    await tester.pumpAndSettle();

    expect(document.serialize(), '# uno\ndos');
    expect(document.blocks.first.type, MarkdownBlockType.heading);
  });

  testWidgets('submitting splits the block and moves the caret down',
      (tester) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    await tester.tap(find.textContaining('leer'));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(document.serialize(), '- leer\n- ');
  });

  testWidgets('losing the sentinel merges with the previous block',
      (tester) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('dos'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'dos');
    await tester.pumpAndSettle();

    expect(document.serialize(), 'unodos');
  });

  testWidgets('read only mode never shows a text field', (tester) async {
    document = MarkdownDocument.parse('uno');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteBlockEditor(
            document: document,
            readOnly: true,
            onChanged: (_) {},
            onCaretChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_block_editor_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/presentation/widgets/note_block_editor.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/presentation/widgets/note_block_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/markdown_document.dart';
import '../../domain/markdown_editing.dart';
import '../design_tokens.dart';
import 'markdown_inline_spans.dart';
import 'note_block_view.dart';

/// Zero width space used to detect Backspace at offset zero on soft keyboards,
/// which do not emit key events. It never reaches the document.
const _sentinel = '\u200B';

/// Lets the owning screen move the caret, for example after a toolbar command.
class NoteBlockEditorController extends ChangeNotifier {
  _NoteBlockEditorState? _state;

  DocumentCaret? get caret => _state?._caret;

  TextSelection? get selection => _state?._fieldController.selection;

  void focusBlock(int index, {int offset = 0}) {
    _state?._activate(index, offset: offset);
  }
}

/// Renders a note body as blocks, turning the block under the caret into a raw
/// Markdown text field.
class NoteBlockEditor extends StatefulWidget {
  final MarkdownDocument document;
  final ValueChanged<MarkdownDocument> onChanged;
  final ValueChanged<DocumentCaret?> onCaretChanged;
  final NoteBlockEditorController? controller;
  final bool readOnly;

  const NoteBlockEditor({
    required this.document,
    required this.onChanged,
    required this.onCaretChanged,
    this.controller,
    this.readOnly = false,
    super.key,
  });

  @override
  State<NoteBlockEditor> createState() => _NoteBlockEditorState();
}

class _NoteBlockEditorState extends State<NoteBlockEditor> {
  final TextEditingController _fieldController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int? _activeIndex;
  bool _applyingRemoteChange = false;

  DocumentCaret? get _caret => _activeIndex == null
      ? null
      : DocumentCaret(
          blockIndex: _activeIndex!,
          offset: _sourceOffset(_fieldController.selection.baseOffset),
        );

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _fieldController.addListener(_onFieldChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _fieldController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var number = 0;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.document.blocks.length,
      itemBuilder: (context, index) {
        final block = widget.document.blocks[index];
        if (block.type == MarkdownBlockType.numberedItem) {
          number++;
        } else {
          number = 0;
        }
        if (index == _activeIndex && !widget.readOnly) {
          return _buildField(context, block);
        }
        return NoteBlockView(
          key: ValueKey('note-block-$index'),
          block: block,
          displayNumber: number == 0 ? null : number,
          onToggleCheck: block.type == MarkdownBlockType.checkItem
              ? () => widget.onChanged(
                    widget.document.replaceBlock(index, block.toggleChecked()),
                  )
              : null,
          onTapAtOffset:
              widget.readOnly ? null : (offset) => _activate(index, offset: offset),
        );
      },
    );
  }

  Widget _buildField(BuildContext context, MarkdownBlock block) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = noteBlockTextStyle(context, block);
    return Padding(
      padding: EdgeInsets.only(
        left: block.indentLevel * context.spacing.md,
        top: context.spacing.xxs,
        bottom: context.spacing.xxs,
      ),
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: TextField(
          key: const ValueKey('note-active-block'),
          controller: _fieldController,
          focusNode: _focusNode,
          style: style,
          maxLines: 1,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _split(),
          cursorColor: context.zentraPalette.brandTeal,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintText: widget.document.blocks.length == 1 ? 'Escribe aquí…' : null,
            hintStyle: style.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final caret = _caret;
      if (caret == null) return KeyEventResult.ignored;
      final increase = !HardwareKeyboard.instance.isShiftPressed;
      _applyEdit(changeIndent(widget.document, caret, increase: increase));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _fieldController.selection.baseOffset <= _sentinel.length) {
      _merge();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _activate(int index, {int offset = 0}) {
    if (widget.readOnly) return;
    setState(() => _activeIndex = index);
    _applyingRemoteChange = true;
    final source = widget.document.blocks[index].toSourceLine();
    final clamped = offset > source.length ? source.length : offset;
    _fieldController.value = TextEditingValue(
      text: '$_sentinel$source',
      selection: TextSelection.collapsed(offset: _sentinel.length + clamped),
    );
    _applyingRemoteChange = false;
    _focusNode.requestFocus();
    widget.onCaretChanged(_caret);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;
    setState(() => _activeIndex = null);
    widget.onCaretChanged(null);
  }

  void _onFieldChanged() {
    if (_applyingRemoteChange) return;
    final index = _activeIndex;
    if (index == null) return;
    if (!_fieldController.text.startsWith(_sentinel)) {
      _merge();
      return;
    }
    final source = _fieldController.text.substring(_sentinel.length);
    final parsed = MarkdownDocument.parse(source).blocks.first;
    if (parsed == widget.document.blocks[index]) {
      widget.onCaretChanged(_caret);
      return;
    }
    widget.onChanged(widget.document.replaceBlock(index, parsed));
    widget.onCaretChanged(_caret);
  }

  void _split() {
    final caret = _caret;
    if (caret == null) return;
    _applyEdit(splitBlock(widget.document, caret));
  }

  void _merge() {
    final index = _activeIndex;
    if (index == null) return;
    final caret = DocumentCaret(blockIndex: index, offset: 0);
    if (index == 0) {
      _activate(0, offset: 0);
      return;
    }
    _applyEdit(mergeWithPrevious(widget.document, caret));
  }

  void _applyEdit(DocumentEdit edit) {
    widget.onChanged(edit.document);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activate(edit.caret.blockIndex, offset: edit.caret.offset);
    });
  }

  int _sourceOffset(int fieldOffset) {
    final value = fieldOffset - _sentinel.length;
    return value < 0 ? 0 : value;
  }
}
```

Nota: los marcadores atenuados del bloque activo se agregan en la Tarea 11
mediante un `TextEditingController` derivado, porque requieren la barra de
formato para probarse en conjunto. Hasta aquí el bloque activo muestra la
sintaxis en el color normal.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_block_editor_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/note_block_editor.dart test/widget/note_block_editor_test.dart
git commit -m "feat(notas): editor de bloque enfocado con un solo controller"
```

---

## Task 11: Controller de resaltado y barra de formato contextual

**Files:**
- Create: `lib/presentation/widgets/markdown_highlight_controller.dart`
- Create: `lib/presentation/widgets/note_format_bar.dart`
- Modify: `lib/presentation/widgets/note_block_editor.dart`
- Test: `test/widget/note_format_bar_test.dart`

**Interfaces:**
- Consumes: `buildMarkdownSpans`, `NoteBlockCommand`, `activeCommandFor`.
- Produces: `class MarkdownHighlightController extends TextEditingController`
  con campo `Color markerColor`.
- Produces: `class NoteFormatBar extends StatelessWidget` con
  `NoteBlockCommand? activeCommand`, `ValueChanged<NoteBlockCommand> onCommand`,
  `VoidCallback? onBold`, `VoidCallback? onItalic`, `VoidCallback? onUndo`,
  `VoidCallback? onRedo`, `bool visible`.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_format_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/presentation/widgets/markdown_highlight_controller.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';

void main() {
  testWidgets('the bar is hidden until the body has focus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(visible: false, onCommand: (_) {}),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  });

  testWidgets('reports the pressed command and marks the active one',
      (tester) async {
    NoteBlockCommand? pressed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(
            visible: true,
            activeCommand: NoteBlockCommand.checklist,
            onCommand: (command) => pressed = command,
          ),
        ),
      ),
    );
    final active = tester.widget<IconButton>(
      find.byKey(const ValueKey('note-format-checklist')),
    );
    expect(active.isSelected, isTrue);

    await tester.tap(find.byKey(const ValueKey('note-format-heading')));
    expect(pressed, NoteBlockCommand.heading);
  });

  testWidgets('the highlight controller dims markers without hiding them',
      (tester) async {
    final controller = MarkdownHighlightController(
      markerColor: const Color(0xFF999999),
    )..text = 'a **b**';
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: false,
              ) as TextSpan;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final flat = span.children!.cast<TextSpan>();
    expect(flat.map((s) => s.text).join(), 'a **b**');
    expect(
      flat.firstWhere((s) => s.text == '**').style!.color,
      const Color(0xFF999999),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_format_bar_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/presentation/widgets/note_format_bar.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/presentation/widgets/markdown_highlight_controller.dart
import 'package:flutter/material.dart';

import 'markdown_inline_spans.dart';

/// Paints the active block's raw Markdown with dimmed markers, using the same
/// span engine as the rendered blocks so the text never shifts.
class MarkdownHighlightController extends TextEditingController {
  Color markerColor;

  MarkdownHighlightController({required this.markerColor, super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    return TextSpan(
      style: base,
      children: buildMarkdownSpans(
        text: text,
        baseStyle: base,
        markerColor: markerColor,
        showMarkers: true,
      ),
    );
  }
}
```

```dart
// lib/presentation/widgets/note_format_bar.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_editing.dart';
import '../design_tokens.dart';

const _commandIcons = <NoteBlockCommand, (IconData, String)>{
  NoteBlockCommand.heading: (Icons.title_rounded, 'Encabezado'),
  NoteBlockCommand.bullet: (Icons.format_list_bulleted_rounded, 'Lista'),
  NoteBlockCommand.numbered: (Icons.format_list_numbered_rounded, 'Lista numerada'),
  NoteBlockCommand.checklist: (Icons.checklist_rounded, 'Casilla'),
  NoteBlockCommand.quote: (Icons.format_quote_rounded, 'Cita'),
  NoteBlockCommand.code: (Icons.code_rounded, 'Código'),
  NoteBlockCommand.divider: (Icons.horizontal_rule_rounded, 'Separador'),
};

/// Formatting bar that only exists while the body has focus and sits above the
/// software keyboard.
class NoteFormatBar extends StatelessWidget {
  final bool visible;
  final NoteBlockCommand? activeCommand;
  final ValueChanged<NoteBlockCommand> onCommand;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const NoteFormatBar({
    required this.visible,
    required this.onCommand,
    this.activeCommand,
    this.onBold,
    this.onItalic,
    this.onUndo,
    this.onRedo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Formato de nota',
      child: Container(
        key: const ValueKey('note-format-bar'),
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.xs,
          vertical: context.spacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final entry in _commandIcons.entries)
                IconButton(
                  key: ValueKey('note-format-${entry.key.name}'),
                  tooltip: entry.value.$2,
                  isSelected: activeCommand == entry.key,
                  selectedIcon: Icon(
                    entry.value.$1,
                    color: context.zentraPalette.brandTeal,
                  ),
                  onPressed: () => onCommand(entry.key),
                  icon: Icon(entry.value.$1),
                ),
              const VerticalDivider(width: 1),
              IconButton(
                key: const ValueKey('note-format-bold'),
                tooltip: 'Negritas',
                onPressed: onBold,
                icon: const Icon(Icons.format_bold_rounded),
              ),
              IconButton(
                key: const ValueKey('note-format-italic'),
                tooltip: 'Cursiva',
                onPressed: onItalic,
                icon: const Icon(Icons.format_italic_rounded),
              ),
              const VerticalDivider(width: 1),
              IconButton(
                key: const ValueKey('note-format-undo'),
                tooltip: 'Deshacer',
                onPressed: onUndo,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                key: const ValueKey('note-format-redo'),
                tooltip: 'Rehacer',
                onPressed: onRedo,
                icon: const Icon(Icons.redo_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

En `note_block_editor.dart`, cambia la declaración del controller para usar el
resaltado:

```dart
  late final MarkdownHighlightController _fieldController =
      MarkdownHighlightController(markerColor: const Color(0x00000000));
```

y al principio de `_buildField`, antes de construir el `TextField`:

```dart
    _fieldController.markerColor = colorScheme.onSurfaceVariant;
```

Agrega el import correspondiente:

```dart
import 'markdown_highlight_controller.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_format_bar_test.dart test/widget/note_block_editor_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/markdown_highlight_controller.dart lib/presentation/widgets/note_format_bar.dart lib/presentation/widgets/note_block_editor.dart test/widget/note_format_bar_test.dart
git commit -m "feat(notas): marcadores atenuados y barra de formato contextual"
```

---

## Task 12: Superficie única de nota

**Files:**
- Create: `lib/presentation/note_surface.dart`
- Create: `lib/presentation/widgets/note_details_panel.dart`
- Test: `test/widget/note_surface_test.dart`

**Interfaces:**
- Consumes: `NoteBlockEditor`, `NoteBlockEditorController`, `NoteFormatBar`,
  `MarkdownUndoHistory`, `noteControllerProvider`, `activeOwnerIdProvider`.
- Produces: `class NoteSurface extends ConsumerStatefulWidget` con
  `String? noteId`, `bool startInWriting`.
- Produces: `class NoteDetailsPanel extends StatelessWidget` con
  `VoidCallback onReminder`, `VoidCallback? onFocus`,
  `TextEditingController tagsController`, `String accentKey`,
  `ValueChanged<String> onAccentChanged`, `bool isPinned`,
  `VoidCallback? onTogglePin`.

Reglas de comportamiento que los tests fijan:

- Estado inicial: lectura si `noteId` existe, escritura si es nota nueva.
- Guardado forzado al cambiar de bloque, además del debounce de 700 ms que ya
  existe en el editor actual.
- Banner de H1 cuando el título está vacío y el primer bloque es encabezado
  nivel 1; al elegir cualquier acción no vuelve a aparecer para esa nota.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_surface_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  testWidgets('an existing note opens in reading mode', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  });

  testWidgets('tapping the body enters writing mode and shows the bar',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-active-block')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);
  });

  testWidgets('a new note starts in writing mode with the title focused',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(buildApp(harness, const NoteSurface()));
    await tester.pumpAndSettle();

    final title = tester.widget<TextField>(
      find.byKey(const ValueKey('note-title-field')),
    );
    expect(title.focusNode!.hasFocus, isTrue);
  });

  testWidgets('changing block saves without waiting for the debounce',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      '\u200B# Nuevo encabezado',
    );
    await tester.tap(find.byKey(const ValueKey('note-block-1')));
    await tester.pump();

    expect(
      harness.noteById(harness.algebraId).body.startsWith('# Nuevo encabezado'),
      isTrue,
    );
  });

  testWidgets('offers the first H1 as the title only once', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(
      noteTitle: '',
      noteBody: '# Desde un archivo\ncontenido',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-h1-banner')), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-h1-banner')), findsNothing);
  });
}
```

`OwnerBoundWidgetHarness` todavía no expone lo que estos tests necesitan.
Agrégale en este mismo paso, en `test/support/owner_bound_widget_harness.dart`,
exactamente tres cosas:

```dart
  static Future<OwnerBoundWidgetHarness> create({
    String noteTitle = 'Álgebra lineal',
    String noteBody = 'Repasar transformaciones lineales.',
  }) async {
    // pasa noteTitle y noteBody al Note semilla con id algebraId
  }

  /// Reads a note straight from the repository, bypassing the widget tree.
  Note noteById(String id) =>
      container.read(noteControllerProvider(ownerId)).value!.getNote(id)!;
```

Los llamadores actuales de `create()` no pasan argumentos, así que los valores
por defecto mantienen verde `test/widget/notes_screen_test.dart` sin tocarlo.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_surface_test.dart`
Expected: FAIL con `Couldn't resolve the package 'zentra/presentation/note_surface.dart'`.

- [ ] **Step 3: Write the implementation**

Crea `lib/presentation/note_surface.dart` con esta estructura. Es la única
pantalla de nota: reemplaza a `NoteEditorScreen` y al cuerpo de
`NoteDetailSurface`.

```dart
// lib/presentation/note_surface.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/note_controller.dart';
import '../application/note_state.dart';
import '../application/session_controller.dart';
import '../domain/markdown_document.dart';
import '../domain/markdown_editing.dart';
import '../domain/markdown_inline.dart';
import '../domain/markdown_undo_history.dart';
import '../domain/note_models.dart';
import 'design_tokens.dart';
import 'note_reminder_screen.dart';
import 'pomodoro_screen.dart';
import 'utils/page_transitions.dart';
import 'widgets/note_block_editor.dart';
import 'widgets/note_details_panel.dart';
import 'widgets/note_format_bar.dart';
import 'widgets/notes_components.dart';
import 'widgets/responsive_layout.dart';

/// A note, readable and writable in the same place.
class NoteSurface extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteSurface({this.noteId, super.key});

  @override
  ConsumerState<NoteSurface> createState() => _NoteSurfaceState();
}

class _NoteSurfaceState extends ConsumerState<NoteSurface> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final NoteBlockEditorController _editorController = NoteBlockEditorController();
  final MarkdownUndoHistory _undo = MarkdownUndoHistory();

  MarkdownDocument _document = MarkdownDocument.parse('');
  DocumentCaret? _caret;
  Timer? _saveDebounce;
  Note? _note;
  String? _ownerId;
  String _accentKey = 'mint';
  NoteSaveVisualState _saveState = NoteSaveVisualState.idle;
  bool _initialized = false;
  bool _writing = false;
  bool _dirty = false;
  bool _saving = false;
  bool _h1BannerDismissed = false;

  bool get _showsH1Banner =>
      !_h1BannerDismissed &&
      _titleController.text.trim().isEmpty &&
      _document.blocks.isNotEmpty &&
      _document.blocks.first.type == MarkdownBlockType.heading &&
      _document.blocks.first.headingLevel == 1;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _titleController.dispose();
    _tagsController.dispose();
    _titleFocus.dispose();
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOwnerId = ref.watch(activeOwnerIdProvider);
    final ownerId = _ownerId ?? activeOwnerId;
    final state = ownerId == null
        ? null
        : ref.watch(noteControllerProvider(ownerId)).valueOrNull;
    if (!_initialized && ownerId != null && state != null) {
      _initialize(ownerId, state);
    }
    if (!_initialized) {
      return const Scaffold(
        key: ValueKey('note-surface'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: const ValueKey('note-surface'),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: _close,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: NoteSaveStatus(state: _saveState, onRetry: _saveNow),
        centerTitle: false,
        actions: [
          IconButton(
            key: const ValueKey('note-reminder-action'),
            tooltip: 'Recordatorio',
            onPressed: _openReminder,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            key: const ValueKey('note-details-action'),
            tooltip: 'Detalles de la nota',
            onPressed: _openDetails,
            icon: const Icon(Icons.tune_rounded),
          ),
          if (_writing)
            TextButton(
              key: const ValueKey('note-done'),
              onPressed: _stopWriting,
              child: const Text('Listo'),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: NoteFormatBar(
          visible: _writing,
          activeCommand: _caret == null
              ? null
              : activeCommandFor(_document.blocks[_caret!.blockIndex]),
          onCommand: _applyCommand,
          onBold: () => _wrap(MarkdownInlineStyle.bold),
          onItalic: () => _wrap(MarkdownInlineStyle.italic),
          onUndo: _undo.canUndo ? _performUndo : null,
          onRedo: _undo.canRedo ? _performRedo : null,
        ),
      ),
      body: ResponsiveLayoutBuilder(
        builder: (context, layout) => Padding(
          padding: EdgeInsets.fromLTRB(
            layout.horizontalPagePadding,
            layout.verticalPagePadding,
            layout.horizontalPagePadding,
            context.spacing.md,
          ),
          child: ResponsiveContentFrame(
            maxWidth: 760,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextField(
                  key: const ValueKey('note-title-field'),
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _markDirty(),
                  decoration: const InputDecoration(
                    hintText: 'Título de la nota',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_showsH1Banner) _buildH1Banner(context),
                SizedBox(height: context.spacing.sm),
                NoteBlockEditor(
                  document: _document,
                  controller: _editorController,
                  readOnly: false,
                  onChanged: _onDocumentChanged,
                  onCaretChanged: _onCaretChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildH1Banner(BuildContext context) {
    return Card(
      key: const ValueKey('note-h1-banner'),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta nota empieza con un encabezado.'),
            SizedBox(height: context.spacing.xs),
            Row(
              children: [
                TextButton(
                  onPressed: _useH1AsTitle,
                  child: const Text('Usar como título'),
                ),
                TextButton(
                  onPressed: () => setState(() => _h1BannerDismissed = true),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _initialize(String ownerId, NoteState state) {
    _initialized = true;
    _ownerId = ownerId;
    final noteId = widget.noteId;
    if (noteId != null) {
      final note = state.getNote(noteId);
      if (note != null) {
        _note = note;
        _titleController.text = note.title;
        _tagsController.text = note.tags.join(', ');
        _accentKey = note.accentKey;
        _document = MarkdownDocument.parse(note.body);
      }
    }
    _undo.record(_document.serialize());
    if (_note == null) {
      _writing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  void _onDocumentChanged(MarkdownDocument document) {
    _undo.record(_document.serialize());
    // Checking a box is a deliberate act with no follow up typing, so it skips
    // the debounce and lands on disk right away.
    final tickedBox = document.checkedCount != _document.checkedCount &&
        document.checkItemCount == _document.checkItemCount;
    setState(() => _document = document);
    if (tickedBox) {
      _saveDebounce?.cancel();
      setState(() {
        _dirty = true;
        _saveState = NoteSaveVisualState.saving;
      });
      unawaited(_saveNow());
      return;
    }
    _markDirty();
  }

  void _onCaretChanged(DocumentCaret? caret) {
    final movedBlock = caret?.blockIndex != _caret?.blockIndex;
    setState(() {
      _caret = caret;
      _writing = caret != null || _writing;
    });
    if (movedBlock && _dirty) unawaited(_saveNow());
  }

  void _markDirty() {
    _saveDebounce?.cancel();
    setState(() {
      _dirty = true;
      _saveState = NoteSaveVisualState.saving;
    });
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  void _applyCommand(NoteBlockCommand command) {
    final caret = _caret;
    if (caret == null) return;
    final edit = applyBlockCommand(_document, caret, command);
    _onDocumentChanged(edit.document);
    _editorController.focusBlock(edit.caret.blockIndex, offset: edit.caret.offset);
  }

  void _wrap(MarkdownInlineStyle style) {
    final caret = _caret;
    final selection = _editorController.selection;
    if (caret == null || selection == null || selection.isCollapsed) return;
    final edit = wrapSelection(
      _document,
      caret.blockIndex,
      selection.start - 1,
      selection.end - 1,
      style,
    );
    _onDocumentChanged(edit.document);
    _editorController.focusBlock(edit.caret.blockIndex, offset: edit.caret.offset);
  }

  void _performUndo() {
    final restored = _undo.undo(_document.serialize());
    if (restored == null) return;
    setState(() => _document = MarkdownDocument.parse(restored));
    _markDirty();
  }

  void _performRedo() {
    final restored = _undo.redo();
    if (restored == null) return;
    setState(() => _document = MarkdownDocument.parse(restored));
    _markDirty();
  }

  void _useH1AsTitle() {
    final first = _document.blocks.first;
    setState(() {
      _titleController.text = first.text;
      _document = _document.removeBlock(0);
      _h1BannerDismissed = true;
    });
    _markDirty();
  }

  void _stopWriting() {
    FocusScope.of(context).unfocus();
    setState(() => _writing = false);
    unawaited(_saveNow());
  }

  Future<bool> _saveNow() async {
    if (_saving) return false;
    final ownerId = _ownerId;
    if (ownerId == null) return false;
    final title = _titleController.text.trim();
    final body = _document.serialize();
    if (_note == null && title.isEmpty && body.trim().isEmpty) {
      setState(() {
        _dirty = false;
        _saveState = NoteSaveVisualState.idle;
      });
      return true;
    }
    _saveDebounce?.cancel();
    setState(() {
      _saving = true;
      _saveState = NoteSaveVisualState.saving;
    });
    final controller = ref.read(noteControllerProvider(ownerId).notifier);
    final tags = _tagsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    try {
      if (_note == null) {
        _note = await controller.createNote(
          title: title,
          body: body,
          tags: tags,
          accentKey: _accentKey,
        );
      } else {
        final updated = _note!.copyWith(
          title: title,
          body: body,
          tags: tags,
          accentKey: _accentKey,
          updatedAt: DateTime.now().toUtc(),
        );
        await controller.saveNote(updated);
        _note = updated;
      }
      if (!mounted) return true;
      setState(() {
        _dirty = false;
        _saveState = NoteSaveVisualState.saved;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _saveState = NoteSaveVisualState.error);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDetails() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => NoteDetailsPanel(
        tagsController: _tagsController,
        accentKey: _accentKey,
        isPinned: _note?.isPinned ?? false,
        onAccentChanged: (value) {
          setState(() => _accentKey = value);
          _markDirty();
        },
        onTogglePin: _note == null ? null : _togglePin,
        onFocus: _note == null ? null : _startFocus,
        onReminder: _openReminder,
      ),
    );
    _markDirty();
  }

  Future<void> _openReminder() async {
    final saved = await _saveNow();
    final note = _note;
    if (!saved || note == null || !mounted) return;
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(NoteReminderScreen(noteId: note.id)),
    );
  }

  Future<void> _startFocus() async {
    final note = _note;
    if (note == null) return;
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        PomodoroScreen(initialTitle: note.title, linkedNoteId: note.id),
      ),
    );
  }

  Future<void> _togglePin() async {
    final note = _note;
    final ownerId = _ownerId;
    if (note == null || ownerId == null) return;
    await ref.read(noteControllerProvider(ownerId).notifier).togglePin(note.id);
    if (mounted) setState(() => _note = note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> _close() async {
    final saved = await _saveNow();
    if (saved && mounted) Navigator.of(context).pop(_note?.id);
  }
}
```

Crea `lib/presentation/widgets/note_details_panel.dart` moviendo tal cual el
contenido del método `_buildTools` de `lib/presentation/note_editor_screen.dart`
líneas 293 a 381, junto con las clases privadas `_EditorToolTile`, `_AccentChoice`
y la constante `_accentOptions` de ese mismo archivo, renombrando la clase
pública a `NoteDetailsPanel` y recibiendo los callbacks del bloque de
Interfaces de esta tarea.

- [ ] **Step 4: Write the failing test for iPad and Reduced Motion**

```dart
// test/widget/note_surface_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    OwnerBoundWidgetHarness harness, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: buildApp(harness, NoteSurface(noteId: harness.algebraId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an expanded window shows the details as a side column',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await pumpAt(tester, harness, size: const Size(1180, 820));

    expect(find.byKey(const ValueKey('note-details-column')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-details-action')), findsNothing);
  });

  testWidgets('the side column can be collapsed', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await pumpAt(tester, harness, size: const Size(1180, 820));

    await tester.tap(find.byKey(const ValueKey('note-details-collapse')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
  });

  testWidgets('large text falls back to the bottom sheet action',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await pumpAt(tester, harness, size: const Size(1180, 820), textScale: 1.6);

    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-action')), findsOneWidget);
  });

  testWidgets('a compact window keeps the bottom sheet action', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await pumpAt(tester, harness, size: const Size(390, 844));

    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-action')), findsOneWidget);
  });

  testWidgets('Reduced Motion removes the format bar animation',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: buildApp(harness, NoteSurface(noteId: harness.algebraId)),
      ),
    );
    await tester.pumpAndSettle();

    final animated = tester.widget<AnimatedSize>(
      find.byKey(const ValueKey('note-format-bar-slot')),
    );
    expect(animated.duration, Duration.zero);
  });
}
```

- [ ] **Step 5: Make the responsive test pass**

Run: `flutter test test/widget/note_surface_responsive_test.dart`
Expected: FAIL con `Could not find a widget with key [<'note-details-column'>]`.

En `_NoteSurfaceState` agrega el estado del panel lateral:

```dart
  bool _detailsExpanded = true;
```

Envuelve la barra de formato para respetar Reduced Motion:

```dart
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: AnimatedSize(
          key: const ValueKey('note-format-bar-slot'),
          duration: context.motionPolicy.duration(
            const Duration(milliseconds: 180),
          ),
          alignment: Alignment.topCenter,
          child: NoteFormatBar(
            // los mismos parámetros de antes
          ),
        ),
      ),
```

Dentro de `ResponsiveLayoutBuilder`, decide la forma del panel y devuelve una
fila cuando cabe:

```dart
      body: ResponsiveLayoutBuilder(
        builder: (context, layout) {
          final usesSideColumn = layout.isExpanded &&
              MediaQuery.textScalerOf(context).scale(16) <= 23;
          final editor = Padding(
            // el Padding con ResponsiveContentFrame que ya existía
          );
          if (!usesSideColumn || !_detailsExpanded) return editor;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: editor),
              const VerticalDivider(width: 1),
              SizedBox(
                key: const ValueKey('note-details-column'),
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        key: const ValueKey('note-details-collapse'),
                        tooltip: 'Ocultar detalles',
                        onPressed: () =>
                            setState(() => _detailsExpanded = false),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(context.spacing.md),
                        child: _buildDetailsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
```

Haz que la acción del `AppBar` solo exista cuando el panel no está en columna, y
que sirva también para volver a mostrar la columna colapsada:

```dart
          if (!_usesSideColumn(context))
            IconButton(
              key: const ValueKey('note-details-action'),
              tooltip: 'Detalles de la nota',
              onPressed: _openDetails,
              icon: const Icon(Icons.tune_rounded),
            )
          else if (!_detailsExpanded)
            IconButton(
              key: const ValueKey('note-details-expand'),
              tooltip: 'Mostrar detalles',
              onPressed: () => setState(() => _detailsExpanded = true),
              icon: const Icon(Icons.tune_rounded),
            ),
```

Extrae el contenido compartido y el criterio de forma:

```dart
  bool _usesSideColumn(BuildContext context) =>
      ZentraBreakpoints.windowClassFor(MediaQuery.sizeOf(context).width)
          .isAtLeastExpanded &&
      MediaQuery.textScalerOf(context).scale(16) <= 23;

  Widget _buildDetailsPanel() => NoteDetailsPanel(
        tagsController: _tagsController,
        accentKey: _accentKey,
        isPinned: _note?.isPinned ?? false,
        onAccentChanged: (value) {
          setState(() => _accentKey = value);
          _markDirty();
        },
        onTogglePin: _note == null ? null : _togglePin,
        onFocus: _note == null ? null : _startFocus,
        onReminder: _openReminder,
      );
```

y usa `_buildDetailsPanel()` también dentro de `_openDetails`, para que la hoja
inferior y la columna nunca se desincronicen. Agrega los imports
`motion_policy.dart` y `widgets/responsive_layout.dart`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/widget/note_surface_test.dart test/widget/note_surface_responsive_test.dart`
Expected: PASS, 10 tests.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/note_surface.dart lib/presentation/widgets/note_details_panel.dart test/support/owner_bound_widget_harness.dart test/widget/note_surface_test.dart test/widget/note_surface_responsive_test.dart
git commit -m "feat(notas): superficie única de lectura y escritura"
```

---

## Task 13: Retirar `NoteEditorScreen`

**Files:**
- Delete: `lib/presentation/note_editor_screen.dart`
- Modify: `lib/main.dart:387`, `lib/main.dart:464`
- Modify: `lib/presentation/notes_screen.dart:405`, `:416`
- Modify: `lib/presentation/calendar_screen.dart:442`
- Modify: `lib/presentation/widgets/notes_components.dart` (retirar
  `NoteFormatToolbar`, `NoteFormatCommand` y el cuerpo plano de
  `NoteDetailSurface`)
- Modify: `integration_test/screen_reviewer_test.dart:701,704,710`
- Modify: `test/widget/notes_screen_test.dart:185,221`

**Interfaces:**
- Consumes: `NoteSurface` de la Tarea 12.
- Produces: ninguna API nueva. `NoteDetailSurface` conserva su firma pública
  pero renderiza el cuerpo con `NoteBlockEditor` en modo `readOnly`, envuelto en
  `SelectionArea`.

- [ ] **Step 1: Write the failing test**

En `test/widget/notes_screen_test.dart`, cambia las dos aserciones de
navegación:

```dart
    expect(find.byType(NoteSurface), findsOneWidget);
```

y agrega:

```dart
  testWidgets('no reference to the removed editor route remains',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notes-create-card')));
    await tester.pumpAndSettle();
    expect(find.byType(NoteSurface), findsOneWidget);
  });

  testWidgets('reading mode allows continuous selection', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SelectionArea), findsOneWidget);
  });
```

Actualiza el import a `package:zentra/presentation/note_surface.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/notes_screen_test.dart`
Expected: FAIL con `Undefined name 'NoteSurface'` antes de tocar el código de
producción.

- [ ] **Step 3: Write the implementation**

Sustituciones exactas:

```dart
// lib/main.dart:387
        builder: (_) => NoteSurface(noteId: noteId),

// lib/main.dart:464
            MaterialPageRoute(builder: (_) => const NoteSurface()),

// lib/presentation/notes_screen.dart:405
      PageTransitions.slideFromRight(const NoteSurface()),

// lib/presentation/notes_screen.dart:416
      PageTransitions.slideFromRight(NoteSurface(noteId: noteId)),

// lib/presentation/calendar_screen.dart:442
        NoteSurface(noteId: note.id),
```

En cada archivo cambia el import de `note_editor_screen.dart` por
`note_surface.dart`.

En `lib/presentation/widgets/notes_components.dart`, dentro de
`NoteDetailSurface`, sustituye el `SingleChildScrollView` con `SelectableText`
de las líneas 462 a 470 por:

```dart
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: NoteBlockEditor(
                    document: MarkdownDocument.parse(body),
                    readOnly: true,
                    onChanged: (_) {},
                    onCaretChanged: (_) {},
                  ),
                ),
              ),
            ),
```

Agrega los imports `../../domain/markdown_document.dart` y
`note_block_editor.dart`, y elimina del archivo las clases `NoteFormatToolbar` y
el enum `NoteFormatCommand`, que ya no tienen consumidores.

En `integration_test/screen_reviewer_test.dart` cambia las tres referencias de
`NoteEditorScreen` a `NoteSurface`.

Por último, borra `lib/presentation/note_editor_screen.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test && flutter analyze`
Expected: PASS y cero referencias restantes. Verifica con
`rg "NoteEditorScreen|NoteFormatToolbar" lib test integration_test`, que debe
devolver vacío.

- [ ] **Step 5: Commit**

```bash
git rm lib/presentation/note_editor_screen.dart
git add lib/main.dart \
  lib/presentation/notes_screen.dart \
  lib/presentation/calendar_screen.dart \
  lib/presentation/widgets/notes_components.dart \
  integration_test/screen_reviewer_test.dart \
  test/widget/notes_screen_test.dart
git commit -m "refactor(notas): retira NoteEditorScreen en favor de la superficie única"
```

---

## Task 14: Modo editar como texto

**Files:**
- Modify: `lib/presentation/note_surface.dart`
- Test: `test/widget/note_raw_mode_test.dart`

**Interfaces:**
- Consumes: `NoteSurface` de la Tarea 12.
- Produces: acción de menú con `ValueKey('note-raw-mode')` que alterna entre el
  editor de bloques y un `TextField` multilínea con la clave
  `ValueKey('note-raw-field')`.
- Produces: acción `ValueKey('note-copy-markdown')` que copia el cuerpo crudo
  completo al portapapeles, la mitigación que pide la sección 5.2 del spec para
  la falta de selección continua entre bloques.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_raw_mode_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  testWidgets('raw mode shows the whole body as plain Markdown',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(
      noteBody: '## Título\n- [ ] pendiente',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('note-raw-field')),
    );
    expect(field.controller!.text, '## Título\n- [ ] pendiente');
  });

  testWidgets('leaving raw mode keeps what was typed', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(noteBody: 'a');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-raw-field')),
      '# nuevo\ntexto',
    );
    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-raw-field')), findsNothing);
    expect(harness.noteById(harness.algebraId).body, '# nuevo\ntexto');
  });

  testWidgets('copies the raw Markdown to the clipboard', (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(
      noteBody: '## Título\n- [ ] pendiente',
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-copy-markdown')));
    await tester.pumpAndSettle();

    expect(copied, '## Título\n- [ ] pendiente');
  });
}
```

Agrega el import `package:flutter/services.dart` al archivo de prueba.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_raw_mode_test.dart`
Expected: FAIL con `Could not find a widget with key [<'note-raw-mode'>]`.

- [ ] **Step 3: Write the implementation**

En `_NoteSurfaceState` agrega el estado y el controller:

```dart
  final TextEditingController _rawController = TextEditingController();
  bool _rawMode = false;
```

recuérdalo en `dispose`:

```dart
    _rawController.dispose();
```

Agrega la acción en el `AppBar`, antes del botón de detalles:

```dart
          IconButton(
            key: const ValueKey('note-raw-mode'),
            tooltip: _rawMode ? 'Volver al editor' : 'Editar como texto',
            onPressed: _toggleRawMode,
            icon: Icon(_rawMode ? Icons.view_agenda_outlined : Icons.code_rounded),
          ),
```

Sustituye el `NoteBlockEditor` del cuerpo por:

```dart
                if (_rawMode)
                  TextField(
                    key: const ValueKey('note-raw-field'),
                    controller: _rawController,
                    maxLines: null,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontFamily: 'monospace', height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => _markDirty(),
                  )
                else
                  NoteBlockEditor(
                    document: _document,
                    controller: _editorController,
                    readOnly: false,
                    onChanged: _onDocumentChanged,
                    onCaretChanged: _onCaretChanged,
                  ),
```

Agrega también la acción de copiado, junto a la de modo texto:

```dart
          IconButton(
            key: const ValueKey('note-copy-markdown'),
            tooltip: 'Copiar Markdown',
            onPressed: _copyMarkdown,
            icon: const Icon(Icons.copy_all_rounded),
          ),
```

```dart
  Future<void> _copyMarkdown() async {
    final body = _rawMode ? _rawController.text : _document.serialize();
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown copiado.')),
    );
  }
```

con el import `package:flutter/services.dart` en `note_surface.dart`.

Y agrega el método:

```dart
  void _toggleRawMode() {
    setState(() {
      if (_rawMode) {
        _undo.record(_document.serialize());
        _document = MarkdownDocument.parse(_rawController.text);
        _rawMode = false;
      } else {
        _rawController.text = _document.serialize();
        _rawMode = true;
        _caret = null;
        _writing = true;
      }
    });
    unawaited(_saveNow());
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_raw_mode_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/note_surface.dart test/widget/note_raw_mode_test.dart
git commit -m "feat(notas): modo de edición en texto plano como válvula de escape"
```

- [ ] **Step 6: Cerrar Fase 2**

Run: `flutter test && flutter analyze && flutter build ios --release --no-codesign`
Expected: todo verde.

---

# Fase 3. Biblioteca

## Task 15: Tarjeta con vista previa legible y progreso

**Files:**
- Modify: `lib/presentation/widgets/notes_components.dart` (`NoteLibraryCard`)
- Modify: `lib/presentation/notes_screen.dart:318-345`
- Test: `test/widget/note_library_card_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument.previewText`, `checkedCount`, `checkItemCount`.
- Produces: `NoteLibraryCard` gana los parámetros `int checkedCount`,
  `int checkItemCount` y `String? highlightQuery`, y su parámetro `body` pasa a
  interpretarse como texto ya legible, no como Markdown crudo.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_library_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/notes_components.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows checklist progress when the note has boxes',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Examen',
          body: 'leer el capítulo',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          checkedCount: 3,
          checkItemCount: 7,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('3 de 7'), findsOneWidget);
    expect(find.byKey(const ValueKey('note-card-progress')), findsOneWidget);
  });

  testWidgets('hides progress when there are no boxes', (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Apunte',
          body: 'texto',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          onTap: () {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('note-card-progress')), findsNothing);
  });

  testWidgets('highlights the matched query inside the preview',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Bio',
          body: 'repasar mitosis con calma',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          highlightQuery: 'mitosis',
          onTap: () {},
        ),
      ),
    );
    final preview = tester.widget<Text>(
      find.byKey(const ValueKey('note-card-preview')),
    );
    final highlighted = (preview.textSpan as TextSpan)
        .children!
        .cast<TextSpan>()
        .firstWhere((span) => span.text == 'mitosis');
    expect(highlighted.style!.fontWeight, FontWeight.w700);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_library_card_test.dart`
Expected: FAIL con `No named parameter with the name 'checkedCount'`.

- [ ] **Step 3: Write the implementation**

En `NoteLibraryCard` agrega los tres campos nuevos con valores por defecto
`this.checkedCount = 0`, `this.checkItemCount = 0`, `this.highlightQuery`.
Sustituye el `Text` del cuerpo, líneas 288 a 297, por:

```dart
                        Text.rich(
                          TextSpan(
                            children: _highlightSpans(
                              context,
                              body.trim().isEmpty
                                  ? 'Todavía no hay contenido.'
                                  : body,
                            ),
                          ),
                          key: const ValueKey('note-card-preview'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (checkItemCount > 0) ...[
                          SizedBox(height: context.spacing.xs),
                          Row(
                            key: const ValueKey('note-card-progress'),
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    context.radii.pill,
                                  ),
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    value: checkedCount / checkItemCount,
                                    backgroundColor:
                                        context.zentraPalette.progressTrack,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(accent),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.spacing.xs),
                              Text(
                                '$checkedCount de $checkItemCount',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
```

y agrega el método privado a la clase:

```dart
  List<TextSpan> _highlightSpans(BuildContext context, String value) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final query = highlightQuery?.trim() ?? '';
    if (query.isEmpty) return [TextSpan(text: value, style: base)];
    final at = value.toLowerCase().indexOf(query.toLowerCase());
    if (at == -1) return [TextSpan(text: value, style: base)];
    return [
      TextSpan(text: value.substring(0, at), style: base),
      TextSpan(
        text: value.substring(at, at + query.length),
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      TextSpan(text: value.substring(at + query.length), style: base),
    ];
  }
```

En `notes_screen.dart`, sustituye el cuerpo completo de `_buildNoteCard`, líneas
317 a 345, por esto. La única diferencia real está en `body` y en los tres
parámetros nuevos, pero se repite entero para que no haya que adivinar nada:

```dart
    final reminder = state.getReminder(note.id);
    final document = MarkdownDocument.parse(note.body);
    final query = _query.trim();
    return NoteLibraryCard(
      key: ValueKey('note-card-${note.id}'),
      title: note.title,
      body: query.isEmpty
          ? document.previewText()
          : markdownExcerptAround(note.body, query),
      checkedCount: document.checkedCount,
      checkItemCount: document.checkItemCount,
      highlightQuery: query.isEmpty ? null : query,
      tag: note.tags.isEmpty ? note.category : note.tags.first,
      updatedLabel: _updatedLabel(note.updatedAt),
      reminderLabel: _reminderLabel(reminder),
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isSelected: selected,
      accent: _accentFor(note),
      onTap: () {
        controller.selectNote(note.id);
        if (opensEditor) {
          _openEditor(note.id);
        } else {
          setState(() => _selectedNoteId = note.id);
        }
      },
      onTogglePin: note.isArchived ? null : () => controller.togglePin(note.id),
      onToggleArchive: () {
        if (note.isArchived) {
          controller.restore(note.id);
        } else {
          controller.archive(note.id);
        }
      },
    );
```

Agrega el import `../domain/markdown_document.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_library_card_test.dart test/widget/notes_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/notes_components.dart lib/presentation/notes_screen.dart test/widget/note_library_card_test.dart
git commit -m "feat(notas): tarjeta con vista previa legible, progreso y resaltado"
```

---

## Task 16: Etiquetas como chips con autocompletado y filtro

**Files:**
- Create: `lib/presentation/widgets/note_tag_field.dart`
- Modify: `lib/presentation/widgets/note_details_panel.dart`
- Modify: `lib/presentation/notes_screen.dart`
- Modify: `lib/application/note_state.dart`
- Test: `test/widget/note_tag_field_test.dart`
- Test: `test/unit/note_state_tags_test.dart`

**Interfaces:**
- Consumes: `NoteState`, `normalizeNoteTags`.
- Produces: `List<String> NoteState.allTags` ordenada alfabéticamente y sin
  repetidos.
- Produces: `class NoteTagField extends StatefulWidget` con
  `List<String> value`, `List<String> suggestions`,
  `ValueChanged<List<String>> onChanged`.
- Produces: `NotesScreen` gana estado `String? _tagFilter` y un
  `NotesTagFilterBar` con clave `ValueKey('notes-tag-filter')`.

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/note_state_tags_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/note_state.dart';
import 'package:zentra/domain/note_models.dart';

void main() {
  test('allTags is sorted, deduplicated and normalized', () {
    final now = DateTime.utc(2026, 8, 3);
    final state = NoteState(
      ownerId: 'uri',
      notes: [
        Note(
          id: '1',
          userId: 'uri',
          title: 'a',
          body: '',
          createdAt: now,
          updatedAt: now,
          accentKey: 'mint',
          tags: const ['Examen', 'estudio'],
        ),
        Note(
          id: '2',
          userId: 'uri',
          title: 'b',
          body: '',
          createdAt: now,
          updatedAt: now,
          accentKey: 'mint',
          tags: const ['examen', 'bio'],
        ),
      ],
    );
    expect(state.allTags, ['bio', 'estudio', 'examen']);
  });
}
```

```dart
// test/widget/note_tag_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/note_tag_field.dart';

void main() {
  testWidgets('shows current tags as removable chips', (tester) async {
    var value = <String>['estudio', 'examen'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteTagField(
              value: value,
              suggestions: const ['bio'],
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(InputChip), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('note-tag-remove-examen')));
    await tester.pumpAndSettle();
    expect(value, ['estudio']);
  });

  testWidgets('suggests existing tags while typing', (tester) async {
    var value = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteTagField(
              value: value,
              suggestions: const ['biología', 'bitácora', 'estudio'],
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'bi');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-tag-suggestion-biología')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('note-tag-suggestion-estudio')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('note-tag-suggestion-biología')));
    await tester.pumpAndSettle();
    expect(value, ['biología']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/note_state_tags_test.dart test/widget/note_tag_field_test.dart`
Expected: FAIL con `The getter 'allTags' isn't defined` y
`Couldn't resolve the package 'zentra/presentation/widgets/note_tag_field.dart'`.

- [ ] **Step 3: Write the implementation**

En `lib/application/note_state.dart`, dentro de la clase `NoteState`:

```dart
  /// Every tag the owner has used, normalized and sorted for suggestions.
  List<String> get allTags {
    final values = <String>{};
    for (final note in notes) {
      values.addAll(note.tags);
    }
    final sorted = values.toList()..sort();
    return List.unmodifiable(sorted);
  }
```

```dart
// lib/presentation/widgets/note_tag_field.dart
import 'package:flutter/material.dart';

import '../../domain/note_models.dart';
import '../design_tokens.dart';

/// Tag editor with chips and suggestions taken from the owner's existing tags.
class NoteTagField extends StatefulWidget {
  final List<String> value;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  const NoteTagField({
    required this.value,
    required this.suggestions,
    required this.onChanged,
    super.key,
  });

  @override
  State<NoteTagField> createState() => _NoteTagFieldState();
}

class _NoteTagFieldState extends State<NoteTagField> {
  final TextEditingController _controller = TextEditingController();
  String _draft = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final draft = _draft.trim().toLowerCase();
    if (draft.isEmpty) return const [];
    return widget.suggestions
        .where((tag) => tag.startsWith(draft) && !widget.value.contains(tag))
        .take(5)
        .toList();
  }

  void _add(String raw) {
    final next = normalizeNoteTags([...widget.value, raw]);
    _controller.clear();
    setState(() => _draft = '');
    widget.onChanged(next);
  }

  void _remove(String tag) {
    widget.onChanged(widget.value.where((value) => value != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xs,
          children: [
            for (final tag in widget.value)
              InputChip(
                key: ValueKey('note-tag-chip-$tag'),
                label: Text(tag),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                deleteButtonTooltipMessage: 'Quitar $tag',
                onDeleted: () => _remove(tag),
                deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                onPressed: null,
              ),
          ],
        ),
        SizedBox(height: context.spacing.xs),
        TextField(
          key: const ValueKey('note-tag-input'),
          controller: _controller,
          textInputAction: TextInputAction.done,
          onChanged: (value) => setState(() => _draft = value),
          onSubmitted: _add,
          decoration: const InputDecoration(
            labelText: 'Etiquetas',
            hintText: 'estudio',
            prefixIcon: Icon(Icons.sell_outlined),
          ),
        ),
        if (_matches.isNotEmpty) ...[
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.xs,
            children: [
              for (final match in _matches)
                ActionChip(
                  key: ValueKey('note-tag-suggestion-$match'),
                  label: Text(match),
                  onPressed: () => _add(match),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
```

El botón de borrar de `InputChip` necesita una clave propia para el test, así
que envuélvelo así en lugar de usar `onDeleted` directo:

```dart
              InputChip(
                key: ValueKey('note-tag-chip-$tag'),
                label: Text(tag),
                onPressed: null,
                deleteIcon: IconButton(
                  key: ValueKey('note-tag-remove-$tag'),
                  tooltip: 'Quitar $tag',
                  onPressed: () => _remove(tag),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
                onDeleted: () => _remove(tag),
              ),
```

En `NoteDetailsPanel`, sustituye el `TextField` de etiquetas por `NoteTagField`,
recibiendo `List<String> tags`, `List<String> tagSuggestions` y
`ValueChanged<List<String>> onTagsChanged` en lugar del `TextEditingController`.

En `NoteSurface`, retira `_tagsController` y su `dispose`, y pon en su lugar:

```dart
  List<String> _tags = const [];
```

`_buildDetailsPanel`, creado en la Tarea 12, es el único lugar que construye el
panel, así que basta cambiarlo ahí para que la hoja inferior de iPhone y la
columna de iPad queden iguales:

```dart
  Widget _buildDetailsPanel() => NoteDetailsPanel(
        tags: _tags,
        tagSuggestions: _ownerId == null
            ? const []
            : ref
                    .watch(noteControllerProvider(_ownerId!))
                    .valueOrNull
                    ?.allTags ??
                const [],
        onTagsChanged: (next) {
          setState(() => _tags = next);
          _markDirty();
        },
        accentKey: _accentKey,
        isPinned: _note?.isPinned ?? false,
        onAccentChanged: (value) {
          setState(() => _accentKey = value);
          _markDirty();
        },
        onTogglePin: _note == null ? null : _togglePin,
        onFocus: _note == null ? null : _startFocus,
        onReminder: _openReminder,
      );
```

En `_initialize` cambia `_tagsController.text = note.tags.join(', ')` por
`_tags = note.tags`, y en `_saveNow` cambia el bloque que parte el texto por
comas por `final tags = _tags;`.

En `notes_screen.dart` agrega el filtro:

```dart
  String? _tagFilter;
```

dentro de `controls`, debajo de `NotesSectionSelector`:

```dart
                        if (noteState.allTags.isNotEmpty) ...[
                          SizedBox(height: context.spacing.sm),
                          SingleChildScrollView(
                            key: const ValueKey('notes-tag-filter'),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final tag in noteState.allTags)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: context.spacing.xs,
                                    ),
                                    child: FilterChip(
                                      key: ValueKey('notes-tag-filter-$tag'),
                                      label: Text(tag),
                                      selected: _tagFilter == tag,
                                      onSelected: (selected) => setState(
                                        () => _tagFilter = selected ? tag : null,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
```

y en `_visibleNotes`, dentro del `where`, después de la comprobación de sección:

```dart
      final tagFilter = _tagFilter;
      if (tagFilter != null && !note.tags.contains(tagFilter)) return false;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/note_state_tags_test.dart test/widget/note_tag_field_test.dart test/widget/notes_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/application/note_state.dart lib/presentation/widgets/note_tag_field.dart lib/presentation/widgets/note_details_panel.dart lib/presentation/note_surface.dart lib/presentation/notes_screen.dart test/unit/note_state_tags_test.dart test/widget/note_tag_field_test.dart
git commit -m "feat(notas): etiquetas como chips con autocompletado y filtro"
```

---

## Task 17: Confirmación de checklist completa

**Files:**
- Modify: `lib/presentation/note_surface.dart`
- Test: `test/widget/note_checklist_completion_test.dart`

**Interfaces:**
- Consumes: `MarkdownDocument.checkedCount`, `checkItemCount`.
- Produces: mensaje en línea con clave `ValueKey('note-checklist-complete')`,
  mostrado una sola vez por sesión de pantalla.

Reglas exactas: aparece cuando `checkItemCount > 0` y `checkedCount` pasa de ser
menor a igual que `checkItemCount`. No otorga XP ni logros. No se repite aunque
el usuario desmarque y vuelva a marcar en la misma sesión.

- [ ] **Step 1: Write the failing test**

```dart
// test/widget/note_checklist_completion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  testWidgets('shows a quiet message when the last box is checked',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(
      noteBody: '- [x] uno\n- [ ] dos',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-checklist-complete')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')).last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('note-checklist-complete')),
      findsOneWidget,
    );
  });

  testWidgets('does not repeat after unchecking and checking again',
      (tester) async {
    final harness = await OwnerBoundWidgetHarness.create(noteBody: '- [ ] uno');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-checklist-complete')), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/note_checklist_completion_test.dart`
Expected: FAIL en la primera aserción positiva, `findsNothing` donde se esperaba
un widget.

- [ ] **Step 3: Write the implementation**

En `_NoteSurfaceState` agrega:

```dart
  bool _checklistCelebrated = false;
  bool _showsChecklistComplete = false;
```

y dentro de `_onDocumentChanged`, antes del `setState`:

```dart
    final wasComplete = _document.checkItemCount > 0 &&
        _document.checkedCount == _document.checkItemCount;
    final isComplete = document.checkItemCount > 0 &&
        document.checkedCount == document.checkItemCount;
    final celebrates = isComplete && !wasComplete && !_checklistCelebrated;
    if (celebrates) _checklistCelebrated = true;
```

extendiendo el `setState` existente:

```dart
    setState(() {
      _document = document;
      _showsChecklistComplete = celebrates || _showsChecklistComplete;
    });
```

Agrega el mensaje al cuerpo, justo debajo del editor de bloques:

```dart
                if (_showsChecklistComplete)
                  Padding(
                    key: const ValueKey('note-checklist-complete'),
                    padding: EdgeInsets.only(top: context.spacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: context.zentraPalette.brandTeal,
                        ),
                        SizedBox(width: context.spacing.xs),
                        Expanded(
                          child: Text(
                            'Terminaste todo lo de esta nota.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
```

No agregues XP, logros, sonido ni animación: el plan maestro 5.12 lo prohíbe.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/note_checklist_completion_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/note_surface.dart test/widget/note_checklist_completion_test.dart
git commit -m "feat(notas): confirmación tranquila al terminar una checklist"
```

---

# Fase 4. Cierre

## Task 18: Capturas, accesibilidad y verificación final

**Files:**
- Modify: `integration_test/screen_reviewer_test.dart`
- Modify: `docs/zentra-salvia-screen-tracker.md`

**Interfaces:**
- Consumes: todas las tareas anteriores.
- Produces: capturas nuevas de Notas en `build/screen-review/`, y el tracker
  actualizado.

- [ ] **Step 1: Extender el recorrido de capturas**

En `integration_test/screen_reviewer_test.dart`, dentro del recorrido de Notas,
agrega dos estados nuevos después de abrir la nota:

```dart
  await review.capture('note-surface-reading');
  await tester.tap(find.byKey(const ValueKey('note-block-0')));
  await tester.pumpAndSettle();
  await review.capture('note-surface-writing');
```

- [ ] **Step 2: Correr el recorrido**

Run: `flutter test integration_test/screen_reviewer_test.dart -d <simulador iPhone>`
Expected: PASS y archivos nuevos en `build/screen-review/`.

- [ ] **Step 3: Revisar accesibilidad**

Run: `flutter test test/widget`
Expected: PASS. Además, revisa manualmente en el simulador con VoiceOver que
los encabezados se anuncien como encabezados y las casillas anuncien marcada o
sin marcar.

- [ ] **Step 4: Verificación de compilación**

Run: `flutter analyze && flutter test && flutter build ios --release --no-codesign`
Expected: sin advertencias nuevas, todos los tests en verde y compilación
exitosa.

- [ ] **Step 5: Commit**

```bash
git add integration_test/screen_reviewer_test.dart docs/zentra-salvia-screen-tracker.md
git commit -m "test(notas): capturas de lectura y escritura en la superficie única"
```

---

## Verificación contra la definición de terminado

Al cerrar la Tarea 18, confirma uno por uno los nueve criterios de la sección 12
del spec. Todos tienen tarea asignada:

| Criterio del spec | Tarea |
| --- | --- |
| 1. Formato visible en lectura, tarjeta y bloques inactivos | 8, 9, 13, 15 |
| 2. Casillas tocables, persistidas y guardadas al instante | 9, 10, 12 |
| 3. Ningún carácter alterado al ir y volver | 1, 2, 14 |
| 4. Modo lectura en iPhone y sin salto en iPad | 12, 13 |
| 5. Barra solo con foco, sobre el teclado, idempotente | 5, 11, 12 |
| 6. Vista previa legible y progreso | 15 |
| 7. Búsqueda con fragmento y resaltado | 6, 15 |
| 8. Etiquetas en chips y filtro | 16 |
| 9. Tests y build de iOS | 18 |

Y estos requisitos del spec que no aparecen en la definición de terminado, pero
sí en el cuerpo del documento:

| Requisito | Sección del spec | Tarea |
| --- | --- | --- |
| Mitigación de la selección discontinua | 5.2 | 13, 14 |
| Banner del H1 como título, una sola vez | 6 | 12 |
| Panel de detalles en columna colapsable en iPad | 6 | 12 |
| Apilado por Dynamic Type sobre el umbral | 9 | 12 |
| Reduced Motion en la barra de formato | 9 | 12 |
| Háptico ligero al marcar una casilla | 7.2 | 9 |
| Confirmación tranquila al completar la checklist | 7.2 | 17 |
| Undo a nivel documento | 3 | 7, 11, 12 |
| Válvula de escape de texto plano | 3 | 14 |
