import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/progress_sync.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/application/theme_provider.dart';
import 'package:zentra/core/constants.dart';
import 'package:zentra/domain/completed_task_repository.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/domain/profile_repository.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_persistence_runtime.dart';
import 'package:zentra/infrastructure/notification_service.dart';
import 'package:zentra/presentation/about_screen.dart';
import 'package:zentra/presentation/auth_screen.dart';
import 'package:zentra/presentation/calendar_screen.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/habits_list_screen.dart';
import 'package:zentra/presentation/history_screen.dart';
import 'package:zentra/presentation/onboarding_screen.dart';
import 'package:zentra/presentation/note_reminder_screen.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/notes_screen.dart';
import 'package:zentra/presentation/pomodoro_history_screen.dart';
import 'package:zentra/presentation/pomodoro_screen.dart';
import 'package:zentra/presentation/profile_screen.dart';
import 'package:zentra/presentation/progress_screen.dart';
import 'package:zentra/presentation/settings_screen.dart';
import 'package:zentra/presentation/session_load_failure_screen.dart';
import 'package:zentra/presentation/splash_screen.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/today_screen.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

class _ReviewNotificationGateway
    implements OnboardingNotificationGateway, HabitFormNotificationGateway {
  _ReviewNotificationGateway({this.permissionGranted = false});

  bool permissionGranted;
  bool habitRemindersEnabled = false;
  DailyReminderSettings dailySettings = const DailyReminderSettings(
    morningEnabled: false,
    morningHour: 9,
    morningMinute: 0,
    eveningEnabled: false,
    eveningHour: 19,
    eveningMinute: 0,
  );

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> setHabitRemindersEnabled(bool enabled) async {
    habitRemindersEnabled = enabled;
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
    dailySettings = settings;
  }
}

class _ReviewHabitReminderService implements HabitReminderService {
  const _ReviewHabitReminderService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelHabitReminder(String habitId) async {}

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
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const deviceName = String.fromEnvironment(
    'SCREEN_REVIEW_DEVICE',
    defaultValue: 'device',
  );
  const reviewScope = String.fromEnvironment(
    'SCREEN_REVIEW_SCOPE',
    defaultValue: 'full',
  );

  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() async {
    await initializeDateFormatting('es', null);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      foregroundChannel,
      (call) async => call.method == 'isRunningService' ? false : null,
    );
    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async => null,
    );

    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  testWidgets('reviews the primary Zentra journey screen by screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setBool(TooltipKeys.fabNewHabit, true);
    await preferences.setBool(TooltipKeys.pomodoroButton, true);
    await preferences.setBool(TooltipKeys.habitCard, true);

    final dependencies = await _ReviewHarness.create(preferences);
    addTearDown(dependencies.dispose);
    final review = _ScreenReviewSession(
      binding: binding,
      tester: tester,
      deviceName: deviceName,
    );

    if (reviewScope == 'habits') {
      await _reviewHabitsScope(review, dependencies);
      return;
    }
    if (reviewScope == 'entry') {
      await _reviewEntryScope(review, dependencies);
      return;
    }
    if (reviewScope == 'onboarding') {
      await _reviewOnboardingScope(review, dependencies);
      return;
    }
    if (reviewScope == 'habit-form') {
      await _reviewHabitFormScope(review, dependencies);
      return;
    }
    if (reviewScope == 'notes') {
      await _reviewNotesScope(review, dependencies);
      return;
    }
    if (reviewScope == 'focus') {
      await _reviewFocusScope(review, dependencies);
      return;
    }

    await _reviewEntryJourney(review, dependencies);
    await _reviewAuthenticatedJourney(review, dependencies);
    await _reviewDarkIdentity(review, dependencies);
  });
}

Future<void> _reviewOnboardingScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await dependencies.seedAuthenticatedData();
  var completed = false;

  Future<void> captureFlow({
    required ThemeMode themeMode,
    required bool completeFlow,
  }) async {
    final suffix = themeMode == ThemeMode.dark ? 'amoled' : 'light';
    final gateway = _ReviewNotificationGateway();
    await review.show(
      dependencies.buildApp(
        home: OnboardingScreen(
          key: ValueKey('review-onboarding-$suffix'),
          userId: _ReviewHarness.ownerId,
          notificationGateway: gateway,
          onComplete: () => completed = true,
        ),
        themeMode: themeMode,
      ),
      expected: find.byType(OnboardingScreen),
    );
    expect(find.text('Hazlo tuyo'), findsNothing);
    expect(find.text('Tu espacio volvió contigo'), findsNothing);
    expect(find.text('Tu primer hábito'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-category-pills')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-reminders-ready')),
      findsOneWidget,
    );
    await review.capture('00-onboarding-first-habit-$suffix');
    await review.tap(
      find.byKey(const ValueKey('onboarding-reminders-adjust')),
    );
    expect(find.text('Ajustar recordatorios'), findsOneWidget);
    await review.capture('01-onboarding-reminder-adjustments-$suffix');
    await review.tap(find.text('Listo'));

    if (!completeFlow) return;
    await review.tap(
      find.byKey(const ValueKey('onboarding-primary-action')),
      settleFor: const Duration(seconds: 1),
    );
    expect(completed, isTrue);
    expect(gateway.permissionGranted, isFalse);
    expect(
      dependencies.preferences.getBool(
        'onboarding_completed_${_ReviewHarness.ownerId}',
      ),
      isTrue,
    );
    expect(
      dependencies.preferences.getBool(
        kNotificationPermissionNoticePendingKey,
      ),
      isTrue,
    );
    final habits = await dependencies.habitRepository.getHabits();
    expect(
      habits.any(
        (habit) =>
            habit.id == 'onboarding-first-habit-${_ReviewHarness.ownerId}',
      ),
      isTrue,
    );
  }

  await captureFlow(themeMode: ThemeMode.light, completeFlow: true);
  await captureFlow(themeMode: ThemeMode.dark, completeFlow: false);

  await review.show(
    dependencies.buildApp(home: const TodayScreen()),
    expected: find.byType(TodayScreen),
  );
  await review.waitForUi(const Duration(milliseconds: 250));
  expect(
    find.byKey(const ValueKey('today-notification-permission-notice')),
    findsOneWidget,
  );
  await review.capture('02-today-permission-notice-light');

  await review.show(
    dependencies.buildApp(
      home: const TodayScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(TodayScreen),
  );
  await review.waitForUi(const Duration(milliseconds: 250));
  expect(
    find.byKey(const ValueKey('today-notification-permission-notice')),
    findsOneWidget,
  );
  await review.capture('02-today-permission-notice-amoled');
}

