// «Nuevo hábito» y «Nuevo enfoque» abren con la misma pregunta —¿se repite, es
// un ciclo?— y tienen que abrirla con el mismo objeto.
//
// Esta prueba existe porque ya se parecieron una vez y se separaron en cuatro
// ejes a la vez: radio (999 contra 18), color del riel, cómo se reparten el
// ancho las mitades, y cómo se rellena la pastilla activa. Ninguna prueba lo
// vio, porque cada pantalla se probaba sola y por separado las dos estaban
// bien. Lo que no estaba bien era la relación entre ellas, y una afirmación
// sobre una relación no cabe en el test de ninguna de las dos partes.
//
// Por eso no compara colores contra literales: monta las dos pantallas de
// verdad y compara la una con la otra. Así la prueba sigue valiendo cuando el
// teal cambie —y no obliga a editarla cuando cambie.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/design_tokens.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/theme.dart';

import '../support/owner_bound_widget_harness.dart';

/// Lo que la banda pinta de verdad, aplanado si viniera translúcido.
Color _bandColor(WidgetTester tester) {
  final band = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey('zentra-mode-band')),
  );
  return (band.decoration! as BoxDecoration).color!;
}

Color _railColor(WidgetTester tester) {
  final rail = tester.widget<Material>(
    find.byKey(const ValueKey('zentra-mode-selector')),
  );
  return Color.alphaBlend(rail.color!, _bandColor(tester));
}

double _railRadius(WidgetTester tester) {
  final rail = tester.widget<Material>(
    find.byKey(const ValueKey('zentra-mode-selector')),
  );
  return (rail.borderRadius! as BorderRadius).topLeft.x;
}

/// El relleno de la pastilla, aplanado contra la banda: lo que el ojo lee es el
/// compuesto, no el color nominal.
Color _pillFill(WidgetTester tester, String key) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final fill = (container.decoration! as BoxDecoration).color!;
  return Color.alphaBlend(fill, _bandColor(tester));
}

Color _pillTextColor(WidgetTester tester, String label) {
  return tester
      .renderObject<RenderParagraph>(find.text(label))
      .text
      .style!
      .color!;
}

/// El ancho de cada mitad. Iguales cuando las mitades se reparten el riel;
/// distintos cuando cada una se ajusta a su etiqueta.
List<double> _halfWidths(WidgetTester tester, List<String> keys) {
  return [for (final key in keys) tester.getSize(find.byKey(ValueKey(key))).width];
}

