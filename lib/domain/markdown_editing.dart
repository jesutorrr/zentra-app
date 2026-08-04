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

  // Enter on an item that has no content leaves the list, the way every notes
  // app does it. An indented item steps out one level first, so the user walks
  // back out of a nested list instead of falling straight to a paragraph.
  final exitsList =
      (block.isListLike || block.type == MarkdownBlockType.quote) &&
          block.text.isEmpty &&
          caret.offset >= block.toSourceLine().length;
  if (exitsList) {
    if (block.isListLike && block.indentLevel > 0) {
      return changeIndent(document, caret, increase: false);
    }
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
  if (!_survivesReparse(next)) return DocumentEdit(document, caret);
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
  // A divider keeps all of its characters in `prefix` and has no text, so
  // merging by text alone would delete the rule instead of joining it.
  final carried =
      current.type == MarkdownBlockType.divider ? current.prefix : current.text;
  final merged = MarkdownDocument.parse('$previousSource$carried').blocks.first;
  final next = document
      .replaceBlock(caret.blockIndex - 1, merged)
      .removeBlock(caret.blockIndex);
  if (!_survivesReparse(next)) return DocumentEdit(document, caret);
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
  // Indentation only means nesting on a list item; four spaces in front of a
  // paragraph is an indented code block to every other Markdown renderer.
  if (block.type == MarkdownBlockType.raw || !block.isListLike) {
    return DocumentEdit(document, caret);
  }
  final level = block.indentLevel;
  final nextLevel = increase ? level + 1 : level - 1;
  final clamped = _clamp(nextLevel, 3);
  if (clamped == level) return DocumentEdit(document, caret);
  final leading = '  ' * clamped;
  final indented = block.copyWith(leading: leading);
  final shifted = _clamp(
    caret.offset + leading.length - block.leading.length,
    indented.toSourceLine().length,
  );
  return DocumentEdit(
    document.replaceBlock(caret.blockIndex, indented),
    DocumentCaret(blockIndex: caret.blockIndex, offset: shifted),
  );
}

/// True when [next] parses back to exactly itself. A transformation that fails
/// this looks right in memory and comes back different after a save: the
/// classic case is a line of prose with three backticks becoming an unclosed
/// code fence that swallows every block below it on reload.
bool _survivesReparse(MarkdownDocument next) {
  final reparsed = MarkdownDocument.parse(next.serialize());
  if (reparsed.blocks.length != next.blocks.length) return false;
  for (var i = 0; i < next.blocks.length; i++) {
    if (reparsed.blocks[i] != next.blocks[i]) return false;
  }
  return true;
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
    final below = caret.blockIndex + 1;
    // Only open a line under the rule when there is not an empty one already,
    // so two taps do not leave a growing stack of blank paragraphs.
    final landsOnEmpty = _holdsBlock(document, below) &&
        _isEmptyParagraph(document.blocks[below]);
    var next = document.insertBlock(
      below,
      const MarkdownBlock(
        type: MarkdownBlockType.divider,
        prefix: '---',
      ),
    );
    if (!landsOnEmpty) {
      next = next.insertBlock(below + 1, const MarkdownBlock.paragraph());
    }
    // An unclosed fence above would swallow the rule and the line under it.
    if (!_survivesReparse(next)) return _unchanged(document, caret, block);
    return DocumentEdit(
      next,
      DocumentCaret(blockIndex: below + 1, offset: 0),
    );
  }

  if (command == NoteBlockCommand.code) {
    final toggled = _toggleFence(block);
    if (toggled == null) return _unchanged(document, caret, block);
    final next = document.replaceBlock(caret.blockIndex, toggled);
    if (!_survivesReparse(next)) return _unchanged(document, caret, block);
    return DocumentEdit(
      next,
      DocumentCaret(blockIndex: caret.blockIndex, offset: 0),
    );
  }

  // A fence spans several source lines and a raw block keeps an unsupported
  // line verbatim. Rebuilding either one from a prefix and `text` would drop
  // the code, the closing marker or the characters we promised not to touch.
  // The `code` command above is the exception: it wraps the whole source line,
  // so a raw one goes into the fence verbatim and comes back out unchanged.
  if (block.type == MarkdownBlockType.codeFence ||
      block.type == MarkdownBlockType.raw) {
    return _unchanged(document, caret, block);
  }

  final nextPrefix = _nextPrefixFor(block, command);
  // A divider keeps all of its characters in `prefix` and has no text, so
  // rebuilding from `text` alone would delete the rule instead of prefixing
  // it, and no command puts those characters back.
  final isDivider = block.type == MarkdownBlockType.divider;
  final payload = isDivider ? block.prefix : block.text;
  final rebuilt = MarkdownDocument.parse(
    '${block.leading}$nextPrefix$payload',
  ).blocks.first;
  // Dropping the marker off a line whose text starts with three backticks
  // opens a fence, and an open fence reads every block below it as code.
  if (rebuilt.type == MarkdownBlockType.codeFence) {
    return _unchanged(document, caret, block);
  }
  final next = document.replaceBlock(caret.blockIndex, rebuilt);
  if (!_survivesReparse(next)) return _unchanged(document, caret, block);
  final length = rebuilt.toSourceLine().length;
  final lower = _clamp(block.leading.length, length);
  // The divider's prefix stays on the line as text, so nothing was removed in
  // front of the caret and only the new marker shifts it.
  final removed = isDivider ? 0 : block.prefix.length;
  return DocumentEdit(
    next,
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: _clampRange(
        caret.offset + nextPrefix.length - removed,
        lower,
        length,
      ),
    ),
  );
}

