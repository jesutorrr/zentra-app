import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/habit_state.dart';
import 'package:zentra/domain/completed_task_repository.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 26, 18, 50);

  test('builds direct daily reminder state from live habits and logs',
      () async {
    final repository = _MemoryHabitRepository();
    final harness = await _createHarness(
      repository,
      reminders: _FakeHabitReminderService(),
      now: fixedNow,
    );
    final today = fixedNow;
    for (final habit in [
      Habit(
        id: 'water',
        title: 'Tomar agua',
        category: Category.agua,
        frequency: Frequency.daily(),
        createdAt: today,
      ),
      Habit(
        id: 'read',
        title: 'Leer',
        category: Category.foco,
        frequency: Frequency.daily(),
        createdAt: today,
      ),
    ]) {
      await harness.controller.createHabit(habit);
    }
    await harness.controller.toggleHabitToday('water');

    final capturedAt = fixedNow;
    final snapshot =
        harness.state.buildDailyReminderSnapshot(capturedAt: capturedAt);

    expect(snapshot.capturedAt, capturedAt);
    expect(snapshot.totalHabits, 2);
    expect(snapshot.completedHabits, 1);
    expect(snapshot.remainingHabits, 1);
    expect(snapshot.firstPendingHabit, 'Leer');
  });

  test('create, archive, restore and delete keep reminders in sync', () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService();
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    final habit = Habit(
      id: 'habit-1',
      title: 'Tomar agua',
      category: Category.agua,
      frequency: Frequency.weekdays(),
      createdAt: DateTime(2026, 7, 25),
      hasReminder: true,
      reminderHour: 9,
      reminderMinute: 15,
    );

    await harness.controller.createHabit(habit);
    expect(reminders.scheduledHabitIds, ['habit-1']);
    expect(reminders.lastDays, [1, 2, 3, 4, 5]);

    await harness.controller.toggleArchive(habit.id);
    expect(reminders.cancelledHabitIds, contains('habit-1'));

    reminders.scheduledHabitIds.clear();
    await harness.controller.toggleArchive(habit.id);
    expect(reminders.scheduledHabitIds, ['habit-1']);

    await harness.controller.deleteHabit(habit.id, addToHistory: false);
    expect(
      reminders.cancelledHabitIds
          .where((habitId) => habitId == 'habit-1')
          .length,
      greaterThanOrEqualTo(2),
    );
  });

  test('disabling a reminder on edit cancels the existing request', () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService();
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    final habit = Habit(
      id: 'habit-2',
      title: 'Leer',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime(2026, 7, 25),
      hasReminder: true,
      reminderHour: 20,
      reminderMinute: 0,
    );
    await harness.controller.createHabit(habit);

    await harness.controller.updateHabit(
      Habit(
        id: habit.id,
        title: habit.title,
        category: habit.category,
        frequency: habit.frequency,
        createdAt: habit.createdAt,
      ),
    );

    expect(reminders.cancelledHabitIds, contains('habit-2'));
  });

  test('surfaces notification capacity limits without losing the habit',
      () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService(
      result: const HabitReminderScheduleResult(
        requestedCount: 5,
        scheduledCount: 2,
      ),
    );
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    final habit = Habit(
      id: 'habit-3',
      title: 'Caminar',
      category: Category.movimiento,
      frequency: Frequency.weekdays(),
      createdAt: DateTime(2026, 7, 25),
      hasReminder: true,
      reminderHour: 7,
      reminderMinute: 30,
    );

    await harness.controller.createHabit(habit);

    expect(harness.state.getHabitById(habit.id), isNotNull);
    expect(harness.controller.consumeReminderWarning(), contains('2 de 5'));
    expect(harness.controller.consumeReminderWarning(), isNull);
  });

  test('a one-time zero schedule explains that its date may be in the past',
      () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService(
      result: const HabitReminderScheduleResult(
        requestedCount: 1,
        scheduledCount: 0,
      ),
    );
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    final habit = Habit(
      id: 'expired-one-time',
      title: 'Presentar examen',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime(2026, 7, 25),
      isOneTime: true,
      scheduledDate: DateTime(2026, 7, 25),
      hasReminder: true,
      reminderHour: 9,
      reminderMinute: 0,
    );

    await harness.controller.createHabit(habit);

    expect(harness.state.getHabitById(habit.id), isNotNull);
    expect(
      harness.controller.consumeReminderWarning(),
      contains('fecha y la hora sigan en el futuro'),
    );
  });

  test('creating a habit without a reminder skips the native service',
      () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService();
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );

    await harness.controller.createHabit(
      Habit(
        id: 'habit-without-reminder',
        title: 'Caminar',
        category: Category.movimiento,
        frequency: Frequency.daily(),
        createdAt: DateTime(2026, 7, 25),
      ),
    );

    expect(reminders.initializeCalls, 0);
    expect(reminders.scheduledHabitIds, isEmpty);
    expect(reminders.cancelledHabitIds, isEmpty);
  });

  test('a dated one-time habit sends its date to the reminder service',
      () async {
    final repository = _MemoryHabitRepository();
    final reminders = _FakeHabitReminderService();
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    final scheduledDate = DateTime(2026, 8, 3);

    await harness.controller.createHabit(
      Habit(
        id: 'dated-task',
        title: 'Entregar proyecto',
        category: Category.foco,
        frequency: Frequency.daily(),
        createdAt: DateTime(2026, 7, 25),
        isOneTime: true,
        scheduledDate: scheduledDate,
        hasReminder: true,
        reminderHour: 18,
        reminderMinute: 30,
      ),
    );

    expect(reminders.lastScheduledDate, scheduledDate);
    expect(reminders.lastIsOneTime, isTrue);
  });

  test('failed delete preserves habit, history and reminder', () async {
    final repository = _ThrowingDeleteHabitRepository();
    final reminders = _FakeHabitReminderService();
    final habit = Habit(
      id: 'protected-habit',
      title: 'Leer',
      category: Category.foco,
      frequency: Frequency.daily(),
      createdAt: DateTime(2026, 7, 25),
      hasReminder: true,
      reminderHour: 20,
      reminderMinute: 0,
    );
    await repository.saveHabit(habit);
    final harness = await _createHarness(
      repository,
      reminders: reminders,
      now: fixedNow,
    );
    reminders.clearCalls();

    await expectLater(
      harness.controller.deleteHabit(habit.id),
      throwsA(isA<StateError>()),
    );
    expect(harness.state.getHabitById(habit.id), isNotNull);
    expect(harness.state.completedTasks, isEmpty);
    expect(reminders.cancelledHabitIds, isEmpty);
    expect(harness.state.error, contains('Error deleting habit'));
  });
}

