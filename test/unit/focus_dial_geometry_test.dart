import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/focus_dial_geometry.dart';

void main() {
  group('FocusDialGeometry', () {
    test('el pulgar cae exactamente sobre la marca escrita', () {
      // El defecto que motivó esto: el relleno arrancaba en 0.045 para que 5
      // minutos mostrara algo, y ese piso dejaba el pulgar 13.5° adelante de la
      // marca del 5. La afirmación compara dos caminos independientes: el ángulo
      // que la geometría le da al valor, y el que sale de la proporción cruda
      // minutos/60. Si alguien vuelve a meter un piso, el primero se corre y el
      // segundo no.
      for (final minutes in const <int>[5, 15, 30, 45, 60]) {
        final fromGeometry = FocusDialGeometry.angleFor(minutes);
        final fromRawRatio = FocusDialGeometry.startAngle +
            FocusDialGeometry.sweepAngle * (minutes / 60);
        expect(
          fromGeometry,
          closeTo(fromRawRatio, 1e-9),
          reason: '$minutes: el pulgar no cae sobre su marca.',
        );
      }
    });

    test('las marcas reparten el arco en cuartos exactos', () {
      // Medido de 5 a 60, el 30 caía en 45.5% del recorrido en vez del centro, y
      // el 5 quedaba pegado al origen: por eso se leía como el cero de un dial
      // cuyo indicador ya había avanzado.
      expect(FocusDialGeometry.fractionFor(15), closeTo(0.25, 1e-9));
      expect(FocusDialGeometry.fractionFor(30), closeTo(0.50, 1e-9));
      expect(FocusDialGeometry.fractionFor(45), closeTo(0.75, 1e-9));
      expect(FocusDialGeometry.fractionFor(60), closeTo(1.00, 1e-9));
    });

    test('30 minutos queda justo arriba, en la vertical del dial', () {
      // Media vuelta de un arco que empieza abajo a la izquierda y barre 300°
      // apunta hacia arriba: -90°, o 3π/2 en el sistema de Flutter.
      final angle = FocusDialGeometry.angleFor(30) % (math.pi * 2);
      expect(angle, closeTo(math.pi * 3 / 2, 1e-9));
    });

    test('5 minutos pinta relleno sin necesitar un piso artificial', () {
      // La razón por la que existía el 0.045: que el mínimo no se viera vacío.
      // Contra un arco de 0 a 60 el mínimo ya vale 8.3% por su propia cuenta.
      expect(FocusDialGeometry.fractionFor(5), closeTo(5 / 60, 1e-9));
      expect(FocusDialGeometry.fractionFor(5), greaterThan(0.08));
    });

    test('un toque sobre una marca devuelve los minutos de esa marca', () {
      const size = Size.square(280);
      final center = size.center(Offset.zero);
      const radius = 100.0;
      for (final minutes in const <int>[5, 15, 30, 45, 60]) {
        final angle = FocusDialGeometry.angleFor(minutes);
        final point = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        expect(
          FocusDialGeometry.minutesFromOffset(point, size),
          minutes,
          reason: 'Tocar la marca de $minutes no eligió $minutes.',
        );
      }
    });

    test('el gesto nunca entrega un valor fuera de lo elegible', () {
      const size = Size.square(280);
      final center = size.center(Offset.zero);
      for (var degrees = 0; degrees < 360; degrees += 3) {
        final radians = degrees * math.pi / 180;
        final point = Offset(
          center.dx + math.cos(radians) * 100,
          center.dy + math.sin(radians) * 100,
        );
        final minutes = FocusDialGeometry.minutesFromOffset(point, size);
        expect(minutes, greaterThanOrEqualTo(5));
        expect(minutes, lessThanOrEqualTo(60));
        expect(minutes % 5, 0, reason: '$degrees° cayó fuera de la rejilla.');
      }
    });

    test('el cero del arco no es elegible: se sube al mínimo', () {
      // El arco empieza en cero para que las marcas queden parejas, pero una
      // sesión de cero minutos no existe.
      expect(FocusDialGeometry.snap(0), 5);
      expect(FocusDialGeometry.snap(2), 5);
      expect(FocusDialGeometry.snap(80), 60);
    });
  });
}