Future<void> _reviewHabitFormScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  final notifications = _ReviewNotificationGateway(permissionGranted: true);

  Future<void> showForm({
    required String state,
    ThemeMode themeMode = ThemeMode.light,
    String? habitId,
  }) {
    return review.show(
      dependencies.buildApp(
        home: HabitFormScreen(
          key: ValueKey('review-habit-form-$state'),
          habitId: habitId,
          notificationGateway: notifications,
          now: () => DateTime(2026, 8, 3, 12),
        ),
        themeMode: themeMode,
      ),
      expected: find.byType(HabitFormScreen),
    );
  }

  Future<void> enterTitle(String value) async {
    final field = find.byKey(const ValueKey('habit-title-field'));
    await review.tap(field, settleFor: const Duration(milliseconds: 200));
    await review.tester.enterText(field, value);
    await review.waitForUi(const Duration(milliseconds: 200));
    FocusManager.instance.primaryFocus?.unfocus();
    await review.waitForUi(const Duration(milliseconds: 250));
  }

  await showForm(state: 'recurring-light');
  await enterTitle('Caminar 20 minutos');
  await review.tap(find.byKey(const ValueKey('habit-category-movimiento')));
  await review.capture('00-habit-form-recurring-light');

  await showForm(
    state: 'recurring-amoled',
    themeMode: ThemeMode.dark,
  );
  await enterTitle('Caminar 20 minutos');
  await review.tap(find.byKey(const ValueKey('habit-category-movimiento')));
  await review.capture('01-habit-form-recurring-amoled');

  await showForm(state: 'one-time-light');
  await review.tap(find.byKey(const ValueKey('habit-mode-one-time')));
  await review.tap(find.byKey(const ValueKey('habit-date-tomorrow')));
  await enterTitle('Llamar al dentista');
  await review.capture('02-habit-form-one-time-light');

  await showForm(state: 'one-time-amoled', themeMode: ThemeMode.dark);
  await review.tap(find.byKey(const ValueKey('habit-mode-one-time')));
  await review.tap(find.byKey(const ValueKey('habit-date-tomorrow')));
  await enterTitle('Llamar al dentista');
  await review.capture('03-habit-form-one-time-amoled');

  await showForm(state: 'custom-days');
  await enterTitle('Entrenar tres días');
  await review.tap(find.byKey(const ValueKey('habit-category-movimiento')));
  await review.tap(find.byKey(const ValueKey('habit-frequency-custom')));
  await review.tap(find.byKey(const ValueKey('habit-day-2')));
  await review.tap(find.byKey(const ValueKey('habit-day-4')));
  await review.tap(find.byKey(const ValueKey('habit-day-6')));
  await review.capture('04-habit-form-custom-days');

  await showForm(state: 'reminder');
  await enterTitle('Leer diez páginas');
  await review.tap(find.byKey(const ValueKey('habit-reminder-toggle')));
  expect(
    find.byKey(const ValueKey('habit-reminder-time')),
    findsOneWidget,
  );
  await review.capture('05-habit-form-reminder');

  await showForm(state: 'keyboard');
  final keyboardField = find.byKey(const ValueKey('habit-title-field'));
  await review.tap(keyboardField, settleFor: const Duration(milliseconds: 200));
  await review.tester.enterText(keyboardField, 'Leer diez páginas');
  await review.waitForUi(const Duration(milliseconds: 250));
  await review.capture('06-habit-form-keyboard');
  FocusManager.instance.primaryFocus?.unfocus();

  const editHabitId = 'screen-review-edit-habit';
  await dependencies.habitRepository.saveHabit(
    Habit(
      id: editHabitId,
      title: 'Revisar metas del día',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime(2026, 7, 1),
    ),
  );
  await dependencies.habitController.reload();
  await showForm(state: 'editing', habitId: editHabitId);
  await review.tap(find.byKey(const ValueKey('habit-more-menu')));
  expect(find.text('Eliminar'), findsOneWidget);
  await review.capture('07-habit-form-editing-menu');
}

