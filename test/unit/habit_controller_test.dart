import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/domain/completed_task_repository.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/models.dart';

import '../support/riverpod_test_harness.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 26, 18);

  test('loads isolated owner-bound workspaces for owners A and B', () async {
    final habitRepositories = <String, _OwnerHabitRepository>{
      'owner-a': _OwnerHabitRepository(
        ownerId: 'owner-a',
        habits: [_habit(id: 'habit-a', title: 'Hábito de A')],
      ),
      'owner-b': _OwnerHabitRepository(
        ownerId: 'owner-b',
        habits: [_habit(id: 'habit-b', title: 'Hábito de B')],
      ),
    };
    final completedRepositories = <String, _OwnerCompletedTaskRepository>{
      'owner-a': _OwnerCompletedTaskRepository(ownerId: 'owner-a'),
      'owner-b': _OwnerCompletedTaskRepository(ownerId: 'owner-b'),
    };
    final container = _createContainer(
      habitRepositories: habitRepositories,
      completedRepositories: completedRepositories,
      reminders: _FakeHabitReminderService(),
      fixedNow: fixedNow,
    );
    final ownerAProvider = habitControllerProvider('owner-a');
    final ownerBProvider = habitControllerProvider('owner-b');
    container.listen(ownerAProvider, (_, __) {}, fireImmediately: true);
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);

    final ownerA = await container.read(ownerAProvider.future);
    final ownerB = await container.read(ownerBProvider.future);

    expect(ownerA.ownerId, 'owner-a');
    expect(ownerA.habits.map((habit) => habit.id), ['habit-a']);
    expect(ownerB.ownerId, 'owner-b');
    expect(ownerB.habits.map((habit) => habit.id), ['habit-b']);
    expect(
      habitRepositories['owner-a'],
      isNot(same(habitRepositories['owner-b'])),
    );
    expect(
      completedRepositories['owner-a'],
      isNot(same(completedRepositories['owner-b'])),
    );
  });

  test('reload propagates repository failures and exposes AsyncError',
      () async {
    final habitRepository = _OwnerHabitRepository(ownerId: 'owner-a');
    final container = _createContainer(
      habitRepositories: {'owner-a': habitRepository},
      completedRepositories: {
        'owner-a': _OwnerCompletedTaskRepository(ownerId: 'owner-a'),
      },
      reminders: _FakeHabitReminderService(),
      fixedNow: fixedNow,
    );
    final provider = habitControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    habitRepository.loadError = StateError('habit reload failed');

    await expectLater(
      container.read(provider.notifier).reload(isImporting: true),
      throwsA(isA<StateError>()),
    );

    final reloaded = container.read(provider);
    expect(reloaded.hasError, isTrue);
    expect(reloaded.error, isA<StateError>());
  });

  test('create, update and delete keep state, history and reminders aligned',
      () async {
    final habitRepository = _OwnerHabitRepository(ownerId: 'owner-a');
    final completedRepository =
        _OwnerCompletedTaskRepository(ownerId: 'owner-a');
    final reminders = _FakeHabitReminderService();
    final container = _createContainer(
      habitRepositories: {'owner-a': habitRepository},
      completedRepositories: {'owner-a': completedRepository},
      reminders: reminders,
      fixedNow: fixedNow,
    );
    final provider = habitControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    final habit = _habit(
      id: 'focus',
      title: 'Leer',
      frequency: Frequency.weekdays(),
      hasReminder: true,
      reminderHour: 9,
      reminderMinute: 15,
    );

    await controller.createHabit(habit);

    expect(habitRepository.saveCalls, 1);
    expect(container.read(provider).valueOrNull!.habits.single.id, 'focus');
    expect(reminders.scheduledHabitIds, ['focus']);
    expect(reminders.lastDays, [1, 2, 3, 4, 5]);

    final updated = habit.copyWith(
      title: 'Leer veinte minutos',
      hasReminder: false,
      clearReminderTime: true,
    );
    await controller.updateHabit(updated);

    expect(habitRepository.updateCalls, 1);
    expect(
      container.read(provider).valueOrNull!.habits.single.title,
      'Leer veinte minutos',
    );
    expect(reminders.cancelledHabitIds, ['focus']);

    await controller.deleteHabit('focus');

    final state = container.read(provider).valueOrNull!;
    expect(habitRepository.deleteCalls, 1);
    expect(state.habits, isEmpty);
    expect(state.completedTasks, hasLength(1));
    expect(state.completedTasks.single.id, 'focus');
    expect(state.completedTasks.single.wasOneTime, isFalse);
    expect(state.completedTasks.single.completedAt, fixedNow);
    expect(completedRepository.tasks, hasLength(1));
    expect(reminders.cancelledHabitIds, ['focus', 'focus']);
  });

  test('one-time completion is archived exactly once on repeated toggle',
      () async {
    final oneTime = _habit(
      id: 'exam',
      title: 'Presentar examen',
      isOneTime: true,
      scheduledDate: DateTime(2026, 7, 26),
      hasReminder: true,
      reminderHour: 18,
      reminderMinute: 30,
    );
    final habitRepository = _OwnerHabitRepository(
      ownerId: 'owner-a',
      habits: [oneTime],
    );
    final completedRepository =
        _OwnerCompletedTaskRepository(ownerId: 'owner-a');
    final reminders = _FakeHabitReminderService();
    final container = _createContainer(
      habitRepositories: {'owner-a': habitRepository},
      completedRepositories: {'owner-a': completedRepository},
      reminders: reminders,
      fixedNow: fixedNow,
    );
    final provider = habitControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    reminders.clearCalls();
    final controller = container.read(provider.notifier);

    await controller.toggleHabitToday('exam');
    await controller.toggleHabitToday('exam');

    final state = container.read(provider).valueOrNull!;
    expect(state.getHabitById('exam'), isNull);
    expect(state.completedTasks, hasLength(1));
    expect(state.completedTasks.single.id, 'exam');
    expect(state.completedTasks.single.wasOneTime, isTrue);
    expect(completedRepository.replaceCalls, 1);
    expect(habitRepository.deleteCalls, 1);
    expect(reminders.cancelledHabitIds, ['exam']);
  });

  test('failed delete preserves habit, history and reminder', () async {
    final protected = _habit(
      id: 'protected',
      title: 'Leer',
      hasReminder: true,
      reminderHour: 20,
      reminderMinute: 0,
    );
    final habitRepository = _OwnerHabitRepository(
      ownerId: 'owner-a',
      habits: [protected],
      throwOnDelete: true,
    );
    final completedRepository =
        _OwnerCompletedTaskRepository(ownerId: 'owner-a');
    final reminders = _FakeHabitReminderService();
    final container = _createContainer(
      habitRepositories: {'owner-a': habitRepository},
      completedRepositories: {'owner-a': completedRepository},
      reminders: reminders,
      fixedNow: fixedNow,
    );
    final provider = habitControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    reminders.clearCalls();

    await expectLater(
      container.read(provider.notifier).deleteHabit('protected'),
      throwsA(isA<StateError>()),
    );

    final state = container.read(provider).valueOrNull!;
    expect(state.getHabitById('protected'), isNotNull);
    expect(state.completedTasks, isEmpty);
    expect(completedRepository.tasks, isEmpty);
    expect(reminders.cancelledHabitIds, isEmpty);
    expect(state.error, contains('Error deleting habit'));
  });

  test('limited reminder warning is consumable without losing the habit',
      () async {
    final habitRepository = _OwnerHabitRepository(ownerId: 'owner-a');
    final completedRepository =
        _OwnerCompletedTaskRepository(ownerId: 'owner-a');
    final reminders = _FakeHabitReminderService(
      result: const HabitReminderScheduleResult(
        requestedCount: 5,
        scheduledCount: 2,
      ),
    );
    final container = _createContainer(
      habitRepositories: {'owner-a': habitRepository},
      completedRepositories: {'owner-a': completedRepository},
      reminders: reminders,
      fixedNow: fixedNow,
    );
    final provider = habitControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    final habit = _habit(
      id: 'walk',
      title: 'Caminar',
      frequency: Frequency.weekdays(),
      hasReminder: true,
      reminderHour: 7,
      reminderMinute: 30,
    );

    await controller.createHabit(habit);

    expect(
      container.read(provider).valueOrNull!.getHabitById('walk'),
      isNotNull,
    );
    expect(controller.consumeReminderWarning(), contains('2 de 5'));
    expect(controller.consumeReminderWarning(), isNull);
  });

  test('import timer settles and owner disposal does not update owner B',
      () async {
    final habitRepositories = <String, _OwnerHabitRepository>{
      'owner-a': _OwnerHabitRepository(
        ownerId: 'owner-a',
        habits: [_habit(id: 'habit-a', title: 'Hábito de A')],
      ),
      'owner-b': _OwnerHabitRepository(
        ownerId: 'owner-b',
        habits: [_habit(id: 'habit-b', title: 'Hábito de B')],
      ),
    };
    final completedRepositories = <String, _OwnerCompletedTaskRepository>{
      'owner-a': _OwnerCompletedTaskRepository(ownerId: 'owner-a'),
      'owner-b': _OwnerCompletedTaskRepository(ownerId: 'owner-b'),
    };
    final observer = _RecordingObserver();
    final container = _createContainer(
      habitRepositories: habitRepositories,
      completedRepositories: completedRepositories,
      reminders: _FakeHabitReminderService(),
      fixedNow: fixedNow,
      observers: [observer],
    );
    final ownerAProvider = habitControllerProvider('owner-a');
    final ownerBProvider = habitControllerProvider('owner-b');
    final ownerASubscription = container.listen(
      ownerAProvider,
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);
    await Future.wait([
      container.read(ownerAProvider.future),
      container.read(ownerBProvider.future),
    ]);
    final ownerAController = container.read(ownerAProvider.notifier);

    await ownerAController.reload(isImporting: true);
    expect(container.read(ownerAProvider).valueOrNull!.isImporting, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(container.read(ownerAProvider).valueOrNull!.isImporting, isFalse);

    await ownerAController.reload(isImporting: true);
    expect(container.read(ownerAProvider).valueOrNull!.isImporting, isTrue);
    final ownerBLoadsBeforeDispose =
        habitRepositories['owner-b']!.getHabitsCalls;
    final ownerBBefore = container.read(ownerBProvider).valueOrNull!;

    ownerASubscription.close();
    container.invalidate(ownerAProvider);
    await container.pump();
    final ownerAUpdatesAfterDispose = observer.updatesFor(ownerAProvider);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(observer.updatesFor(ownerAProvider), ownerAUpdatesAfterDispose);
    expect(
      habitRepositories['owner-b']!.getHabitsCalls,
      ownerBLoadsBeforeDispose,
    );
    final ownerBAfter = container.read(ownerBProvider).valueOrNull!;
    expect(ownerBAfter.ownerId, ownerBBefore.ownerId);
    expect(
      ownerBAfter.habits.map((habit) => habit.id),
      ownerBBefore.habits.map((habit) => habit.id),
    );
    expect(ownerBAfter.isImporting, isFalse);
  });
}

