// test/widget/note_block_view_test.dart
import 'package:flutter/material.dart';
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
