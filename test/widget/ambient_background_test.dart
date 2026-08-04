import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/widgets/ambient_background.dart';

void main() {
  testWidgets('ambient color stays decorative and preserves its child',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ZentraAmbientBackground(
              child: Center(child: Text('Contenido principal')),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Contenido principal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('zentra_ambient_background')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
