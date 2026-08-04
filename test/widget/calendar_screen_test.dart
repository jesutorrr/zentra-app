import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/calendar_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_CalendarHarness> createHarness({bool withActivity = true}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = ProgressEngine.dayKey(today);
    final habit = Habit(
      id: 'habit-water',
      title: 'Beber agua',
      category: Category.agua,
      frequency: Frequency.daily(),
      createdAt: today.subtract(const Duration(days: 30)),
      hasReminder: true,
      reminderHour: 9,
      reminderMinute: 30,
    );
    final profile = UserProfile(
      id: 'profile-calendar',
      name: 'Uri',
      createdAt: today.subtract(const Duration(days: 60)),
      totalHabitsCompleted: 12,
      totalDaysActive: 4,
      totalFocusMinutes: 50,
      dailyHabitCompletions: withActivity ? {dayKey: 2} : const {},
      dailyFocusSessions: withActivity ? {dayKey: 1} : const {},
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final habits = LocalStorageRepository.forOwner(
      prefs,
      ownerId: _CalendarHarness.ownerId,
    );
    final profiles = SharedPreferencesProfileRepository(
      prefs,
      ownerId: _CalendarHarness.ownerId,
    );
    final completedTasks = SharedPreferencesCompletedTaskRepository(
      prefs,
      ownerId: _CalendarHarness.ownerId,
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    final notes = DriftNoteRepository.forOwner(
      database,
      ownerId: _CalendarHarness.ownerId,
    );
    if (withActivity) {
      await habits.saveHabit(habit);
      await habits.toggleLog(habit.id, today);
    }
    await profiles.saveProfile(profile);
    final harness = _CalendarHarness(
      habits: habits,
      profiles: profiles,
      completedTasks: completedTasks,
      notes: notes,
      database: database,
    );
    addTearDown(harness.dispose);
    await harness.initialize();
    return harness;
  }

  Future<void> pumpCalendar(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    bool darkMode = false,
    bool withActivity = true,
  }) async {
    final harness = await createHarness(withActivity: withActivity);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp(
          theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('combines live details with durable daily activity',
      (tester) async {
    await pumpCalendar(tester, size: const Size(390, 844));

    expect(find.byTooltip('2 avances'), findsOneWidget);
    expect(find.byTooltip('1 enfoque'), findsOneWidget);
    expect(find.text('Beber agua'), findsOneWidget);
    expect(
      find.textContaining(
        '1 avance guardado de un hábito eliminado.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-preserved-activity')),
      findsOneWidget,
    );
    expect(find.text('Plan del día'), findsNothing);
    expect(find.text('Notas para volver'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses direct language when a day has no activity',
      (tester) async {
    await pumpCalendar(
      tester,
      size: const Size(390, 844),
      withActivity: false,
    );

    expect(find.text('Sin actividad'), findsOneWidget);
    expect(
      find.text('No hay nada guardado para este día.'),
      findsOneWidget,
    );
    expect(find.text('Un día con espacio'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'keeps an AMOLED surface and chromatic ambient layer in dark mode',
      (tester) async {
    await pumpCalendar(
      tester,
      size: const Size(390, 844),
      darkMode: true,
    );

    final ambient = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('calendar-ambient-layer')),
    );
    final decoration = ambient.decoration! as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect(
      Theme.of(
        tester.element(
          find.byKey(const ValueKey('calendar-month-panel')),
        ),
      ).scaffoldBackgroundColor,
      const Color(0xFF000000),
    );
    expect(find.text('Beber agua'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a true two-panel layout at expanded width', (tester) async {
    await pumpCalendar(tester, size: const Size(834, 1194));

    final month = find.byKey(const ValueKey('calendar-month-panel'));
    final detail = find.byKey(const ValueKey('calendar-day-panel'));
    expect(month, findsOneWidget);
    expect(detail, findsOneWidget);
    expect(tester.getTopLeft(month).dx, lessThan(tester.getTopLeft(detail).dx));
    expect(
      (tester.getTopLeft(month).dy - tester.getTopLeft(detail).dy).abs(),
      lessThan(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated calendar supports 320 percent text on a 320px phone',
      (tester) async {
    await pumpCalendar(
      tester,
      size: const Size(320, 568),
      textScale: 3.2,
    );

    expect(find.byKey(const ValueKey('calendar-scroll')), findsOneWidget);
    expect(find.text('Beber agua'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeHabitReminderService implements HabitReminderService {
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

class _CalendarHarness {
  static const ownerId = 'calendar-owner';

  final LocalStorageRepository habits;
  final SharedPreferencesProfileRepository profiles;
  final SharedPreferencesCompletedTaskRepository completedTasks;
  final DriftNoteRepository notes;
  final ZentraDatabase database;
  late final ProviderContainer container;

  _CalendarHarness({
    required this.habits,
    required this.profiles,
    required this.completedTasks,
    required this.notes,
    required this.database,
  }) {
    container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
        habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return habits;
        }),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          (requestedOwner) {
            expect(requestedOwner, ownerId);
            return completedTasks;
          },
        ),
        profileRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return profiles;
        }),
        noteRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          expect(requestedOwner, ownerId);
          return notes;
        }),
        habitReminderServiceProvider.overrideWithValue(
          _FakeHabitReminderService(),
        ),
      ],
    );
  }

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
  }

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}