/// The document as it was, with the caret pinned inside [block]. Every path
/// that acts clamps the caret, so the ones that refuse do too rather than
/// handing back an offset that points past the end of the line.
DocumentEdit _unchanged(
  MarkdownDocument document,
  DocumentCaret caret,
  MarkdownBlock block,
) {
  return DocumentEdit(
    document,
    DocumentCaret(
      blockIndex: caret.blockIndex,
      offset: _clamp(caret.offset, block.toSourceLine().length),
    ),
  );
}

bool _isEmptyParagraph(MarkdownBlock block) =>
    block.type == MarkdownBlockType.paragraph && block.toSourceLine().isEmpty;

/// Wraps [block] in a fence, or unwraps the one it already is. Null when the
/// fence cannot be unwrapped without losing source.
///
/// The fence is always closed: an open one would swallow every block below it
/// the next time the note is parsed. Only a fence shaped like the one this
/// command produces is unwrapped, because that is the only shape where
/// toggling back returns the block the user started from: folding several code
/// lines into one would delete the newlines between them, and dropping the
/// language would delete the word typed right after the marker. Neither comes
/// back, so a fence the user wrote by hand is left alone instead.
MarkdownBlock? _toggleFence(MarkdownBlock block) {
  if (block.type == MarkdownBlockType.codeFence) {
    if (block.codeLines.length != 1 || block.language.isNotEmpty) return null;
    // Parsed rather than assumed to be a paragraph so the resulting block
    // still describes the line it serializes.
    final unwrapped =
        MarkdownDocument.parse(block.codeLines.single).blocks.first;
    // A fenced line that is itself a run of backticks would come out of a
    // closed fence as an open one.
    if (unwrapped.type == MarkdownBlockType.codeFence) return null;
    return unwrapped;
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
      // Unreachable: both commands are answered in full before this is
      // called. They stay named so the switch remains exhaustive and a new
      // command cannot be added without deciding what prefix it carries.
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
  // A backwards drag hands `end` in before `start`. Normalizing here keeps the
  // range usable instead of collapsing it, so the domain API stays safe for a
  // caller that does not sort the selection first.
  final rangeStart = start <= end ? start : end;
  final rangeEnd = start <= end ? end : start;

  final block = document.blocks[blockIndex];
  final source = block.toSourceLine();
  final marker = _inlineMarkers[style];
  // A fence spans several lines and a raw block holds an unsupported one, so a
  // single pair of offsets cannot address either without losing source. A link
  // has no marker of this shape either: it needs a target, not a wrap.
  if (marker == null ||
      block.type == MarkdownBlockType.codeFence ||
      block.type == MarkdownBlockType.raw) {
    return DocumentEdit(
      document,
      DocumentCaret(
        blockIndex: blockIndex,
        offset: _clamp(rangeEnd, source.length),
      ),
    );
  }

  // The block marker is not styled text: wrapping it would demote a heading to
  // a paragraph the moment the line is parsed again.
  var from = _clampRange(
    rangeStart,
    _clamp(block.leading.length + block.prefix.length, source.length),
    source.length,
  );
  var to = _clampRange(rangeEnd, from, source.length);
  // Emphasis has to hug its content: the tokenizer refuses a marker followed
  // by a space and one preceded by a space, so a selection that swallowed
  // either would read back as literal asterisks. A double tap on a word takes
  // the trailing space with it, which makes this the common case rather than
  // the odd one. A code span is exempt, a backtick may sit against anything.
  if (marker != '`') {
    while (from < to && _isBlank(source[from])) {
      from++;
    }
    while (to > from && _isBlank(source[to - 1])) {
      to--;
    }
  }
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
  if (_endsWithMarker(before, marker) && _startsWithMarker(after, marker)) {
    rebuilt = '${before.substring(0, before.length - marker.length)}'
        '$selected${after.substring(marker.length)}';
    caretEnd = to - marker.length;
  } else if (selected.length > marker.length * 2 &&
      _startsWithMarker(selected, marker) &&
      _endsWithMarker(selected, marker)) {
    // The selection swallowed the markers it should toggle off.
    rebuilt = '$before'
        '${selected.substring(marker.length, selected.length - marker.length)}'
        '$after';
    caretEnd = to - marker.length * 2;
  } else {
    rebuilt = '$before$marker$selected$marker$after';
    caretEnd = to + marker.length;
  }

  final rebuiltBlock = MarkdownDocument.parse(rebuilt).blocks.first;
  // Markers that add up to a fence or to a rule stop being text: the fence
  // reads every block below it as code and the rule renders nothing at all.
  // Neither can be undone from here, because the block that replaced the line
  // no longer offers a selection to toggle.
  final unchanged = DocumentEdit(
    document,
    DocumentCaret(blockIndex: blockIndex, offset: to),
  );
  if (rebuiltBlock.type == MarkdownBlockType.codeFence ||
      rebuiltBlock.type == MarkdownBlockType.divider) {
    return unchanged;
  }
  final next = document.replaceBlock(blockIndex, rebuiltBlock);
  if (!_survivesReparse(next)) return unchanged;

  return DocumentEdit(
    next,
    DocumentCaret(blockIndex: blockIndex, offset: caretEnd),
  );
}

/// True when [text] ends with [marker] and that marker is not the tail of a
/// longer run of the same character.
///
/// Without the run check a single `*` claims one half of the `**` that makes a
/// word bold, so adding italics to a bold word would unbold it instead.
bool _endsWithMarker(String text, String marker) {
  if (!text.endsWith(marker)) return false;
  final neighbour = text.length - marker.length - 1;
  return neighbour < 0 || text[neighbour] != marker[0];
}

/// True when [text] starts with [marker] and that marker is not the head of a
/// longer run of the same character. See [_endsWithMarker].
bool _startsWithMarker(String text, String marker) {
  if (!text.startsWith(marker)) return false;
  final neighbour = marker.length;
  return neighbour >= text.length || text[neighbour] != marker[0];
}

/// The tokenizer's own notion of a space, so a tab or a non breaking space
/// blocks a marker exactly the way a plain space does.
bool _isBlank(String character) => character.trim().isEmpty;

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
  final digits = match.group(1)!;
  final value = '${int.parse(digits) + 1}';
  // Keep the author's zero padding: rewriting `01.` as `2.` would be a second
  // source normalization, and the parser only allows `[X]` becoming `[x]`.
  final padded = value.padLeft(digits.length, '0');
  return '$padded${match.group(2)}';
}

bool _holdsBlock(MarkdownDocument document, int index) =>
    index >= 0 && index < document.blocks.length;

int _clamp(int value, int max) => _clampRange(value, 0, max);

/// Keeps [value] within `[min, max]`. Callers must pass `min <= max`.
int _clampRange(int value, int min, int max) {
  if (value < min) return min;
  return value > max ? max : value;
}
