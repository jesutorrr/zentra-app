// test/widget/note_format_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/markdown_document.dart';
import 'package:zentra/domain/markdown_editing.dart';
import 'package:zentra/presentation/widgets/markdown_highlight_controller.dart';
import 'package:zentra/presentation/widgets/note_block_editor.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';

const _marker = Color(0xFF999999);

/// The zero width space the editor keeps in front of the active field's text.
const _sentinel = '\u200B';

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
  Widget hostBar(double width, NoteFormatBar bar, {double textScale = 1}) =>
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(width: width, child: bar),
              ),
            ),
          ),
        ),
      );

  /// The bar as an ordinary paragraph leaves it: every command able to act.
  NoteFormatBar wiredBar({
    NoteBlockCommand? activeCommand,
    ValueChanged<NoteBlockCommand>? onCommand,
    Set<NoteBlockCommand>? availableCommands,
    bool blockAcceptsNoCommand = false,
  }) =>
      NoteFormatBar(
        visible: true,
        activeCommand: activeCommand,
        availableCommands: availableCommands ?? NoteBlockCommand.values.toSet(),
        blockAcceptsNoCommand: blockAcceptsNoCommand,
        onCommand: onCommand ?? (_) {},
        onBold: () {},
        onItalic: () {},
        onUndo: () {},
        onRedo: () {},
      );

  // Every command acts on the block under the caret, so the bar may only be
  // on screen while the body holds one. Driven from a real focus change: the
  // `visible` flag on its own says nothing about when the screen sets it.
  testWidgets('the bar is hidden until the body has focus', (tester) async {
    var document = MarkdownDocument.parse('nota');
    DocumentCaret? caret;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                NoteBlockEditor(
                  document: document,
                  onChanged: (next) => setState(() => document = next),
                  onCaretChanged: (value) => setState(() => caret = value),
                ),
                const TextField(key: ValueKey('otro-campo')),
                NoteFormatBar(
                  visible: caret != null,
                  onCommand: (_) {},
                  availableCommands: NoteBlockCommand.values.toSet(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);

    await tester.tap(find.text('nota'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('otro-campo')));
    await tester.pumpAndSettle();
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
            availableCommands: NoteBlockCommand.values.toSet(),
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
            availableCommands: NoteBlockCommand.values.toSet(),
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
            availableCommands: NoteBlockCommand.values.toSet(),
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

  // A command the block refuses used to look exactly like one that works, so
  // the only way to find out was to tap it and watch nothing happen.
  testWidgets('a command the block refuses is drawn as unavailable', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      hostBar(
        744,
        wiredBar(
          onCommand: (_) => pressed++,
          availableCommands: const {
            NoteBlockCommand.code,
            NoteBlockCommand.divider,
          },
        ),
      ),
    );

    final quote = find.byKey(const ValueKey('note-format-quote'));
    expect(tester.widget<IconButton>(quote).onPressed, isNull);
    await tester.tap(quote);
    expect(pressed, 0);

    // The two that can act are untouched, so the bar still offers a way out.
    for (final name in const ['code', 'divider']) {
      final live = find.byKey(ValueKey('note-format-$name'));
      expect(tester.widget<IconButton>(live).onPressed, isNotNull);
      await tester.tap(live);
    }
    expect(pressed, 2);
  });

  // Dimming is invisible to a screen reader, and "button, dimmed" does not say
  // that the same command works one block away.
  testWidgets('a disabled command says it is unavailable out loud', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      hostBar(
        744,
        NoteFormatBar(
          visible: true,
          activeCommand: NoteBlockCommand.code,
          availableCommands: const {NoteBlockCommand.divider},
          onCommand: (_) {},
          onUndo: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-code'))),
      isSemantics(
        label: 'Código',
        hint: 'No disponible en este bloque',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    // Bold was never wired, which is the shape of a selection nothing can be
    // done with, and it has to read the same way.
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-bold'))),
      isSemantics(
        label: 'Negritas',
        hint: 'No disponible en este bloque',
        isEnabled: false,
      ),
    );
    // History has its own reason, and it is not the block.
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-redo'))),
      isSemantics(label: 'Rehacer', hint: 'No hay nada que rehacer'),
    );
    // And the one command that can act still reads as available.
    expect(
      tester.getSemantics(find.byKey(const ValueKey('note-format-divider'))),
      isSemantics(label: 'Separador', isButton: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('the collapsed menu dims the commands the block refuses', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final pressed = <NoteBlockCommand>[];
    await tester.pumpWidget(
      hostBar(
        390,
        wiredBar(
          onCommand: pressed.add,
          availableCommands: const {NoteBlockCommand.code},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('note-format-block-menu')));
    await tester.pumpAndSettle();

    final quote = find.byKey(const ValueKey('note-format-menu-quote'));
    expect(
      tester.widget<PopupMenuItem<NoteBlockCommand>>(quote).enabled,
      isFalse,
    );
    expect(
      tester.getSemantics(find.text('Cita')),
      isSemantics(hint: 'No disponible en este bloque'),
    );
    await tester.tap(quote);
    await tester.pumpAndSettle();
    expect(pressed, isEmpty);

    // The menu is still open, because nothing was chosen, and the one live
    // row still answers.
    final code = find.byKey(const ValueKey('note-format-menu-code'));
    await tester.ensureVisible(code);
    await tester.pumpAndSettle();
    await tester.tap(code);
    await tester.pumpAndSettle();
    expect(pressed, [NoteBlockCommand.code]);
    handle.dispose();
  });

  // A block nothing can change is still a block the user has to get out of.
  testWidgets('a block no command reaches points at plain text mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostBar(
        390,
        wiredBar(
          availableCommands: const {NoteBlockCommand.divider},
          blockAcceptsNoCommand: true,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('note-format-plain-text-hint')),
      findsOneWidget,
    );
    expect(find.textContaining('Editar como texto'), findsOneWidget);
  });

  testWidgets('an ordinary block says nothing at all', (tester) async {
    await tester.pumpWidget(hostBar(390, wiredBar()));

    expect(
      find.byKey(const ValueKey('note-format-plain-text-hint')),
      findsNothing,
    );
  });

  // The narrowest phone at the largest text size, with the extra line the
  // hint adds: the row has no give left there.
  testWidgets('the bar with its hint fits 320 points at twice the text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hostBar(
        320,
        wiredBar(
          availableCommands: const {NoteBlockCommand.divider},
          blockAcceptsNoCommand: true,
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    final bounds =
        tester.getRect(find.byKey(const ValueKey('note-format-bar')));
    expect(bounds.width, lessThanOrEqualTo(320));
    for (final name in const ['undo', 'redo', 'bold', 'italic']) {
      final rect = tester.getRect(find.byKey(ValueKey('note-format-$name')));
      expect(rect.left, greaterThanOrEqualTo(bounds.left), reason: name);
      expect(rect.right, lessThanOrEqualTo(bounds.right), reason: name);
      expect(rect.height, greaterThanOrEqualTo(44), reason: name);
    }
    // The line wraps rather than running past the edge of the bar.
    final hint = tester.getRect(find.textContaining('Editar como texto'));
    expect(hint.right, lessThanOrEqualTo(bounds.right));
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

  // An IME hands its buffer over as a composing region and re-commits it,
  // duplicating characters, the moment the field stops reporting one. The
  // region has to survive both the painting and a rewrite from the screen.
  testWidgets('an open composing region survives being painted', (
    tester,
  ) async {
    const composing = TextRange(start: 8, end: 11);
    var document = MarkdownDocument.parse('hola **mun**do');
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return NoteBlockEditor(
                document: document,
                onChanged: (next) => setState(() => document = next),
                onCaretChanged: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.textContaining('hola'));
    await tester.pumpAndSettle();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '${_sentinel}hola **mun**do',
        selection: TextSelection.collapsed(offset: 11),
        composing: composing,
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final controller = field.controller! as MarkdownHighlightController;
    expect(controller.value.composing, composing);
    expect(
      controller.text.substring(composing.start, composing.end),
      'mun',
      reason: 'the region has to keep covering the letters the IME opened it '
          'over',
    );

    // A second block arriving from the screen while the composition is open.
    rebuild(
      () => document = MarkdownDocument.parse('hola **mun**do\nsegunda'),
    );
    await tester.pumpAndSettle();
    expect(controller.value.composing, composing);

    // And the painted spans still rebuild the text character for character,
    // which is what keeps the caret on the letter the user is composing.
    final context = tester.element(find.byType(TextField));
    final span = controller.buildTextSpan(
      context: context,
      style: field.style,
      withComposing: true,
    );
    expect(span.toPlainText(), controller.text);
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
