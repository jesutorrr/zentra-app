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
/// trace of one pressed at offset zero is this character disappearing. It is
/// stripped again on the way to the document and never reaches a saved note.
const _sentinel = '\u200B';
const _sentinelUnit = 0x200B;

/// Lets the owning screen read and move the caret, for example after a
/// toolbar command.
class NoteBlockEditorController extends ChangeNotifier {
  _NoteBlockEditorState? _state;

  /// Where the caret sits on the active block's source line, or null when no
  /// block is being edited.
  DocumentCaret? get caret => _state?._caret;

  /// The raw field selection. Its offsets sit one character ahead of the block
  /// source because of the sentinel, which callers compensate for.
  TextSelection? get selection => _state?._fieldController.selection;

  /// Moves the caret to [index]. Applied after the current frame, because a
  /// caller usually hands a new document to the parent in the same turn and
  /// the editor is still holding the previous one.
  void focusBlock(int index, {int offset = 0}) {
    _state?._requestFocusBlock(index, offset);
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
  int _pendingFocusOffset = 0;

  DocumentCaret? get _caret {
    final index = _activeIndex;
    if (index == null) return null;
    return DocumentCaret(
      blockIndex: index,
      offset: _sourceOffset(_fieldController.selection.baseOffset),
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
    if (widget.document.blocks[index].toSourceLine() == _fieldSource()) return;
    _bindTo(
      widget.document,
      index,
      _sourceOffset(_fieldController.selection.baseOffset),
    );
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
        NoteBlockView(
          key: ValueKey('note-block-$index'),
          block: block,
          displayNumber: number == 0 ? null : number,
          onToggleCheck: block.type == MarkdownBlockType.checkItem
              ? () => widget.onChanged(
                    widget.document.replaceBlock(index, block.toggleChecked()),
                  )
              : null,
          onTapAtOffset: widget.readOnly
              ? null
              : (offset) => _activate(index, offset: offset),
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
        child: TextField(
          controller: _fieldController,
          focusNode: _focusNode,
          style: style,
          maxLines: 1,
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
      if (caret == null) return KeyEventResult.handled;
      _applyEdit(
        document,
        changeIndent(
          document,
          caret,
          increase: !HardwareKeyboard.instance.isShiftPressed,
        ),
      );
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

  /// Puts the caret on [index], committing the block being left first.
  void _activate(int index, {int offset = 0}) {
    if (widget.readOnly) return;
    // Only when the field is moving elsewhere: on the same block the document
    // is the newer of the two, since a toolbar command has just rewritten it.
    final document =
        (index == _activeIndex ? null : _commitField()) ?? widget.document;
    if (document.blocks.isEmpty) return;
    _bindTo(document, index, offset);
    _focusNode.requestFocus();
    widget.onCaretChanged(_caret);
  }

  void _requestFocusBlock(int index, int offset) {
    _pendingFocusIndex = index;
    _pendingFocusOffset = offset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _pendingFocusIndex;
      if (target == null) return;
      _pendingFocusIndex = null;
      _activate(target, offset: _pendingFocusOffset);
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
      widget.onCaretChanged(null);
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
    widget.onCaretChanged(_caret);
  }

  void _split() {
    if (_activeIndex == null) return;
    final document = _commitField() ?? widget.document;
    final caret = _caret;
    if (caret == null) return;
    _applyEdit(document, splitBlock(document, caret));
  }

  void _merge() {
    if (_activeIndex == 0) {
      // Nothing above to join. Re-arm the sentinel so the next Backspace is
      // still visible to us, and leave the text exactly where it was.
      _rearm(_fieldController.text);
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

  /// Restores the sentinel in front of [text] without moving the caret off the
  /// character it was on.
  void _rearm(String text) {
    final offset = _fieldController.selection.baseOffset;
    _setFieldValue(
      '$_sentinel$text',
      (offset < 0 ? text.length : offset) + _sentinel.length,
    );
    _commitField();
    widget.onCaretChanged(_caret);
  }

  /// Writes what the field holds into the document.
  ///
  /// Returns the document that now holds it, or null when the field already
  /// agreed with the one the parent handed over.
  MarkdownDocument? _commitField() {
    final index = _activeIndex;
    if (index == null || index >= widget.document.blocks.length) return null;
    final parsed = MarkdownDocument.parse(_fieldSource()).blocks;
    if (parsed.length == 1 && parsed.first == widget.document.blocks[index]) {
      return null;
    }
    var next = widget.document.replaceBlock(index, parsed.first);
    for (var i = 1; i < parsed.length; i++) {
      next = next.insertBlock(index + i, parsed[i]);
    }
    _boundDocument = next;
    widget.onChanged(next);
    if (parsed.length > 1) {
      // A multi line paste became several blocks. The caret follows the text
      // so none of it is left stranded behind an inert field.
      final last = index + parsed.length - 1;
      _bindTo(next, last, next.blocks[last].toSourceLine().length);
    }
    return next;
  }

  /// Applies a domain transformation and lands the caret exactly where it
  /// asked for, on the document it produced rather than on the one the parent
  /// will hand back a frame later.
  void _applyEdit(MarkdownDocument previous, DocumentEdit edit) {
    _bindTo(edit.document, edit.caret.blockIndex, edit.caret.offset);
    if (!identical(edit.document, previous)) widget.onChanged(edit.document);
    _focusNode.requestFocus();
    widget.onCaretChanged(_caret);
  }

  /// Points the field at [index] of [document], with [offset] measured on the
  /// block source rather than on the field.
  void _bindTo(MarkdownDocument document, int index, int offset) {
    if (document.blocks.isEmpty) return;
    final target = _clamp(index, document.blocks.length - 1);
    final source = document.blocks[target].toSourceLine();
    _boundDocument = document;
    setState(() => _activeIndex = target);
    _setFieldValue(
      '$_sentinel$source',
      _sentinel.length + _clamp(offset, source.length),
    );
  }

  void _setFieldValue(String text, int offset) {
    _applyingRemoteChange = true;
    _fieldController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: _clamp(offset, text.length)),
    );
    _applyingRemoteChange = false;
    _lastFieldText = text;
  }

  /// The field's text as the document should store it. Every sentinel is
  /// removed, not just the leading one, so a paste carrying the same character
  /// cannot smuggle it into a saved note.
  String _fieldSource() => _fieldController.text.replaceAll(_sentinel, '');

  /// Translates a field offset into one on the block source line.
  int _sourceOffset(int fieldOffset) {
    final text = _fieldController.text;
    final at = _clamp(fieldOffset, text.length);
    var sentinels = 0;
    for (var i = 0; i < at; i++) {
      if (text.codeUnitAt(i) == _sentinelUnit) sentinels++;
    }
    return at - sentinels;
  }

  static int _clamp(int value, int maximum) {
    if (value < 0) return 0;
    return value > maximum ? maximum : value;
  }
}