Future<void> _reviewNotesScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await dependencies.seedAuthenticatedData();

  Future<void> showLibrary({ThemeMode themeMode = ThemeMode.light}) {
    return review.show(
      dependencies.buildApp(home: const NotesScreen(), themeMode: themeMode),
      expected: find.byType(NotesScreen),
    );
  }

  /// Opens the seeded note from the library.
  ///
  /// A window wide enough for list and detail keeps the library on screen and
  /// only selects the card, so the surface is one more tap away there.
  Future<void> openNote() async {
    await review.tap(
      find.byKey(const ValueKey('note-card-review-note-algebra')),
    );
    if (find.byType(NoteSurface).evaluate().isEmpty) {
      await review.tap(find.byTooltip('Editar nota'));
    }
    expect(find.byType(NoteSurface), findsOneWidget);
    expect(find.byKey(const ValueKey('note-surface')), findsOneWidget);
  }

  Finder checkboxOf(int blockIndex) => find.descendant(
        of: find.byKey(ValueKey('note-block-$blockIndex')),
        matching: find.byKey(const ValueKey('note-block-checkbox')),
      );

  await showLibrary();
  expect(find.byKey(const ValueKey('notes-tag-filter')), findsOneWidget);
  expect(find.text('Repasar Álgebra lineal'), findsWidgets);
  await review.capture('00-notes-library-light');

  await review.tap(
    find.byKey(const ValueKey('notes-tag-filter-producto')),
  );
  expect(find.text('Ideas para Zentra'), findsWidgets);
  expect(find.text('Repasar Álgebra lineal'), findsNothing);
  await review.capture('01-notes-tag-filter-light');
  await review.tap(find.byKey(const ValueKey('notes-tag-filter-all')));

  final search = find.byKey(const ValueKey('notes-search'));
  await review.tap(search);
  await review.tester.enterText(search, 'vectoriales');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Repasar Álgebra lineal'), findsWidgets);
  expect(find.text('Ideas para Zentra'), findsNothing);
  await review.capture('02-notes-search-light');
  await review.tap(find.byTooltip('Limpiar búsqueda'));

  await openNote();
  // Reading: no field, no caret and no bar anywhere on the note.
  expect(find.byKey(const ValueKey('note-title-heading')), findsOneWidget);
  expect(find.byKey(const ValueKey('note-active-block')), findsNothing);
  expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  await review.capture('03-note-surface-reading-light');

  await review.tap(find.byKey(const ValueKey('note-block-0')));
  expect(find.byKey(const ValueKey('note-active-block')), findsOneWidget);
  expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);
  await review.capture('04-note-surface-writing-light');
  await review.tap(find.byKey(const ValueKey('note-done')));
  expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);

  // The details reach the reader through the shape the window allows: a sheet
  // on a phone, a column that can be folded away on a wide window.
  final usesSideColumn =
      find.byKey(const ValueKey('note-details-column')).evaluate().isNotEmpty;
  if (usesSideColumn) {
    expect(find.byKey(const ValueKey('note-details-action')), findsNothing);
    await review.tap(find.byKey(const ValueKey('note-details-collapse')));
    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    await review.capture('05-note-details-light');
    await review.tap(find.byKey(const ValueKey('note-details-expand')));
  } else {
    await review.tap(find.byKey(const ValueKey('note-details-action')));
    expect(find.text('Volver con intención'), findsOneWidget);
    await review.capture('05-note-details-light');
    await review.backTo<NoteSurface>();
  }

  for (final block in _pendingCheckBlocks) {
    await review.tap(checkboxOf(block));
  }
  expect(find.byKey(const ValueKey('note-checklist-complete')), findsOneWidget);
  await review.capture('06-note-checklist-complete-light');
  // Put the note back the way it was seeded so the AMOLED pass shows the same
  // half finished checklist instead of a note that is already done.
  for (final block in _pendingCheckBlocks) {
    await review.tap(checkboxOf(block));
  }
  expect(find.byKey(const ValueKey('note-checklist-complete')), findsNothing);
  await review.backTo<NotesScreen>();

  await showLibrary(themeMode: ThemeMode.dark);
  await review.capture('07-notes-library-amoled');

  await openNote();
  expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  await review.capture('08-note-surface-reading-amoled');

  await review.tap(find.byKey(const ValueKey('note-block-0')));
  expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);
  await review.capture('09-note-surface-writing-amoled');
}

Future<void> _reviewFocusScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  final controller = dependencies.pomodoroController;
  controller.selectSessionType(SessionType.work);

  await review.show(
    dependencies.buildApp(home: const PomodoroScreen()),
    expected: find.byType(PomodoroScreen),
  );
  expect(find.byKey(const ValueKey('focus_portal')), findsOneWidget);
  expect(find.text('Haz espacio para\nuna sola cosa'), findsOneWidget);
  expect(find.text('Enfoque'), findsNothing);
  await review.capture('00-focus-portal-light');

  await review.tap(
    find.byKey(const ValueKey('pomodoro_custom_duration_button')),
  );
  expect(
    find.byKey(const ValueKey('pomodoro_duration_dial')),
    findsOneWidget,
  );
  await review.capture('01-focus-duration-dial-light');
  await review.tap(find.byKey(const ValueKey('pomodoro_duration_apply')));

  await review.tap(find.byKey(const ValueKey('pomodoro_mode_cycle')));
  expect(find.textContaining('4 enfoques · descansos'), findsOneWidget);
  await review.capture('02-focus-cycle-light');

  await review.tap(find.byKey(const ValueKey('pomodoro_mode_quick')));

  // Naming a session is optional but it is the only thing that tells two
  // entries apart in the history, so the field gets a capture of its own.
  await review.tap(find.byKey(const ValueKey('pomodoro_optional_context')));
  final activityField = find.byKey(const ValueKey('pomodoro_activity_field'));
  expect(activityField, findsOneWidget);
  await review.capture('03-focus-name-field-empty-light');
  await review.enterText(activityField, 'Estudiar Química');
  await review.capture('04-focus-named-session-light');

  await review.tap(find.byKey(const ValueKey('pomodoro_start_button')));
  expect(
    find.byKey(const ValueKey('focus_work_immersion')),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('focus_session_active')),
      matching: find.text('Estudiar Química'),
    ),
    findsOneWidget,
  );
  await review.capture('05-focus-active-light');

  await review.tap(find.byKey(const ValueKey('pomodoro_pause_resume')));
  expect(find.byKey(const ValueKey('focus_pause_gap')), findsOneWidget);
  await review.capture('06-focus-paused-light');

  await review.tap(find.byTooltip('Salir del enfoque'));
  expect(
    find.byKey(const ValueKey('focus_safe_exit_sheet')),
    findsOneWidget,
  );
  await review.capture('07-focus-safe-exit-light');
  await review.tap(find.text('Seguir aquí'));

  await controller.skip();
  await review.waitForUi();
  controller.selectSessionType(SessionType.shortBreak);
  await review.waitForUi();
  expect(
    find.byKey(const ValueKey('focus_rest_immersion')),
    findsOneWidget,
  );
  expect(find.text('Suelta los hombros'), findsOneWidget);
  await review.capture('08-focus-rest-light');

  controller.selectSessionType(SessionType.work);
  await review.show(
    dependencies.buildApp(
      home: const PomodoroScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(PomodoroScreen),
  );
  await review.capture('09-focus-portal-amoled');
  await review.tap(find.byKey(const ValueKey('pomodoro_start_button')));
  expect(
    find.byKey(const ValueKey('focus_work_immersion')),
    findsOneWidget,
  );
  await review.capture('10-focus-active-amoled');
  await controller.skip();
  await review.waitForUi();

  await review.show(
    dependencies.buildApp(
      home: FocusCompletionScene(
        activity: PomodoroActivity(
          id: 'screen-review-completion',
          name: 'Repasar Álgebra lineal',
          startTime: DateTime(2026, 8, 4, 12),
          endTime: DateTime(2026, 8, 4, 12, 25),
          cyclesCompleted: 1,
          totalMinutes: 25,
          isCompleted: true,
        ),
        onClose: () {},
      ),
    ),
    expected: find.byKey(const ValueKey('focus_completion_dialog')),
  );
  await review.capture('11-focus-completion-light');
}

