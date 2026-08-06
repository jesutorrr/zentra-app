import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/completed_task_repository.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/presentation/design_tokens.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _MemoryHabitRepository implements HabitRepository {
  _MemoryHabitRepository({
    List<Habit> habits = const [],
    this.saveBarrier,
    this.throwOnSave = false,
  }) : _habits = List<Habit>.from(habits);

  List<Habit> _habits;
  final List<HabitLog> _logs = [];
  final Completer<void>? saveBarrier;
  final bool throwOnSave;
  int saveCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);

  @override
  void setCurrentUser(String? userId) {}

  @override
  Future<List<Habit>> getHabits() async => List<Habit>.from(_habits);

  @override
  Future<void> saveHabit(Habit habit) async {
    saveCalls += 1;
    if (throwOnSave) {
      throw StateError('save failed');
    }
    if (saveBarrier != null) {
      await saveBarrier!.future;
    }
    _habits = [..._habits, habit];
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    updateCalls += 1;
    _habits = [
      for (final current in _habits)
        if (current.id == habit.id) habit else current,
    ];
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    deleteCalls += 1;
    _habits = _habits.where((habit) => habit.id != habitId).toList();
    _logs.removeWhere((log) => log.habitId == habitId);
  }

  @override
  Future<List<HabitLog>> getAllLogs() async => List<HabitLog>.from(_logs);

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    return _logs.where((log) => log.matches(log.habitId, date)).toList();
  }

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final index = _logs.indexWhere((log) => log.matches(habitId, date));
    if (index >= 0) {
      _logs.removeAt(index);
      return;
    }
    _logs.add(
      HabitLog(
        habitId: habitId,
        date: HabitLog.normalizeDate(date),
      ),
    );
  }
}

class _ScheduledReminder {
  final String habitId;
  final String habitTitle;
  final int hour;
  final int minute;
  final List<int> daysOfWeek;
  final bool isOneTime;
  final DateTime? scheduledDate;

  const _ScheduledReminder({
    required this.habitId,
    required this.habitTitle,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    required this.isOneTime,
    this.scheduledDate,
  });
}

class _FakeHabitReminderService implements HabitReminderService {
  final List<_ScheduledReminder> scheduled = [];
  final List<String> cancelled = [];
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
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
    scheduled.add(
      _ScheduledReminder(
        habitId: habitId,
        habitTitle: habitTitle,
        hour: hour,
        minute: minute,
        daysOfWeek: List<int>.from(daysOfWeek),
        isOneTime: isOneTime,
        scheduledDate: scheduledDate,
      ),
    );
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    cancelled.add(habitId);
  }
}

class _FakeHabitFormNotificationGateway
    implements HabitFormNotificationGateway {
  _FakeHabitFormNotificationGateway({
    this.permissionGranted = false,
    this.requestResult = false,
  });

  bool permissionGranted;
  final bool requestResult;
  int permissionRequests = 0;
  int preferenceWrites = 0;
  bool? remindersEnabled;

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    permissionGranted = requestResult;
    return requestResult;
  }

  @override
  Future<void> setHabitRemindersEnabled(bool enabled) async {
    preferenceWrites += 1;
    remindersEnabled = enabled;
  }
}

class _Harness {
  final _MemoryHabitRepository repository;
  final _TestHabitWorkspace provider;
  final _FakeHabitReminderService reminders;
  final _FakeHabitFormNotificationGateway notifications;

  const _Harness({
    required this.repository,
    required this.provider,
    required this.reminders,
    required this.notifications,
  });
}

class _MemoryCompletedTaskRepository implements CompletedTaskRepository {
  @override
  final String ownerId;
  List<CompletedTask> tasks = [];

  _MemoryCompletedTaskRepository(this.ownerId);

  @override
  Future<List<CompletedTask>> loadCompletedTasks() async => [...tasks];

  @override
  Future<void> replaceCompletedTasks(List<CompletedTask> tasks) async {
    this.tasks = [...tasks];
  }
}

class _TestHabitWorkspace {
  static const ownerId = 'habit-form-owner';

  final ProviderContainer container;

