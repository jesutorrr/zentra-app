import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/animated_list_item.dart';

void main() {
  Widget host({
    required Widget child,
    required bool reduceMotion,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              disableAnimations: reduceMotion,
              accessibleNavigation: reduceMotion,
            ),
            child: Scaffold(body: child),
          );
        },
      ),
    );
  }

  testWidgets('AnimatedListItem cancels its stagger and settles immediately',
      (tester) async {
    const childKey = ValueKey('animated-list-child');
    const itemKey = ValueKey('animated-list-item');
    const item = AnimatedListItem(
      key: itemKey,
      index: 10,
      delay: Duration(milliseconds: 100),
      child: Text('Hábito', key: childKey),
    );
    final itemFinder = find.byKey(itemKey);
    final itemFade = find.descendant(
      of: itemFinder,
      matching: find.byType(FadeTransition),
    );
    final itemSlide = find.descendant(
      of: itemFinder,
      matching: find.byType(SlideTransition),
    );
    final itemScale = find.descendant(
      of: itemFinder,
      matching: find.byType(ScaleTransition),
    );

    await tester.pumpWidget(host(child: item, reduceMotion: false));
    await tester.pump();
    expect(
      tester.widget<FadeTransition>(itemFade).opacity.value,
      0,
    );

    await tester.pumpWidget(host(child: item, reduceMotion: true));
    await tester.pump();

    expect(find.byKey(childKey), findsOneWidget);
    expect(
      tester.widget<FadeTransition>(itemFade).opacity.value,
      1,
    );
    expect(
      tester.widget<SlideTransition>(itemSlide).position.value,
      Offset.zero,
    );
    expect(
      tester.widget<ScaleTransition>(itemScale).scale.value,
      1,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnimatedSectionHeader skips delayed decorative motion',
      (tester) async {
    const headerKey = ValueKey('animated-section-header');
    await tester.pumpWidget(
      host(
        reduceMotion: true,
        child: const AnimatedSectionHeader(
          key: headerKey,
          delay: Duration(seconds: 1),
          child: Text('Pendientes'),
        ),
      ),
    );
    await tester.pump();
    final headerFinder = find.byKey(headerKey);
    final headerFade = find.descendant(
      of: headerFinder,
      matching: find.byType(FadeTransition),
    );
    final headerSlide = find.descendant(
      of: headerFinder,
      matching: find.byType(SlideTransition),
    );

    expect(
      tester.widget<FadeTransition>(headerFade).opacity.value,
      1,
    );
    expect(
      tester.widget<SlideTransition>(headerSlide).position.value,
      Offset.zero,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