ProviderContainer _createContainer({
  required Map<String, _OwnerHabitRepository> habitRepositories,
  required Map<String, _OwnerCompletedTaskRepository> completedRepositories,
  required _FakeHabitReminderService reminders,
  required DateTime fixedNow,
  List<ProviderObserver> observers = const [],
}) {
  HabitRepository habitFactory(String ownerId) {
    final repository = habitRepositories[ownerId];
    if (repository == null) {
      throw StateError('Missing habit repository for $ownerId');
    }
    return repository;
  }

  CompletedTaskRepository completedTaskFactory(String ownerId) {
    final repository = completedRepositories[ownerId];
    if (repository == null) {
      throw StateError('Missing completed task repository for $ownerId');
    }
    return repository;
  }

  return createTestProviderContainer(
    overrides: [
      habitRepositoryFactoryProvider.overrideWithValue(habitFactory),
      completedTaskRepositoryFactoryProvider.overrideWithValue(
        completedTaskFactory,
      ),
      habitReminderServiceProvider.overrideWithValue(reminders),
      habitClockProvider.overrideWithValue(() => fixedNow),
    ],
    observers: observers,
  );
}

Habit _habit({
  required String id,
  required String title,
  Frequency? frequency,
  bool isArchived = false,
  bool isOneTime = false,
  DateTime? scheduledDate,
  bool hasReminder = false,
  int? reminderHour,
  int? reminderMinute,
}) {
  return Habit(
    id: id,
    title: title,
    category: Category.foco,
    frequency: frequency ?? Frequency.daily(),
    createdAt: DateTime(2026, 7, 1),
    isArchived: isArchived,
    isOneTime: isOneTime,
    scheduledDate: scheduledDate,
    hasReminder: hasReminder,
    reminderHour: reminderHour,
    reminderMinute: reminderMinute,
  );
}

