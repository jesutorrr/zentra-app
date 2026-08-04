// test/widget/note_block_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/widgets/note_block_view.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

MarkdownBlock blockOf(String source) =>
    MarkdownDocument.parse(source).blocks.first;

void main() {
  testWidgets('renders a heading without its marker', (tester) async {
    await tester.pumpWidget(host(NoteBlockView(block: blockOf('## Examen'))));
    expect(find.textContaining('##'), findsNothing);
    expect(find.textContaining('Examen'), findsOneWidget);
  });

  testWidgets('checkbox reports taps and has a 44 point target', (
    tester,
  ) async {
    var toggled = 0;
    await tester.pumpWidget(
      host(
        NoteBlockView(
          block: blockOf('- [ ] leer'),
          onToggleCheck: () => toggled++,
        ),
      ),
    );
    final box =
        tester.getSize(find.byKey(const ValueKey('note-block-checkbox')));
    expect(box.width, greaterThanOrEqualTo(44));
    expect(box.height, greaterThanOrEqualTo(44));
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    expect(toggled, 1);
  });

  testWidgets('a checked item is struck through', (tester) async {
    await tester.pumpWidget(host(NoteBlockView(block: blockOf('- [x] listo'))));
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('note-block-text')),
    );
    expect(
      (text.textSpan! as TextSpan)
          .children!
          .cast<TextSpan>()
          .first
          .style!
          .decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('numbered items use the display number, not the source', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(NoteBlockView(block: blockOf('1. uno'), displayNumber: 4)),
    );
    expect(find.text('4.'), findsOneWidget);
  });

  testWidgets('a divider renders a rule and no text', (tester) async {
    await tester.pumpWidget(host(NoteBlockView(block: blockOf('---'))));
    expect(find.byKey(const ValueKey('note-block-divider')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-block-text')), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  // A screen reader has to hear what the box is for and whether it is on, so
  // the label and the checked state live on the tappable box itself.
  testWidgets('the checkbox announces its label and checked state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(NoteBlockView(block: blockOf('- [x] leer'))));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-block-checkbox'))),
      isSemantics(
        label: 'Casilla: leer',
        hasCheckedState: true,
        isChecked: true,
      ),
    );
    handle.dispose();
  });

  // The caret has to land on the source line, whose offsets differ from the
  // rendered text by every marker that was hidden before the tap.
  testWidgets('a tap maps back to an offset on the source line', (
    tester,
  ) async {
    int? offset;
    await tester.pumpWidget(
      host(
        NoteBlockView(
          block: blockOf('- **hola** mundo'),
          onTapAtOffset: (value) => offset = value,
        ),
      ),
    );
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('note-block-text')),
    );
    await tester.tapAt(origin + const Offset(1, 6));
    // Visible offset 0 is the `h`, which sits at index 4 of `- **hola** mundo`.
    expect(offset, 4);
  });

  // Fenced code is literal: running it through the inline styler would eat the
  // very characters the author is trying to show.
  testWidgets('code fence content keeps its markers', (tester) async {
    await tester.pumpWidget(
      host(NoteBlockView(block: blockOf('```\nlet a = **b**;\n```'))),
    );
    expect(find.textContaining('**b**'), findsOneWidget);
  });

  // A literal block shows only part of its source: the opening marker, the
  // language and the closing line are never rendered, so a tap has to be
  // pushed past the header before it means anything to the editor.
  group('a literal block', () {
    Future<int?> tapFirstCharacter(WidgetTester tester, String source) async {
      int? offset;
      await tester.pumpWidget(
        host(
          NoteBlockView(
            block: blockOf(source),
            onTapAtOffset: (value) => offset = value,
          ),
        ),
      );
      final origin = tester.getTopLeft(
        find.byKey(const ValueKey('note-block-text')),
      );
      await tester.tapAt(origin + const Offset(1, 6));
      return offset;
    }

    testWidgets('maps a tap past the opening marker of a fence', (
      tester,
    ) async {
      const source = '```dart\nlet a = 1;\n```';
      final offset = await tapFirstCharacter(tester, source);
      // The marker, the language and the newline after them come first.
      expect(offset, 8);
      expect(source[offset!], 'l');
    });

    testWidgets('maps a tap on an unsupported line one to one', (tester) async {
      const source = '| a | b |';
      final offset = await tapFirstCharacter(tester, source);
      expect(blockOf(source).type, MarkdownBlockType.raw);
      expect(offset, 0);
    });

    testWidgets('shows the code without the fence lines', (tester) async {
      await tester.pumpWidget(
        host(NoteBlockView(block: blockOf('```dart\nlet a = 1;\n```'))),
      );
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('note-block-text')),
      );
      expect(text.textSpan!.toPlainText(), 'let a = 1;');
    });
  });

  // The spec asks every block to say what it is. Without this a bullet is
  // announced as the character `•` and a numbered item as `4.`.
  group('the role a screen reader hears', () {
    Future<SemanticsNode> roleOf(
      WidgetTester tester,
      String source, {
      int? displayNumber,
    }) async {
      await tester.pumpWidget(
        host(
          NoteBlockView(
            block: blockOf(source),
            displayNumber: displayNumber,
            onTapAtOffset: (_) {},
          ),
        ),
      );
      return tester.getSemantics(find.byType(NoteBlockView));
    }

    testWidgets('names every kind of block in Spanish', (tester) async {
      final handle = tester.ensureSemantics();

      expect(
        await roleOf(tester, '## Examen'),
        isSemantics(label: 'Encabezado nivel 2: Examen', isHeader: true),
      );
      expect(
        await roleOf(tester, '- leer'),
        isSemantics(label: 'Elemento de lista: leer'),
      );
      expect(
        await roleOf(tester, '1. uno', displayNumber: 4),
        isSemantics(label: 'Elemento 4 de lista numerada: uno'),
      );
      expect(
        await roleOf(tester, '> pensar'),
        isSemantics(label: 'Cita: pensar'),
      );
      expect(
        await roleOf(tester, '```\nlet a = 1;\n```'),
        isSemantics(label: 'Bloque de código: let a = 1;'),
      );
      expect(
        await roleOf(tester, '| a | b |'),
        isSemantics(label: 'Contenido sin formato: | a | b |'),
      );

      handle.dispose();
    });

    testWidgets('says separator instead of reading nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(NoteBlockView(block: blockOf('---'))));
      expect(
        tester.getSemantics(find.byType(NoteBlockView)),
        isSemantics(label: 'Separador'),
      );
      handle.dispose();
    });
  });

  // A bare `GestureDetector` publishes no semantic action, so the only way
  // into a block was a real finger landing on it.
  group('entering edit mode without a finger', () {
    const hint = 'Toca dos veces para editar el bloque';

    testWidgets('a block with a role offers the action and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? offset;
      await tester.pumpWidget(
        host(
          NoteBlockView(
            block: blockOf('- **hola** mundo'),
            onTapAtOffset: (value) => offset = value,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(NoteBlockView)),
        isSemantics(hint: hint, hasTapAction: true),
      );

      tester.semantics.tap(
        find.semantics.byLabel('Elemento de lista: hola mundo'),
      );
      await tester.pump();

      // The start of the text, not the start of the line: offset 0 of the
      // rendered block is the `h`, four characters into `- **hola** mundo`.
      expect(offset, 4);
      handle.dispose();
    });

    testWidgets('a paragraph offers it too', (tester) async {
      final handle = tester.ensureSemantics();
      int? offset;
      await tester.pumpWidget(
        host(
          NoteBlockView(
            block: blockOf('texto'),
            onTapAtOffset: (value) => offset = value,
          ),
        ),
      );

      // A paragraph has no role to announce, so the hint and the action ride
      // on the node its own text already publishes.
      expect(
        tester.getSemantics(find.byKey(const ValueKey('note-block-text'))),
        isSemantics(label: 'texto', hint: hint, hasTapAction: true),
      );

      tester.semantics.tap(find.semantics.byLabel('texto'));
      await tester.pump();

      expect(offset, 0);
      handle.dispose();
    });

    testWidgets('a read only block offers nothing to activate', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(NoteBlockView(block: blockOf('- leer'))));
      expect(
        tester.getSemantics(find.byType(NoteBlockView)),
        isSemantics(label: 'Elemento de lista: leer', hasTapAction: false),
      );
      handle.dispose();
    });
  });

  // VoiceOver reads the flipped state off the node on its own. TalkBack and
  // Switch Control do not always, and the spec asks for the announcement.
  testWidgets('ticking the box is announced out loud', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (message) async {
        final event = (message! as Map).cast<String, Object?>();
        if (event['type'] != 'announce') return null;
        final data = (event['data']! as Map).cast<String, Object?>();
        announced.add(data['message']! as String);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        null,
      ),
    );

    await tester.pumpWidget(
      host(NoteBlockView(block: blockOf('- [ ] leer'), onToggleCheck: () {})),
    );
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pump();

    expect(announced, ['Casilla marcada']);
  });

  // The note's name and its tallest heading were the same size, so a note that
  // opened with `#` showed two titles stacked. The ramp below has to keep
  // descending without ever dropping under the body it introduces.
  testWidgets('the title outranks every heading, and none sink under the body',
      (tester) async {
    late double title;
    late List<double> headings;
    late double body;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            title = noteTitleTextStyle(context)!.fontSize!;
            headings = [
              for (final source in const ['# uno', '## dos', '### tres'])
                noteBlockTextStyle(context, blockOf(source)).fontSize!,
            ];
            body = noteBlockTextStyle(context, blockOf('texto')).fontSize!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(title, greaterThan(headings.first));
    for (var i = 1; i < headings.length; i++) {
      expect(headings[i], lessThanOrEqualTo(headings[i - 1]));
    }
    for (final heading in headings) {
      expect(heading, greaterThanOrEqualTo(body));
    }
  });
}
