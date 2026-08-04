// test/widget/note_surface_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

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
