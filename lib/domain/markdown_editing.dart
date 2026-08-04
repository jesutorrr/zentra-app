// lib/domain/markdown_editing.dart
import 'markdown_document.dart';

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

int _clamp(int value, int max) {
  if (value < 0) return 0;
  return value > max ? max : value;
}
