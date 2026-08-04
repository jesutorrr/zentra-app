import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/splash_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  Future<void> configureDevice(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget buildSplash({
    double textScale = 1,
    bool darkMode = false,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }

  testWidgets('Salvia uses the quiet Sello y aire composition', (tester) async {
    await configureDevice(
      tester,
      logicalSize: const Size(393, 852),
    );

    await tester.pumpWidget(buildSplash());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('zentra-splash-logo')), findsOneWidget);
    final logoImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('zentra-splash-logo')),
        matching: find.byType(Image),
      ),
    );
    expect(
      logoImage.image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        'assets/images/zentra_logo_mark.png',
      ),
    );
    expect(find.text('ZENTRA'), findsOneWidget);
    expect(find.text('Una acción clara a la vez.'), findsOneWidget);
    expect(
      find.text(
        'Hábitos, notas y enfoque en un espacio hecho para darte claridad.',
      ),
      findsNothing,
    );
    expect(find.text('Preparando tu espacio'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports compact width with 320 percent text', (tester) async {
    await configureDevice(
      tester,
      logicalSize: const Size(320, 568),
    );

    await tester.pumpWidget(
      buildSplash(textScale: 3.2, reduceMotion: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('splash-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composes on iPad in dark mode', (tester) async {
    await configureDevice(
      tester,
      logicalSize: const Size(1024, 1366),
    );

    await tester.pumpWidget(
      buildSplash(darkMode: true, reduceMotion: true),
    );
    await tester.pumpAndSettle();

    final logo = tester.getSize(
      find.byKey(const ValueKey('zentra-splash-logo')),
    );
    expect(logo.width, 84);
    expect(logo.height, 84);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the previous splash available as a working fallback',
      (tester) async {
    await configureDevice(
      tester,
      logicalSize: const Size(393, 852),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ClassicSplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.text(
        'Hábitos, notas y enfoque en un espacio hecho para darte claridad.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a static loading state with Reduced Motion',
      (tester) async {
    await configureDevice(
      tester,
      logicalSize: const Size(393, 852),
    );

    await tester.pumpWidget(buildSplash(reduceMotion: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('zentra-static-loading-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('zentra-animated-loading-indicator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
