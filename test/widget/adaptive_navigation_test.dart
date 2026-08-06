import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/infrastructure/notification_service.dart';
import 'package:zentra/presentation/auth_screen.dart';
import 'package:zentra/presentation/design_tokens.dart';
import 'package:zentra/presentation/habits_list_screen.dart';
import 'package:zentra/presentation/onboarding_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/today_screen.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

import '../support/owner_bound_widget_harness.dart';

class _AdaptiveOnboardingNotifications
    implements OnboardingNotificationGateway {
  @override
  Future<DailyReminderSettings> getDailyReminderSettings() async =>
      const DailyReminderSettings(
        morningEnabled: true,
        morningHour: 9,
        morningMinute: 0,
        eveningEnabled: true,
        eveningHour: 19,
        eveningMinute: 0,
      );

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> setDailyReminderSettings(
    DailyReminderSettings settings, {
    DailyReminderSnapshot? snapshot,
  }) async {}

  @override
  Future<void> setHabitRemindersEnabled(bool enabled) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  OwnerBoundWidgetHarness? currentHarness;

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
    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (_) async => null,
    );
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() {
    currentHarness = null;
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
  });

  Future<void> configureDevice(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<Widget> buildApp(
    Widget home, {
    double textScale = 1,
    ThemeData? theme,
  }) async {
    var harness = currentHarness;
    if (harness == null) {
      harness = await OwnerBoundWidgetHarness.create();
      currentHarness = harness;
      addTearDown(harness.dispose);
    }
    return harness.buildApp(
      home: home,
      theme: theme ?? AppTheme.lightTheme,
      textScale: textScale,
    );
  }

  testWidgets('classic auth fallback keeps its two-panel composition',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(1024, 1366));
    await tester.pumpWidget(await buildApp(const ClassicAuthScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final brand = find.byKey(const ValueKey('auth-brand-panel'));
    final form = find.byKey(const ValueKey('auth-form-panel'));
    expect(brand, findsOneWidget);
    expect(form, findsOneWidget);
    expect(tester.getRect(brand).right, lessThan(tester.getRect(form).left));
    expect(tester.getSize(form).width, lessThanOrEqualTo(500));

    await configureDevice(tester, logicalSize: const Size(507, 1133));
    await tester.pumpWidget(await buildApp(const ClassicAuthScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('auth-brand-panel')), findsNothing);
    expect(find.byKey(const ValueKey('auth-form-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia auth confirms one of two local-first paths',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const AuthScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Elige cómo empezar.'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-brand-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-bento-surface')), findsOneWidget);
    expect(find.text('Zentra funciona completa sin cuenta.'), findsNothing);
    expect(find.text('Usar en este dispositivo'), findsOneWidget);
    expect(find.text('Privado y completo.'), findsNothing);
    expect(find.text('Recupera tu espacio.'), findsNothing);
    expect(find.text('Sin perder tu historial.'), findsNothing);
    expect(
      find.text('Tus datos permanecen locales hasta que tú decidas.'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.text('Elige cómo empezar.')).height,
      lessThan(50),
    );
    expect(
      find.byKey(const ValueKey('auth-local-path')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-backup-path')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-google-future')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('auth-google-action')), findsNothing);
    expect(find.byKey(const ValueKey('auth-apple-action')), findsNothing);
    expect(find.byType(TextFormField), findsNothing);

    final bento = tester.getRect(
      find.byKey(const ValueKey('auth-bento-surface')),
    );
    final local = tester.getRect(
      find.byKey(const ValueKey('auth-local-path')),
    );
    final backup = tester.getRect(
      find.byKey(const ValueKey('auth-backup-path')),
    );
    final continueButton = tester.getRect(
      find.byKey(const ValueKey('auth-continue')),
    );
    final privacy = tester.getRect(
      find.text('Tus datos permanecen locales hasta que tú decidas.'),
    );

    expect(local.right, lessThan(backup.left));
    expect(continueButton.top, greaterThan(bento.bottom));
    expect(continueButton.top - bento.bottom, lessThanOrEqualTo(24));
    expect(continueButton.bottom, lessThanOrEqualTo(844));
    expect(
      find.byKey(const ValueKey('auth-continue')),
      findsOneWidget,
    );
    expect(privacy.top, greaterThan(continueButton.bottom));

    final backupPath = find.byKey(const ValueKey('auth-backup-path'));
    await tester.ensureVisible(backupPath);
    await tester.pump();
    await tester.tap(backupPath);
    await tester.tap(find.byKey(const ValueKey('auth-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Restaura tu espacio.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-select-backup')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia auth centers its two local paths on iPad',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(834, 1194));
    await tester.pumpWidget(await buildApp(const AuthScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final form = find.byKey(const ValueKey('auth-form-panel'));
    expect(form, findsOneWidget);
    expect(tester.getSize(form).width, lessThanOrEqualTo(900));
    expect(tester.getCenter(form).dx, closeTo(834 / 2, 1));
    final local = tester.getRect(
      find.byKey(const ValueKey('auth-local-path')),
    );
    final backup = tester.getRect(
      find.byKey(const ValueKey('auth-backup-path')),
    );
    final bento = tester.getRect(
      find.byKey(const ValueKey('auth-bento-surface')),
    );
    expect(local.right, lessThan(backup.left));
    expect(local.top, closeTo(backup.top, 1));
    expect(bento.center.dy, closeTo(1194 / 2, 150));
    expect(find.byKey(const ValueKey('auth-google-future')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salvia auth keeps its two-door bento on iPad mini',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(744, 1133));
    await tester.pumpWidget(await buildApp(const AuthScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final local = tester.getRect(
      find.byKey(const ValueKey('auth-local-path')),
    );
    final backup = tester.getRect(
      find.byKey(const ValueKey('auth-backup-path')),
    );
    final bento = tester.getRect(
      find.byKey(const ValueKey('auth-bento-surface')),
    );

    expect(local.right, lessThan(backup.left));
    expect(bento.center.dy, closeTo(1133 / 2, 150));
    expect(find.byKey(const ValueKey('auth-google-future')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding stays centered between iPad and Split View',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(1133, 744));
    await tester.pumpWidget(
      await buildApp(OnboardingScreen(onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final content = find.byKey(const ValueKey('onboarding-content-panel'));
    final shell = find.byKey(const ValueKey('onboarding-shell'));
    expect(find.byKey(const ValueKey('onboarding-brand-panel')), findsNothing);
    expect(content, findsOneWidget);
    expect(tester.getSize(shell).width, lessThanOrEqualTo(680));
    expect(tester.getCenter(shell).dx, closeTo(1133 / 2, 1));
    expect(
      find.byKey(const ValueKey('onboarding-habit-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-habit-two-column')),
      findsNothing,
    );

    await configureDevice(tester, logicalSize: const Size(507, 1133));
    await tester.pumpWidget(
      await buildApp(OnboardingScreen(onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('onboarding-brand-panel')), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-content-panel')),
      findsOneWidget,
    );
    expect(tester.getCenter(shell).dx, closeTo(507 / 2, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding uses a centered one-screen flow in iPad portrait',
      (tester) async {
    const logicalSize = Size(834, 1194);
    await configureDevice(tester, logicalSize: logicalSize);
    await tester.pumpWidget(
      await buildApp(OnboardingScreen(onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final shell = find.byKey(const ValueKey('onboarding-shell'));
    final next = find.byKey(const ValueKey('onboarding-primary-action'));
    expect(shell, findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-brand-panel')), findsNothing);
    expect(tester.getSize(shell).width, lessThanOrEqualTo(680));
    expect(tester.getCenter(shell).dx, closeTo(logicalSize.width / 2, 1));
    expect(tester.getSize(next).height, greaterThanOrEqualTo(52));
    expect(
      find.byKey(const ValueKey('onboarding-habit-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-habit-two-column')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding keeps iPad mini compact and single-column',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(744, 1133));
    await tester.pumpWidget(
      await buildApp(OnboardingScreen(onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tu primer hábito'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('onboarding-habit-choice-horizontal'),
      ),
      findsOneWidget,
    );
    final create = tester.getRect(find.text('Crear hábito'));
    final skip = tester.getRect(find.text('Saltar'));
    expect(skip.left, greaterThanOrEqualTo(create.right));
    expect(
      find.byKey(const ValueKey('onboarding-habit-single-column')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding keeps a natural horizontal habit choice when wide',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(1366, 1024));
    await tester.pumpWidget(
      await buildApp(OnboardingScreen(onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tu primer hábito'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('onboarding-habit-choice-horizontal'),
      ),
      findsOneWidget,
    );
    final create = tester.getRect(find.text('Crear hábito'));
    final skip = tester.getRect(find.text('Saltar'));
    expect(skip.left, greaterThanOrEqualTo(create.right));
    expect(
      find.byKey(const ValueKey('onboarding-habit-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-habit-two-column')),
      findsNothing,
    );

    final selector = tester.getRect(
      find.byKey(const ValueKey('onboarding-habit-choice')),
    );
    final field = tester.getRect(
      find.byKey(const ValueKey('onboarding-habit-name')),
    );
    expect(field.top - selector.bottom, lessThan(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro keeps its primary action clear on phone and tablet',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const PomodoroScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final quickMode = find.text('Rápido');
    final cycleMode = find.text('Ciclo');
    final startButton = find.byKey(const ValueKey('pomodoro_start_button'));
    expect(quickMode, findsOneWidget);
    expect(cycleMode, findsOneWidget);
    expect(
      find.byKey(const ValueKey('focus_portal_headline')),
      findsOneWidget,
    );
    expect(find.text('Una sola cosa'), findsOneWidget);
    expect(find.text('Enfoque'), findsNothing);
    // Rhythm before headline: the mode selector is the first thing on the
    // screen, the way "Se repite / Una sola vez" opens the habit form.
    expect(
      tester.getRect(quickMode).top,
      lessThan(
        tester
            .getRect(find.byKey(const ValueKey('focus_portal_headline')))
            .top,
      ),
    );
    expect(find.text('Entrar'), findsOneWidget);
    expect(startButton, findsOneWidget);
    expect(startButton.hitTestable(), findsOneWidget);
    expect(tester.getRect(startButton).bottom, lessThanOrEqualTo(844));
    expect(
      tester.getCenter(cycleMode).dx,
      greaterThan(tester.getCenter(quickMode).dx),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(cycleMode);
    await tester.pump();
    expect(find.textContaining('4 enfoques · descansos'), findsOneWidget);
    expect(startButton.hitTestable(), findsOneWidget);
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.byKey(const ValueKey('focus_session_active')),
      findsOneWidget,
    );
    expect(find.text('ENFOQUE · 1 DE 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('focus_work_immersion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pomodoro_timer_progress')),
      findsOneWidget,
    );
    final reset = find.byKey(const ValueKey('pomodoro_reset'));
    final pause = find.byKey(const ValueKey('pomodoro_pause_resume'));
    final cancel = find.byKey(const ValueKey('pomodoro_cancel_activity'));
    expect(reset, findsOneWidget);
    expect(pause, findsOneWidget);
    expect(cancel, findsOneWidget);
    expect(
      (tester.getCenter(reset).dy - tester.getCenter(pause).dy).abs(),
      lessThan(2),
    );
    expect(
      (tester.getCenter(cancel).dy - tester.getCenter(pause).dy).abs(),
      lessThan(2),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(pause);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byKey(const ValueKey('focus_pause_gap')), findsOneWidget);

    await tester.tap(find.byTooltip('Salir del enfoque'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Salir del enfoque?'), findsOneWidget);
    expect(find.text('Salir y conservar'), findsOneWidget);
    expect(find.text('Terminar sesión'), findsOneWidget);
    await tester.tap(find.text('Seguir aquí'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¿Terminar este enfoque?'), findsOneWidget);
    expect(find.text('Esta sesión no sumará minutos.'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('pomodoro_cancel_confirm')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('pomodoro_launcher')),
      findsOneWidget,
    );

    await configureDevice(tester, logicalSize: const Size(1024, 1366));
    await tester.pumpWidget(await buildApp(const PomodoroScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('Ciclo'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Ciclo')).dx,
      greaterThan(tester.getCenter(find.text('Rápido')).dx),
    );
    final launcher = find.byKey(const ValueKey('pomodoro_launcher'));
    expect(tester.getSize(launcher).width, greaterThan(800));
    expect(tester.getCenter(launcher).dx, closeTo(1024 / 2, 1));
    expect(startButton, findsOneWidget);

    // On a tablet the portal claims the middle of the window instead of hugging
    // the top edge and leaving the lower half empty. It centers in the space
    // below the top bar, so its middle lands in the middle third of the window
    // rather than exactly on the window center.
    final portalTop =
        tester.getRect(find.byKey(const ValueKey('focus_portal_headline'))).top;
    final portalBottom = tester
        .getRect(find.byKey(const ValueKey('pomodoro_optional_context')))
        .bottom;
    expect((portalTop + portalBottom) / 2, closeTo(1366 / 2, 1366 / 6));
    expect(portalTop, greaterThan(1366 * 0.25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the whole focus launcher fits on one screen without scrolling',
      (tester) async {
    // Every option on this screen has to be visible without a scroll. "Otro" and
    // "Nombrar esta sesión" are the two the user reported missing: they sat
    // 135dp below the fold behind a five-line headline, a subtitle and a dial
    // sized only by width, and nothing on screen suggested there was more.
    for (final size in const <Size>[
      Size(430, 932), // iPhone 15 Pro Max
      Size(393, 852), // iPhone 15
      Size(375, 667), // iPhone SE 2/3
      Size(360, 640), // small Android
      Size(320, 568), // iPhone SE 1
    ]) {
      currentHarness = null;
      await configureDevice(tester, logicalSize: size);
      await tester.pumpWidget(await buildApp(const PomodoroScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      final label = '${size.width.toInt()}x${size.height.toInt()}';
      final scroll = Scrollable.of(
        tester.element(find.byKey(const ValueKey('pomodoro_optional_context'))),
      ).position;
      expect(
        scroll.maxScrollExtent,
        0,
        reason: '$label: el lanzador de enfoque exige scroll.',
      );

      for (final key in <String>[
        'pomodoro_mode_quick',
        'pomodoro_mode_cycle',
        'focus_portal_headline',
        'pomodoro_duration_25',
        'pomodoro_custom_duration_button',
        'pomodoro_optional_context',
      ]) {
        final finder = find.byKey(ValueKey(key));
        expect(finder, findsOneWidget, reason: '$label: falta $key.');
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(0), reason: '$label: $key');
        expect(
          rect.bottom,
          lessThanOrEqualTo(size.height),
          reason: '$label: $key queda debajo del borde inferior.',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(size.width + 0.5),
          reason: '$label: $key se sale por la derecha.',
        );
      }

      // Fitting must not come out of the tap targets.
      for (final key in <String>[
        'pomodoro_duration_5',
        'pomodoro_duration_15',
        'pomodoro_duration_25',
        'pomodoro_duration_45',
        'pomodoro_custom_duration_button',
      ]) {
        expect(
          tester.getSize(find.byKey(ValueKey(key))).height,
          greaterThanOrEqualTo(48),
          reason: '$label: $key quedó por debajo de 48dp de alto.',
        );
      }

      // Y la duración elegida se sigue leyendo. Caber en una fila no vale nada
      // si el chip seleccionado se queda sin espacio para su propio número: el
      // palomeado se lo comía y el «25» salía a 0dp de ancho, con el número
      // encimado por el check.
      for (final preset in const <int>[5, 15, 25, 45]) {
        final finder = find.byKey(ValueKey('pomodoro_duration_$preset'));
        final chip = tester.getRect(finder);
        final digits = tester.getRect(
          find.descendant(of: finder, matching: find.text('$preset')),
        );
        expect(
          digits.width,
          greaterThanOrEqualTo(10),
          reason: '$label: el chip de $preset aplastó su propio número.',
        );
        expect(
          digits.left,
          greaterThanOrEqualTo(chip.left - 0.5),
          reason: '$label: el número de $preset se sale del chip.',
        );
        expect(
          digits.right,
          lessThanOrEqualTo(chip.right + 0.5),
          reason: '$label: el número de $preset se sale del chip.',
        );
      }

      // All five presets on one row: a second row is what pushed the naming
      // button off the bottom, and it stranded "Otro" where nobody looks.
      final presetTop = tester.getRect(
        find.byKey(const ValueKey('pomodoro_duration_5')),
      ).top;
      expect(
        tester
            .getRect(find.byKey(const ValueKey('pomodoro_custom_duration_button')))
            .top,
        closeTo(presetTop, 1),
        reason: '$label: "Otro" cayó a una segunda fila.',
      );

      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('Focus carries a typed session name into the history',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const PomodoroScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    // Naming a session is the only way to tell two entries apart in the
    // history, so the field has to be reachable from the launcher and its text
    // has to survive all the way into the running session.
    final toggle = find.byKey(const ValueKey('pomodoro_optional_context'));
    expect(toggle, findsOneWidget);
    expect(find.text('Nombrar esta sesión'), findsOneWidget);

    await tester.ensureVisible(toggle);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('pomodoro_activity_field'));
    expect(field, findsOneWidget);
    expect(find.text('Nombre de la sesión'), findsOneWidget);

    // On a phone the field opens below the fold, so revealing it has to also
    // focus it: otherwise the user taps the button and nothing appears to
    // happen until they scroll.
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);

    // The field must not change height when it gains focus or text: it sits in
    // an AnimatedSize, and a jump there overflowed the portal's sliver.
    final emptyHeight = tester.getSize(field).height;
    await tester.enterText(field, 'Estudiar Química');
    await tester.pumpAndSettle();
    expect(tester.getSize(field).height, emptyHeight);

    // Collapsing the field animates the portal's height, and mid-animation the
    // column must not paint taller than the space the sliver reserved.
    await tester.tap(toggle);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pomodoro_start_button')));
    // Entering the portal waits out its own transition, then the engine persists
    // the session before the immersive scene replaces the launcher, so the scene
    // is waited for rather than assumed after a fixed number of frames.
    final controls = find.byKey(const ValueKey('pomodoro_cancel_activity'));
    for (var i = 0; i < 20 && controls.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(controls, findsOneWidget);

    final state = currentHarness!.pomodoroController.state;
    expect(state.quickSessionName, 'Estudiar Química');
    expect(state.sessionLabel, 'Estudiar Química');
    // Scoped to the running session: the launcher's field still holds the same
    // text while the two scenes cross-fade.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('focus_session_active')),
        matching: find.text('Estudiar Química'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // Leave no timer running behind this test.
    await tester.tap(controls);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('pomodoro_cancel_confirm')));
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
      'Pomodoro keeps the compact primary action visible at 320dp and 320% text',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(320, 568));
    await tester.pumpWidget(
      await buildApp(
        const PomodoroScreen(),
        textScale: 3.2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final startButton = find.byKey(const ValueKey('pomodoro_start_button'));
    expect(startButton, findsOneWidget);
    expect(startButton.hitTestable(), findsOneWidget);
    expect(tester.getRect(startButton).bottom, lessThanOrEqualTo(568));
    expect(find.text('Iniciar enfoque'), findsOneWidget);
    expect(tester.takeException(), isNull);

    currentHarness!.pomodoroController.selectMode(PomodoroMode.cycle);
    await tester.pump();

    expect(startButton.hitTestable(), findsOneWidget);
    expect(find.text('Iniciar ciclo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro custom duration uses a 60-minute dial', (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const PomodoroScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final customDuration =
        find.byKey(const ValueKey('pomodoro_custom_duration_button'));
    await tester.ensureVisible(customDuration);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(customDuration);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pomodoro_duration_dial')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pomodoro_duration_picker')),
      findsNothing,
    );
    expect(find.text('Gira el dial. De 5 a 60 minutos.'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('pomodoro_duration_dial')),
    );
    expect(semantics.value, '25 minutos');
    expect(semantics.increasedValue, '30 minutos');
    expect(semantics.decreasedValue, '20 minutos');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro timer scales down at 320dp without overflowing',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(320, 640));
    await tester.pumpWidget(await buildApp(const PomodoroScreen()));
    currentHarness!.pomodoroController.selectSessionType(
      SessionType.shortBreak,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Descanso corto'), findsWidgets);
    expect(find.text('Suelta los hombros'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('focus_rest_immersion')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro completion closes the circle without a dialog card',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    var closed = false;
    await tester.pumpWidget(
      await buildApp(
        FocusCompletionScene(
          activity: PomodoroActivity(
            id: 'completed-focus',
            name: 'Repasar Álgebra lineal',
            startTime: DateTime(2026, 8, 4, 12),
            endTime: DateTime(2026, 8, 4, 12, 25),
            cyclesCompleted: 1,
            totalMinutes: 25,
            isCompleted: true,
          ),
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('focus_completion_dialog')),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Enfoque completado'), findsOneWidget);
    expect(find.text('Una cosa menos en tu cabeza.'), findsOneWidget);
    await tester.tap(find.text('Hecho'));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pomodoro completion stays readable when the app is in AMOLED',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(
      await buildApp(
        FocusCompletionScene(
          activity: PomodoroActivity(
            id: 'completed-focus',
            name: 'Repasar Álgebra lineal',
            startTime: DateTime(2026, 8, 4, 12),
            endTime: DateTime(2026, 8, 4, 12, 25),
            cyclesCompleted: 1,
            totalMinutes: 25,
            isCompleted: true,
          ),
          onClose: () {},
        ),
        // The closing seal paints a light surface regardless of the app theme,
        // so it is the dark theme that exposes the bug: descendants resolved
        // their foreground from the ambient scheme and landed near-black ink on
        // cream (1.31:1 for the button, 1.44:1 for the close icon).
        theme: AppTheme.darkTheme,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final surface = ZentraPalette.light.functionalSurface;

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final buttonBackground =
        button.style!.backgroundColor!.resolve(<WidgetState>{})!;
    final buttonLabel = button.style!.foregroundColor?.resolve(<WidgetState>{}) ??
        Theme.of(tester.element(find.byType(FilledButton)))
            .filledButtonTheme
            .style!
            .foregroundColor!
            .resolve(<WidgetState>{})!;
    expect(
      _contrastRatio(buttonLabel, buttonBackground),
      greaterThanOrEqualTo(4.5),
    );

    final closeIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('focus_completion_close')),
        matching: find.byType(Icon),
      ),
    );
    final closeColor = closeIcon.color ??
        IconTheme.of(
          tester.element(find.byKey(const ValueKey('focus_completion_close'))),
        ).color!;
    expect(_contrastRatio(closeColor, surface), greaterThanOrEqualTo(3.0));

    // The headline and the closing line are the two largest pieces of text and
    // must hold normal-text contrast against the light surface too.
    for (final text in <String>[
      'Enfoque completado',
      'Una cosa menos en tu cabeza.',
      'LISTO',
    ]) {
      final widget = tester.widget<Text>(find.text(text));
      final resolved = widget.style?.color ??
          DefaultTextStyle.of(tester.element(find.text(text))).style.color!;
      expect(
        _contrastRatio(resolved, surface),
        greaterThanOrEqualTo(4.5),
        reason: 'El texto «$text» no alcanza 4.5:1 sobre el fondo claro.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today exposes primary destinations instead of a hidden menu',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const TodayScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Hábitos'), findsWidgets);
    expect(find.text('Enfoque'), findsWidgets);
    expect(find.text('Progreso'), findsOneWidget);
    expect(find.text('Mes'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(
      tester.getRect(find.text('Mes')).right,
      lessThanOrEqualTo(390),
    );

    await tester.tap(
      find.byKey(const ValueKey('today-destination-label-Hábitos')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HabitsListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today keeps its empty state in a centered medium canvas',
      (tester) async {
    const logicalSize = Size(834, 1194);
    await configureDevice(tester, logicalSize: logicalSize);
    await tester.pumpWidget(await buildApp(const TodayScreen()));
    await tester.pump(const Duration(seconds: 1));

    final emptyState = find.byKey(const ValueKey('today-empty-state'));
    expect(emptyState, findsOneWidget);
    expect(
      find.byKey(const ValueKey('today-single-column-layout')),
      findsOneWidget,
    );
    expect(tester.getSize(emptyState).width, lessThanOrEqualTo(720));
    expect(
      tester.getCenter(emptyState).dx,
      closeTo(logicalSize.width / 2, 1),
    );
    expect(find.text('Hábito'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today settles new habits and avoids double completed opacity',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    await tester.pumpWidget(await buildApp(const TodayScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final habitController = currentHarness!.habitController;
    await habitController.createHabit(
      Habit(
        id: 'adaptive-visible-habit',
        title: 'Caminar 20 minutos',
        category: Category.movimiento,
        frequency: Frequency.daily(),
        createdAt: DateTime.now(),
      ),
    );

    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final pending = find.byKey(
      const ValueKey('today-pending-adaptive-visible-habit'),
    );
    expect(pending, findsOneWidget);
    final pendingFade = tester.widget<FadeTransition>(
      find.descendant(of: pending, matching: find.byType(FadeTransition)).first,
    );
    expect(pendingFade.opacity.value, closeTo(1, 0.001));

    await habitController.toggleHabitToday('adaptive-visible-habit');
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final completed = find.byKey(
      const ValueKey('today-completed-adaptive-visible-habit'),
    );
    expect(completed, findsOneWidget);
    expect(
      find.descendant(of: completed, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  final onboardingDevices = <({String name, Size size, double textScale})>[
    (
      name: 'compact iPhone with maximum text',
      size: const Size(320, 568),
      textScale: 3.2,
    ),
    (
      name: 'iPad landscape',
      size: const Size(1366, 1024),
      textScale: 1,
    ),
  ];

  for (final device in onboardingDevices) {
    testWidgets('onboarding remains completable on ${device.name}',
        (tester) async {
      var completed = false;
      await configureDevice(tester, logicalSize: device.size);
      await tester.pumpWidget(
        await buildApp(
          OnboardingScreen(
            onComplete: () => completed = true,
            notificationGateway: _AdaptiveOnboardingNotifications(),
          ),
          textScale: device.textScale,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await currentHarness!.profileController.createProfile(name: 'Prueba');

      final start = find.byKey(const ValueKey('onboarding-primary-action'));
      expect(start, findsOneWidget);
      await tester.ensureVisible(start);
      await tester.tap(start);
      for (var attempt = 0; attempt < 20 && !completed; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(completed, isTrue);
      expect(tester.takeException(), isNull);

      // The production callback replaces onboarding with Today. Mirror that
      // teardown so delayed flutter_animate callbacks do not outlive the test.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

/// WCAG relative-luminance contrast ratio between two opaque colours.
double _contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}
