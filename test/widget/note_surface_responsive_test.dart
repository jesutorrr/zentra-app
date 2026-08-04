// test/widget/note_surface_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/widgets/note_format_bar.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OwnerBoundWidgetHarness> createHarness() async {
    final harness = await OwnerBoundWidgetHarness.create();
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
}