Future<void> _reviewEntryScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await review.show(
    dependencies.buildApp(home: const SplashScreen()),
    expected: find.byType(SplashScreen),
  );
  expect(find.text('Una acción clara a la vez.'), findsOneWidget);
  await review.capture('00-splash-light');

  await review.show(
    dependencies.buildApp(
      home: const SplashScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(SplashScreen),
  );
  await review.capture('01-splash-amoled');

  await review.show(
    dependencies.buildApp(home: const AuthScreen()),
    expected: find.byType(AuthScreen),
  );
  expect(find.text('Elige cómo empezar.'), findsOneWidget);
  expect(
    find.textContaining('Google'),
    findsNothing,
  );
  expect(find.textContaining('Apple'), findsNothing);
  await review.capture('02-auth-light');

  await review.tap(
    find.byKey(const ValueKey('auth-backup-path')),
  );
  await review.tap(
    find.byKey(const ValueKey('auth-continue')),
  );
  expect(find.text('Restaura tu espacio.'), findsOneWidget);
  await review.capture('03-auth-backup');

  await review.show(
    dependencies.buildApp(
      home: const AuthScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(AuthScreen),
  );
  await review.capture('04-auth-amoled');

  await review.show(
    dependencies.buildApp(home: const SettingsScreen()),
    expected: find.byType(SettingsScreen),
  );
  final parkedCloudCard = find.byKey(
    const ValueKey('settings-cloud-paused'),
  );
  await review.tester.scrollUntilVisible(
    parkedCloudCard,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Cuenta y sincronización en la nube'), findsOneWidget);
  expect(find.text('Sincronización Supabase'), findsNothing);
  await review.capture('05-settings-cloud-parked-light');

  await review.show(
    dependencies.buildApp(
      home: const SettingsScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(SettingsScreen),
  );
  await review.tester.scrollUntilVisible(
    parkedCloudCard,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Cuenta y sincronización en la nube'), findsOneWidget);
  await review.capture('06-settings-cloud-parked-amoled');

  Widget failure({ThemeMode themeMode = ThemeMode.light}) =>
      dependencies.buildApp(
        home: SessionLoadFailureScreen(
          message: 'No pudimos preparar tu espacio. Tus datos siguen seguros.',
          onRetry: () {},
          onExit: () async {},
        ),
        themeMode: themeMode,
      );
  await review.show(
    failure(),
    expected: find.byType(SessionLoadFailureScreen),
  );
  expect(find.text('Reintentar'), findsOneWidget);
  expect(find.text('Volver al acceso'), findsOneWidget);
  await review.capture('07-session-load-failure-light');

  await review.show(
    failure(themeMode: ThemeMode.dark),
    expected: find.byType(SessionLoadFailureScreen),
  );
  await review.capture('08-session-load-failure-amoled');
}

Future<void> _reviewHabitsScope(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await dependencies.seedAuthenticatedData();
  await dependencies.habitRepository.saveHabit(
    Habit(
      id: 'review-new-movement',
      title: 'Caminar 20 minutos',
      category: Category.movimiento,
      frequency: Frequency.daily(),
      createdAt: DateTime.now(),
    ),
  );
  await dependencies.habitController.reload();
  await review.show(
    dependencies.buildApp(home: const HabitsListScreen()),
    expected: find.byType(HabitsListScreen),
  );
  await review.capture('00-habits-light');

  await review.tap(
    find.byKey(const ValueKey('habits-search-toggle')),
  );
  final search = find.byKey(const ValueKey('habits-search'));
  await review.tap(search);
  await review.tester.enterText(search, 'descanso');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Preparar descanso'), findsOneWidget);
  expect(find.text('Revisar metas del día'), findsNothing);
  await review.capture('01-habits-search');

  await review.tap(
    find.byKey(const ValueKey('habits-search-toggle')),
  );
  await review.tap(
    find.byKey(const ValueKey('habits-category-agua')),
  );
  expect(find.text('Tomar agua'), findsOneWidget);
  expect(find.text('EN PAUSA'), findsOneWidget);
  await review.capture('02-habits-paused');

  await review.show(
    dependencies.buildApp(
      home: const HabitsListScreen(),
      themeMode: ThemeMode.dark,
    ),
    expected: find.byType(HabitsListScreen),
  );
  await review.capture('03-habits-amoled');
}

Future<void> _reviewEntryJourney(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await review.show(
    dependencies.buildApp(home: const SplashScreen()),
    expected: find.byType(SplashScreen),
  );
  expect(find.text('Una acción clara a la vez.'), findsOneWidget);
  await review.capture('00-splash');

  await review.show(
    dependencies.buildApp(home: const AuthScreen()),
    expected: find.byType(AuthScreen),
  );
  expect(find.text('Elige cómo empezar.'), findsOneWidget);
  await review.capture('00-auth-local-first');

  await review.tap(
    find.byKey(const ValueKey('auth-backup-path')),
  );
  await review.tap(
    find.byKey(const ValueKey('auth-continue')),
  );
  expect(find.text('Restaura tu espacio.'), findsOneWidget);
  await review.capture('01-auth-backup');

  await review.show(
    dependencies.buildApp(
      home: OnboardingScreen(
        key: const ValueKey('review-onboarding-first-run'),
        userId: _ReviewHarness.ownerId,
        notificationGateway: _ReviewNotificationGateway(),
        onComplete: () {},
      ),
    ),
    expected: find.byType(OnboardingScreen),
  );
  expect(find.text('Hazlo tuyo'), findsNothing);
  expect(find.text('Tu primer hábito'), findsOneWidget);
  await review.capture('02-onboarding-first-habit');

  final habitName = find.byKey(const ValueKey('onboarding-habit-name'));
  await review.tap(habitName);
  await review.tester.enterText(habitName, 'Leer diez páginas');
  await review.waitForUi(const Duration(milliseconds: 300));
  await review.capture('03-onboarding-first-habit-keyboard');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));
}

Future<void> _reviewAuthenticatedJourney(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  await dependencies.seedAuthenticatedData();
  await review.show(
    dependencies.buildApp(home: const TodayScreen()),
    expected: find.byType(TodayScreen),
  );
  expect(find.text('Revisar metas del día'), findsOneWidget);
  expect(find.text('Preparar descanso'), findsWidgets);
  await review.capture('09-today-overview');

  await review.tap(find.byKey(const ValueKey('today-add-habit')));
  expect(find.byType(HabitFormScreen), findsOneWidget);
  await review.capture('10-habit-form');

  final habitTitle = find.byKey(const ValueKey('habit-title-field'));
  await review.tap(habitTitle);
  await review.tester.enterText(
    habitTitle,
    'Caminar 20 minutos',
  );
  await review.waitForUi(const Duration(milliseconds: 300));
  await review.capture('10-habit-form-keyboard');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));

  await review.tap(
    find.byKey(const ValueKey('habit-category-movimiento')),
  );
  await review.tap(
    find.byKey(const ValueKey('habit-frequency-weekdays')),
  );
  expect(find.byKey(const ValueKey('habit-preview')), findsNothing);
  expect(
    find.byKey(const ValueKey('habit-frequency-presets')),
    findsOneWidget,
  );
  await review.waitForUi(const Duration(milliseconds: 300));
  await review.capture('10-habit-form-schedule');

  // Keep the result deterministic on weekends while still exercising the
  // weekday preset in the form.
  await review.tap(find.byKey(const ValueKey('habit-frequency-all')));
  final createHabit = find.byKey(const ValueKey('habit-submit'));
  await review.tap(createHabit, settleFor: const Duration(seconds: 2));
  expect(find.byType(TodayScreen), findsOneWidget);
  expect(find.text('Caminar 20 minutos'), findsOneWidget);
  await review.capture('11-today-after-create');

  await review.tap(find.text('Revisar metas del día'));
  await dependencies.syncProgress();
  await review.waitForUi();
  await review.capture('12-today-after-complete');

  await review.tap(
    find.byKey(const ValueKey('today-destination-label-Hábitos')),
  );
  expect(find.byType(HabitsListScreen), findsOneWidget);
  await review.capture('13-habits');

  await review.tap(
    find.byKey(const ValueKey('habits-search-toggle')),
  );
  final habitsSearch = find.byKey(const ValueKey('habits-search'));
  await review.tap(habitsSearch);
  await review.tester.enterText(habitsSearch, 'descanso');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Preparar descanso'), findsOneWidget);
  expect(find.text('Caminar 20 minutos'), findsNothing);
  await review.capture('13-habits-search');

  await review.tap(
    find.byKey(const ValueKey('habits-search-toggle')),
  );
  expect(find.text('Tomar agua'), findsWidgets);
  await review.capture('13-habits-paused');
  await review.backTo<TodayScreen>();

  await review.tap(find.byKey(const ValueKey('today-notes-action')));
  expect(find.byType(NotesScreen), findsOneWidget);
  expect(find.text('Repasar Álgebra lineal'), findsWidgets);
  await review.capture('14-notes-library');

  final notesSearch = find.byKey(const ValueKey('notes-search'));
  await review.tap(notesSearch);
  await review.tester.enterText(notesSearch, 'algebra');
  FocusManager.instance.primaryFocus?.unfocus();
  await review.waitForUi(const Duration(milliseconds: 300));
  expect(find.text('Repasar Álgebra lineal'), findsWidgets);
  expect(find.text('Ideas para Zentra'), findsNothing);
  await review.capture('14-notes-search');

  await review.tap(find.byTooltip('Limpiar búsqueda'));
  await review.tap(
    find.byKey(const ValueKey('note-card-review-note-algebra')),
  );
  if (find.byType(NoteSurface).evaluate().isEmpty) {
    await review.tap(find.byTooltip('Editar nota'));
  }
  expect(find.byType(NoteSurface), findsOneWidget);
  expect(find.byKey(const ValueKey('note-format-bar')), findsNothing);
  await review.capture('14-note-surface-reading');

  await review.tap(find.byKey(const ValueKey('note-block-0')));
  expect(find.byKey(const ValueKey('note-active-block')), findsOneWidget);
  expect(find.byKey(const ValueKey('note-format-bar')), findsOneWidget);
  await review.capture('14-note-surface-writing');
  await review.tap(find.byKey(const ValueKey('note-done')));

  await review.tap(find.byKey(const ValueKey('note-reminder-action')));
  expect(find.byType(NoteReminderScreen), findsOneWidget);
  await review.capture('14-note-reminder');
  await review.backTo<NoteSurface>();
  await review.backTo<NotesScreen>();
  await review.backTo<TodayScreen>();

  await review.tap(find.byKey(const ValueKey('today-focus-action')));
  expect(find.byType(PomodoroScreen), findsOneWidget);
  await review.capture('14-focus');
  await review.tap(
    find.byKey(const ValueKey('pomodoro_custom_duration_button')),
  );
  expect(
    find.byKey(const ValueKey('pomodoro_duration_dial')),
    findsOneWidget,
  );
  await review.capture('14-focus-duration-dial');
  await review.tap(find.byKey(const ValueKey('pomodoro_duration_apply')));
  await review.tap(
    find.byKey(const ValueKey('pomodoro_mode_cycle')),
  );
  await review.scrollToTop();
  expect(find.textContaining('4 enfoques · descansos'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('pomodoro_activity_field')),
    findsNothing,
  );
  await review.capture('14-focus-cycle');

  await review.tap(
    find.byKey(const ValueKey('pomodoro_mode_quick')),
  );
  await review.tap(
    find.byKey(const ValueKey('pomodoro_start_button')),
  );
  expect(
    find.byKey(const ValueKey('focus_session_active')),
    findsOneWidget,
  );
  expect(find.text('ENFOQUE'), findsOneWidget);
  await review.capture('14-focus-active');

  await review.tap(
    find.byKey(const ValueKey('pomodoro_pause_resume')),
  );
  expect(find.text('Continuar'), findsOneWidget);
  await review.capture('14-focus-paused');

  await review.tap(find.byTooltip('Historial'));
  expect(find.byType(PomodoroHistoryScreen), findsOneWidget);
  await review.capture('14-focus-history');
  await review.backTo<PomodoroScreen>();

  await review.tap(
    find.byKey(const ValueKey('pomodoro_cancel_activity')),
  );
  expect(find.text('¿Terminar este enfoque?'), findsOneWidget);
  await review.capture('14-focus-cancel-confirm');
  await review.tap(
    find.byKey(const ValueKey('pomodoro_cancel_confirm')),
  );
  await review.waitForUi();
  expect(
    find.byKey(const ValueKey('pomodoro_launcher')),
    findsOneWidget,
  );
  await review.backTo<TodayScreen>();

  await review.tap(find.text('Progreso'));
  expect(find.byType(ProgressScreen), findsOneWidget);
  await review.capture('15-progress');
  await review.tap(
    find.byKey(const ValueKey('progress-achievement-collection')),
  );
  expect(
    find.byKey(const ValueKey('achievement-collection')),
    findsOneWidget,
  );
  await review.capture('15-achievement-collection');
  await review.backTo<ProgressScreen>();
  await review.tap(find.byTooltip('Tu actividad'));
  expect(find.byType(HistoryScreen), findsOneWidget);
  await review.capture('15-activity-history');
  await review.tester.ensureVisible(
    find.byKey(const ValueKey('activity-history-archive')),
  );
  await review.waitForUi(const Duration(milliseconds: 300));
  await review.capture('15-activity-history-archive');
  await review.backTo<ProgressScreen>();
  await review.backTo<TodayScreen>();

  await review.tap(find.byKey(const ValueKey('today-calendar-action')));
  expect(find.byType(CalendarScreen), findsOneWidget);
  await review.capture('16-calendar');
  await review.backTo<TodayScreen>();

  await review.tap(find.byKey(const ValueKey('today-profile-action')));
  expect(find.byType(ProfileScreen), findsOneWidget);
  await review.capture('17-profile');

  await review.tap(find.byTooltip('Configuración'));
  expect(find.byType(SettingsScreen), findsOneWidget);
  await review.capture('18-settings');

  final about = find.text('Sobre la app');
  await review.tester.scrollUntilVisible(
    about,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await review.tap(about);
  expect(find.byType(AboutScreen), findsOneWidget);
  await review.capture('19-about');
}

Future<void> _reviewDarkIdentity(
  _ScreenReviewSession review,
  _ReviewHarness dependencies,
) async {
  Widget dark(Widget home) => dependencies.buildApp(
        home: home,
        themeMode: ThemeMode.dark,
      );

  await review.show(
    dark(const TodayScreen()),
    expected: find.byType(TodayScreen),
  );
  await review.capture('20-dark-today');

  await review.show(
    dark(const NotesScreen()),
    expected: find.byType(NotesScreen),
  );
  await review.capture('21-dark-notes');

  await review.show(
    dark(const PomodoroScreen()),
    expected: find.byType(PomodoroScreen),
  );
  await review.capture('22-dark-focus');
  await review.tap(find.byKey(const ValueKey('pomodoro_start_button')));
  expect(
    find.byKey(const ValueKey('focus_session_active')),
    findsOneWidget,
  );
  await review.capture('23-dark-focus-active');
  await dependencies.pomodoroController.cancelActivity();

  await review.show(
    dark(const ProgressScreen()),
    expected: find.byType(ProgressScreen),
  );
  await review.capture('24-dark-progress');

  await review.show(
    dark(const CalendarScreen()),
    expected: find.byType(CalendarScreen),
  );
  await review.capture('25-dark-calendar');

  await review.show(
    dark(const ProfileScreen()),
    expected: find.byType(ProfileScreen),
  );
  await review.capture('26-dark-profile');

  await review.show(
    dark(const SettingsScreen()),
    expected: find.byType(SettingsScreen),
  );
  await review.capture('27-dark-settings');

  await review.show(
    dark(const AboutScreen()),
    expected: find.byType(AboutScreen),
  );
  await review.capture('28-dark-about');
}

class _ScreenReviewSession {
  final IntegrationTestWidgetsFlutterBinding binding;
  final WidgetTester tester;
  final String deviceName;

  const _ScreenReviewSession({
    required this.binding,
    required this.tester,
    required this.deviceName,
  });

  Future<void> show(
    Widget app, {
    required Finder expected,
  }) async {
    await tester.pumpWidget(app);
    await waitForUi();
    expect(expected, findsOneWidget);
    _expectHealthyLayout();
  }

  Future<void> tap(
    Finder finder, {
    Duration settleFor = const Duration(milliseconds: 900),
  }) async {
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await waitForUi(settleFor);
  }

  Future<void> enterText(Finder finder, String value) async {
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.enterText(finder, value);
    await waitForUi();
  }

  Future<void> backTo<T extends Widget>() async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await waitForUi();
    expect(find.byType(T), findsOneWidget);
  }

  Future<void> scrollToTop() async {
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(0);
    await waitForUi(const Duration(milliseconds: 300));
  }

  Future<void> waitForUi([
    Duration duration = const Duration(milliseconds: 900),
  ]) async {
    await tester.pump();
    const frameDuration = Duration(milliseconds: 50);
    var elapsed = Duration.zero;
    while (elapsed < duration) {
      final remaining = duration - elapsed;
      final step = remaining < frameDuration ? remaining : frameDuration;
      await tester.pump(step);
      elapsed += step;
    }
    _expectHealthyLayout();
  }

  Future<void> capture(String name) async {
    await waitForUi(const Duration(milliseconds: 300));
    final bytes = await binding.takeScreenshot('$deviceName-$name');
    expect(bytes, isNotEmpty);
  }

  void _expectHealthyLayout() {
    expect(
      tester.takeException(),
      isNull,
      reason: 'Flutter reported a layout or rendering exception.',
    );
  }
}

