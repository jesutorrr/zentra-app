import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/habit_state.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/core/constants.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/notification_service.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/onboarding_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _FakePomodoroNotificationsPlatform
    extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel(int id) async {}
}

class _FakeNotificationGateway implements OnboardingNotificationGateway {
  _FakeNotificationGateway({
    this.requestResult = false,
    this.requestCompleter,
  });

  final bool requestResult;
  final Completer<bool>? requestCompleter;
  bool systemGranted = false;
  int permissionRequests = 0;
  int habitPreferenceWrites = 0;
  int dailyPreferenceWrites = 0;
  bool? habitRemindersEnabled;
  DailyReminderSettings dailySettings = const DailyReminderSettings(
    morningEnabled: false,
    morningHour: 9,
    morningMinute: 0,
    eveningEnabled: false,
    eveningHour: 19,
    eveningMinute: 0,
  );
  DailyReminderSnapshot? dailySnapshot;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    final result = requestCompleter == null
        ? requestResult
        : await requestCompleter!.future;
    systemGranted = result;
    return result;
  }

  @override
  Future<bool> isPermissionGranted() async {
    return systemGranted;
  }

  @override
  Future<void> setHabitRemindersEnabled(bool enabled) async {
    habitPreferenceWrites += 1;
    habitRemindersEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('habit_reminders_enabled', enabled);
  }

  @override
  Future<DailyReminderSettings> getDailyReminderSettings() async {
    return dailySettings;
  }

  @override
  Future<void> setDailyReminderSettings(
    DailyReminderSettings settings, {
    DailyReminderSnapshot? snapshot,
  }) async {
    dailyPreferenceWrites += 1;
    dailySettings = settings;
    dailySnapshot = snapshot;
  }
}

class _FakeHabitReminderService implements HabitReminderService {
  int scheduled = 0;
  int cancelled = 0;
  String? habitTitle;
  int? hour;
  int? minute;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    cancelled += 1;
  }

  @override
  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    bool isOneTime = false,
    DateTime? scheduledDate,
  }) async {
    scheduled += 1;
    this.habitTitle = habitTitle;
    this.hour = hour;
    this.minute = minute;
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }
}

class _Harness {
  final String ownerId;
  final ProviderContainer container;

  const _Harness({
    required this.ownerId,
    required this.container,
  });

  HabitState get habits {
    return container.read(habitControllerProvider(ownerId)).requireValue;
  }

  UserProfile? get profile {
    return container
        .read(profileControllerProvider(ownerId))
        .valueOrNull
        ?.profile;
  }

