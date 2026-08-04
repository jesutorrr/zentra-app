// lib/domain/markdown_editing.dart
import 'markdown_document.dart';
import 'markdown_inline.dart';

final _boxPattern = RegExp(r'\[[ xX]\]');
final _numberPattern = RegExp(r'^(\d+)([.)][ \t]+)$');

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
  if (!_holdsBlock(document, caret.blockIndex)) {
    return DocumentEdit(document, caret);
  }
  final block = document.blocks[caret.blockIndex];
  // A fence spans several source lines, so one offset cannot address it and
  // reparsing a slice of it would drop the code and the closing marker.
  if (block.type == MarkdownBlockType.codeFence) {
    return DocumentEdit(document, caret);
  }

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

  final source = block.toSourceLine();
  final offset = _clamp(caret.offset, source.length);
  final head = source.substring(0, offset);
  final tail = source.substring(offset);
  // Only repeat the marker once the caret is past it. Splitting inside the
  // indentation or the marker leaves those characters in the tail already, so
  // adding a continuation there would duplicate them.
  final continuation = offset >= block.leading.length + block.prefix.length
      ? _continuationPrefix(block)
      : '';

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
  if (caret.blockIndex <= 0 || !_holdsBlock(document, caret.blockIndex)) {
    return DocumentEdit(document, caret);
  }
  final previous = document.blocks[caret.blockIndex - 1];
  final current = document.blocks[caret.blockIndex];
  // Merging is a single line operation. A fence on either side would lose its
  // code lines or swallow the neighbour as code, so leave both alone.
  if (previous.type == MarkdownBlockType.codeFence ||
      current.type == MarkdownBlockType.codeFence) {
    return DocumentEdit(document, caret);
  }
  final previousSource = previous.toSourceLine();
  final merged =
      MarkdownDocument.parse('$previousSource${current.text}').blocks.first;
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
  if (!_holdsBlock(document, caret.blockIndex)) {
    return DocumentEdit(document, caret);
  }
  final block = document.blocks[caret.blockIndex];
  // A raw block serializes its whole line from `text`, so rewriting `leading`
  // would move the caret without changing a single character of the source.
  if (block.type == MarkdownBlockType.raw) {
    return DocumentEdit(document, caret);
  }
  final level = block.indentLevel;
  final nextLevel = increase ? level + 1 : level - 1;
  final clamped = _clamp(nextLevel, 3);
  if (clamped == level) return DocumentEdit(document, caret);
  final leading = '  ' * clamped;
  final shifted = caret.offset + leading.length - block.leading.length;
  return DocumentEdit(
    document.replaceBlock(caret.blockIndex, block.copyWith(leading: leading)),
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: shifted < 0 ? 0 : shifted,
    ),
  );
}

/// Block level formatting actions exposed by the editor toolbar.
enum NoteBlockCommand {
  heading,
  bullet,
  numbered,
  checklist,
  quote,
  code,
  divider,
}

/// Applies a toolbar command to the whole active block. Commands are
/// idempotent toggles and never insert text at the caret.
DocumentEdit applyBlockCommand(
  MarkdownDocument document,
  DocumentCaret caret,
  NoteBlockCommand command,
) {
  if (!_holdsBlock(document, caret.blockIndex)) {
    return DocumentEdit(document, caret);
  }
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
    return DocumentEdit(
      document.replaceBlock(caret.blockIndex, _toggleFence(block)),
      DocumentCaret(blockIndex: caret.blockIndex, offset: 0),
    );
  }

  // A fence spans several source lines and a raw block keeps an unsupported
  // line verbatim. Rebuilding either one from a prefix and `text` would drop
  // the code, the closing marker or the characters we promised not to touch.
  if (block.type == MarkdownBlockType.codeFence ||
      block.type == MarkdownBlockType.raw) {
    return DocumentEdit(document, caret);
  }

  final nextPrefix = _nextPrefixFor(block, command);
  final rebuilt = MarkdownDocument.parse(
    '${block.leading}$nextPrefix${block.text}',
  ).blocks.first;
  final length = rebuilt.toSourceLine().length;
  final lower = _clamp(block.leading.length, length);
  return DocumentEdit(
    document.replaceBlock(caret.blockIndex, rebuilt),
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: _clampRange(
        caret.offset + nextPrefix.length - block.prefix.length,
        lower,
        length,
      ),
    ),
  );
}