/// Body of the note the review opens.
///
/// It carries one of every block the surface has to render, so a capture shows
/// whether headings, emphasis, checklists and quotes survive the round trip
/// instead of only proving that a paragraph fits on screen.
const String _algebraBody = '# Repaso de la semana\n'
    '\n'
    'Transformaciones, matrices y espacios **vectoriales**.\n'
    '\n'
    '- [x] Releer el capítulo 3\n'
    '- [ ] Resolver los ejercicios impares\n'
    '- [ ] Preparar el resumen de valores propios\n'
    '\n'
    '> Una base ordena el espacio; la matriz sólo lo describe.';

/// Index of the two checklist blocks that start unticked in [_algebraBody].
const List<int> _pendingCheckBlocks = [5, 6];

class _ReviewHarness {
  static const ownerId = 'screen-reviewer';

  final SharedPreferences preferences;
  final HabitRepository habitRepository;
  final CompletedTaskRepository completedTaskRepository;
  final ProfileRepository profileRepository;
  final ZentraDatabase noteDatabase;
  final DriftNoteRepository noteRepository;
  final riverpod.ProviderContainer container;

  const _ReviewHarness._({
    required this.preferences,
    required this.habitRepository,
    required this.completedTaskRepository,
    required this.profileRepository,
    required this.noteDatabase,
    required this.noteRepository,
    required this.container,
  });

