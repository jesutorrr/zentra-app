// test/widget/note_raw_mode_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OwnerBoundWidgetHarness> createHarness(String noteBody) async {
    final harness = await OwnerBoundWidgetHarness.create(noteBody: noteBody);
    addTearDown(harness.dispose);
    return harness;
  }

  String rawFieldText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const ValueKey('note-raw-field')))
      .controller!
      .text;

  testWidgets('raw mode shows the whole body as plain Markdown',
      (tester) async {
    final harness = await createHarness('## Título\n- [ ] pendiente');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    expect(rawFieldText(tester), '## Título\n- [ ] pendiente');
  });

  // Tables and inline HTML are kept as raw blocks, which the block editor can
  // show but not really work on. Plain text mode is where they get repaired,
  // so it has to hand them over byte for byte.
  testWidgets('raw mode shows syntax the parser kept verbatim', (tester) async {
    const body = '## Título\n| a | b |\n<div>hola</div>\n\n    sangría';
    final harness = await createHarness(body);
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    expect(rawFieldText(tester), body);
  });

  // A mode that read only the saved document would silently drop whatever the
  // block under the caret is still holding.
  testWidgets('raw mode picks up the block that is still being typed',
      (tester) async {
    final harness = await createHarness('a');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      '\u200Ba medio escribir',
    );
    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    expect(rawFieldText(tester), 'a medio escribir');
  });

  testWidgets('leaving raw mode keeps what was typed', (tester) async {
    final harness = await createHarness('a');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-raw-field')),
      '# nuevo\ntexto',
    );
    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-raw-field')), findsNothing);
    expect(harness.noteById(harness.algebraId).body, '# nuevo\ntexto');
  });

  // Nothing makes the reader return to the block editor before closing the
  // note, so a save started from plain text mode has to write the field rather
  // than the document sitting behind it.
  testWidgets('saves what plain text mode holds without leaving it',
      (tester) async {
    final harness = await createHarness('a');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-raw-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-raw-field')),
      'sin bloques\n| ni tabla |',
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(
      harness.noteById(harness.algebraId).body,
      'sin bloques\n| ni tabla |',
    );
  });

  testWidgets('copies the raw Markdown to the clipboard', (tester) async {
    final harness = await createHarness('## Título\n- [ ] pendiente');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-copy-markdown')));
    await tester.pumpAndSettle();

    expect(copied, '## Título\n- [ ] pendiente');

    // The snack bar keeps a dismissal timer alive, and a timer still pending
    // when the test ends is reported as a leak.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
