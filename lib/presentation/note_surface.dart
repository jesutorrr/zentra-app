// lib/presentation/note_surface.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'motion_policy.dart';
import 'note_reminder_screen.dart';
import 'pomodoro_screen.dart';
import 'utils/page_transitions.dart';
import 'widgets/markdown_inline_spans.dart';
import 'widgets/note_block_editor.dart';
import 'widgets/note_block_view.dart';
import 'widgets/note_details_panel.dart';
import 'widgets/note_format_bar.dart';
import 'widgets/notes_components.dart';
import 'widgets/responsive_layout.dart';

/// Smallest touch target this screen hands out, in logical points.
const double _touchTarget = 44;

/// How long typing waits before it reaches disk.
const Duration _saveDebounceDelay = Duration(milliseconds: 700);

/// Width of the details column on a window wide enough to hold one.
const double _detailsColumnWidth = 320;

/// Widest the details sheet lets its content grow on a tablet.
const double _detailsSheetWidth = 560;

/// Largest scaled body size that still leaves room for a side column. Past it
/// the details go back to the bottom sheet, where they get the full width.
const double _sideColumnTextCeiling = 23;

/// The single line a finished checklist gets. It acknowledges the work instead
/// of rewarding it: no XP, no achievement, no sound and no animation.
const String _checklistDoneMessage = 'Terminaste todo lo de esta nota.';

/// A note, readable and writable in the same place.
///
/// There is no separate edit mode to enter and leave: the body is always the
/// rendered note, and the block under the caret is the only one that turns
/// into raw Markdown.
class NoteSurface extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteSurface({this.noteId, super.key});

  @override
  ConsumerState<NoteSurface> createState() => _NoteSurfaceState();
}

