// test/widget/note_block_editor_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/presentation/widgets/note_block_editor.dart';
import 'package:zentra/presentation/widgets/note_block_view.dart';

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
  Widget host({
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    double textScale = 1,
    bool readOnly = false,
  }) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    NoteBlockEditor(
                      document: document,
                      controller: controller,
                      readOnly: readOnly,
                      onChanged: (next) => setState(() => document = next),
                      onCaretChanged: (value) => caret = value,
                      onUndo: onUndo,
                      onRedo: onRedo,
                    ),
                    TextButton(onPressed: () {}, child: const Text('Guardar')),
                  ],
                );
              },
            ),
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
  testWidgets('the editor\'s own sentinel never reaches the document', (
    tester,
  ) async {
    document = MarkdownDocument.parse('- leer');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 6);
    await tester.pumpAndSettle();

    expect(fieldOf(tester).text, '$_sentinel- leer');
    expect(document.serialize(), '- leer');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(document.serialize(), '- leer\n- ');
    expect(document.serialize().contains(_sentinel), isFalse);
  });

  // A zero width space arrives in anything pasted from the web and carries
  // meaning in Thai and Khmer. Only the one this widget inserted is its own.
  group('a zero width space the user owns', () {
    testWidgets('survives entering and leaving the block', (tester) async {
      document = MarkdownDocument.parse('hola${_sentinel}mundo\nsegunda');
      await tester.pumpWidget(host());

      await tester.tap(find.textContaining('hola'));
      await tester.pumpAndSettle();
      expect(fieldOf(tester).text, '${_sentinel}hola${_sentinel}mundo');

      await tester.tap(find.text('segunda'));
      await tester.pumpAndSettle();

      expect(document.serialize(), 'hola${_sentinel}mundo\nsegunda');
    });

    testWidgets('survives a keystroke on the same block', (tester) async {
      document = MarkdownDocument.parse('hola${_sentinel}mundo');
      await tester.pumpWidget(host());
      await tester.tap(find.textContaining('hola'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '${_sentinel}hola${_sentinel}mundo!',
      );
      await tester.pumpAndSettle();

      expect(document.serialize(), 'hola${_sentinel}mundo!');
    });
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

  // Indentation means nothing on a paragraph, so the domain refuses it. If the
  // editor still swallowed the key, a keyboard user would be stuck in the body
  // with no way to reach anything else on the screen.
  testWidgets('Tab on a block that cannot indent hands focus on', (
    tester,
  ) async {
    document = MarkdownDocument.parse('texto');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 2);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(document.serialize(), 'texto');
    expect(find.byType(TextField), findsNothing);
    expect(caret, isNull);
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

  testWidgets('a document that lost the active block closes the field', (
    tester,
  ) async {
    document = MarkdownDocument.parse('uno\ndos');
    await tester.pumpWidget(host());
    await tester.tap(find.text('dos'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    rebuild(() => document = MarkdownDocument.parse('uno'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('uno'), findsOneWidget);
  });

  testWidgets('turning read only on closes the open field', (tester) async {
    document = MarkdownDocument.parse('uno\ndos');
    var readOnly = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NoteBlockEditor(
                document: document,
                controller: controller,
                readOnly: readOnly,
                onChanged: (next) => setState(() => document = next),
                onCaretChanged: (value) => caret = value,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('uno'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    rebuild(() => readOnly = true);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(document.serialize(), 'uno\ndos');
  });

  group('Backspace on the first block', () {
    testWidgets('keeps the text and re-arms', (tester) async {
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

    // On the hardware path the sentinel is still in the field, so re-arming
    // over the raw text left a second one behind: the published selection then
    // sat a character ahead of the block, and bold wrapped the wrong letters.
    testWidgets('leaves exactly one sentinel, however it arrived', (
      tester,
    ) async {
      document = MarkdownDocument.parse('uno');
      await tester.pumpWidget(host());
      controller.focusBlock(0, offset: 0);
      await tester.pumpAndSettle();

      for (var press = 1; press <= 2; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();

        expect(fieldOf(tester).text, '${_sentinel}uno', reason: 'press $press');
        expect(document.serialize(), 'uno', reason: 'press $press');
        expect(caret, const DocumentCaret(blockIndex: 0, offset: 0));
        expect(controller.sourceSelection!.baseOffset, 0);
      }
    });
  });

  // The screen wraps a selection by handing these offsets to the domain, so
  // they have to index the source line the domain is about to rewrite.
  testWidgets('the published selection is measured on the block source', (
    tester,
  ) async {
    document = MarkdownDocument.parse('- hola mundo');
    await tester.pumpWidget(host());
    controller.focusBlock(0, offset: 0);
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '$_sentinel- hola mundo',
        selection: TextSelection(baseOffset: 3, extentOffset: 7),
      ),
    );
    await tester.pumpAndSettle();

    final selection = controller.sourceSelection!;
    expect(selection.start, 2);
    expect(selection.end, 6);
    expect('- hola mundo'.substring(selection.start, selection.end), 'hola');
  });

  // Every source line of a fence lives in one block, so a single line field
  // would strip the newlines on the first keystroke and leave an open fence
  // swallowing everything under it.
  group('a code fence', () {
    const body = '```dart\nlet a = 1;\n```\ntexto después\n- pendiente';

    testWidgets('survives being edited', (tester) async {
      document = MarkdownDocument.parse(body);
      await tester.pumpWidget(host());
      await tester.tap(find.textContaining('let a = 1;'));
      await tester.pumpAndSettle();
      expect(fieldOf(tester).text, '$_sentinel```dart\nlet a = 1;\n```');

      await tester.enterText(
        find.byType(TextField),
        '$_sentinel```dart\nlet a = 2;\n```',
      );
      await tester.pumpAndSettle();

      expect(
        document.serialize(),
        '```dart\nlet a = 2;\n```\ntexto después\n- pendiente',
      );
      expect(document.blocks, hasLength(3));
      expect(document.blocks[1].text, 'texto después');
      expect(document.blocks[2].type, MarkdownBlockType.bulletItem);
    });

    testWidgets('grows a line instead of splitting on Return', (tester) async {
      document = MarkdownDocument.parse('```\nuno\n```');
      await tester.pumpWidget(host());
      controller.focusBlock(0, offset: 7);
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(document.serialize(), '```\nuno\n\n```');
      expect(document.blocks, hasLength(1));
      expect(document.blocks.single.type, MarkdownBlockType.codeFence);
    });

    // The caret has to land on the source line, which starts three characters
    // and a newline before the first line of code.
    testWidgets('opens with the caret on the line that was tapped', (
      tester,
    ) async {
      document = MarkdownDocument.parse('```\nhola\n```');
      await tester.pumpWidget(host());

      final origin = tester.getTopLeft(
        find.byKey(const ValueKey('note-block-text')),
      );
      await tester.tapAt(origin + const Offset(1, 6));
      await tester.pumpAndSettle();

      expect(caret, const DocumentCaret(blockIndex: 0, offset: 4));
      expect(fieldOf(tester).selection.baseOffset, _sentinel.length + 4);
    });
  });

  testWidgets('an unsupported line opens as the raw text it is', (
    tester,
  ) async {
    document = MarkdownDocument.parse('| a | b |\ntexto');
    await tester.pumpWidget(host());
    expect(document.blocks.first.type, MarkdownBlockType.raw);

    await tester.tap(find.textContaining('| a | b |'));
    await tester.pumpAndSettle();

    expect(fieldOf(tester).text, '$_sentinel| a | b |');
    expect(caret!.blockIndex, 0);

    await tester.enterText(find.byType(TextField), '$_sentinel| a | c |');
    await tester.pumpAndSettle();
    expect(document.serialize(), '| a | c |\ntexto');
  });

  // Three backticks in a paragraph parse into a fence that eats every block
  // below it. The line is kept exactly as typed, as a block that cannot.
  testWidgets('a line that would reparse into a fence is kept literal', (
    tester,
  ) async {
    document = MarkdownDocument.parse('nota\nsegunda');
    await tester.pumpWidget(host());
    await tester.tap(find.text('nota'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '$_sentinel```');
    await tester.pumpAndSettle();

    expect(document.serialize(), '```\nsegunda');
    expect(document.blocks, hasLength(2));
    expect(document.blocks.first.type, MarkdownBlockType.raw);
    expect(document.blocks.last.type, MarkdownBlockType.paragraph);
    expect(document.blocks.last.text, 'segunda');
  });

  // Pasting a document is a first class case for this editor: the whole point
  // of the escape hatch is that it should rarely be needed.
  testWidgets('a multi line paste keeps its line breaks and becomes blocks', (
    tester,
  ) async {
    document = MarkdownDocument.parse('');
    await tester.pumpWidget(host());
    controller.focusBlock(0);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '$_sentinel# Titulo\n- uno\n- dos',
    );
    await tester.pumpAndSettle();

    expect(document.serialize(), '# Titulo\n- uno\n- dos');
    expect(document.blocks, hasLength(3));
    // The caret follows the text instead of staying on the first line.
    expect(caret, const DocumentCaret(blockIndex: 2, offset: 5));
    expect(fieldOf(tester).text, '$_sentinel- dos');
  });

  // The field keeps one undo history for the whole session while the editor
  // swaps blocks underneath it, so its own undo can pour one block's text into
  // another. Undo belongs to the document.
  testWidgets('undo never reaches the field\'s own history', (tester) async {
    // The platform decides which chord the framework turns into an undo, and
    // the reported corruption was on iOS, where a hardware keyboard, the
    // keyboard's undo key and shaking the phone all lead here.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var undos = 0;
    document = MarkdownDocument.parse('primero\nsegundo');
    try {
      await tester.pumpWidget(host(onUndo: () => undos++));

      await tester.tap(find.text('primero'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '${_sentinel}primero editado',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('segundo'));
      await tester.pumpAndSettle();
      expect(fieldOf(tester).text, '${_sentinel}segundo');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(undos, 1);
      expect(document.serialize(), 'primero editado\nsegundo');
      expect(fieldOf(tester).text, '${_sentinel}segundo');
    } finally {
      // Restored inside the body: the framework checks for a leaked debug
      // variable before any tear down of ours has run.
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // Cancelling a composition is what makes Japanese, Chinese and Korean IMEs,
  // and Android predictive text, re-commit their buffer and duplicate it.
  group('an open composing region', () {
    testWidgets('survives a block the parent rewrote', (tester) async {
      document = MarkdownDocument.parse('hola\nsegunda');
      await tester.pumpWidget(host());
      await tester.tap(find.text('hola'));
      await tester.pumpAndSettle();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '${_sentinel}hola mun',
          selection: TextSelection.collapsed(offset: 9),
          composing: TextRange(start: 6, end: 9),
        ),
      );
      await tester.pumpAndSettle();
      expect(fieldOf(tester).value.composing.isValid, isTrue);

      rebuild(
        () => document = MarkdownDocument.parse('hola mun\ntercera'),
      );
      await tester.pumpAndSettle();

      expect(
        fieldOf(tester).value.composing,
        const TextRange(start: 6, end: 9),
      );
      expect(fieldOf(tester).text, '${_sentinel}hola mun');
    });

    testWidgets('is left alone when only its own text changed', (tester) async {
      document = MarkdownDocument.parse('hola mundo');
      await tester.pumpWidget(host());
      await tester.tap(find.textContaining('hola'));
      await tester.pumpAndSettle();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '${_sentinel}hola mundo',
          selection: TextSelection.collapsed(offset: 11),
          composing: TextRange(start: 6, end: 11),
        ),
      );
      await tester.pumpAndSettle();

      rebuild(() => document = MarkdownDocument.parse('hola MUNDO'));
      await tester.pumpAndSettle();

      expect(fieldOf(tester).text, '${_sentinel}hola mundo');
      expect(
        fieldOf(tester).value.composing,
        const TextRange(start: 6, end: 11),
      );
    });
  });

  // The column rebuilds every block on every keystroke on purpose, so the
  // active field keeps its element and its focus. Re-tokenizing all of them
  // would make a long note quadratic to type in.
  testWidgets('a keystroke does not re-tokenize the untouched blocks', (
    tester,
  ) async {
    document = MarkdownDocument.parse(
      'uno **dos**\n- tres\n> cuatro\n# cinco',
    );
    debugResetNoteBlockSpanCache();
    await tester.pumpWidget(host());
    await tester.tap(find.textContaining('tres'));
    await tester.pumpAndSettle();

    final before = debugNoteBlockSpanBuilds;
    expect(before, greaterThan(0));

    await tester.enterText(find.byType(TextField), '$_sentinel- tres cosas');
    await tester.pumpAndSettle();

    expect(
      document.serialize(),
      'uno **dos**\n- tres cosas\n> cuatro\n# cinco',
    );
    expect(debugNoteBlockSpanBuilds, before);
  });

  testWidgets('the editor still works at a large text scale', (tester) async {
    document = MarkdownDocument.parse('# Título\n- uno');
    await tester.pumpWidget(host(textScale: 3.2));

    await tester.tap(find.textContaining('uno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '$_sentinel- uno y dos');
    await tester.pumpAndSettle();

    expect(document.serialize(), '# Título\n- uno y dos');
    expect(tester.takeException(), isNull);
  });
}