class _Harness {
  final ProviderContainer container;
  final AsyncNotifierFamilyProvider<HabitController, HabitState, String>
      provider;

  const _Harness({
    required this.container,
    required this.provider,
  });

  HabitController get controller => container.read(provider.notifier);

  HabitState get state => container.read(provider).requireValue;
}

Future<_Harness> _createHarness(
  HabitRepository repository, {
  required _FakeHabitReminderService reminders,
  required DateTime now,
}) async {
  const ownerId = 'notification-owner';
  final completedRepository = _MemoryCompletedTaskRepository(ownerId);
  final provider = habitControllerProvider(ownerId);
  final container = ProviderContainer(
    overrides: [
      habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
        expect(requestedOwner, ownerId);
        return repository;
      }),
      completedTaskRepositoryFactoryProvider.overrideWithValue(
        (requestedOwner) {
          expect(requestedOwner, ownerId);
          return completedRepository;
        },
      ),
      habitReminderServiceProvider.overrideWithValue(reminders),
      habitClockProvider.overrideWithValue(() => now),
    ],
  );
  addTearDown(container.dispose);
  container.listen(provider, (_, __) {}, fireImmediately: true);
  await container.read(provider.future);
  return _Harness(container: container, provider: provider);
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

class _FakeHabitReminderService implements HabitReminderService {
  final HabitReminderScheduleResult result;
  final List<String> scheduledHabitIds = [];
  final List<String> cancelledHabitIds = [];
  int initializeCalls = 0;
  List<int>? lastDays;
  DateTime? lastScheduledDate;
  bool? lastIsOneTime;

  _FakeHabitReminderService({
    this.result = const HabitReminderScheduleResult(
      requestedCount: 1,
      scheduledCount: 1,
    ),
  });

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
    scheduledHabitIds.add(habitId);
    lastDays = List<int>.from(daysOfWeek);
    lastIsOneTime = isOneTime;
    lastScheduledDate = scheduledDate;
    return result;
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    cancelledHabitIds.add(habitId);
  }

  void clearCalls() {
    scheduledHabitIds.clear();
    cancelledHabitIds.clear();
    initializeCalls = 0;
    lastDays = null;
    lastScheduledDate = null;
    lastIsOneTime = null;
  }
}

class _MemoryHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((habit) => habit.id == habitId);
    _logs.removeWhere((log) => log.habitId == habitId);
  }

  @override
  Future<List<HabitLog>> getAllLogs() async => List.of(_logs);

  @override
  Future<List<Habit>> getHabits() async => List.of(_habits);

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    return _logs.where((log) => log.date == date).toList();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    _habits.add(habit);
  }

  @override
  void setCurrentUser(String? userId) {}

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final index = _logs.indexWhere((log) => log.matches(habitId, date));
    if (index == -1) {
      _logs.add(HabitLog(habitId: habitId, date: date));
    } else {
      _logs.removeAt(index);
    }
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((current) => current.id == habit.id);
    _habits[index] = habit;
  }
}

class _ThrowingDeleteHabitRepository extends _MemoryHabitRepository {
  @override
  Future<void> deleteHabit(String habitId) async {
    throw StateError('delete failed');
  }
}
