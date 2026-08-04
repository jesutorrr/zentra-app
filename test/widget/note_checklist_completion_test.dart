// test/widget/note_checklist_completion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/theme.dart';

import '../support/owner_bound_widget_harness.dart';

/// The sentinel the block editor keeps in front of the active field's text.
const String _sentinel = '\u200B';

const ValueKey<String> _message = ValueKey('note-checklist-complete');
const String _messageText = 'Terminaste todo lo de esta nota.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OwnerBoundWidgetHarness> createHarness(String noteBody) async {
    final harness = await OwnerBoundWidgetHarness.create(noteBody: noteBody);
    addTearDown(harness.dispose);
    return harness;
  }

  testWidgets('shows a quiet message when the last box is checked', (
    tester,
  ) async {
    final harness = await createHarness('- [x] uno\n- [ ] dos');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsNothing);

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')).last);
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsOneWidget);
    expect(find.text(_messageText), findsOneWidget);
  });

  testWidgets('does not repeat after unchecking and checking again', (
    tester,
  ) async {
    final harness = await createHarness('- [ ] uno');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();
    expect(find.byKey(_message), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsNothing);
  });

  // Opening a note that was already finished is not finishing it, and neither
  // is any later edit to the rest of the note.
  testWidgets('stays away on a note that opens already complete', (
    tester,
  ) async {
    final harness = await createHarness('- [x] uno\nSiguiente paso');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsNothing);

    await tester.tap(find.byKey(const ValueKey('note-block-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      '${_sentinel}Siguiente paso mañana',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsNothing);
  });

  // Emptying the last pending item leaves every remaining box ticked, but
  // nothing was finished: the item is simply gone.
  testWidgets('stays away when the last pending item is deleted', (
    tester,
  ) async {
    final harness = await createHarness('- [x] uno\n- [ ] dos');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      _sentinel,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsNothing);
  });

  // A screen reader has to hear the confirmation where it stands, without the
  // caret being pulled out of the note to read it.
  testWidgets('announces itself without taking focus', (tester) async {
    final handle = tester.ensureSemantics();
    final harness = await createHarness('- [ ] uno');
    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(_message)),
      isSemantics(
        label: _messageText,
        isLiveRegion: true,
        isFocused: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('the message wraps instead of overflowing at a large text scale',
      (tester) async {
    final harness = await createHarness('- [ ] uno');
    await tester.pumpWidget(
      harness.buildApp(
        home: NoteSurface(noteId: harness.algebraId),
        theme: AppTheme.lightTheme,
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-checkbox')));
    await tester.pumpAndSettle();

    expect(find.byKey(_message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
