// test/widget/note_format_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/presentation/widgets/markdown_highlight_controller.dart';
import 'package:zentra/presentation/widgets/note_block_editor.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';

const _marker = Color(0xFF999999);

/// Lines the highlight controller has to hand back untouched. A `TextField`
/// aligns its caret by counting characters through the spans it is given, so a
/// single one added, dropped or reordered puts the caret on the wrong letter.
/// Every construct the tokenizer treats specially is represented here.
const _corpus = <String>[
  '',
  'texto plano',
  'a **b**',
  '**negritas** y *cursiva*',
  '__doble__ y _simple_',
  '~~tachado~~',
  'código `en línea` aquí',
  '`**esto es literal**`',
  '[Zentra](https://zentra.app)',
  '[](https://vacio.mx)',
  '[etiqueta con **negritas**](https://x.mx)',
  r'escape \* literal',
  r'\\ \` \[ \] \( \)',
  'asterisco suelto * al aire',
  'guion_bajo_en_identificador',
  '**sin cerrar',
  '``',
  '***',
  '****',
  '- [ ] casilla con `código`',
  '# Encabezado **fuerte**',
  '> cita *suave*',
  '\u200B- lista con centinela',
  'emoji 🎯 y acentos ñáéíóú',
  'texto con\ttabulación',
  '   espacios al inicio y al final   ',
  '1. numerada **uno**',
  '```',
  'a*b*c',
  '**a** **b** **c**',
  '[enlace](url) y **negritas**',
  r'\[no es enlace](tampoco)',
];