  Future<void> createHabit(Habit habit) {
    return container
        .read(habitControllerProvider(ownerId).notifier)
        .createHabit(habit);
  }

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterLocalNotificationsPlatform.instance =
        _FakePomodoroNotificationsPlatform();
  });

  Future<_Harness> pumpOnboarding(
    WidgetTester tester, {
    required OnboardingNotificationGateway notificationGateway,
    required VoidCallback onComplete,
    HabitReminderService? reminderService,
    Size size = const Size(390, 844),
    double textScale = 1,
    String userId = 'user-1',
    String instanceId = 'primary',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(userId),
        habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, userId);
          return LocalStorageRepository.forOwner(
            prefs,
            ownerId: requestedOwner,
          );
        }),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          (requestedOwner) {
            expect(requestedOwner, userId);
            return SharedPreferencesCompletedTaskRepository(
              prefs,
              ownerId: requestedOwner,
            );
          },
        ),
        profileRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, userId);
          return SharedPreferencesProfileRepository(
            prefs,
            ownerId: requestedOwner,
          );
        }),
        habitReminderServiceProvider.overrideWithValue(
          reminderService ?? _FakeHabitReminderService(),
        ),
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required ownerId,
            required onChanged,
          }) {
            return PomodoroEngine(
              initialUserId: ownerId,
              onChanged: onChanged,
            );
          },
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      habitControllerProvider(userId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      profileControllerProvider(userId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(userId).future),
      container.read(profileControllerProvider(userId).future),
    ]);
    if (container
            .read(profileControllerProvider(userId))
            .valueOrNull
            ?.profile ==
        null) {
      await container
          .read(profileControllerProvider(userId).notifier)
          .createProfile(name: 'Uri');
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: OnboardingScreen(
            key: ValueKey('onboarding-$instanceId'),
            userId: userId,
            notificationGateway: notificationGateway,
            onComplete: onComplete,
          ),
        ),
      ),
    );
    await tester.pump();
    return _Harness(ownerId: userId, container: container);
  }

  Future<void> continueFlow(WidgetTester tester) async {
    await tester.pump();
  }

  Future<void> completeFlow(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('onboarding-primary-action'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets(
    'persists the one-screen flow and defers denied permission to Today',
    (tester) async {
      var completions = 0;
      final notifications = _FakeNotificationGateway();
      final reminders = _FakeHabitReminderService();
      final harness = await pumpOnboarding(
        tester,
        notificationGateway: notifications,
        reminderService: reminders,
        onComplete: () => completions += 1,
      );

      expect(find.text('Tu primer hábito'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Hazlo tuyo'), findsNothing);
      final field = find.byKey(const ValueKey('onboarding-habit-name'));
      await tester.enterText(field, 'Practicar escalas');
      await tester.tap(find.byKey(const ValueKey('habit-category-varios')));
      await completeFlow(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(completions, 1);
      expect(harness.habits.habits, hasLength(1));
      expect(harness.habits.habits.single.title, 'Practicar escalas');
      expect(harness.habits.habits.single.category, Category.varios);
      expect(harness.habits.habits.single.hasReminder, isFalse);
      expect(notifications.permissionRequests, 1);
      expect(notifications.dailyPreferenceWrites, 1);
      expect(notifications.dailySettings.hasEnabledReminder, isFalse);
      expect(reminders.scheduled, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed_user-1'), isTrue);
      expect(
        prefs.getBool(kNotificationPermissionNoticePendingKey),
        isTrue,
      );
      final reloadedHabits = await LocalStorageRepository.forOwner(
        prefs,
        ownerId: 'user-1',
      ).getHabits();
      expect(reloadedHabits.single.title, 'Practicar escalas');
    },
  );

  testWidgets('requests permission once at the final CTA and saves defaults',
      (tester) async {
    var completed = false;
    final notifications = _FakeNotificationGateway(requestResult: true);
    final harness = await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () => completed = true,
    );

    await continueFlow(tester);
    expect(
      find.byKey(const ValueKey('onboarding-reminders-ready')),
      findsOneWidget,
    );
    expect(notifications.permissionRequests, 0);
    await completeFlow(tester);

    expect(completed, isTrue);
    expect(notifications.permissionRequests, 1);
    expect(notifications.dailySettings.morningEnabled, isTrue);
    expect(notifications.dailySettings.eveningEnabled, isTrue);
    expect(notifications.dailySnapshot?.totalHabits, 1);
    expect(harness.habits.habits.single.hasReminder, isFalse);
    expect(
      (await SharedPreferences.getInstance())
          .getBool(kNotificationPermissionNoticePendingKey),
      isFalse,
    );
  });

  testWidgets('denial never blocks entry', (tester) async {
    var completed = false;
    final notifications = _FakeNotificationGateway();
    final harness = await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () => completed = true,
    );
    await continueFlow(tester);
    await completeFlow(tester);

    expect(completed, isTrue);
    expect(harness.habits.habits.single.hasReminder, isFalse);
    expect(
      (await SharedPreferences.getInstance())
          .getBool(kNotificationPermissionNoticePendingKey),
      isTrue,
    );

    expect(find.text('Tu espacio volvió contigo'), findsNothing);
  });

  testWidgets('keeps step two reachable at 320dp and 320 percent text',
      (tester) async {
    await pumpOnboarding(
      tester,
      notificationGateway: _FakeNotificationGateway(),
      onComplete: () {},
      size: const Size(320, 568),
      textScale: 3.2,
    );
    expect(find.byKey(const ValueKey('onboarding-brand-panel')), findsNothing);
    await continueFlow(tester);
    expect(find.text('Tu primer hábito'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-reminders-ready')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('onboarding-primary-action')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lets morning and night be adjusted independently',
      (tester) async {
    final notifications = _FakeNotificationGateway(requestResult: true);
    await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () {},
    );
    await continueFlow(tester);
    final evening = find.byKey(const ValueKey('onboarding-evening-reminder'));
    await tester.ensureVisible(evening);
    await tester.tap(evening);
    await tester.pump();
    await completeFlow(tester);

    expect(notifications.dailySettings.morningEnabled, isTrue);
    expect(notifications.dailySettings.morningHour, 9);
    expect(notifications.dailySettings.eveningEnabled, isFalse);
    expect(notifications.permissionRequests, 1);
  });

  testWidgets('keeps reminders available when the first habit is skipped',
      (tester) async {
    final notifications = _FakeNotificationGateway(requestResult: true);
    final harness = await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () {},
    );
    await continueFlow(tester);
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding-morning-reminder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-evening-reminder')),
      findsOneWidget,
    );
    await completeFlow(tester);

    expect(harness.habits.habits, isEmpty);
    expect(notifications.dailySettings.morningEnabled, isTrue);
    expect(notifications.dailySettings.eveningEnabled, isTrue);
    expect(notifications.dailySnapshot?.totalHabits, 0);
  });

  testWidgets('disables the final CTA while system permission is pending',
      (tester) async {
    var completed = false;
    final permission = Completer<bool>();
    final notifications = _FakeNotificationGateway(
      requestCompleter: permission,
    );
    await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () => completed = true,
    );
    await continueFlow(tester);
    final button = find.byKey(const ValueKey('onboarding-primary-action'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    permission.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(notifications.permissionRequests, 1);
    expect(completed, isTrue);
  });

  testWidgets('keeps the one-screen flow centered on iPad width',
      (tester) async {
    await pumpOnboarding(
      tester,
      notificationGateway: _FakeNotificationGateway(),
      onComplete: () {},
      size: const Size(1024, 1366),
    );
    await continueFlow(tester);
    expect(find.byKey(const ValueKey('onboarding-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-habit-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-category-pills')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reuses the stable first-habit id after an interrupted flow',
      (tester) async {
    final notifications = _FakeNotificationGateway();
    var completions = 0;
    final first = await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () => completions += 1,
    );
    await continueFlow(tester);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-habit-name')),
      'Leer diez páginas',
    );
    await completeFlow(tester);
    expect(first.habits.habits.single.id, 'onboarding-first-habit-user-1');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed_user-1', false);
    final resumed = await pumpOnboarding(
      tester,
      notificationGateway: notifications,
      onComplete: () => completions += 1,
      instanceId: 'resumed',
    );
    await continueFlow(tester);
    final resumedField = tester.widget<TextField>(
      find.byKey(const ValueKey('onboarding-habit-name')),
    );
    expect(resumedField.controller?.text, 'Leer diez páginas');
    await completeFlow(tester);

    expect(completions, 2);
    expect(resumed.habits.habits, hasLength(1));
    expect(resumed.habits.habits.single.title, 'Leer diez páginas');
  });
}
