import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/presentation/celebration_dialog.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  Widget host({
    required bool reduceMotion,
    double textScale = 1,
    double viewInsetsBottom = 0,
    bool useLauncher = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: reduceMotion,
            accessibleNavigation: reduceMotion,
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
          ),
          child: child!,
        );
      },
      home: useLauncher
          ? Scaffold(
              body: Builder(
                builder: (context) {
                  return FilledButton(
                    key: const ValueKey('open-day-completed-dialog'),
                    onPressed: () => DayCompletedDialog.show(
                      context,
                      phrase: 'Un paso claro. Luego el siguiente, con calma.',
                      categories: const [
                        Category.foco,
                        Category.movimiento,
                      ],
                    ),
                    child: const Text('Abrir celebración'),
                  );
                },
              ),
            )
          : const Scaffold(
              body: DayCompletedDialog(
                motivationalPhrase: 'Un paso claro. Luego el siguiente.',
                completedCategories: [Category.foco],
              ),
            ),
    );
  }

  testWidgets('DayCompletedDialog is static with Reduced Motion',
      (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('day-completed-static-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-static-icon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-scale-transition')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('day-completed-animated-frame')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('day-completed-animated-icon')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 4));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DayCompletedDialog keeps its animated presentation normally',
      (tester) async {
    await tester.pumpWidget(host(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.byKey(const ValueKey('day-completed-scale-transition')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-animated-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-animated-icon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-static-frame')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'DayCompletedDialog is readable and actionable at 320x640 and 3.2x text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      host(
        reduceMotion: true,
        textScale: 3.2,
        useLauncher: true,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-day-completed-dialog')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DayCompletedDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('day-completed-static-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-scroll-view')),
      findsOneWidget,
    );
    final criticalCopy = <Finder>[
      find.byKey(const ValueKey('day-completed-title')),
      find.byKey(const ValueKey('day-completed-phrase')),
    ];
    for (final finder in criticalCopy) {
      expect(finder, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    expect(tester.takeException(), isNull);

    final dismiss = find.byKey(const ValueKey('day-completed-dismiss'));
    await tester.ensureVisible(dismiss);
    await tester.pump();
    expect(tester.getSize(dismiss).height, greaterThanOrEqualTo(48));
    await tester.tap(dismiss);
    await tester.pumpAndSettle();

    expect(find.byType(DayCompletedDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'DayCompletedDialog remains actionable above keyboard at 320x640 and 3.2x text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      host(
        reduceMotion: true,
        textScale: 3.2,
        viewInsetsBottom: 280,
        useLauncher: true,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-day-completed-dialog')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DayCompletedDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('day-completed-static-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-completed-scroll-view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final dismiss = find.byKey(const ValueKey('day-completed-dismiss'));
    await tester.ensureVisible(dismiss);
    await tester.pump();
    expect(tester.getSize(dismiss).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);

    await tester.tap(dismiss);
    await tester.pumpAndSettle();

    expect(find.byType(DayCompletedDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