class _OwnerHabitRepository implements HabitRepository {
  final String ownerId;
  final bool throwOnDelete;
  Object? loadError;
  final List<Habit> _habits;
  final List<HabitLog> _logs;
  int getHabitsCalls = 0;
  int saveCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  _OwnerHabitRepository({
    required this.ownerId,
    List<Habit> habits = const [],
    List<HabitLog> logs = const [],
    this.throwOnDelete = false,
  })  : _habits = [...habits],
        _logs = [...logs];

  @override
  void setCurrentUser(String? userId) {
    if (userId != ownerId) {
      throw StateError('Repository is bound to $ownerId, not $userId');
    }
  }

  @override
  Future<List<Habit>> getHabits() async {
    getHabitsCalls += 1;
    final error = loadError;
    if (error != null) throw error;
    return List.unmodifiable(_habits);
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    saveCalls += 1;
    if (_habits.any((current) => current.id == habit.id)) {
      throw StateError('Habit ${habit.id} already exists for $ownerId');
    }
    _habits.add(habit);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    updateCalls += 1;
    final index = _habits.indexWhere((current) => current.id == habit.id);
    if (index == -1) throw StateError('Habit ${habit.id} is missing');
    _habits[index] = habit;
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    deleteCalls += 1;
    if (throwOnDelete) throw StateError('delete failed');
    _habits.removeWhere((habit) => habit.id == habitId);
    _logs.removeWhere((log) => log.habitId == habitId);
  }

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    return _logs.where((log) => log.matches(log.habitId, date)).toList();
  }

  @override
  Future<List<HabitLog>> getAllLogs() async => List.unmodifiable(_logs);

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final index = _logs.indexWhere((log) => log.matches(habitId, date));
    if (index == -1) {
      _logs.add(HabitLog(habitId: habitId, date: date));
    } else {
      _logs.removeAt(index);
    }
  }
}

