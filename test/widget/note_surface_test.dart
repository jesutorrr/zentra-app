// test/widget/note_surface_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

/// The zero width space the block editor keeps in front of the active field.
const String _sentinel = '\u200B';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OwnerBoundWidgetHarness> createHarness({
    String noteTitle = 'Álgebra lineal',
    String noteBody = 'Repasar transformaciones lineales.\n'
        'Espacios vectoriales y matrices.\n'
        '- [ ] Resolver los ejercicios',
  }) async {
    final harness = await OwnerBoundWidgetHarness.create(
      noteTitle: noteTitle,
      noteBody: noteBody,
    );
    addTearDown(harness.dispose);
    return harness;
  }

  testWidgets('an existing note opens in reading mode', (tester) async {
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  });

  testWidgets('tapping the body enters writing mode and shows the bar',
      (tester) async {
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-active-block')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);
  });

  testWidgets('a new note starts in writing mode with the title focused',
      (tester) async {
    final harness = await createHarness();
    await tester.pumpWidget(buildApp(harness, const NoteSurface()));
    await tester.pumpAndSettle();

    final title = tester.widget<TextField>(
      find.byKey(const ValueKey('note-title-field')),
    );
    expect(title.focusNode!.hasFocus, isTrue);
  });

  testWidgets('changing block saves without waiting for the debounce',
      (tester) async {
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      '\u200B# Nuevo encabezado',
    );
    await tester.tap(find.byKey(const ValueKey('note-block-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      harness.noteById(harness.algebraId).body.startsWith('# Nuevo encabezado'),
      isTrue,
    );
  });

  // Ticking a box is often the last thing a user does before closing the note,
  // so it cannot ride the debounce: the timer would die with the screen.
  testWidgets('ticking a box saves without waiting for the debounce',
      (tester) async {
    final harness = await createHarness();
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('note-block-2')),
        matching: find.byKey(const ValueKey('note-block-checkbox')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      harness.noteById(harness.algebraId).body,
      contains('- [x] Resolver los ejercicios'),
    );
  });

  // A fence with a language used to show Código as the selected command and
  // then do nothing when tapped, with every other command inert beside it.
  testWidgets('the code command unwraps a fence written by hand',
      (tester) async {
    final harness = await createHarness(
      noteBody: '```dart\ncodigo uno\ncodigo dos\n```',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    final code = find.byKey(const ValueKey('note-format-code'));
    expect(tester.widget<IconButton>(code).onPressed, isNotNull);
    await tester.tap(code);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // The language and both lines come back, each on its own line.
    expect(
      harness.noteById(harness.algebraId).body,
      'dart\ncodigo uno\ncodigo dos',
    );
  });

  testWidgets('a fence dims the commands that cannot touch it', (tester) async {
    final harness = await createHarness(
      noteBody: '```dart\ncodigo uno\n```',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    for (final name in const ['heading', 'bullet', 'quote', 'checklist']) {
      expect(
        tester
            .widget<IconButton>(find.byKey(ValueKey('note-format-$name')))
            .onPressed,
        isNull,
        reason: name,
      );
    }
    // Bold has no selection to act on either.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('note-format-bold')))
          .onPressed,
      isNull,
    );
    // And the way out of the fence is live.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('note-format-code')))
          .onPressed,
      isNotNull,
    );
  });

  // The residue: a fence holding a longer run of backticks cannot be unwrapped
  // without opening a fence over everything below it, so the bar says where
  // the block can still be edited instead of leaving the user to guess.
  testWidgets('a block no command reaches keeps a way out', (tester) async {
    const body = '```\n````\n```\nsegunda';
    final harness = await createHarness(noteBody: body);
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('note-format-code')))
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('note-format-plain-text-hint')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    final raw = tester.widget<TextField>(
      find.byKey(const ValueKey('note-raw-field')),
    );
    expect(raw.controller!.text, body);
  });

  // Negritas used to collapse the selection, so turning the bold back off
  // meant finding the word and selecting it again by hand. Nobody does that,
  // which left the un-bold half of the toggle out of reach.
  testWidgets('Negritas keeps the word selected so a second tap undoes it',
      (tester) async {
    final harness = await createHarness(noteBody: 'hola mundo');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();

    TextEditingController fieldOf() => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const ValueKey('note-active-block')),
            matching: find.byType(TextField),
          ),
        )
        .controller!;

    String selectedText() {
      final field = fieldOf();
      return field.text.substring(
        field.selection.start,
        field.selection.end,
      );
    }

    // A double tap on `mundo`, over the sentinel the editor keeps in front of
    // the block source.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '${_sentinel}hola mundo',
        selection: TextSelection(baseOffset: 6, extentOffset: 11),
      ),
    );
    await tester.pumpAndSettle();
    expect(selectedText(), 'mundo');

    final bold = find.byKey(const ValueKey('note-format-bold'));
    expect(tester.widget<IconButton>(bold).onPressed, isNotNull);
    await tester.tap(bold);
    await tester.pumpAndSettle();

    expect(fieldOf().text, '${_sentinel}hola **mundo**');
    expect(selectedText(), 'mundo');

    // Which is what makes the second tap reachable at all.
    expect(tester.widget<IconButton>(bold).onPressed, isNotNull);
    await tester.tap(bold);
    await tester.pumpAndSettle();

    expect(fieldOf().text, '${_sentinel}hola mundo');
    expect(selectedText(), 'mundo');
    expect(harness.noteById(harness.algebraId).body, 'hola mundo');
  });

  testWidgets('offers the first H1 as the title only once', (tester) async {
    final harness = await createHarness(
      noteTitle: '',
      noteBody: '# Desde un archivo\ncontenido',
    );
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-h1-banner')), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-h1-banner')), findsNothing);
  });
}
