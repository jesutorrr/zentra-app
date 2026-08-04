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