class _OwnerCompletedTaskRepository implements CompletedTaskRepository {
  @override
  final String ownerId;
  List<CompletedTask> _tasks;
  int replaceCalls = 0;

  _OwnerCompletedTaskRepository({
    required this.ownerId,
    List<CompletedTask> tasks = const [],
  }) : _tasks = [...tasks];

  List<CompletedTask> get tasks => List.unmodifiable(_tasks);

  @override
  Future<List<CompletedTask>> loadCompletedTasks() async {
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> replaceCompletedTasks(List<CompletedTask> tasks) async {
    replaceCalls += 1;
    _tasks = [...tasks];
  }
}

class _FakeHabitReminderService implements HabitReminderService {
  final HabitReminderScheduleResult? result;
  final List<String> scheduledHabitIds = [];
  final List<String> cancelledHabitIds = [];
  int initializeCalls = 0;
  List<int>? lastDays;
  DateTime? lastScheduledDate;
  bool? lastIsOneTime;

  _FakeHabitReminderService({this.result});

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
    lastDays = List.unmodifiable(daysOfWeek);
    lastScheduledDate = scheduledDate;
    lastIsOneTime = isOneTime;
    return result ??
        HabitReminderScheduleResult(
          requestedCount: daysOfWeek.length,
          scheduledCount: daysOfWeek.length,
        );
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

class _RecordingObserver extends ProviderObserver {
  final Map<ProviderBase<Object?>, int> _updates = {};

  int updatesFor(ProviderBase<Object?> provider) => _updates[provider] ?? 0;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _updates.update(provider, (count) => count + 1, ifAbsent: () => 1);
  }
}
