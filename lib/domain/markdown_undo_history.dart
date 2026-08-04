// lib/domain/markdown_undo_history.dart
import 'markdown_editing.dart';

/// One restore point: the whole note body plus where the caret was.
class _Snapshot {
  final String markdown;
  final DocumentCaret? caret;

  const _Snapshot(this.markdown, this.caret);
}

/// Document level undo for the note editor.
///
/// Snapshots are serialized Markdown, not text field states, so undo survives
/// block splits, merges and toolbar commands.
///
/// The current state lives with the caller, which is why [undo] asks for it:
/// the history only keeps what came before and what was undone.
class MarkdownUndoHistory {
  final int maxEntries;
  final List<_Snapshot> _past = [];
  final List<_Snapshot> _future = [];

  /// The state the caller is showing, known only after an [undo] or a [redo].
  /// [redo] needs it because moving forward pushes the state being left onto
  /// the undo stack, and the caller never hands it over a second time.
  _Snapshot? _current;

  DocumentCaret? _restoredCaret;

  MarkdownUndoHistory({this.maxEntries = 50})
      : assert(
          maxEntries > 0,
          'A history with no room cannot restore anything',
        );

  bool get canUndo => _past.isNotEmpty;

  bool get canRedo => _future.isNotEmpty;

  /// The caret stored with the snapshot the last [undo] or [redo] returned, or
  /// null when that call failed or the snapshot was recorded without one.
  DocumentCaret? get restoredCaret => _restoredCaret;

  /// Stores [markdown] as a restore point, with the caret it was edited at.
  ///
  /// Consecutive duplicates are ignored: they would cost the user an undo press
  /// that changes nothing on screen. Anything else counts as a fresh edit and
  /// drops the redo stack, which describes a future that no longer exists.
  void record(String markdown, {DocumentCaret? caret}) {
    if (_past.isNotEmpty && _past.last.markdown == markdown) return;
    _past.add(_Snapshot(markdown, caret));
    _trimPast();
    _future.clear();
    _current = null;
  }

  /// Returns the previous snapshot, remembering [current] so [redo] can restore
  /// it, along with the [caret] the caller is leaving behind.
  String? undo(String current, {DocumentCaret? caret}) {
    _restoredCaret = null;
    if (_past.isEmpty) return null;
    var previous = _past.removeLast();
    // A restore point identical to what is on screen would look like a dead
    // button, so skip it and hand back the one before it.
    if (previous.markdown == current) {
      if (_past.isEmpty) return null;
      previous = _past.removeLast();
    }
    final leaving = _Snapshot(current, caret);
    _future.add(leaving);
    _current = previous;
    _restoredCaret = previous.caret;
    return previous.markdown;
  }

  /// Returns the snapshot the last [undo] took away.
  String? redo() {
    _restoredCaret = null;
    if (_future.isEmpty) return null;
    final next = _future.removeLast();
    // Push the state being left, not the one being restored: pushing the
    // restored state would drop an undo level on every undo and redo pair.
    final leaving = _current;
    if (leaving != null) {
      _past.add(leaving);
      _trimPast();
    }
    _current = next;
    _restoredCaret = next.caret;
    return next.markdown;
  }

  /// Keeps the oldest entries from piling up during a long editing session.
  void _trimPast() {
    while (_past.length > maxEntries) {
      _past.removeAt(0);
    }
  }
}
