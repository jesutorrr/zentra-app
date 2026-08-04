import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/empty_state.dart';

void main() {
  Widget buildTestWidget({
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EmptyStateWidget(
          icon: Icons.star,
          title: 'Test Title',
          message: 'Test message content',
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        ),
      ),
    );
  }

  group('EmptyStateWidget', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Breathing animation never settles, so advance time manually
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test message content'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows button when text provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          buttonText: 'Crear hábito',
          onButtonPressed: () => tapped = true,
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Crear hábito'), findsOneWidget);
      await tester.tap(find.text('Crear hábito'));
      expect(tapped, isTrue);
    });

    testWidgets('hides button when no text provided', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('AllDoneEmptyState', () {
    testWidgets('renders default text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AllDoneEmptyState()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Todo listo!'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });
  });
}