  _TestHabitWorkspace(
    HabitRepository repository, {
    required HabitReminderService reminderService,
  }) : container = ProviderContainer(
          overrides: [
            activeOwnerIdProvider.overrideWithValue(ownerId),
            habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
              expect(requestedOwner, ownerId);
              return repository;
            }),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return _MemoryCompletedTaskRepository(ownerId);
              },
            ),
            habitReminderServiceProvider.overrideWithValue(reminderService),
          ],
        );

  Future<void> initialize() async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await container.read(habitControllerProvider(ownerId).future);
  }

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<_Harness> pumpForm(
    WidgetTester tester, {
    List<Habit> habits = const [],
    String? habitId,
    _MemoryHabitRepository? repository,
    _FakeHabitReminderService? reminderService,
    _FakeHabitFormNotificationGateway? notificationGateway,
    Size size = const Size(390, 844),
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    bool reduceMotion = false,
    DateTime Function()? now,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final memoryRepository =
        repository ?? _MemoryHabitRepository(habits: habits);
    final reminders = reminderService ?? _FakeHabitReminderService();
    final notifications =
        notificationGateway ?? _FakeHabitFormNotificationGateway();
    final provider = _TestHabitWorkspace(
      memoryRepository,
      reminderService: reminders,
    );
    addTearDown(provider.dispose);
    await provider.initialize();

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: provider.container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reduceMotion,
                accessibleNavigation: reduceMotion,
              ),
              child: child!,
            );
          },
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        allowSnapshotting: false,
        builder: (_) => HabitFormScreen(
          habitId: habitId,
          notificationGateway: notifications,
          now: now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return _Harness(
      repository: memoryRepository,
      provider: provider,
      reminders: reminders,
      notifications: notifications,
    );
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    if (rect.top < 0 || rect.bottom > viewportHeight) {
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('habit-form-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        finder,
        120,
        scrollable: scrollable.first,
      );
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String key) {
    return tester
            .getSemantics(find.byKey(ValueKey(key)))
            .getSemanticsData()
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;
  }

  bool isToggled(WidgetTester tester, String key) {
    return tester
            .getSemantics(find.byKey(ValueKey(key)))
            .getSemanticsData()
            .flagsCollection
            .isToggled ==
        Tristate.isTrue;
  }

  AnimatedContainer headerContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('habit-form-header')),
        matching: find.byKey(const ValueKey('zentra-mode-band')),
      ),
    );
  }

  Color headerColor(WidgetTester tester) {
    final header = headerContainer(tester);
    return (header.decoration! as BoxDecoration).color!;
  }

  /// The colour actually painted for a glyph run, inherited styles included.
  /// Reading `Text.style?.color` instead would report `null` for anything that
  /// takes its colour from the theme — and a null read looks like a pass.
  Color paintedColor(WidgetTester tester, Finder finder) {
    return tester.renderObject<RenderParagraph>(finder).text.style!.color!;
  }

  /// The mode pill's fill flattened against the band behind it, for the same
  /// reason as [categoryFillColor]: the pill may paint a translucent colour, and
  /// what the eye reads is the composite.
  Color modeOptionFill(WidgetTester tester, String key) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final fill = (container.decoration! as BoxDecoration).color!;
    return Color.alphaBlend(fill, headerColor(tester));
  }

  BoxDecoration categoryDecoration(WidgetTester tester, Category category) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(ValueKey('habit-category-${category.name}')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  Color categoryRingColor(WidgetTester tester, Category category) {
    return categoryDecoration(tester, category).border!.bottom.color;
  }

  /// The selected fill flattened against the page it sits on: the cell paints a
  /// translucent tint, so the icon is really read against this composite, not
  /// against the tint's own nominal colour.
  Color categoryFillColor(WidgetTester tester, Category category) {
    final fill = categoryDecoration(tester, category).color!;
    final backdrop = Theme.of(
      tester.element(find.byKey(const ValueKey('habit-form-screen'))),
    ).colorScheme.surface;
    return Color.alphaBlend(fill, backdrop);
  }

  Future<void> enterTitle(WidgetTester tester, String value) async {
    final field = find.byKey(const ValueKey('habit-title-field'));
    await tester.enterText(field, value);
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('creates a trimmed habit with category and all days',
      (tester) async {
    final harness = await pumpForm(tester);

    await enterTitle(tester, '  Caminar 20 minutos  ');
    await tapKey(tester, 'habit-category-movimiento');
    await tapKey(tester, 'habit-frequency-all');
    await tapKey(tester, 'habit-submit');

    expect(find.byKey(const ValueKey('habit-form-screen')), findsNothing);
    expect(harness.repository.habits, hasLength(1));
    final habit = harness.repository.habits.single;
    expect(habit.title, 'Caminar 20 minutos');
    expect(habit.category, Category.movimiento);
    expect(habit.frequency.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(habit.hasReminder, isFalse);
    expect(harness.reminders.scheduled, isEmpty);
  });

  testWidgets('the seven weekdays fit on a phone without sideways scrolling',
      (tester) async {
    // Sunday used to sit off the right edge: the row only laid out as a plain
    // Row when each cell reached 42dp, and below that it fell back to a
    // horizontal scroller with no affordance, so the last day simply looked
    // cut off. Every phone width has to show all seven at once.
    for (final width in <double>[430, 393, 375, 360, 320]) {
      await pumpForm(tester, size: Size(width, 844));
      await enterTitle(tester, 'Practicar guitarra');
      await tapKey(tester, 'habit-frequency-custom');

      final row = find.byKey(const ValueKey('habit-custom-days'));
      expect(row, findsOneWidget, reason: 'ancho $width');
      expect(
        find.descendant(of: row, matching: find.byType(SingleChildScrollView)),
        findsNothing,
        reason: 'A $width dp la fila de días cayó al scroll horizontal.',
      );

      final rowRect = tester.getRect(row);
      for (var day = 1; day <= DateTime.daysPerWeek; day++) {
        final cell = tester.getRect(find.byKey(ValueKey('habit-day-$day')));
        expect(
          cell.right,
          lessThanOrEqualTo(rowRect.right + 0.5),
          reason: 'A $width dp el día $day se sale por la derecha.',
        );
        expect(
          cell.width,
          greaterThanOrEqualTo(30),
          reason: 'A $width dp el día $day quedó demasiado angosto.',
        );
      }
      expect(tester.takeException(), isNull, reason: 'ancho $width');
    }
  });

  testWidgets(
      'custom frequency validates empty days and persists selected days',
      (tester) async {
    final harness = await pumpForm(tester);
    final semantics = tester.ensureSemantics();

    await enterTitle(tester, 'Practicar guitarra');
    await tapKey(tester, 'habit-frequency-custom');
    expect(
      find.byKey(const ValueKey('habit-custom-days')),
      findsOneWidget,
    );

    for (var day = 1; day <= DateTime.daysPerWeek; day++) {
      final key = 'habit-day-$day';
      if (isSelected(tester, key)) {
        await tapKey(tester, key);
      }
    }

    await tapKey(tester, 'habit-submit');
    expect(
      find.text('Selecciona al menos un día'),
      findsOneWidget,
    );
    expect(harness.repository.habits, isEmpty);

    for (final day in const [1, 3, 5]) {
      await tapKey(tester, 'habit-day-$day');
    }
    await tapKey(tester, 'habit-submit');

    expect(harness.repository.habits.single.frequency.daysOfWeek, [1, 3, 5]);
    semantics.dispose();
  });

  testWidgets('denied notification permission keeps reminder disabled',
      (tester) async {
    final gateway = _FakeHabitFormNotificationGateway(requestResult: false);
    final harness = await pumpForm(
      tester,
      notificationGateway: gateway,
    );
    final semantics = tester.ensureSemantics();

    await tapKey(tester, 'habit-reminder-toggle');

    expect(harness.notifications.permissionRequests, 1);
    expect(harness.notifications.preferenceWrites, 0);
    expect(isToggled(tester, 'habit-reminder-toggle'), isFalse);
    expect(
      find.byKey(const ValueKey('habit-reminder-time')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('granted permission persists and schedules a reminder',
      (tester) async {
    final gateway = _FakeHabitFormNotificationGateway(requestResult: true);
    final harness = await pumpForm(
      tester,
      notificationGateway: gateway,
    );

    await enterTitle(tester, 'Tomar agua');
    await tapKey(tester, 'habit-category-agua');
    await tapKey(tester, 'habit-reminder-toggle');
    expect(
      find.byKey(const ValueKey('habit-reminder-time')),
      findsOneWidget,
    );
    await tapKey(tester, 'habit-submit');

    expect(harness.notifications.permissionRequests, 1);
    expect(harness.notifications.preferenceWrites, 1);
    expect(harness.notifications.remindersEnabled, isTrue);
    expect(harness.repository.habits.single.hasReminder, isTrue);
    expect(harness.repository.habits.single.reminderHour, 9);
    expect(harness.repository.habits.single.reminderMinute, 0);
    expect(harness.reminders.scheduled, hasLength(1));
    expect(harness.reminders.scheduled.single.habitTitle, 'Tomar agua');
    expect(harness.reminders.scheduled.single.hour, 9);
    expect(harness.reminders.scheduled.single.minute, 0);
    expect(
      harness.reminders.scheduled.single.daysOfWeek,
      [1, 2, 3, 4, 5, 6, 7],
    );
    expect(harness.reminders.scheduled.single.isOneTime, isFalse);
  });

  testWidgets('edit hydrates data, preserves identity and disables reminder',
      (tester) async {
    final createdAt = DateTime(2024, 2, 3, 12);
    final original = Habit(
      id: 'habit-focus',
      title: 'Leer veinte páginas',
      category: Category.foco,
      frequency: Frequency.weekdays(),
      createdAt: createdAt,
      hasReminder: true,
      reminderHour: 20,
      reminderMinute: 30,
    );
    final gateway = _FakeHabitFormNotificationGateway(
      permissionGranted: true,
    );
    final harness = await pumpForm(
      tester,
      habits: [original],
      habitId: original.id,
      notificationGateway: gateway,
    );
    final semantics = tester.ensureSemantics();

    final titleField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('habit-title-field')),
    );
    expect(titleField.controller!.text, original.title);
    expect(isSelected(tester, 'habit-category-foco'), isTrue);
    expect(
      find.byKey(const ValueKey('habit-reminder-time')),
      findsOneWidget,
    );

    await tapKey(tester, 'habit-reminder-toggle');
    expect(isToggled(tester, 'habit-reminder-toggle'), isFalse);
    await enterTitle(tester, 'Leer treinta páginas');
    await tapKey(tester, 'habit-submit');

    expect(harness.repository.updateCalls, 1);
    expect(harness.repository.habits, hasLength(1));
    final updated = harness.repository.habits.single;
    expect(updated.id, original.id);
    expect(updated.createdAt, createdAt);
    expect(updated.title, 'Leer treinta páginas');
    expect(updated.category, Category.foco);
    expect(updated.hasReminder, isFalse);
    expect(updated.reminderHour, isNull);
    expect(updated.reminderMinute, isNull);
    expect(harness.reminders.cancelled, contains(original.id));
    semantics.dispose();
  });

  testWidgets('edit menu cancels and then confirms deletion exactly once',
      (tester) async {
    final original = Habit(
      id: 'habit-delete',
      title: 'Eliminar con cuidado',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime(2026, 8, 1),
    );
    final harness = await pumpForm(
      tester,
      habits: [original],
      habitId: original.id,
    );

    await tapKey(tester, 'habit-more-menu');
    await tapKey(tester, 'habit-delete');
    expect(find.text('Eliminar hábito'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(harness.repository.deleteCalls, 0);
    expect(harness.repository.habits, [original]);
    expect(find.byKey(const ValueKey('habit-form-screen')), findsOneWidget);

    await tapKey(tester, 'habit-more-menu');
    await tapKey(tester, 'habit-delete');
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(harness.repository.deleteCalls, 1);
    expect(harness.repository.habits, isEmpty);
    expect(find.byKey(const ValueKey('habit-form-screen')), findsNothing);
  });

  testWidgets('one-time habit hydrates scheduling controls', (tester) async {
    final habit = Habit(
      id: 'one-time',
      title: 'Presentar examen',
      category: Category.varios,
      frequency: Frequency.daily(),
      createdAt: DateTime(2024, 1, 1),
      isOneTime: true,
      scheduledDate: DateTime(2026, 8, 10),
    );
    await pumpForm(
      tester,
      habits: [habit],
      habitId: habit.id,
    );
    final semantics = tester.ensureSemantics();

    expect(
      find.byKey(const ValueKey('zentra-mode-selector')),
      findsOneWidget,
    );
    expect(isSelected(tester, 'habit-mode-one-time'), isTrue);
    expect(find.text('Editar actividad'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('habit-scheduled-date')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habit-advanced-toggle')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('one-time activity always persists its default date',
      (tester) async {
    final fixedNow = DateTime(2026, 7, 25, 8);
    final harness = await pumpForm(
      tester,
      now: () => fixedNow,
    );

    await enterTitle(tester, 'Llamar al dentista');
    expect(find.text('Nuevo hábito'), findsOneWidget);
    expect(find.text('Crear hábito'), findsOneWidget);
    await tapKey(tester, 'habit-mode-one-time');
    expect(find.text('Nueva actividad'), findsOneWidget);
    expect(find.text('Crear actividad'), findsOneWidget);
    await tapKey(tester, 'habit-submit');

    expect(harness.repository.habits, hasLength(1));
    final habit = harness.repository.habits.single;
    expect(habit.isOneTime, isTrue);
    expect(habit.scheduledDate, DateTime(2026, 7, 25));
    expect(habit.hasReminder, isFalse);
  });

  testWidgets('legacy one-time activity is not rewritten until save',
      (tester) async {
    final fixedNow = DateTime(2026, 7, 25, 8);
    final legacy = Habit(
      id: 'legacy-one-time',
      title: 'Actividad anterior',
      category: Category.varios,
      frequency: Frequency.daily(),
      createdAt: DateTime(2024, 1, 1),
      isOneTime: true,
    );
    final harness = await pumpForm(
      tester,
      habits: [legacy],
      habitId: legacy.id,
      now: () => fixedNow,
    );

    expect(harness.repository.updateCalls, 0);
    expect(harness.repository.habits.single.scheduledDate, isNull);
    expect(
      find.byKey(const ValueKey('habit-scheduled-date')),
      findsOneWidget,
    );

    await tapKey(tester, 'habit-submit');

    expect(harness.repository.updateCalls, 1);
    expect(
      harness.repository.habits.single.scheduledDate,
      DateTime(2026, 7, 25),
    );
  });

  testWidgets('rejects a dated one-time reminder in the past', (tester) async {
    final fixedNow = DateTime(2026, 7, 25, 12);
    final gateway = _FakeHabitFormNotificationGateway(
      permissionGranted: true,
    );
    final harness = await pumpForm(
      tester,
      notificationGateway: gateway,
      now: () => fixedNow,
    );

    await enterTitle(tester, 'Presentar examen');
    await tapKey(tester, 'habit-reminder-toggle');
    await tapKey(tester, 'habit-mode-one-time');
    await tapKey(tester, 'habit-submit');

    expect(
      find.text('Elige una fecha y hora futuras para este recordatorio.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('habit-form-screen')),
      findsOneWidget,
    );
    expect(harness.repository.habits, isEmpty);
    expect(harness.reminders.scheduled, isEmpty);
  });

  testWidgets('saves a future dated one-time reminder exactly once',
      (tester) async {
    final fixedNow = DateTime(2026, 7, 25, 8);
    final gateway = _FakeHabitFormNotificationGateway(
      permissionGranted: true,
    );
    final harness = await pumpForm(
      tester,
      notificationGateway: gateway,
      now: () => fixedNow,
    );

    await enterTitle(tester, 'Presentar examen');
    await tapKey(tester, 'habit-reminder-toggle');
    await tapKey(tester, 'habit-mode-one-time');
    await tapKey(tester, 'habit-submit');

    expect(harness.repository.habits, hasLength(1));
    final habit = harness.repository.habits.single;
    expect(habit.isOneTime, isTrue);
    expect(habit.scheduledDate, DateTime(2026, 7, 25));
    expect(habit.hasReminder, isTrue);
    expect(harness.reminders.scheduled, hasLength(1));
    final reminder = harness.reminders.scheduled.single;
    expect(reminder.isOneTime, isTrue);
    expect(reminder.scheduledDate, DateTime(2026, 7, 25));
    expect(reminder.hour, 9);
    expect(reminder.minute, 0);
  });

  testWidgets('double tap cannot create duplicate habits', (tester) async {
    final barrier = Completer<void>();
    final repository = _MemoryHabitRepository(saveBarrier: barrier);
    final harness = await pumpForm(
      tester,
      repository: repository,
    );

    await enterTitle(tester, 'Una sola vez');
    final submit = find.byKey(const ValueKey('habit-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(harness.repository.habits, isEmpty);

    barrier.complete();
    await tester.pumpAndSettle();
    expect(harness.repository.habits, hasLength(1));
  });

  testWidgets('save failure keeps the form open and preserves input',
      (tester) async {
    final repository = _MemoryHabitRepository(throwOnSave: true);
    await pumpForm(
      tester,
      repository: repository,
    );

    await enterTitle(tester, 'No perder este texto');
    await tapKey(tester, 'habit-category-sueno');
    await tapKey(tester, 'habit-submit');

    expect(
      find.byKey(const ValueKey('habit-form-screen')),
      findsOneWidget,
    );
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('habit-title-field')),
    );
    expect(field.controller!.text, 'No perder este texto');
    expect(find.text('No pudimos crear el hábito.'), findsOneWidget);
  });

  testWidgets('all category controls expose labels, tap and selected state',
      (tester) async {
    await pumpForm(tester);
    final semantics = tester.ensureSemantics();

    for (final category in Category.values) {
      final key = 'habit-category-${category.name}';
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);
      expect(node.label, contains(category.label));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
    }

    expect(isSelected(tester, 'habit-category-varios'), isTrue);
    await tapKey(tester, 'habit-category-agua');
    expect(isSelected(tester, 'habit-category-agua'), isTrue);
    expect(isSelected(tester, 'habit-category-varios'), isFalse);
    semantics.dispose();
  });

  testWidgets('the form accent is the same teal for every category',
      (tester) async {
    // The accent used to be the category colour, so choosing "Agua" turned the
    // whole form blue and "Movimiento" turned it orange. The form now speaks
    // with one voice: the teal of the save button. The category still reads
    // through its icon, which is the signal that actually distinguishes them.
    for (final themeMode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final dark = themeMode == ThemeMode.dark;
      final palette = dark ? ZentraPalette.dark : ZentraPalette.light;
      final accents = <Category, Color>{};
      final fills = <Category, Color>{};

      for (final category in Category.values) {
        await pumpForm(tester, themeMode: themeMode);
        await tapKey(tester, 'habit-category-${category.name}');
        accents[category] = categoryRingColor(tester, category);
        fills[category] = categoryFillColor(tester, category);
      }

      for (final category in Category.values) {
        expect(
          accents[category],
          palette.brandTeal,
          reason: '${category.name} en $themeMode no usa el teal de la marca.',
        );
        // Icon on its own selected fill: an icon is a large graphical object,
        // so 3.0 is the bar it has to clear.
        expect(
          _contrastRatio(palette.brandTeal, fills[category]!),
          greaterThanOrEqualTo(3.0),
          reason: '${category.name} en $themeMode pierde el icono en el relleno.',
        );
      }
    }
  });

  testWidgets('the light header keeps one fixed tint across categories',
      (tester) async {
    await pumpForm(tester);
    final initialColor = headerColor(tester);

    expect(initialColor, ZentraPalette.light.salviaFormHeader);
    expect(headerContainer(tester).duration, const Duration(milliseconds: 240));
    expect(headerContainer(tester).curve, Curves.easeOutCubic);

    await tapKey(tester, 'habit-category-movimiento');

    expect(headerColor(tester), initialColor);
  });

  testWidgets('the light header band is solid brand teal', (tester) async {
    await pumpForm(tester);

    // The band used to be a pale tint (#DCEDE6). It is now the same teal as the
    // save button, which makes it the strongest surface on the screen — and that
    // is the point: the top of the form states the brand once, loudly.
    expect(headerColor(tester), ZentraPalette.light.brandTeal);
  });

  testWidgets('light header content is legible on the teal band',
      (tester) async {
    await pumpForm(tester);
    final band = headerColor(tester);

    // Ink measures 2.96:1 on this teal and inkSecondary 1.09:1, so the band
    // cannot carry dark content: everything on it has to invert to light. These
    // are the numbers that force the inversion, not a preference.
    expect(_contrastRatio(ZentraPalette.light.ink, band), lessThan(4.5));

    expect(
      _contrastRatio(paintedColor(tester, find.text('Nuevo hábito')), band),
      greaterThanOrEqualTo(4.5),
      reason: 'El título del formulario se pierde sobre la banda teal.',
    );

    final back = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('habit-back')),
        matching: find.byType(Icon),
      ),
    );
    expect(
      _contrastRatio(back.color!, band),
      greaterThanOrEqualTo(3.0),
      reason: 'La flecha de atrás se pierde sobre la banda teal.',
    );
  });

  testWidgets('the light mode selector reads on the teal band', (tester) async {
    await pumpForm(tester);
    final band = headerColor(tester);

    final rail = tester.widget<Material>(
      find.byKey(const ValueKey('zentra-mode-selector')),
    );
    final railColor = Color.alphaBlend(rail.color!, band);

    // The rail used to be white at 55%, which over teal composites to #8CC3BC
    // and leaves white text at 1.97:1 — unreadable. Darkening the rail instead
    // of lightening it is what keeps the inactive label legible.
    expect(
      _contrastRatio(paintedColor(tester, find.text('Una sola vez')), railColor),
      greaterThanOrEqualTo(4.5),
      reason: 'La opción inactiva se pierde en el riel.',
    );

    // The selected pill stays light so it reads as a raised chip on the band.
    final selectedFill = modeOptionFill(tester, 'habit-mode-recurring');
    expect(
      _contrastRatio(selectedFill, band),
      greaterThanOrEqualTo(3.0),
      reason: 'La pastilla activa no se distingue de la banda.',
    );
    expect(
      _contrastRatio(paintedColor(tester, find.text('Se repite')), selectedFill),
      greaterThanOrEqualTo(4.5),
      reason: 'El texto activo se pierde en su pastilla.',
    );
  });

  testWidgets('AMOLED header stays fixed when the category changes',
      (tester) async {
    await pumpForm(tester, themeMode: ThemeMode.dark);
    final initialColor = headerColor(tester);

    await tapKey(tester, 'habit-category-movimiento');

    expect(initialColor, ZentraPalette.dark.salviaFormHeader);
    expect(headerColor(tester), initialColor);
  });

  testWidgets('320dp at 320 percent text keeps compact CTA reachable',
      (tester) async {
    await pumpForm(
      tester,
      size: const Size(320, 568),
      textScale: 3.2,
    );

    expect(find.byKey(const ValueKey('habit-form-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-preview')), findsNothing);
    final submit = find.byKey(const ValueKey('habit-submit'));
    expect(submit, findsOneWidget);
    final rect = tester.getRect(submit);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPad keeps a centered single-column form without preview',
      (tester) async {
    await pumpForm(
      tester,
      size: const Size(1024, 1366),
    );

    final content = find.byKey(const ValueKey('habit-form-content'));
    expect(content, findsOneWidget);
    expect(tester.getSize(content).width, lessThanOrEqualTo(680));
    expect(find.byKey(const ValueKey('habit-preview')), findsNothing);
    expect(find.byKey(const ValueKey('habit-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme keeps category selection and save functional',
      (tester) async {
    final harness = await pumpForm(
      tester,
      themeMode: ThemeMode.dark,
    );

    await enterTitle(tester, 'Descansar mejor');
    await tapKey(tester, 'habit-category-sueno');
    await tapKey(tester, 'habit-submit');

    expect(harness.repository.habits.single.category, Category.sueno);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps controls functional without pending motion',
      (tester) async {
    await pumpForm(
      tester,
      reduceMotion: true,
    );
    final semantics = tester.ensureSemantics();

    expect(headerContainer(tester).duration, Duration.zero);
    await tapKey(tester, 'habit-category-foco');
    await tapKey(tester, 'habit-frequency-weekends');

    expect(isSelected(tester, 'habit-category-foco'), isTrue);
    expect(isSelected(tester, 'habit-frequency-weekends'), isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

double _contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}
