// test/unit/markdown_undo_history_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_editing.dart';
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

  test('redo keeps the older snapshots reachable by undo', () {
    final history = MarkdownUndoHistory()
      ..record('a')
      ..record('b');
    expect(history.undo('c'), 'b');
    expect(history.undo('b'), 'a');
    expect(history.redo(), 'b');
    expect(history.redo(), 'c');
    expect(history.undo('c'), 'b');
    expect(history.undo('b'), 'a');
  });

  test('canUndo and canRedo track what is reachable', () {
    final history = MarkdownUndoHistory();
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
    history.record('a');
    expect(history.canUndo, isTrue);
    history.undo('ab');
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    history.redo();
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
  });

  test('undo restores the caret recorded with the snapshot', () {
    final history = MarkdownUndoHistory()
      ..record('a', caret: const DocumentCaret(blockIndex: 0, offset: 1));
    expect(history.undo('ab'), 'a');
    expect(
      history.restoredCaret,
      const DocumentCaret(blockIndex: 0, offset: 1),
    );
  });

  test('redo restores the caret the undone state was left with', () {
    final history = MarkdownUndoHistory()..record('a');
    history.undo('a\nb', caret: const DocumentCaret(blockIndex: 1, offset: 1));
    expect(history.restoredCaret, isNull);
    expect(history.redo(), 'a\nb');
    expect(
      history.restoredCaret,
      const DocumentCaret(blockIndex: 1, offset: 1),
    );
  });

  test('a refused undo does not leave a stale caret behind', () {
    final history = MarkdownUndoHistory()
      ..record('a', caret: const DocumentCaret(blockIndex: 0, offset: 1));
    history.undo('ab');
    expect(history.undo('a'), isNull);
    expect(history.restoredCaret, isNull);
  });
}