void main() {
  MarkdownHighlightController makeController() {
    final controller = MarkdownHighlightController(markerColor: _marker);
    addTearDown(controller.dispose);
    return controller;
  }

  /// Hands the bar a window of exactly [width], which is what decides whether
  /// the block commands stay side by side or collapse into their menu.
  Widget hostBar(double width, NoteFormatBar bar) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(width: width, child: bar),
          ),
        ),
      );

  NoteFormatBar wiredBar({
    NoteBlockCommand? activeCommand,
    ValueChanged<NoteBlockCommand>? onCommand,
  }) =>
      NoteFormatBar(
        visible: true,
        activeCommand: activeCommand,
        onCommand: onCommand ?? (_) {},
        onBold: () {},
        onItalic: () {},
        onUndo: () {},
        onRedo: () {},
      );

  testWidgets('the bar is hidden until the body has focus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(visible: false, onCommand: (_) {}),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  });

  testWidgets('reports the pressed command and marks the active one', (
    tester,
  ) async {
    NoteBlockCommand? pressed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(
            visible: true,
            activeCommand: NoteBlockCommand.checklist,
            onCommand: (command) => pressed = command,
          ),
        ),
      ),
    );
    final active = tester.widget<IconButton>(
      find.byKey(const ValueKey('note-format-checklist')),
    );
    expect(active.isSelected, isTrue);

    await tester.tap(find.byKey(const ValueKey('note-format-heading')));
    expect(pressed, NoteBlockCommand.heading);
  });

  testWidgets('inline and history buttons report their taps', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(
            visible: true,
            onCommand: (_) {},
            onBold: () => tapped.add('bold'),
            onItalic: () => tapped.add('italic'),
            onUndo: () => tapped.add('undo'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('note-format-bold')));
    await tester.tap(find.byKey(const ValueKey('note-format-italic')));
    await tester.tap(find.byKey(const ValueKey('note-format-undo')));
    expect(tapped, ['bold', 'italic', 'undo']);

    // Redo was not wired up, so it has to read as unavailable rather than as a
    // button that silently does nothing.
    final redo = tester.widget<IconButton>(
      find.byKey(const ValueKey('note-format-redo')),
    );
    expect(redo.onPressed, isNull);
  });

  testWidgets('every button is labelled, reachable and announces its state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteFormatBar(
            visible: true,
            activeCommand: NoteBlockCommand.quote,
            onCommand: (_) {},
            onBold: () {},
            onItalic: () {},
            onUndo: () {},
            onRedo: () {},
          ),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-quote'))),
      isSemantics(label: 'Cita', isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-bullet'))),
      isSemantics(label: 'Lista', isButton: true, isSelected: false),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-bold'))),
      isSemantics(label: 'Negritas', isButton: true),
    );
    handle.dispose();
  });

  // Undo is the only way back from a block command that did the wrong thing,
  // so it is the one control the bar may never push past its own edge.
  testWidgets('a phone bar keeps undo and redo inside its own bounds', (
    tester,
  ) async {
    await tester.pumpWidget(hostBar(390, wiredBar()));

    final bounds =
        tester.getRect(find.byKey(const ValueKey('note-format-bar')));
    for (final name in const ['undo', 'redo']) {
      final rect = tester.getRect(find.byKey(ValueKey('note-format-$name')));
      expect(rect.left, greaterThanOrEqualTo(bounds.left));
      expect(rect.right, lessThanOrEqualTo(bounds.right));
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone bar collapses the block commands into one menu', (
    tester,
  ) async {
    await tester.pumpWidget(hostBar(390, wiredBar()));

    expect(
      find.byKey(const ValueKey('note-format-block-menu')),
      findsOneWidget,
    );
    for (final command in NoteBlockCommand.values) {
      expect(
        find.byKey(ValueKey('note-format-${command.name}')),
        findsNothing,
        reason: '${command.name} should live in the menu on a phone',
      );
    }
    // The two inline styles are cheap enough to stay out in the open.
    expect(find.byKey(const ValueKey('note-format-bold')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-format-italic')), findsOneWidget);
  });

  testWidgets('a tablet bar keeps every block command side by side', (
    tester,
  ) async {
    await tester.pumpWidget(hostBar(744, wiredBar()));

    expect(find.byKey(const ValueKey('note-format-block-menu')), findsNothing);
    for (final command in NoteBlockCommand.values) {
      expect(
        find.byKey(ValueKey('note-format-${command.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('the collapsed menu still reaches every block command', (
    tester,
  ) async {
    final pressed = <NoteBlockCommand>[];
    await tester.pumpWidget(hostBar(390, wiredBar(onCommand: pressed.add)));

    await tester.tap(find.byKey(const ValueKey('note-format-block-menu')));
    await tester.pumpAndSettle();

    for (final command in NoteBlockCommand.values) {
      expect(
        find.byKey(ValueKey('note-format-menu-${command.name}')),
        findsOneWidget,
      );
    }

    final divider = find.byKey(const ValueKey('note-format-menu-divider'));
    await tester.ensureVisible(divider);
    await tester.pumpAndSettle();
    await tester.tap(divider);
    await tester.pumpAndSettle();

    expect(pressed, [NoteBlockCommand.divider]);
  });

  testWidgets('the collapsed bar keeps its targets and Spanish labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      hostBar(390, wiredBar(activeCommand: NoteBlockCommand.checklist)),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    // The menu wears the active block, so the bar still answers what the
    // block is without the reader opening anything.
    final menu = find.bySemanticsLabel('Tipo de bloque: Casilla');
    expect(menu, findsOneWidget);
    expect(tester.getSemantics(menu), isSemantics(isButton: true));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-undo'))),
      isSemantics(label: 'Deshacer', isButton: true),
    );
    handle.dispose();
  });

  testWidgets('the highlight controller dims markers without hiding them', (
    tester,
  ) async {
    final controller = makeController()..text = 'a **b**';
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final flat = span.children!.cast<TextSpan>();
    expect(flat.map((s) => s.text).join(), 'a **b**');
    expect(flat.firstWhere((s) => s.text == '**').style!.color, _marker);
    expect(
      flat.firstWhere((s) => s.text == 'b').style!.fontWeight,
      FontWeight.w700,
    );
  });

  // The caret lands by counting characters through these spans. Any corpus
  // line that comes back altered is a caret that jumps while the user types.
  testWidgets('the painted spans rebuild the text character for character', (
    tester,
  ) async {
    final controller = makeController();
    final rebuilt = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              for (final sample in _corpus) {
                controller.value = TextEditingValue(
                  text: sample,
                  selection: TextSelection.collapsed(offset: sample.length),
                );
                rebuilt.add(
                  controller
                      .buildTextSpan(
                        context: context,
                        style: const TextStyle(fontSize: 16),
                        withComposing: true,
                      )
                      .toPlainText(),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(rebuilt, _corpus);
  });

  testWidgets('an open composing region leaves the text intact', (
    tester,
  ) async {
    final controller = makeController()
      ..value = const TextEditingValue(
        text: 'hola **mun**do',
        selection: TextSelection.collapsed(offset: 11),
        composing: TextRange(start: 7, end: 10),
      );
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: true,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(span.toPlainText(), 'hola **mun**do');
  });

  // The editor is the only caller that matters: if it kept a plain controller
  // the markers would stay at full strength while the block is being edited.
  testWidgets('the active block paints its markers dimmed', (tester) async {
    var document = MarkdownDocument.parse('nota **fuerte**');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteBlockEditor(
              document: document,
              onChanged: (next) => setState(() => document = next),
              onCaretChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.textContaining('fuerte'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final controller = field.controller;
    expect(controller, isA<MarkdownHighlightController>());

    final context = tester.element(find.byType(TextField));
    final span = (controller! as MarkdownHighlightController).buildTextSpan(
      context: context,
      style: field.style,
      withComposing: false,
    );
    expect(span.toPlainText(), controller.text);
    final markers =
        span.children!.cast<TextSpan>().where((child) => child.text == '**');
    expect(markers, hasLength(2));
    expect(
      markers.every(
        (child) =>
            child.style!.color ==
            Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      isTrue,
    );
  });
}
