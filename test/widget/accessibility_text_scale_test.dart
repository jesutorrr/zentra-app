import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/presentation/about_screen.dart';
import 'package:zentra/presentation/auth_screen.dart';
import 'package:zentra/presentation/calendar_screen.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/habits_list_screen.dart';
import 'package:zentra/presentation/history_screen.dart';
import 'package:zentra/presentation/onboarding_screen.dart';
import 'package:zentra/presentation/pomodoro_history_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/profile_screen.dart';
import 'package:zentra/presentation/progress_screen.dart';
import 'package:zentra/presentation/settings_screen.dart';
import 'package:zentra/presentation/splash_screen.dart';
import 'package:zentra/presentation/support_screen.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/today_screen.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

import '../support/owner_bound_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Zentra',
      packageName: 'com.jesutorr.appzentra',
      version: '2.0.0',
      buildNumber: '25',
      buildSignature: '',
    );
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
    double textScale = 3.2,
    bool darkMode = false,
  }) async {
    final harness = await OwnerBoundWidgetHarness.create();
    addTearDown(harness.dispose);
    return harness.buildApp(
      home: home,
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      textScale: textScale,
    );
  }

  Future<void> expectNoLayoutException(
    WidgetTester tester,
    Widget screen, {
    Size logicalSize = const Size(390, 844),
    double textScale = 3.2,
  }) async {
    await configureDevice(tester, logicalSize: logicalSize);
    await tester.pumpWidget(
      await buildApp(screen, textScale: textScale),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  }

  testWidgets('auth screen supports maximum accessibility text',
      (tester) async {
    await expectNoLayoutException(tester, const AuthScreen());
  });

  testWidgets('onboarding supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(
      tester,
      OnboardingScreen(onComplete: () {}),
    );
  });

  testWidgets('today screen supports maximum accessibility text',
      (tester) async {
    await expectNoLayoutException(tester, const TodayScreen());
  });

  testWidgets('calendar supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const CalendarScreen());
  });

  testWidgets('about screen supports maximum accessibility text',
      (tester) async {
    await expectNoLayoutException(tester, const AboutScreen());
  });

  testWidgets('habit form supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const HabitFormScreen());
  });

  testWidgets('habit list supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const HabitsListScreen());
  });

  testWidgets('history supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const HistoryScreen());
  });

  testWidgets('pomodoro history supports maximum accessibility text',
      (tester) async {
    await expectNoLayoutException(tester, const PomodoroHistoryScreen());
  });

  testWidgets('pomodoro supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const PomodoroScreen());
  });

  testWidgets('profile supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const ProfileScreen());
  });

  testWidgets('progress supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const ProgressScreen());
  });

  testWidgets('settings supports maximum accessibility text', (tester) async {
    await expectNoLayoutException(tester, const SettingsScreen());
  });

  final additionalDevices = <({String name, Size logicalSize})>[
    (name: 'compact iPhone', logicalSize: const Size(320, 568)),
    (name: 'iPad', logicalSize: const Size(1024, 1366)),
  ];
  final screenFactories = <({String name, Widget Function() build})>[
    (name: 'auth', build: () => const AuthScreen()),
    (
      name: 'onboarding',
      build: () => OnboardingScreen(onComplete: () {}),
    ),
    (name: 'today', build: () => const TodayScreen()),
    (name: 'calendar', build: () => const CalendarScreen()),
    (name: 'about', build: () => const AboutScreen()),
    (name: 'habit form', build: () => const HabitFormScreen()),
    (name: 'habit list', build: () => const HabitsListScreen()),
    (name: 'history', build: () => const HistoryScreen()),
    (name: 'pomodoro history', build: () => const PomodoroHistoryScreen()),
    (name: 'pomodoro', build: () => const PomodoroScreen()),
    (name: 'profile', build: () => const ProfileScreen()),
    (name: 'progress', build: () => const ProgressScreen()),
    (name: 'settings', build: () => const SettingsScreen()),
    (name: 'support', build: () => const SupportScreen()),
    (name: 'splash', build: () => const SplashScreen()),
  ];

  for (final device in additionalDevices) {
    for (final screen in screenFactories) {
      testWidgets(
        '${screen.name} supports maximum accessibility text on ${device.name}',
        (tester) async {
          await expectNoLayoutException(
            tester,
            screen.build(),
            logicalSize: device.logicalSize,
          );
        },
      );
    }
  }

  final adaptiveDevices = <({String name, Size logicalSize})>[
    (name: 'iPhone SE portrait', logicalSize: const Size(320, 568)),
    (name: 'compact Android portrait', logicalSize: const Size(360, 640)),
    (name: 'iPhone standard portrait', logicalSize: const Size(390, 844)),
    (name: 'iPhone large portrait', logicalSize: const Size(440, 956)),
    (name: 'iPad narrow Split View', logicalSize: const Size(507, 1133)),
    (name: 'medium boundary', logicalSize: const Size(600, 960)),
    (name: 'iPad mini portrait', logicalSize: const Size(744, 1133)),
    (name: 'expanded boundary', logicalSize: const Size(840, 1080)),
    (name: 'iPad mini landscape', logicalSize: const Size(1133, 744)),
    (name: 'iPad Pro portrait', logicalSize: const Size(1024, 1366)),
    (name: 'iPad Pro landscape', logicalSize: const Size(1366, 1024)),
  ];

  for (final device in adaptiveDevices) {
    for (final screen in screenFactories) {
      testWidgets(
        '${screen.name} adapts at normal text on ${device.name}',
        (tester) async {
          await expectNoLayoutException(
            tester,
            screen.build(),
            logicalSize: device.logicalSize,
            textScale: 1,
          );
        },
      );
    }
  }

  final darkBoundaryScreens = <({
    String name,
    Size logicalSize,
    Widget Function() build,
  })>[
    (
      name: 'Today compact',
      logicalSize: const Size(360, 640),
      build: () => const TodayScreen(),
    ),
    (
      name: 'Habit form medium',
      logicalSize: const Size(600, 960),
      build: () => const HabitFormScreen(),
    ),
    (
      name: 'Onboarding expanded',
      logicalSize: const Size(840, 1080),
      build: () => OnboardingScreen(onComplete: () {}),
    ),
  ];

  for (final screen in darkBoundaryScreens) {
    testWidgets('${screen.name} adapts in dark mode', (tester) async {
      await configureDevice(tester, logicalSize: screen.logicalSize);
      await tester.pumpWidget(
        await buildApp(
          screen.build(),
          textScale: 2,
          darkMode: true,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }
}