  static Future<_ReviewHarness> create(
    SharedPreferences preferences,
  ) async {
    final noteDatabase = ZentraDatabase(NativeDatabase.memory());
    final persistenceRuntime = LocalPersistenceRuntime(
      preferences: preferences,
      database: noteDatabase,
      cloudSyncAllowed: false,
    );
    await persistenceRuntime.initialize();
    final habitRepository = persistenceRuntime.habitRepositoryFor(ownerId);
    final completedTaskRepository =
        persistenceRuntime.completedTaskRepositoryFor(ownerId);
    final profileRepository = persistenceRuntime.profileRepositoryFor(ownerId);
    final noteRepository = DriftNoteRepository.forOwner(
      noteDatabase,
      ownerId: ownerId,
    );
    final container = riverpod.ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
        cloudRuntimeEnabledProvider.overrideWithValue(false),
        accountRepositoryProvider.overrideWithValue(
          persistenceRuntime.accountRepository,
        ),
        coreOwnerStoreProvider.overrideWithValue(persistenceRuntime),
        accountLocalDataCleanupProvider.overrideWithValue(
          persistenceRuntime.deleteOwner,
        ),
        habitRepositoryFactoryProvider.overrideWithValue(
          persistenceRuntime.habitRepositoryFor,
        ),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          persistenceRuntime.completedTaskRepositoryFor,
        ),
        profileRepositoryFactoryProvider.overrideWithValue(
          persistenceRuntime.profileRepositoryFor,
        ),
        noteRepositoryFactoryProvider.overrideWithValue(
          (requestedOwner) => DriftNoteRepository.forOwner(
            noteDatabase,
            ownerId: requestedOwner,
          ),
        ),
        sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
        habitReminderServiceProvider.overrideWithValue(
          const _ReviewHabitReminderService(),
        ),
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required String ownerId,
            required VoidCallback onChanged,
          }) {
            return PomodoroEngine(
              initialUserId: ownerId,
              focusRepository: persistenceRuntime.focusRepositoryFor(ownerId),
              onChanged: onChanged,
            );
          },
        ),
        initialThemeModeProvider.overrideWithValue(AppThemeMode.light),
      ],
    );
    final harness = _ReviewHarness._(
      preferences: preferences,
      habitRepository: habitRepository,
      completedTaskRepository: completedTaskRepository,
      profileRepository: profileRepository,
      noteDatabase: noteDatabase,
      noteRepository: noteRepository,
      container: container,
    );
    await harness.initialize();
    return harness;
  }

  HabitController get habitController =>
      container.read(habitControllerProvider(ownerId).notifier);

  ProfileController get profileController =>
      container.read(profileControllerProvider(ownerId).notifier);

  PomodoroController get pomodoroController =>
      container.read(pomodoroControllerProvider(ownerId).notifier);

  NoteController get noteController =>
      container.read(noteControllerProvider(ownerId).notifier);

  Future<void> initialize() async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      profileControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      noteControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(ownerId).future),
      container.read(profileControllerProvider(ownerId).future),
      container.read(noteControllerProvider(ownerId).future),
    ]);
    container.read(pomodoroControllerProvider(ownerId));
    await pomodoroController.initialize();
  }

  Future<void> seedAuthenticatedData() async {
    final now = DateTime.now();
    await completedTaskRepository.replaceCompletedTasks(
      [
        CompletedTask(
          id: 'review-finished-task',
          title: 'Preparar lectura de ayer',
          category: Category.foco,
          completedAt: now.subtract(const Duration(hours: 18)),
          wasOneTime: true,
        ),
      ],
    );
    await habitRepository.saveHabit(
      Habit(
        id: 'review-goals',
        title: 'Revisar metas del día',
        category: Category.foco,
        frequency: Frequency.daily(),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    );
    await habitRepository.saveHabit(
      Habit(
        id: 'review-sleep',
        title: 'Preparar descanso',
        category: Category.sueno,
        frequency: Frequency.daily(),
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    );
    await habitRepository.saveHabit(
      Habit(
        id: 'review-water-archived',
        title: 'Tomar agua',
        category: Category.agua,
        frequency: Frequency.daily(),
        createdAt: now.subtract(const Duration(days: 20)),
        isArchived: true,
      ),
    );
    for (var daysAgo = 1; daysAgo <= 14; daysAgo++) {
      final date = now.subtract(Duration(days: daysAgo));
      await habitRepository.toggleLog('review-goals', date);
      await habitRepository.toggleLog('review-sleep', date);
      if (daysAgo <= 8) {
        await habitRepository.toggleLog('review-water-archived', date);
      }
    }
    await habitRepository.toggleLog('review-sleep', now);

    final algebra = Note(
      id: 'review-note-algebra',
      userId: ownerId,
      title: 'Repasar Álgebra lineal',
      body: _algebraBody,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      category: 'Estudio',
      accentKey: 'focus',
      isPinned: true,
      tags: const ['examen', 'estudio'],
    );
    await noteRepository.upsertNote(algebra);
    await noteRepository.upsertReminder(
      NoteReminder(
        id: 'review-reminder-algebra',
        noteId: algebra.id,
        userId: algebra.userId,
        scheduledAtUtc: now.toUtc().subtract(const Duration(hours: 1)),
        timezoneName: 'America/Mexico_City',
        status: NoteReminderStatus.scheduled,
        notificationId: 2000000001,
        privacyMode: NotePrivacyMode.titleOnly,
        createdAt: now.toUtc().subtract(const Duration(days: 1)),
        updatedAt: now.toUtc().subtract(const Duration(hours: 1)),
      ),
    );
    await noteRepository.upsertNote(
      Note(
        id: 'review-note-ideas',
        userId: 'screen-reviewer',
        title: 'Ideas para Zentra',
        body: 'Un espacio cálido, sobrio y útil.',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
        category: 'Producto',
        accentKey: 'peach',
        tags: const ['producto'],
      ),
    );
    await noteRepository.upsertNote(
      Note(
        id: 'review-note-archive',
        userId: 'screen-reviewer',
        title: 'Lecturas terminadas',
        body: 'Notas que ya cumplieron su propósito.',
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 7)),
        accentKey: 'water',
        isArchived: true,
        archivedAt: now.subtract(const Duration(days: 7)),
      ),
    );
    final profile = UserProfile(
      id: ownerId,
      name: 'Uri',
      avatarEmoji: '🐉',
      createdAt: now.subtract(const Duration(days: 30)),
      totalHabitsCompleted: 1,
      totalDaysActive: 1,
      longestStreak: 1,
      unlockedAchievements: const ['first_habit'],
    );
    await profileRepository.saveProfile(profile);

    await Future.wait([
      habitController.reload(),
      noteController.reload(),
      profileController.reload(),
    ]);
    await syncProgress();
  }

  Future<void> syncProgress() async {
    final habitState =
        container.read(habitControllerProvider(ownerId)).valueOrNull;
    if (habitState == null) {
      throw StateError('Habit workspace is not ready.');
    }
    final pomodoroState = container.read(
      pomodoroControllerProvider(ownerId),
    );
    await profileController.syncProgress(
      announceUnlocks: false,
      snapshot: buildProgressSnapshotFromState(
        habitState: habitState,
        activityHistory: pomodoroState.activityHistory,
        totalPomodoros: pomodoroState.totalPomodoros,
        totalFocusMinutes: pomodoroState.totalMinutes,
        now: DateTime.now(),
      ),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await noteDatabase.close();
  }

  Widget buildApp({
    required Widget home,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final appThemeMode = switch (themeMode) {
      ThemeMode.system => AppThemeMode.system,
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
    };
    unawaited(
      container
          .read(themeControllerProvider.notifier)
          .setThemeMode(appThemeMode),
    );

    return riverpod.UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        key: ValueKey(
          'screen-review-${home.runtimeType}-${themeMode.name}',
        ),
        title: 'Zentra Screen Reviewer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home,
      ),
    );
  }
}
