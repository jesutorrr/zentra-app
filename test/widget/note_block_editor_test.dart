// test/widget/note_block_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/presentation/widgets/note_block_editor.dart';

const _sentinel = '\u200B';

void main() {
  late MarkdownDocument document;
  late NoteBlockEditorController controller;
  late StateSetter rebuild;
  DocumentCaret? caret;

  setUp(() {
    controller = NoteBlockEditorController();
    caret = null;
  });

  tearDown(() => controller.dispose());

  // The trailing button stands in for the rest of the note screen. Without a
  // second focusable the default handling of `TextInputAction.next` has
  // nowhere to send focus, and a field that gives it away would look fine.
  Widget host() => MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Column(
                children: [
                  NoteBlockEditor(
                    document: document,
                    controller: controller,
                    onChanged: (next) => setState(() => document = next),
                    onCaretChanged: (value) => caret = value,
                  ),
                  TextButton(onPressed: () {}, child: const Text('Guardar')),
                ],
              );
            },
          ),
        ),
      );

  TextEditingController fieldOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  testWidgets('tapping a block turns it into a raw text field', (tester) async {
    document = MarkdownDocument.parse('## Examen\ncuerpo');
    await tester.pumpWidget(host());
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.textContaining('Examen'));
    await tester.pumpAndSettle();

    expect(fieldOf(tester).text.replaceAll(_sentinel, ''), '## Examen');
  });

  testWidgets('typing rewrites only the active block', (tester) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '$_sentinel# uno');
    await tester.pumpAndSettle();

    expect(document.serialize(), '# uno\ndos');
    expect(document.blocks.first.type, MarkdownBlockType.heading);
  });

  testWidgets('submitting splits the block and moves the caret down', (
    tester,
  ) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    await tester.tap(find.textContaining('leer'));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(document.serialize(), '- leer\n- ');
  });

  testWidgets('losing the sentinel merges with the previous block', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('dos'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'dos');
    await tester.pumpAndSettle();

    expect(document.serialize(), 'unodos');
  });

  testWidgets('read only mode never shows a text field', (tester) async {
    document = MarkdownDocument.parse('uno');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteBlockEditor(
            document: document,
            readOnly: true,
            onChanged: (_) {},
            onCaretChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  // Every keystroke reaches the document, but a block change must not depend
  // on that: whatever the field holds has to be written down before the
  // controller is pointed somewhere else.
  testWidgets('leaving a block commits its edit before the field moves', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '${_sentinel}uno editado');
    await tester.pumpAndSettle();
    await tester.tap(find.text('dos'));
    await tester.pumpAndSettle();

    expect(document.serialize(), 'uno editado\ndos');
    expect(fieldOf(tester).text, '${_sentinel}dos');
  });

  // The sentinel is a detection trick, not content. A note that saved it would
  // grow an invisible character on every visit.
  testWidgets('the sentinel never reaches the document', (tester) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 6);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '$_sentinel$_sentinel- leer$_sentinel',
    );
    await tester.pumpAndSettle();
    expect(document.serialize(), '- leer');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(document.serialize(), '- leer\n- ');
    expect(document.serialize().contains(_sentinel), isFalse);
  });

  testWidgets('Enter leaves the caret exactly where splitBlock put it', (
    tester,
  ) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 6);
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final expected = splitBlock(
      MarkdownDocument.parse('- leer'),
      const DocumentCaret(blockIndex: 0, offset: 6),
    ).caret;
    expect(caret, expected);
    expect(fieldOf(tester).text, '$_sentinel- ');
    expect(fieldOf(tester).selection.baseOffset, _sentinel.length + 2);
  });

  testWidgets('Backspace at the start merges and keeps the domain caret', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    controller.focusBlock(1, offset: 0);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(document.serialize(), 'unodos');
    expect(caret, const DocumentCaret(blockIndex: 0, offset: 3));
    expect(fieldOf(tester).text, '${_sentinel}unodos');
    expect(fieldOf(tester).selection.baseOffset, _sentinel.length + 3);
  });

  testWidgets('Tab and Shift Tab move the indent and the caret with it', (
    tester,
  ) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 4);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(document.serialize(), '  - leer');
    expect(caret, const DocumentCaret(blockIndex: 0, offset: 6));
    expect(fieldOf(tester).selection.baseOffset, _sentinel.length + 6);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(document.serialize(), '- leer');
    expect(caret, const DocumentCaret(blockIndex: 0, offset: 4));
    expect(fieldOf(tester).selection.baseOffset, _sentinel.length + 4);
  });

  // The listener writes to the document on every keystroke and the document
  // comes back as a rebuild. If the two fight, the caret snaps to the end.
  testWidgets('typing in the middle keeps the caret where the user left it', (
    tester,
  ) async {
    document = MarkdownDocument.parse('hola mundo');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 4);
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '${_sentinel}holax mundo',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    await tester.pump();
    expect(document.serialize(), 'holax mundo');
    expect(fieldOf(tester).selection.baseOffset, 6);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '${_sentinel}holaxy mundo',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    await tester.pumpAndSettle();
    expect(document.serialize(), 'holaxy mundo');
    expect(fieldOf(tester).selection.baseOffset, 7);
    expect(caret, const DocumentCaret(blockIndex: 0, offset: 6));
  });

  // A select all and replace also wipes the sentinel, but it is not a
  // Backspace: merging there would throw away what the user just typed.
  testWidgets('replacing the whole field does not merge', (tester) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('dos'));
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'X',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(document.serialize(), 'uno\nX');
    expect(fieldOf(tester).text, '${_sentinel}X');
  });

  // An undo or a toolbar command rewrites the body from outside. The field has
  // to follow it instead of holding on to the line it happened to be showing.
  testWidgets('an external document change rebinds the active field', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();
    expect(fieldOf(tester).text, '${_sentinel}uno');

    rebuild(() => document = MarkdownDocument.parse('# uno\ndos'));
    await tester.pumpAndSettle();

    expect(fieldOf(tester).text, '$_sentinel# uno');
    expect(document.serialize(), '# uno\ndos');
  });

  testWidgets('Backspace on the first block keeps the text and re-arms', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 0);
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'uno',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(document.serialize(), 'uno');
    expect(fieldOf(tester).text, '${_sentinel}uno');
  });
}
