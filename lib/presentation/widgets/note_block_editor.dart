// lib/presentation/widgets/note_block_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/markdown_document.dart';
import '../../domain/markdown_editing.dart';
import '../design_tokens.dart';
import 'markdown_highlight_controller.dart';
import 'note_block_view.dart';

/// Zero width space kept in front of the active field's text.
///
/// iOS and Android soft keyboards emit no key event for Backspace, so the only
/// trace of one pressed at offset zero is this character disappearing. Exactly
/// one is inserted, at index zero, and exactly that one is removed again on the
/// way to the document: a zero width space the user already had is content.
const _sentinel = '\u200B';

/// Lets the owning screen read and move the caret, for example after a
/// toolbar command.
class NoteBlockEditorController extends ChangeNotifier {
  _NoteBlockEditorState? _state;

  /// Where the caret sits on the active block's source line, or null when no
  /// block is being edited.
  DocumentCaret? get caret => _state?._caret;

  /// The selection, with both endpoints measured on the block's source line.
  ///
  /// Callers never see the sentinel: an offset here indexes the same character
  /// as the matching offset of [MarkdownBlock.toSourceLine].
  TextSelection? get sourceSelection => _state?._sourceSelection;

  /// Moves the caret to [index]. Applied after the current frame, because a
  /// caller usually hands a new document to the parent in the same turn and
  /// the editor is still holding the previous one.
  void focusBlock(int index, {int offset = 0}) {
    focusBlockSelection(index, start: offset, end: offset);
  }

  /// Selects `[start, end)` of [index], deferred and for the same reason as
  /// [focusBlock].
  ///
  /// Both offsets are measured on the block's source line, exactly as
  /// [sourceSelection] reports them: the sentinel is this widget's business
  /// and no caller should be shifting offsets past it by hand.
  void focusBlockSelection(
    int index, {
    required int start,
    required int end,
  }) {
    _state?._requestFocusBlock(index, start, end);
  }

  void _caretMoved() => notifyListeners();
}

/// Renders a note body as blocks, turning the block under the caret into a raw
/// Markdown text field.
class NoteBlockEditor extends StatefulWidget {
  final MarkdownDocument document;
  final ValueChanged<MarkdownDocument> onChanged;
  final ValueChanged<DocumentCaret?> onCaretChanged;
  final NoteBlockEditorController? controller;
  final bool readOnly;

  /// Document level undo and redo, which take over from the text field's own
  /// history. That history outlives a rebind, so reaching it would restore one
  /// block's text over another's.
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const NoteBlockEditor({
    required this.document,
    required this.onChanged,
    required this.onCaretChanged,
    this.controller,
    this.readOnly = false,
    this.onUndo,
    this.onRedo,
    super.key,
  });

  @override
  State<NoteBlockEditor> createState() => _NoteBlockEditorState();
}

class _NoteBlockEditorState extends State<NoteBlockEditor> {
  /// Transparent until the first build: `_buildField` assigns the themed
  /// colour before the field that paints with it exists.
  final MarkdownHighlightController _fieldController =
      MarkdownHighlightController(markerColor: Colors.transparent);
  final FocusNode _focusNode = FocusNode();

  int? _activeIndex;

  /// Silences the field listener while the field is rewritten from a document,
  /// so a rebind is never mistaken for something the user typed.
  bool _applyingRemoteChange = false;

  /// The text the field held before the current notification. Losing exactly
  /// the leading sentinel and nothing else is the signature of Backspace at
  /// offset zero; every other way of losing it is an ordinary edit.
  String _lastFieldText = '';

  /// The document the field is known to agree with. Anything else arriving
  /// from the parent was produced elsewhere and has to be picked up.
  MarkdownDocument? _boundDocument;

  int? _pendingFocusIndex;
  int _pendingFocusStart = 0;
  int _pendingFocusEnd = 0;

  DocumentCaret? get _caret {
    final index = _activeIndex;
    if (index == null) return null;
    return DocumentCaret(
      blockIndex: index,
      offset: _sourceOffset(_fieldController.selection.baseOffset),
    );
  }

