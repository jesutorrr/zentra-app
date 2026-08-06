import 'dart:math' as math;
import 'dart:ui';

/// La correspondencia entre minutos y ángulo en el dial de Enfoque.
///
/// Vivía copiada en tres lugares —el pintor del arco, el gesto del portal y la
/// hoja de «otra duración»— y las tres copias tenían que estar de acuerdo para
/// que el pulgar cayera sobre su marca. No lo estaban: el pintor arrancaba en
/// `0.045` para que 5 minutos mostrara algo de relleno, y ese piso dejaba el
/// pulgar 13.5° adelante de la marca del 5. Con una sola fuente, el desacuerdo
/// deja de ser posible.
///
/// El arco mide **de 0 a 60**, aunque sólo se pueda elegir de 5 a 60. Medirlo de
/// 5 a 60 fue lo que puso el 30 en 45.5% del recorrido en lugar del centro, y lo
/// que hacía leer el 5 como un cero cuyo indicador ya había avanzado. Contra un
/// arco de 0 a 60 las marcas caen en cuartos exactos, el 30 queda justo arriba,
/// y 5 minutos pinta 8.3% por su propia cuenta: el piso artificial ya no hace
/// falta.
class FocusDialGeometry {
  const FocusDialGeometry._();

  /// El mínimo que se puede elegir. El arco empieza antes, en cero.
  static const int minMinutes = 5;

  /// El máximo, y el final del arco.
  static const int maxMinutes = 60;

  /// El dial se mueve de cinco en cinco: doce paradas de 0 a 60.
  static const int step = 5;

  /// Abajo a la izquierda, y de ahí en el sentido del reloj.
  static const double startAngle = math.pi * 2 / 3;

  /// 300°, con la boca del arco abajo.
  static const double sweepAngle = math.pi * 5 / 3;

  /// Las marcas escritas sobre el arco: los cuartos exactos del recorrido.
  ///
  /// Antes eran `5, 15, 30, 45, 60`, cinco números separados por 10, 15, 15 y
  /// 15 minutos: sobre un arco parejo, saltos desparejos.
  static const List<int> marks = <int>[15, 30, 45, 60];

  /// Qué parte del arco ocupan `minutes`, de 0 a 1.
  static double fractionFor(int minutes) {
    return (minutes / maxMinutes).clamp(0.0, 1.0);
  }

  /// El ángulo al que corresponden `minutes`.
  static double angleFor(int minutes) {
    return startAngle + sweepAngle * fractionFor(minutes);
  }

  /// Redondea a la parada de 5 minutos más cercana, dentro de lo elegible.
  static int snap(int minutes) {
    final snapped = (minutes / step).round() * step;
    return snapped.clamp(minMinutes, maxMinutes);
  }

  /// Los minutos que señala un toque en `position`, dentro de un cuadro `size`.
  ///
  /// Un toque fuera de la boca del arco se va al extremo más cercano en vez de
  /// saltar al opuesto.
  static int minutesFromOffset(Offset position, Size size) {
    final center = size.center(Offset.zero);
    final vector = position - center;
    var relative = math.atan2(vector.dy, vector.dx) - startAngle;
    while (relative < 0) {
      relative += math.pi * 2;
    }
    while (relative >= math.pi * 2) {
      relative -= math.pi * 2;
    }
    if (relative > sweepAngle) {
      relative = relative - sweepAngle < math.pi * 2 - relative
          ? sweepAngle
          : 0;
    }
    final fraction = relative / sweepAngle;
    return snap((fraction * maxMinutes).round());
  }
}