double _contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  OwnerBoundWidgetHarness? harness;

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

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() {
    harness = null;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool dark = false,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var current = harness;
    if (current == null) {
      current = await OwnerBoundWidgetHarness.create();
      harness = current;
      addTearDown(current.dispose);
    }
    await tester.pumpWidget(
      current.buildApp(
        home: home,
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        textScale: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Lee de una pantalla todo lo que define el aspecto del control, para poder
  /// comparar las dos lecturas sin volver a montar nada.
  Future<Map<String, Object>> readBand(
    WidgetTester tester,
    Widget home,
    List<String> keys,
    List<String> labels, {
    bool dark = false,
  }) async {
    await pump(tester, home, dark: dark);
    return <String, Object>{
      'band': _bandColor(tester),
      'rail': _railColor(tester),
      'radius': _railRadius(tester),
      'selectedFill': _pillFill(tester, keys.first),
      'selectedText': _pillTextColor(tester, labels.first),
      'inactiveText': _pillTextColor(tester, labels.last),
      'halves': _halfWidths(tester, keys),
    };
  }

  const habitKeys = ['habit-mode-recurring', 'habit-mode-one-time'];
  const habitLabels = ['Se repite', 'Una sola vez'];
  const focusKeys = ['pomodoro_mode_quick', 'pomodoro_mode_cycle'];
  const focusLabels = ['Rápido', 'Ciclo'];

  for (final dark in [false, true]) {
    final mode = dark ? 'AMOLED' : 'light';

    testWidgets('$mode: both launchers paint the same band and selector',
        (tester) async {
      final habit = await readBand(
        tester,
        const HabitFormScreen(),
        habitKeys,
        habitLabels,
        dark: dark,
      );
      harness = null;
      final focus = await readBand(
        tester,
        const PomodoroScreen(),
        focusKeys,
        focusLabels,
        dark: dark,
      );

      expect(focus['band'], habit['band'], reason: 'La banda no coincide.');
      expect(focus['rail'], habit['rail'], reason: 'El riel no coincide.');
      expect(
        focus['radius'],
        habit['radius'],
        reason: 'El radio no coincide: 999 contra 18 fue la diferencia más '
            'visible entre las dos pantallas.',
      );
      expect(
        focus['selectedFill'],
        habit['selectedFill'],
        reason: 'La pastilla activa no se rellena igual.',
      );
      expect(focus['selectedText'], habit['selectedText']);
      expect(focus['inactiveText'], habit['inactiveText']);

      // Las mitades se reparten el riel en vez de ajustarse a su etiqueta. En
      // Enfoque «Rápido» y «Ciclo» miden distinto, así que un MainAxisSize.min
      // daba dos mitades desiguales y el control cambiaba de forma al cambiar
      // las palabras.
      final focusHalves = focus['halves']! as List<double>;
      expect(
        focusHalves.first,
        closeTo(focusHalves.last, 0.5),
        reason: 'Las mitades de Enfoque no se reparten el ancho.',
      );
      final habitHalves = habit['halves']! as List<double>;
      expect(habitHalves.first, closeTo(habitHalves.last, 0.5));
    });

    testWidgets('$mode: the Focus band carries legible content', (tester) async {
      await pump(tester, const PomodoroScreen(), dark: dark);
      final band = _bandColor(tester);
      final rail = _railColor(tester);

      expect(
        _contrastRatio(_pillTextColor(tester, 'Ciclo'), rail),
        greaterThanOrEqualTo(4.5),
        reason: '$mode: la opción inactiva se pierde en el riel.',
      );
      final selectedFill = _pillFill(tester, focusKeys.first);
      expect(
        _contrastRatio(selectedFill, band),
        greaterThanOrEqualTo(3.0),
        reason: '$mode: la pastilla activa no se distingue de la banda.',
      );
      expect(
        _contrastRatio(_pillTextColor(tester, 'Rápido'), selectedFill),
        greaterThanOrEqualTo(4.5),
        reason: '$mode: el texto activo se pierde en su pastilla.',
      );
    });
  }

  testWidgets('the light band is the solid brand teal in both launchers',
      (tester) async {
    await pump(tester, const HabitFormScreen());
    expect(_bandColor(tester), ZentraPalette.light.brandTeal);
    harness = null;
    await pump(tester, const PomodoroScreen());
    expect(_bandColor(tester), ZentraPalette.light.brandTeal);
  });

  testWidgets('the dark band keeps its own deep tone, not the light teal',
      (tester) async {
    // El usuario pidió el cambio solo para light. Si el token oscuro se
    // arrastrara al teal, el modo AMOLED perdería su fondo negro.
    await pump(tester, const PomodoroScreen(), dark: true);
    expect(_bandColor(tester), ZentraPalette.dark.salviaFormHeader);
    expect(_bandColor(tester), isNot(ZentraPalette.light.brandTeal));
  });

  testWidgets('the status bar turns light so its glyphs survive the band',
      (tester) async {
    // La banda es la superficie más alta de la pantalla y en light pasó de
    // clara a oscura: sin esto los iconos del sistema se quedan oscuros y
    // desaparecen dentro del teal.
    await pump(tester, const HabitFormScreen());
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('zentra-mode-band')),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.light);
  });

  for (final entry in {
    'Nuevo hábito': const HabitFormScreen(),
    'Nuevo enfoque': const PomodoroScreen(),
  }.entries) {
    testWidgets('${entry.key}: the band reaches the physical top edge',
        (tester) async {
      // La banda es el techo de la pantalla, no un rectángulo flotando en ella.
      // Con el inset del notch aplicado por fuera quedaba una franja crema
      // encima del teal y la banda se leía despegada del borde. El inset tiene
      // que consumirse *dentro* del color: la banda empieza en 0 y el contenido
      // baja.
      tester.view.padding = const FakeViewPadding(top: 47);
      tester.view.viewPadding = const FakeViewPadding(top: 47);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await pump(tester, entry.value);

      final band = tester.getRect(find.byKey(const ValueKey('zentra-mode-band')));
      expect(
        band.top,
        0,
        reason: 'La banda arranca por debajo del borde: eso es la franja crema.',
      );
      // Y el inset se respeta de todas formas: nada del contenido se mete
      // debajo del notch.
      final selector = tester.getRect(
        find.byKey(const ValueKey('zentra-mode-selector')),
      );
      expect(selector.top, greaterThanOrEqualTo(47));
    });
  }

  testWidgets('las dos bandas nombran su pantalla sobre el selector',
      (tester) async {
    // La paridad no era sólo de color: el formulario de hábito se presentaba
    // —flecha, nombre, una acción— y Enfoque no se presentaba, abría con un
    // titular poético debajo del selector. Ahora las dos bandas dicen dónde
    // estás en la misma fila y el selector va debajo en las dos.
    await pump(tester, const HabitFormScreen());
    final habitTitle = tester.getRect(find.text('Nuevo hábito'));
    final habitSelector = tester.getRect(
      find.byKey(const ValueKey('zentra-mode-selector')),
    );
    expect(habitTitle.bottom, lessThanOrEqualTo(habitSelector.top + 0.5));

    harness = null;
    await pump(tester, const PomodoroScreen());
    final focusTitle = tester.getRect(
      find.byKey(const ValueKey('focus_portal_headline')),
    );
    final focusSelector = tester.getRect(
      find.byKey(const ValueKey('zentra-mode-selector')),
    );
    expect(find.text('Enfoque'), findsOneWidget);
    expect(focusTitle.bottom, lessThanOrEqualTo(focusSelector.top + 0.5));

    // Y una sola acción cierra la fila del título en las dos: ⋯ en el hábito,
    // ⟲ en Enfoque. Dos accesos a lo mismo desde extremos opuestos —un ⚙ arriba
    // y un «Otro» abajo— era el botón de más que se fue.
    final history = find.byTooltip('Historial');
    expect(history, findsOneWidget);
    expect(tester.getCenter(history).dx, greaterThan(focusTitle.right));
    expect(
      tester.getCenter(history).dy,
      closeTo(focusTitle.center.dy, 4),
    );
    expect(find.byTooltip('Ajustes de enfoque'), findsNothing);
  });

  testWidgets('at huge text the halves stack instead of squeezing',
      (tester) async {
    // «Una sola vez» a escala grande no cabe junto a «Se repite»; apilar cuesta
    // una fila y encoger cuesta la etiqueta entera.
    final current = await OwnerBoundWidgetHarness.create();
    harness = current;
    addTearDown(current.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      current.buildApp(
        home: const HabitFormScreen(),
        theme: AppTheme.lightTheme,
        textScale: 2.2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final recurring = tester.getRect(find.byKey(ValueKey(habitKeys[0])));
    final oneTime = tester.getRect(find.byKey(ValueKey(habitKeys[1])));
    expect(
      oneTime.top,
      greaterThanOrEqualTo(recurring.bottom - 0.5),
      reason: 'A escala grande las mitades siguen lado a lado.',
    );
    // Y ninguna baja de la altura mínima de toque.
    expect(recurring.height, greaterThanOrEqualTo(48));
    expect(oneTime.height, greaterThanOrEqualTo(48));
  });
}
