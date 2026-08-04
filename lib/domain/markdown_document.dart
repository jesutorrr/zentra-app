// lib/domain/markdown_document.dart
import 'markdown_inline.dart';

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

const Object _keepFenceClose = Object();
final _boxPattern = RegExp(r'\[[ xX]\]');

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
  ///
  /// Refuses to act when the prefix no longer holds a box, so [checked] can
  /// never disagree with what the serialized line says.
  MarkdownBlock toggleChecked() {
    if (type != MarkdownBlockType.checkItem) return this;
    if (!_boxPattern.hasMatch(prefix)) return this;
    final next = !checked;
    return copyWith(
      prefix: prefix.replaceFirst(_boxPattern, next ? '[x]' : '[ ]'),
      checked: next,
    );
  }

  MarkdownBlock copyWith({
    MarkdownBlockType? type,
    String? leading,
    String? prefix,
    String? text,
    bool? checked,
    int? headingLevel,
    String? language,
    List<String>? codeLines,
    // Sentinel rather than null: null is a meaningful value here, it means the
    // fence was never closed, so it cannot double as "leave this alone".
    Object? fenceClose = _keepFenceClose,
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
      fenceClose: identical(fenceClose, _keepFenceClose)
          ? this.fenceClose
          : fenceClose as String?,
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
// The lookahead lets an empty checklist item keep its box: a user who just
// typed `- [ ]` and has not written anything yet still gets a tappable box,
// while `- [x]texto` stays a plain bullet the way CommonMark reads it.
final _checkPattern =
    RegExp(r'^([-*][ \t]+\[[ xX]\](?:[ \t]+|(?=\r?$)))([\s\S]*)$');
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
    RangeError.checkValidIndex(index, blocks, 'index');
    if (blocks.length == 1) {
      return const MarkdownDocument([MarkdownBlock.paragraph()]);
    }
    final next = [...blocks]..removeAt(index);
    return MarkdownDocument(List.unmodifiable(next));
  }

  int get checkItemCount =>
      blocks.where((block) => block.type == MarkdownBlockType.checkItem).length;

  int get checkedCount => blocks
      .where(
        (block) => block.type == MarkdownBlockType.checkItem && block.checked,
      )
      .length;

  /// Human readable text of every block, one per line, without markers.
  String plainText() =>
      blocks.map(_visibleText).where((line) => line.isNotEmpty).join('\n');

  /// First meaningful line, for note cards.
  String previewText({int maxLength = 140}) {
    if (maxLength <= 0) return '';
    for (final block in blocks) {
      final line = _visibleText(block);
      if (line.isEmpty) continue;
      if (line.length <= maxLength) return line;
      final space = line.lastIndexOf(' ', maxLength);
      final cut = space <= 0 ? _wholeCodePointCut(line, maxLength) : space;
      return '${line.substring(0, cut).trimRight()}…';
    }
    return '';
  }

  /// The text a reader actually sees on [block], with every marker removed.
  static String _visibleText(MarkdownBlock block) {
    switch (block.type) {
      case MarkdownBlockType.divider:
        return '';
      case MarkdownBlockType.codeFence:
        // The fence body keeps its own indentation and blank lines, which read
        // as a run of spaces once the lines are folded into one.
        return block.codeLines
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .join(' ');
      case MarkdownBlockType.raw:
        // Unsupported syntax is kept verbatim everywhere else, so a preview
        // that rewrote it would describe a line the note does not contain.
        return block.text.trim();
      default:
        // Marker segments cover backslash escapes and link targets too, so
        // dropping them leaves the escaped character and the link label. Code
        // spans arrive as a single literal segment and survive untouched.
        return tokenizeInline(block.text)
            .where((segment) => !segment.isMarker)
            .map((segment) => segment.text)
            .join()
            .trim();
    }
  }

  /// Moves a hard cut off the middle of a surrogate pair, so truncating a line
  /// that ends in an emoji never leaves half a code point behind.
  static int _wholeCodePointCut(String line, int at) {
    final unit = line.codeUnitAt(at - 1);
    final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
    return isHighSurrogate ? at - 1 : at;
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

/// Returns the slice of [body] around the first occurrence of [query], so the
/// note card can show where the match actually is.
String markdownExcerptAround(String body, String query, {int radius = 40}) {
  final plain = MarkdownDocument.parse(body).plainText().replaceAll('\n', ' ');
  final needle = query.trim();
  if (needle.isEmpty) return plain;
  final at = plain.toLowerCase().indexOf(needle.toLowerCase());
  if (at == -1) return plain;
  // Lowercasing can change a string's length, so the offsets it yields are
  // clamped before they ever index back into the original text.
  final span = radius < 0 ? 0 : radius;
  final start = _clampToLength(at - span, plain.length);
  final end = _clampToLength(at + needle.length + span, plain.length);
  if (start >= end) return plain;
  final prefix = start > 0 ? '…' : '';
  final suffix = end < plain.length ? '…' : '';
  return '$prefix${plain.substring(start, end)}$suffix';
}

int _clampToLength(int value, int length) {
  if (value < 0) return 0;
  return value > length ? length : value;
}