class _NoteSurfaceState extends ConsumerState<NoteSurface> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _rawController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final NoteBlockEditorController _editorController =
      NoteBlockEditorController();
  final MarkdownUndoHistory _undo = MarkdownUndoHistory();
  final _FormatAvailability _availability = _FormatAvailability();

  MarkdownDocument _document = MarkdownDocument.parse('');
  DocumentCaret? _caret;
  Timer? _saveDebounce;
  Note? _note;
  String? _ownerId;
  String _accentKey = 'mint';
  NoteSaveVisualState _saveState = NoteSaveVisualState.idle;
  Future<bool>? _inFlightSave;
  bool _initialized = false;
  bool _writing = false;
  bool _dirty = false;
  bool _allowPop = false;
  bool _detailsExpanded = true;
  bool _h1BannerDismissed = false;
  bool _rawMode = false;

  /// Whether a checklist has already been finished during this visit to the
  /// screen. Finishing one twice is still finishing it once.
  bool _checklistCelebrated = false;
  bool _showsChecklistComplete = false;

  /// The body as it stands right now.
  ///
  /// In plain text mode the field is the only source of truth: the document
  /// behind it is deliberately left unparsed until the reader leaves, so a save
  /// that read the document would write back text the reader has replaced.
  String get _currentBody =>
      _rawMode ? _rawController.text : _document.serialize();

  bool get _showsH1Banner =>
      !_rawMode &&
      !_h1BannerDismissed &&
      _titleController.text.trim().isEmpty &&
      _document.blocks.isNotEmpty &&
      _document.blocks.first.type == MarkdownBlockType.heading &&
      _document.blocks.first.headingLevel == 1;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _titleController.dispose();
    _tagsController
      ..removeListener(_markDirty)
      ..dispose();
    _rawController.dispose();
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

    final usesSideColumn = _usesSideColumn(context);
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final saved = await _saveNow();
        if (saved) await _popWithResult();
      },
      child: Scaffold(
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
              key: const ValueKey('note-copy-markdown'),
              tooltip: 'Copiar Markdown',
              onPressed: _copyMarkdown,
              icon: const Icon(
                Icons.copy_all_rounded,
                semanticLabel: 'Copiar Markdown',
              ),
            ),
            IconButton(
              key: const ValueKey('note-raw-mode'),
              tooltip: _rawMode ? 'Volver al editor' : 'Editar como texto',
              onPressed: _toggleRawMode,
              icon: _rawMode
                  ? const Icon(
                      Icons.view_agenda_outlined,
                      semanticLabel: 'Volver al editor',
                    )
                  : const Icon(
                      Icons.text_snippet_outlined,
                      semanticLabel: 'Editar como texto',
                    ),
            ),
            if (!usesSideColumn)
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
            if (_writing)
              IconButton(
                key: const ValueKey('note-done'),
                tooltip: 'Listo',
                onPressed: _stopWriting,
                icon: const Icon(Icons.check_rounded),
              ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _formatBarSlot(
            context,
            NoteFormatBar(
              // Every command on the bar acts on the block under the caret,
              // and plain text mode has no blocks and no caret to act on.
              visible: _writing && !_rawMode,
              activeCommand: _activeCommand,
              availableCommands: _availableCommands,
              blockAcceptsNoCommand: _blockAcceptsNoCommand,
              onCommand: _applyCommand,
              onBold: _wrapCallback(MarkdownInlineStyle.bold),
              onItalic: _wrapCallback(MarkdownInlineStyle.italic),
              onUndo: _undo.canUndo ? _performUndo : null,
              onRedo: _undo.canRedo ? _performRedo : null,
            ),
          ),
        ),
        body: ResponsiveLayoutBuilder(
          builder: (context, layout) {
            final editor = Padding(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPagePadding,
                layout.verticalPagePadding,
                layout.horizontalPagePadding,
                context.spacing.md,
              ),
              child: ResponsiveContentFrame(
                maxWidth: 760,
                child: _buildEditor(context),
              ),
            );
            if (!usesSideColumn || !_detailsExpanded) return editor;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: editor),
                const VerticalDivider(width: 1),
                SizedBox(
                  key: const ValueKey('note-details-column'),
                  width: _detailsColumnWidth,
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
                          padding: EdgeInsets.fromLTRB(
                            context.spacing.md,
                            0,
                            context.spacing.md,
                            context.spacing.md,
                          ),
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
      ),
    );
  }

  /// Grows and shrinks the bar's slot, except when there is no animation to
  /// give. An [AnimatedSize] with a zero duration re-dirties itself during its
  /// own layout, so with Reduced Motion or a screen reader on it throws instead
  /// of simply appearing.
  Widget _formatBarSlot(BuildContext context, Widget child) {
    const slot = ValueKey('note-format-bar-slot');
    if (context.motionPolicy.reduceMotion) {
      return KeyedSubtree(key: slot, child: child);
    }
    return AnimatedSize(
      key: slot,
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildEditor(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildTitle(context),
        if (_showsH1Banner) _buildH1Banner(context),
        SizedBox(height: context.spacing.sm),
        if (_rawMode)
          _buildRawField(context)
        else ...[
          NoteBlockEditor(
            document: _document,
            controller: _editorController,
            onChanged: _onDocumentChanged,
            onCaretChanged: _onCaretChanged,
            // The field's own history would restore one block's text over
            // another's, so the keyboard's undo reaches this one instead.
            onUndo: _performUndo,
            onRedo: _performRedo,
          ),
          if (_showsChecklistComplete) _buildChecklistDone(context),
        ],
      ],
    );
  }

  /// The quiet confirmation that every box on the note is ticked.
  Widget _buildChecklistDone(BuildContext context) {
    return Semantics(
      key: const ValueKey('note-checklist-complete'),
      // Read out where it stands, so the caret is never pulled away from the
      // box the reader just ticked.
      liveRegion: true,
      label: _checklistDoneMessage,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(top: context.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: context.zentraPalette.brandTeal,
            ),
            SizedBox(width: context.spacing.xs),
            // Expanded rather than a bare text: at a large text scale the line
            // has to wrap instead of running off the edge.
            Expanded(
              child: Text(
                _checklistDoneMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The whole body as literal Markdown, the way out when the block editor
  /// cannot show or repair something.
  ///
  /// Nothing typed here is parsed until the reader leaves the mode, so even
  /// text that never becomes a valid block is kept exactly as written.
  Widget _buildRawField(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.5,
          fontFamily: monospaceFontFamilies.first,
          fontFamilyFallback: monospaceFontFamilies.sublist(1),
        );
    return ConstrainedBox(
      // An empty note would otherwise leave a single line to aim at.
      constraints: const BoxConstraints(minHeight: _touchTarget),
      child: TextField(
        key: const ValueKey('note-raw-field'),
        controller: _rawController,
        maxLines: null,
        style: style,
        decoration: const InputDecoration(
          hintText: 'Markdown de la nota',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (_) => _markDirty(),
      ),
    );
  }

  /// The title is a plain heading until the note is being written, so a note
  /// that is only being read shows no field and no caret anywhere.
  Widget _buildTitle(BuildContext context) {
    final style = noteTitleTextStyle(context);
    if (_writing) {
      return TextField(
        key: const ValueKey('note-title-field'),
        controller: _titleController,
        focusNode: _titleFocus,
        style: style,
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
      );
    }
    final title = _titleController.text.trim();
    return Semantics(
      button: true,
      header: true,
      label: title.isEmpty ? 'Nota sin título. Toca para escribir.' : title,
      child: GestureDetector(
        key: const ValueKey('note-title-heading'),
        behavior: HitTestBehavior.opaque,
        onTap: _startWritingTitle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _touchTarget),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              title.isEmpty ? 'Nota sin título' : title,
              style: title.isEmpty
                  ? style?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : style,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildH1Banner(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(64, _touchTarget),
    );
    return Card(
      key: const ValueKey('note-h1-banner'),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta nota empieza con un encabezado.'),
            SizedBox(height: context.spacing.xs),
            Wrap(
              spacing: context.spacing.xs,
              children: [
                TextButton(
                  style: buttonStyle,
                  onPressed: _useH1AsTitle,
                  child: const Text('Usar como título'),
                ),
                TextButton(
                  style: buttonStyle,
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

  /// The details only become a column when the window is wide enough and the
  /// reader's text is small enough for two columns to still be readable.
  bool _usesSideColumn(BuildContext context) =>
      ZentraBreakpoints.windowClassFor(MediaQuery.sizeOf(context).width)
          .isAtLeastExpanded &&
      MediaQuery.textScalerOf(context).scale(16) <= _sideColumnTextCeiling;

  /// [onRefresh] repaints a host that owns its own element tree, such as the
  /// bottom sheet, which this state cannot rebuild on its own.
  Widget _buildDetailsPanel({VoidCallback? onRefresh}) => NoteDetailsPanel(
        onReminder: _openReminder,
        tagsController: _tagsController,
        accentKey: _accentKey,
        onAccentChanged: (value) {
          setState(() => _accentKey = value);
          _markDirty();
          onRefresh?.call();
        },
        onFocus: _note == null ? null : _startFocus,
        isPinned: _note?.isPinned ?? false,
        onTogglePin: _note == null
            ? null
            : () async {
                await _togglePin();
                onRefresh?.call();
              },
      );

  NoteBlockCommand? get _activeCommand {
    final caret = _caret;
    if (caret == null || caret.blockIndex >= _document.blocks.length) {
      return null;
    }
    return activeCommandFor(_document.blocks[caret.blockIndex]);
  }

  /// The commands the bar may offer as live right now.
  Set<NoteBlockCommand> get _availableCommands =>
      _availability.commandsFor(_document, _caret);

  /// Whether the block under the caret refuses everything that could change
  /// it, which is the one case where the bar points at plain text mode.
  ///
  /// The separator is discounted: it inserts a rule under the block rather
  /// than rewriting it, so it stays available on a block nothing else reaches
  /// and would otherwise make every block look editable.
  bool get _blockAcceptsNoCommand {
    final caret = _caret;
    if (caret == null || caret.blockIndex >= _document.blocks.length) {
      return false;
    }
    return _availableCommands
        .difference(const {NoteBlockCommand.divider}).isEmpty;
  }

  /// The bold or italic action, or null when wrapping the current selection
  /// would do nothing.
  VoidCallback? _wrapCallback(MarkdownInlineStyle style) {
    final available = _availability.stylesFor(
      _document,
      _caret,
      _editorController.sourceSelection,
    );
    if (!available.contains(style)) return null;
    return () => _wrap(style);
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
    // Attached after the seed values land, so restoring a note is not mistaken
    // for the reader editing it.
    _tagsController.addListener(_markDirty);
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
    // Checking a box is a deliberate act with no follow up typing, and it is
    // often the last thing done before closing the note, so it skips the
    // debounce and lands on disk right away.
    final tickedBox = document.checkedCount != _document.checkedCount &&
        document.checkItemCount == _document.checkItemCount;
    setState(() {
      _document = document;
      _showsChecklistComplete = _confirmsChecklist(document, tickedBox);
    });
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

  /// Whether the finished checklist line belongs on screen now that
  /// [document] has landed, given whether a box was ticked to produce it.
  ///
  /// Only a tick can finish a checklist. Deleting the last pending item leaves
  /// the rest ticked without anything having been done, and a note that was
  /// already complete when it opened never crossed the line at all. Once shown
  /// the message leaves as soon as a box is unticked and does not come back,
  /// so the same checklist cannot be finished twice in one visit.
  ///
  /// Only call inside a [setState]: it latches the visit's one confirmation.
  bool _confirmsChecklist(MarkdownDocument document, bool tickedBox) {
    final isComplete = document.checkItemCount > 0 &&
        document.checkedCount == document.checkItemCount;
    if (!isComplete) return false;
    if (_showsChecklistComplete) return true;
    if (!tickedBox || _checklistCelebrated) return false;
    _checklistCelebrated = true;
    return true;
  }

  void _onCaretChanged(DocumentCaret? caret) {
    final movedBlock = caret?.blockIndex != _caret?.blockIndex;
    setState(() {
      _caret = caret;
      _writing = caret != null || _writing;
    });
    // The editor has already written the block being left into the document,
    // so this saves the finished block instead of waiting out the debounce.
    if (movedBlock && _dirty) unawaited(_saveNow());
  }

  void _markDirty() {
    if (!_initialized) return;
    _saveDebounce?.cancel();
    setState(() {
      _dirty = true;
      _saveState = NoteSaveVisualState.saving;
    });
    _saveDebounce = Timer(_saveDebounceDelay, _saveNow);
  }

  void _applyCommand(NoteBlockCommand command) {
    final caret = _caret;
    if (caret == null) return;
    final edit = applyBlockCommand(_document, caret, command);
    _onDocumentChanged(edit.document);
    _editorController.focusBlock(
      edit.caret.blockIndex,
      offset: edit.caret.offset,
    );
  }

  void _wrap(MarkdownInlineStyle style) {
    final caret = _caret;
    final selection = _editorController.sourceSelection;
    if (caret == null || selection == null || selection.isCollapsed) return;
    final edit = wrapSelection(
      _document,
      caret.blockIndex,
      selection.start,
      selection.end,
      style,
    );
    _onDocumentChanged(edit.document);
    _editorController.focusBlock(
      edit.caret.blockIndex,
      offset: edit.caret.offset,
    );
  }

  void _performUndo() {
    final restored = _undo.undo(_document.serialize());
    if (restored == null) return;
    setState(() => _replaceDocument(MarkdownDocument.parse(restored)));
    _markDirty();
  }

  void _performRedo() {
    final restored = _undo.redo();
    if (restored == null) return;
    setState(() => _replaceDocument(MarkdownDocument.parse(restored)));
    _markDirty();
  }

  /// Swaps the document wholesale, for the paths that restore a body instead of
  /// editing one. Undoing the tick that finished a checklist has to take the
  /// confirmation down with it. Only call inside a [setState].
  void _replaceDocument(MarkdownDocument document) {
    _document = document;
    _showsChecklistComplete = _confirmsChecklist(document, false);
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

  void _startWritingTitle() {
    setState(() => _writing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  void _stopWriting() {
    FocusScope.of(context).unfocus();
    setState(() {
      // There is no rendered plain text mode to stay in once writing is over.
      if (_rawMode) _leaveRawMode();
      _writing = false;
    });
    unawaited(_saveNow());
  }

  /// Swaps the block editor for the note's literal Markdown, and back.
  void _toggleRawMode() {
    setState(() {
      if (_rawMode) {
        _leaveRawMode();
        return;
      }
      _rawController.text = _document.serialize();
      _rawMode = true;
      _caret = null;
      _writing = true;
    });
    unawaited(_saveNow());
  }

  /// Turns what the field holds back into blocks. Only call inside a
  /// [setState]: this reads and replaces the document the body is built from.
  ///
  /// The body being left becomes a restore point, so a round trip the reader
  /// did not mean to make is one undo away.
  void _leaveRawMode() {
    _undo.record(_document.serialize());
    _replaceDocument(MarkdownDocument.parse(_rawController.text));
    _rawMode = false;
  }

  /// Copies the whole body, the mitigation for the one thing the block editor
  /// cannot do: a selection never spans two blocks, so there is no way to
  /// select the note and copy it by hand.
  Future<void> _copyMarkdown() async {
    await Clipboard.setData(ClipboardData(text: _currentBody));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown copiado.')),
    );
  }

  /// Saves, queueing behind any write already on its way to disk.
  ///
  /// This screen writes far more often than a debounce alone would, so turning
  /// a caller away while another write is in flight would leave the reader
  /// pressing Back on a screen that refuses to close.
  Future<bool> _saveNow() async {
    final pending = _inFlightSave;
    if (pending != null) await pending;
    final write = _write();
    _inFlightSave = write;
    try {
      return await write;
    } finally {
      if (identical(_inFlightSave, write)) _inFlightSave = null;
    }
  }

  Future<bool> _write() async {
    if (!mounted) return false;
    if (!_dirty && _note != null) return true;
    final ownerId = _ownerId;
    if (ownerId == null) return false;
    final title = _titleController.text.trim();
    final body = _currentBody;
    if (_note == null && title.isEmpty && body.trim().isEmpty) {
      setState(() {
        _dirty = false;
        _saveState = NoteSaveVisualState.idle;
      });
      return true;
    }
    _saveDebounce?.cancel();
    setState(() => _saveState = NoteSaveVisualState.saving);
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
    }
  }

  Future<void> _openDetails() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              0,
              context.spacing.md,
              context.spacing.md,
            ),
            // A stack of tiles and chips, not prose: past this width the
            // tiles stop reading as controls and start reading as banners.
            child: ResponsiveContentFrame(
              maxWidth: _detailsSheetWidth,
              child: _buildDetailsPanel(
                onRefresh: () => setSheetState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
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
    final ownerId = _ownerId;
    if (note == null || ownerId == null) return;
    ref.read(noteControllerProvider(ownerId).notifier).selectNote(note.id);
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
    if (!mounted) return;
    setState(() => _note = note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> _close() async {
    final saved = await _saveNow();
    if (saved) await _popWithResult();
  }

  Future<void> _popWithResult() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(_note?.id);
  }
}

/// Which toolbar controls can act, remembered against what they were computed
/// from.
///
/// Each answer runs a whole document transformation, reparse included, and the
/// bar asks nine times. This screen rebuilds on much more than an edit: the
/// caret moving, the save indicator changing and the details panel opening all
/// land here, and none of them change what the bar may offer. On a note of a
/// few hundred lines a full pass costs about a millisecond, so the answers are
/// kept until the things they were computed from move.
///
/// Cached rather than restated: the predicates run the real transformation, so
/// they cannot drift from the commands, and only what they depend on is used as
/// the key. A block command depends on the document and which block the caret
/// is in, never on where in the block it sits; a wrap depends on the selection
/// as well.
class _FormatAvailability {
  MarkdownDocument? _commandDocument;
  int? _commandBlock;
  Set<NoteBlockCommand> _commands = const {};

  MarkdownDocument? _styleDocument;
  int? _styleBlock;
  TextSelection? _styleSelection;
  Set<MarkdownInlineStyle> _styles = const {};

  Set<NoteBlockCommand> commandsFor(
    MarkdownDocument document,
    DocumentCaret? caret,
  ) {
    if (caret == null || caret.blockIndex >= document.blocks.length) {
      return const {};
    }
    if (identical(_commandDocument, document) &&
        _commandBlock == caret.blockIndex) {
      return _commands;
    }
    _commandDocument = document;
    _commandBlock = caret.blockIndex;
    return _commands = {
      for (final command in NoteBlockCommand.values)
        if (canApplyBlockCommand(document, caret, command)) command,
    };
  }

  /// Only the two styles the bar offers: asking for the others would pay for
  /// an answer nothing reads.
  Set<MarkdownInlineStyle> stylesFor(
    MarkdownDocument document,
    DocumentCaret? caret,
    TextSelection? selection,
  ) {
    if (caret == null ||
        selection == null ||
        !selection.isValid ||
        selection.isCollapsed) {
      return const {};
    }
    if (identical(_styleDocument, document) &&
        _styleBlock == caret.blockIndex &&
        _styleSelection == selection) {
      return _styles;
    }
    _styleDocument = document;
    _styleBlock = caret.blockIndex;
    _styleSelection = selection;
    return _styles = {
      for (final style in const [
        MarkdownInlineStyle.bold,
        MarkdownInlineStyle.italic,
      ])
        if (canWrapSelection(
          document,
          caret.blockIndex,
          selection.start,
          selection.end,
          style,
        ))
          style,
    };
  }
}
