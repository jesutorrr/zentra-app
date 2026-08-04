// test/widget/note_surface_responsive_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/widgets/note_details_panel.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';
import 'package:zentra/presentation/widgets/notes_components.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OwnerBoundWidgetHarness> createHarness({String? noteBody}) async {
    final harness = noteBody == null
        ? await OwnerBoundWidgetHarness.create()
        : await OwnerBoundWidgetHarness.create(noteBody: noteBody);
    addTearDown(harness.dispose);
    return harness;
  }

  // Derived from the ambient media query rather than built from scratch: a
  // fresh `MediaQueryData` here would sit below the one the view installs and
  // would hand the screen a window of zero size.
  Future<void> pumpAt(
    WidgetTester tester,
    OwnerBoundWidgetHarness harness, {
    required Size size,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: buildApp(harness, NoteSurface(noteId: harness.algebraId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an expanded window shows the details as a side column',
      (tester) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(1180, 820));

    expect(find.byKey(const ValueKey('note-details-column')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-details-action')), findsNothing);
  });

  testWidgets('the side column can be collapsed', (tester) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(1180, 820));

    await tester.tap(find.byKey(const ValueKey('note-details-collapse')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-expand')), findsOneWidget);
  });

  testWidgets('large text falls back to the bottom sheet action',
      (tester) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(1180, 820), textScale: 1.6);

    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-action')), findsOneWidget);
  });

  testWidgets('a compact window keeps the bottom sheet action', (tester) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(390, 844));

    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-action')), findsOneWidget);
  });

  testWidgets('Reduced Motion removes the format bar animation entirely',
      (tester) async {
    final harness = await createHarness();
    await pumpAt(
      tester,
      harness,
      size: const Size(390, 844),
      reduceMotion: true,
    );

    // Not an AnimatedSize with a zero duration: that combination re-dirties
    // itself during its own layout and throws when the bar appears.
    expect(find.byType(AnimatedSize), findsNothing);
    expect(find.byKey(const ValueKey('note-format-bar-slot')), findsOneWidget);
  });

  testWidgets('the format bar can open with Reduced Motion on', (tester) async {
    final harness = await createHarness();
    await pumpAt(
      tester,
      harness,
      size: const Size(390, 844),
      reduceMotion: true,
    );

    await tester.tap(find.byKey(const ValueKey('note-title-heading')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NoteFormatBar), findsOneWidget);
  });

  // Undo used to be the eighth of eleven controls on a scrolling row with no
  // hint that it scrolled, so on a phone it was simply gone.
  testWidgets('a phone keeps undo and redo on screen while writing', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('note-title-heading')));
    await tester.pumpAndSettle();

    for (final name in const ['undo', 'redo']) {
      final button = find.byKey(ValueKey('note-format-$name'));
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getRect(button).right, lessThanOrEqualTo(390));
    }
    expect(
      find.byKey(const ValueKey('note-format-block-menu')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the format bar survives a phone at a large text scale', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(320, 640), textScale: 2);
    await tester.tap(find.byKey(const ValueKey('note-title-heading')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('note-format-undo')).hitTestable(),
      findsOneWidget,
    );
  });

  // The name of the note and its `#` blocks were both `headlineSmall`, so a
  // note opening with a heading rendered the same title twice.
  testWidgets('the note title renders above a leading heading block', (
    tester,
  ) async {
    final harness = await createHarness(
      noteBody: '# Vectores propios\nRepasar la definición.',
    );
    await pumpAt(tester, harness, size: const Size(390, 844));

    final title = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(const ValueKey('note-title-heading')),
        matching: find.byType(Text),
      ),
    );
    final heading = tester.renderObject<RenderParagraph>(
      find.byKey(const ValueKey('note-block-text')).first,
    );
    expect(_largestSize(title.text), greaterThan(_largestSize(heading.text)));
  });

  // `Sin cambios` used to ellipsize to `Sin …` once writing mode added its own
  // action to the bar. The word is dropped whole instead, and the live region
  // above it still reads the state out in full.
  testWidgets('a crowded app bar drops the save word rather than cutting it', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('note-title-heading')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-save-label')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NoteSaveStatus),
        matching: find.byType(Icon),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide window still spells the save state out', (tester) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(1180, 820));

    final label = find.byKey(const ValueKey('note-save-label'));
    expect(label, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isFalse,
    );
  });

  // A tablet gets the sheet, not the column, and the sheet used to hand the
  // tiles the whole width of the window.
  testWidgets('the details sheet stays within its reading width', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpAt(tester, harness, size: const Size(744, 1133));

    await tester.tap(find.byKey(const ValueKey('note-details-action')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(NoteDetailsPanel)).width,
      lessThanOrEqualTo(560),
    );
  });
}

/// Largest font size anywhere in [span], which is what the eye reads as the
/// size of the line.
double _largestSize(InlineSpan span) {
  var largest = span.style?.fontSize ?? 0;
  span.visitChildren((child) {
    largest = math.max(largest, child.style?.fontSize ?? 0);
    return true;
  });
  return largest;
}
