import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/widgets/focus_dial_geometry.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

import '../support/owner_bound_widget_harness.dart';

/// Recoge los arcos y círculos que pinta el dial, para poder preguntarle al
/// lienzo dónde quedó el pulgar en vez de confiar en la aritmética de la prueba.
class _RecordingCanvas implements Canvas {
  final List<({double start, double sweep, double strokeWidth})> arcs = [];
  final List<({Offset center, double radius})> circles = [];

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    arcs.add(
      (start: startAngle, sweep: sweepAngle, strokeWidth: paint.strokeWidth),
    );
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add((center: c, radius: radius));
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() async {
    await initializeDateFormatting('es', null);
    FlutterForegroundTask.skipServiceResponseCheck = true;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      foregroundChannel,
      (call) async => call.method == 'isRunningService' ? false : null,
    );
    messenger.setMockMethodCallHandler(notificationsChannel, (_) async => null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
  });

  /// El pintor real del portal, tal como la pantalla lo construye.
  CustomPainter painterOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byKey(const ValueKey('focus_portal')),
            matching: find.byKey(const ValueKey('pomodoro_duration_arc')),
          )
          .first,
    );
    return paint.painter!;
  }

  _RecordingCanvas record(CustomPainter painter, Size size) {
    final canvas = _RecordingCanvas();
    painter.paint(canvas, size);
    return canvas;
  }

  testWidgets('el pulgar del dial cae sobre la marca que dice el número',
      (tester) async {
    // Esto es el defecto que el usuario vio: el relleno arrancaba en 0.045 para
    // que 5 minutos no se viera vacío, así que el pulgar quedaba 13.5° adelante
    // de la marca del 5 y el mínimo se leía como un cero cuyo indicador ya había
    // avanzado. Mide el lienzo de la pantalla real, no la geometría sola: si
    // alguien vuelve a meter un piso en `_PortalDial`, esta prueba cae y las de
    // FocusDialGeometry no.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final harness = await OwnerBoundWidgetHarness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(
      harness.buildApp(
        home: const PomodoroScreen(),
        theme: AppTheme.lightTheme,
        textScale: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    for (final minutes in const <int>[5, 15, 25, 45]) {
      await tester.tap(find.byKey(ValueKey('pomodoro_duration_$minutes')));
      await tester.pump(const Duration(milliseconds: 400));

      const size = Size.square(300);
      final canvas = record(painterOf(tester), size);

      // El arco de relleno es el segundo: primero el riel completo, luego el
      // progreso. El grueso los distingue -- 3 el riel, 4 el relleno.
      final progress = canvas.arcs.last;
      expect(
        progress.start,
        closeTo(FocusDialGeometry.startAngle, 1e-6),
        reason: '$minutes: el arco no arranca donde arranca la geometría.',
      );
      expect(
        progress.sweep,
        closeTo(
          FocusDialGeometry.sweepAngle * (minutes / 60),
          1e-6,
        ),
        reason: '$minutes: el relleno no corresponde a los minutos.',
      );

      // El pulgar: el círculo pequeño y sólido del final del arco. Su ángulo
      // respecto al centro tiene que ser el de la geometría.
      final center = size.center(Offset.zero);
      final thumb = canvas.circles.last;
      final angle = math.atan2(
        thumb.center.dy - center.dy,
        thumb.center.dx - center.dx,
      );
      final expected = FocusDialGeometry.angleFor(minutes);
      final normalized = (angle - expected) % (math.pi * 2);
      final delta = math.min(normalized, math.pi * 2 - normalized);
      expect(
        delta,
        lessThan(0.001),
        reason: '$minutes: el pulgar quedó '
            '${(delta * 180 / math.pi).toStringAsFixed(1)}° fuera de su marca.',
      );
    }
  });

  testWidgets('las marcas escritas reparten el arco en cuartos',
      (tester) async {
    // Eran 5, 15, 30, 45, 60 sobre un arco de 5 a 60: saltos de 10, 15, 15 y 15
    // minutos repartidos como si fueran iguales, con el 30 en 45.5% del
    // recorrido en lugar del centro.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final harness = await OwnerBoundWidgetHarness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(
      harness.buildApp(
        home: const PomodoroScreen(),
        theme: AppTheme.lightTheme,
        textScale: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    const size = Size.square(300);
    final canvas = record(painterOf(tester), size);
    final center = size.center(Offset.zero);

    // Las marcas son los círculos de radio 2.5. El pulgar usa 10 y 6.
    final marks = canvas.circles.where((c) => c.radius == 2.5).toList();
    expect(
      marks.length,
      FocusDialGeometry.marks.length,
      reason: 'El dial no pintó una marca por cada valor de la geometría.',
    );

    final fractions = <double>[];
    for (final mark in marks) {
      var relative = math.atan2(
            mark.center.dy - center.dy,
            mark.center.dx - center.dx,
          ) -
          FocusDialGeometry.startAngle;
      while (relative < -0.001) {
        relative += math.pi * 2;
      }
      fractions.add(relative / FocusDialGeometry.sweepAngle);
    }
    fractions.sort();
    expect(fractions[0], closeTo(0.25, 0.001));
    expect(fractions[1], closeTo(0.50, 0.001));
    expect(fractions[2], closeTo(0.75, 0.001));
    expect(fractions[3], closeTo(1.00, 0.001));
  });
}
