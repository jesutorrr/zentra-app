import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/support_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  testWidgets('support screen never invents unavailable store products',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SupportScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Las compras no están disponibles en esta versión.'),
      findsOneWidget,
    );
    expect(find.text(r'$0.99'), findsNothing);
    expect(find.text(r'$2.99'), findsNothing);
    expect(find.text(r'$9.99'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