/// Wraps [block] in a fence, or unwraps the one it already is.
///
/// The fence is always closed: an open one would swallow every block below it
/// the next time the note is parsed.
MarkdownBlock _toggleFence(MarkdownBlock block) {
  if (block.type == MarkdownBlockType.codeFence) {
    // Parsed rather than assumed to be a paragraph so the resulting block
    // still describes the line it serializes.
    return MarkdownDocument.parse(block.codeLines.join(' ')).blocks.first;
  }
  return MarkdownBlock(
    type: MarkdownBlockType.codeFence,
    prefix: '```',
    // The whole source line, marker included, so toggling back returns the
    // block the user started from.
    codeLines: List.unmodifiable([block.toSourceLine()]),
    fenceClose: '```',
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

// Asterisks rather than underscores for emphasis: the tokenizer refuses an
// underscore that touches a word character, so `hola_mundo_` would never read
// back as italics.
const _inlineMarkers = <MarkdownInlineStyle, String>{
  MarkdownInlineStyle.bold: '**',
  MarkdownInlineStyle.italic: '*',
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
  if (!_holdsBlock(document, blockIndex)) {
    return DocumentEdit(
      document,
      DocumentCaret(
        blockIndex: _clamp(blockIndex, document.blocks.length - 1),
        offset: 0,
      ),
    );
  }
  final block = document.blocks[blockIndex];
  final source = block.toSourceLine();
  final marker = _inlineMarkers[style];
  // A fence spans several lines and a raw block holds an unsupported one, so a
  // single pair of offsets cannot address either without losing source.
  if (marker == null ||
      block.type == MarkdownBlockType.codeFence ||
      block.type == MarkdownBlockType.raw) {
    return DocumentEdit(
      document,
      DocumentCaret(
        blockIndex: blockIndex,
        offset: _clamp(end, source.length),
      ),
    );
  }

  // The block marker is not styled text: wrapping it would demote a heading to
  // a paragraph the moment the line is parsed again.
  final from = _clampRange(
    start,
    _clamp(block.leading.length + block.prefix.length, source.length),
    source.length,
  );
  final to = _clampRange(end, from, source.length);
  if (from == to) {
    return DocumentEdit(
      document,
      DocumentCaret(blockIndex: blockIndex, offset: to),
    );
  }

  final before = source.substring(0, from);
  final selected = source.substring(from, to);
  final after = source.substring(to);

  final String rebuilt;
  final int caretEnd;
  if (before.endsWith(marker) && after.startsWith(marker)) {
    rebuilt = '${before.substring(0, before.length - marker.length)}'
        '$selected${after.substring(marker.length)}';
    caretEnd = to - marker.length;
  } else if (selected.length > marker.length * 2 &&
      selected.startsWith(marker) &&
      selected.endsWith(marker)) {
    // The selection swallowed the markers it should toggle off.
    rebuilt = '$before'
        '${selected.substring(marker.length, selected.length - marker.length)}'
        '$after';
    caretEnd = to - marker.length * 2;
  } else {
    rebuilt = '$before$marker$selected$marker$after';
    caretEnd = to + marker.length;
  }

  return DocumentEdit(
    document.replaceBlock(
      blockIndex,
      MarkdownDocument.parse(rebuilt).blocks.first,
    ),
    DocumentCaret(blockIndex: blockIndex, offset: caretEnd),
  );
}

String _continuationPrefix(MarkdownBlock block) {
  switch (block.type) {
    case MarkdownBlockType.bulletItem:
      return '${block.leading}${block.prefix}';
    case MarkdownBlockType.checkItem:
      return '${block.leading}'
          '${block.prefix.replaceFirst(_boxPattern, '[ ]')}';
    case MarkdownBlockType.numberedItem:
      return '${block.leading}${_nextNumber(block.prefix)}';
    case MarkdownBlockType.quote:
      return '${block.leading}${block.prefix}';
    default:
      return block.leading;
  }
}

String _nextNumber(String prefix) {
  final match = _numberPattern.firstMatch(prefix);
  if (match == null) return prefix;
  final value = int.parse(match.group(1)!) + 1;
  return '$value${match.group(2)}';
}

bool _holdsBlock(MarkdownDocument document, int index) =>
    index >= 0 && index < document.blocks.length;

int _clamp(int value, int max) => _clampRange(value, 0, max);

/// Keeps [value] within `[min, max]`. Callers must pass `min <= max`.
int _clampRange(int value, int min, int max) {
  if (value < min) return min;
  return value > max ? max : value;
}