  TextSelection get _sourceSelection {
    final selection = _fieldController.selection;
    // An invalid selection is handed back untouched: mapping it would turn
    // "there is no selection" into a collapsed one at the start of the block.
    if (!selection.isValid) return selection;
    return TextSelection(
      baseOffset: _sourceOffset(selection.baseOffset),
      extentOffset: _sourceOffset(selection.extentOffset),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _fieldController.addListener(_onFieldChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(NoteBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }

    final index = _activeIndex;
    if (index == null) return;
    if (widget.readOnly || index >= widget.document.blocks.length) {
      _activeIndex = null;
      _focusNode.unfocus();
      return;
    }
    // A document this widget produced is already on screen. Rebinding on it
    // would undo whatever arrived between the edit and this rebuild.
    if (identical(widget.document, _boundDocument)) return;
    _boundDocument = widget.document;
    final source = widget.document.blocks[index].toSourceLine();
    if (source == _fieldSource()) return;
    // A difference confined to the composing region is the IME's own buffer
    // coming back around. Rebinding there cancels the composition, and every
    // IME answers that by re-committing what it had, duplicating characters.
    if (_differsOnlyWhileComposing('$_sentinel$source')) return;
    final offset = _sourceOffset(_fieldController.selection.baseOffset);
    _bindTo(widget.document, index, start: offset, end: offset);
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
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
    final blocks = widget.document.blocks;
    final children = <Widget>[];
    var number = 0;
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      if (block.type == MarkdownBlockType.numberedItem) {
        number++;
      } else {
        number = 0;
      }
      if (index == _activeIndex && !widget.readOnly) {
        children.add(_buildField(context, block));
        continue;
      }
      children.add(
        // A boundary per block so a keystroke in the active field repaints
        // that field alone instead of every rendered block above and below.
        RepaintBoundary(
          key: ValueKey('note-block-$index'),
          child: NoteBlockView(
            block: block,
            displayNumber: number == 0 ? null : number,
            onToggleCheck: block.type == MarkdownBlockType.checkItem
                ? () => widget.onChanged(
                      widget.document
                          .replaceBlock(index, block.toggleChecked()),
                    )
                : null,
            onTapAtOffset: widget.readOnly
                ? null
                : (offset) => _activate(index, start: offset, end: offset),
          ),
        ),
      );
    }
    // A column rather than a list: its children are matched by key, so the
    // field keeps the same element, and therefore its focus and its text,
    // when the active block moves up or down.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildField(BuildContext context, MarkdownBlock block) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = noteBlockTextStyle(context, block);
    _fieldController.markerColor = colorScheme.onSurfaceVariant;
    return Padding(
      key: const ValueKey('note-active-block'),
      padding: EdgeInsets.only(
        left: block.indentLevel * context.spacing.md,
        top: context.spacing.xxs,
        bottom: context.spacing.xxs,
      ),
      child: Focus(
        // Only here to see key events on their way up from the field. Taking
        // focus itself would leave the user with no caret at all.
        canRequestFocus: false,
        onKeyEvent: _onKeyEvent,
        child: Actions(
          // The field keeps a private undo history that survives a rebind, so
          // one of its entries can hold a different block's text. Undo belongs
          // to the document, as the design spec requires, and mapping both
          // intents here means the field's own history is never reachable.
          actions: <Type, Action<Intent>>{
            UndoTextIntent: CallbackAction<UndoTextIntent>(
              onInvoke: (_) {
                widget.onUndo?.call();
                return null;
              },
            ),
            RedoTextIntent: CallbackAction<RedoTextIntent>(
              onInvoke: (_) {
                widget.onRedo?.call();
                return null;
              },
            ),
          },
          child: TextField(
            controller: _fieldController,
            focusNode: _focusNode,
            style: style,
            // Never one: a `maxLines` of one makes `EditableText` prepend
            // `singleLineFormatter`, and the first keystroke on a code fence
            // would then strip every newline and leave an open fence that
            // swallows the rest of the note. Return is handled below instead.
            maxLines: null,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            // `onEditingComplete` rather than `onSubmitted`: the default
            // completion for `next` hands focus to the following widget before
            // the callback runs, which would drop the caret out of the note.
            onEditingComplete: _split,
            cursorColor: context.zentraPalette.brandTeal,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              hintText:
                  widget.document.blocks.length == 1 ? 'Escribe aquí…' : null,
              hintStyle: style.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_activeIndex == null) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final document = _commitField() ?? widget.document;
      final caret = _caret;
      // Indentation only means something on a list item. Swallowing Tab
      // anywhere else traps focus in the body, which on a keyboard is the
      // whole note: there is nothing else left to reach.
      if (caret == null) return KeyEventResult.ignored;
      final edit = changeIndent(
        document,
        caret,
        increase: !HardwareKeyboard.instance.isShiftPressed,
      );
      if (identical(edit.document, document)) return KeyEventResult.ignored;
      _applyEdit(document, edit);
      return KeyEventResult.handled;
    }

    // Only a collapsed caret at the very start means "join with the block
    // above". Anything wider is a selection the field has to delete itself.
    final selection = _fieldController.selection;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        selection.isCollapsed &&
        selection.baseOffset <= _sentinel.length) {
      _merge();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Selects `[start, end)` of [index], committing the block being left first.
  void _activate(int index, {required int start, required int end}) {
    if (widget.readOnly) return;
    // Only when the field is moving elsewhere: on the same block the document
    // is the newer of the two, since a toolbar command has just rewritten it.
    final document =
        (index == _activeIndex ? null : _commitField()) ?? widget.document;
    if (document.blocks.isEmpty) return;
    _bindTo(document, index, start: start, end: end);
    _focusNode.requestFocus();
    _publishCaret(_caret);
  }

  void _requestFocusBlock(int index, int start, int end) {
    _pendingFocusIndex = index;
    _pendingFocusStart = start;
    _pendingFocusEnd = end;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _pendingFocusIndex;
      if (target == null) return;
      _pendingFocusIndex = null;
      _activate(target, start: _pendingFocusStart, end: _pendingFocusEnd);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;
    _commitField();
    // Rebuilding the body can detach and reattach the field inside a single
    // frame, so the loss only counts once that frame is over.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusNode.hasFocus || _activeIndex == null) return;
      setState(() => _activeIndex = null);
      _publishCaret(null);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _onFieldChanged() {
    if (_applyingRemoteChange) return;
    if (_activeIndex == null) return;
    final text = _fieldController.text;
    final previous = _lastFieldText;
    _lastFieldText = text;

    if (!text.startsWith(_sentinel)) {
      if (previous.startsWith(_sentinel) &&
          text == previous.substring(_sentinel.length)) {
        _merge();
        return;
      }
      // Something else ate the sentinel, a select all and replace for
      // instance. Put it back and keep every character the user typed.
      _rearm(text);
      return;
    }
    _commitField();
    _publishCaret(_caret);
  }

  void _split() {
    final index = _activeIndex;
    if (index == null) return;
    final document = _commitField() ?? widget.document;
    final caret = _caret;
    if (caret == null || caret.blockIndex >= document.blocks.length) return;
    // A fence spans several source lines, so splitting it would drop its code
    // and its closing marker. Return adds a line inside it instead, which is
    // the only way to grow one now that the field is no longer single line.
    if (document.blocks[caret.blockIndex].type == MarkdownBlockType.codeFence) {
      _insertLineBreak();
      return;
    }
    _applyEdit(document, splitBlock(document, caret));
  }

  void _merge() {
    if (_activeIndex == 0) {
      // Nothing above to join. Re-arm the sentinel so the next Backspace is
      // still visible to us, and leave the text exactly where it was.
      //
      // The source, not the raw field text: on the hardware key path the
      // sentinel is still there, and prepending a second one would put the
      // published selection a character ahead of the block it describes.
      _rearm(_fieldSource());
      return;
    }
    final document = _commitField() ?? widget.document;
    final index = _activeIndex;
    if (index == null || index <= 0) return;
    _applyEdit(
      document,
      mergeWithPrevious(document, DocumentCaret(blockIndex: index, offset: 0)),
    );
  }

  /// Restores the sentinel in front of [source] without moving the caret off
  /// the character it was on. [source] is measured without the sentinel.
  void _rearm(String source) {
    final selection = _fieldController.selection;
    final offset = selection.baseOffset < 0
        ? source.length
        : _sourceOffset(selection.baseOffset);
    _setFieldValue(
      '$_sentinel$source',
      TextSelection.collapsed(offset: _fieldOffset(offset, source)),
    );
    _commitField();
    _publishCaret(_caret);
  }

  /// Adds a line inside the active block, for the blocks that own more than
  /// one source line and therefore cannot be split.
  void _insertLineBreak() {
    final selection = _fieldController.selection;
    if (!selection.isValid) return;
    final text = _fieldController.text;
    final start = _clamp(selection.start, text.length);
    final end = _clamp(selection.end, text.length);
    // Field offsets throughout: the replacement is measured on what the field
    // holds, sentinel included, not on the block source.
    _setFieldValue(
      text.replaceRange(start, end, '\n'),
      TextSelection.collapsed(offset: start + 1),
    );
    _commitField();
    _publishCaret(_caret);
  }

  /// Writes what the field holds into the document.
  ///
  /// Returns the document that now holds it, or null when the field already
  /// agreed with the one the parent handed over.
  MarkdownDocument? _commitField() {
    final index = _activeIndex;
    if (index == null || index >= widget.document.blocks.length) return null;
    final source = _fieldSource();
    var blocks = MarkdownDocument.parse(source).blocks;
    var next = _documentWith(index, blocks);
    // The same guard the domain puts on splitting and merging. Without it,
    // typing three backticks into a paragraph turns every block below it into
    // the body of a fence the user never opened. A raw block keeps the line
    // exactly as written and cannot swallow its neighbours.
    if (!_sameBlocks(next, MarkdownDocument.parse(next.serialize()))) {
      blocks = _literalBlocksFor(source);
      next = _documentWith(index, blocks);
    }
    if (_sameBlocks(next, widget.document)) return null;
    _boundDocument = next;
    widget.onChanged(next);
    if (blocks.length > 1) {
      // A multi line paste became several blocks. The caret follows the text
      // so none of it is left stranded behind an inert field.
      final last = index + blocks.length - 1;
      final end = next.blocks[last].toSourceLine().length;
      _bindTo(next, last, start: end, end: end);
    }
    return next;
  }

  /// [widget.document] with the block at [index] replaced by [blocks].
  MarkdownDocument _documentWith(int index, List<MarkdownBlock> blocks) {
    var next = widget.document.replaceBlock(index, blocks.first);
    for (var i = 1; i < blocks.length; i++) {
      next = next.insertBlock(index + i, blocks[i]);
    }
    return next;
  }

  /// One raw block per line, the shape that round trips verbatim whatever the
  /// parser would have read differently.
  static List<MarkdownBlock> _literalBlocksFor(String source) => [
        for (final line in source.split('\n'))
          MarkdownBlock(type: MarkdownBlockType.raw, text: line),
      ];

  static bool _sameBlocks(MarkdownDocument a, MarkdownDocument b) {
    if (a.blocks.length != b.blocks.length) return false;
    for (var i = 0; i < a.blocks.length; i++) {
      if (a.blocks[i] != b.blocks[i]) return false;
    }
    return true;
  }

  /// Applies a domain transformation and lands the caret exactly where it
  /// asked for, on the document it produced rather than on the one the parent
  /// will hand back a frame later.
  void _applyEdit(MarkdownDocument previous, DocumentEdit edit) {
    _bindTo(
      edit.document,
      edit.caret.blockIndex,
      start: edit.caret.offset,
      end: edit.caret.offset,
    );
    if (!identical(edit.document, previous)) widget.onChanged(edit.document);
    _focusNode.requestFocus();
    _publishCaret(_caret);
  }

  /// Points the field at [index] of [document] and selects `[start, end)`,
  /// with both offsets measured on the block source rather than on the field.
  void _bindTo(
    MarkdownDocument document,
    int index, {
    required int start,
    required int end,
  }) {
    if (document.blocks.isEmpty) return;
    final target = _clamp(index, document.blocks.length - 1);
    final source = document.blocks[target].toSourceLine();
    final text = '$_sentinel$source';
    // Staying on the same block is the only case where an open composition
    // still describes the characters it was opened over.
    final composing =
        target == _activeIndex ? _carriedComposing(text) : TextRange.empty;
    _boundDocument = document;
    setState(() => _activeIndex = target);
    _setFieldValue(
      text,
      TextSelection(
        baseOffset: _fieldOffset(start, source),
        extentOffset: _fieldOffset(end, source),
      ),
      composing: composing,
    );
  }

  void _setFieldValue(
    String text,
    TextSelection selection, {
    TextRange composing = TextRange.empty,
  }) {
    _applyingRemoteChange = true;
    _fieldController.value = TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: _clamp(selection.baseOffset, text.length),
        extentOffset: _clamp(selection.extentOffset, text.length),
      ),
      composing: composing,
    );
    _applyingRemoteChange = false;
    _lastFieldText = text;
  }

  void _publishCaret(DocumentCaret? caret) {
    widget.onCaretChanged(caret);
    widget.controller?._caretMoved();
  }

  /// The open composing range, kept only when [next] leaves every character in
  /// front of it untouched. Anywhere else the range would cover letters the
  /// IME never saw.
  TextRange _carriedComposing(String next) {
    final composing = _fieldController.value.composing;
    final text = _fieldController.text;
    if (!composing.isValid || !composing.isNormalized) return TextRange.empty;
    if (composing.end > text.length || composing.end > next.length) {
      return TextRange.empty;
    }
    if (text.substring(0, composing.start) !=
        next.substring(0, composing.start)) {
      return TextRange.empty;
    }
    return composing;
  }

  /// Whether [incoming] and the field agree on everything outside the range
  /// the IME is currently composing over.
  bool _differsOnlyWhileComposing(String incoming) {
    final composing = _fieldController.value.composing;
    final text = _fieldController.text;
    if (!composing.isValid || !composing.isNormalized) return false;
    if (composing.end > text.length) return false;
    final head = text.substring(0, composing.start);
    final tail = text.substring(composing.end);
    return incoming.length >= head.length + tail.length &&
        incoming.startsWith(head) &&
        incoming.endsWith(tail);
  }

  /// The field's text as the document should store it.
  ///
  /// Only the one sentinel this widget put at index zero is removed. Zero width
  /// spaces arrive in text pasted from the web and carry meaning in Thai and
  /// Khmer, so every other one is the user's and stays.
  String _fieldSource() {
    final text = _fieldController.text;
    return text.startsWith(_sentinel) ? text.substring(_sentinel.length) : text;
  }

  /// Translates a field offset into one on the block source line.
  int _sourceOffset(int fieldOffset) {
    final text = _fieldController.text;
    final at = _clamp(fieldOffset, text.length);
    if (!text.startsWith(_sentinel)) return at;
    return at <= _sentinel.length ? 0 : at - _sentinel.length;
  }

  /// Translates an offset on [source] into one on the field that will hold it,
  /// the inverse of [_sourceOffset]. Every field this widget writes is armed
  /// with the sentinel, so there is no unarmed case to answer for here.
  static int _fieldOffset(int sourceOffset, String source) =>
      _sentinel.length + _clamp(sourceOffset, source.length);

  static int _clamp(int value, int maximum) {
    if (value < 0) return 0;
    return value > maximum ? maximum : value;
  }
}
