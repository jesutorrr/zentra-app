import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/habit_state.dart';
import 'package:zentra/domain/models.dart';

void main() {
  final now = DateTime(2026, 7, 26, 18);

  test('partitions active habits and respects one-time scheduled dates', () {
    final state = HabitState(
      ownerId: 'owner-a',
      habits: [
        _habit(id: 'daily', title: 'Beber agua'),
        _habit(id: 'archived', title: 'Archivado', isArchived: true),
        _habit(
          id: 'weekend',
          title: 'Caminar',
          frequency: Frequency.weekends(),
        ),
        _habit(
          id: 'today-task',
          title: 'Entregar reporte',
          isOneTime: true,
          scheduledDate: DateTime(2026, 7, 26),
        ),
        _habit(
          id: 'tomorrow-task',
          title: 'Preparar junta',
          isOneTime: true,
          scheduledDate: DateTime(2026, 7, 27),
        ),
      ],
    );

    expect(
      state.activeHabits.map((habit) => habit.id),
      ['daily', 'weekend', 'today-task', 'tomorrow-task'],
    );
    expect(state.archivedHabits.map((habit) => habit.id), ['archived']);
    expect(
      state.getHabitsForDate(now).map((habit) => habit.id),
      ['daily', 'weekend', 'today-task'],
    );
    expect(
      state.getHabitsForDate(DateTime(2026, 7, 27)).map((habit) => habit.id),
      ['daily', 'tomorrow-task'],
    );
  });

  test('derives completion, today stats and reminder snapshot at fixed time',
      () {
    final state = HabitState(
      ownerId: 'owner-a',
      habits: [
        _habit(id: 'water', title: 'Beber agua'),
        _habit(
          id: 'walk',
          title: 'Caminar',
          frequency: Frequency.weekends(),
        ),
        _habit(
          id: 'exam',
          title: 'Presentar examen',
          isOneTime: true,
          scheduledDate: DateTime(2026, 7, 26),
        ),
      ],
      logs: [
        HabitLog(
          habitId: 'water',
          date: DateTime(2026, 7, 26, 23, 59),
        ),
        HabitLog(
          habitId: 'exam',
          date: DateTime(2026, 7, 26, 8),
        ),
      ],
    );

    expect(
      state.isHabitCompleted('water', DateTime(2026, 7, 26, 1)),
      isTrue,
    );
    expect(state.isHabitCompleted('walk', now), isFalse);
    expect(state.getCompletionCount(now), 2);
    expect(state.getTotalHabitsCount(now), 3);
    expect(state.getDailyProgress(now), closeTo(2 / 3, 0.0001));
    expect(state.getTodayStats(now), {'completed': 2, 'total': 3});

    final snapshot = state.buildDailyReminderSnapshot(capturedAt: now);
    expect(snapshot.capturedAt, now);
    expect(snapshot.totalHabits, 3);
    expect(snapshot.completedHabits, 2);
    expect(snapshot.remainingHabits, 1);
    expect(snapshot.firstPendingHabit, 'Caminar');
  });

  test('calculates the seven-day average from historically valid days', () {
    final state = HabitState(
      ownerId: 'owner-a',
      habits: [
        _habit(
          id: 'weekdays',
          title: 'Leer',
          frequency: Frequency.weekdays(),
        ),
      ],
      logs: [
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 20)),
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 22)),
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 24)),
      ],
    );

    final history = state.getProgressHistory(7, now: now);

    expect(history, hasLength(7));
    expect(history.first['date'], DateTime(2026, 7, 20));
    expect(history.first['progress'], 1.0);
    expect(history[1]['progress'], 0.0);
    expect(history[5]['total'], 0);
    expect(history[6]['total'], 0);
    expect(state.getWeeklyAverageProgress(now), closeTo(3 / 5, 0.0001));
  });

  test('builds historical detail and skips unscheduled days in streaks', () {
    final weekdayHabit = _habit(
      id: 'weekdays',
      title: 'Leer',
      frequency: Frequency.weekdays(),
    );
    final archivedHabit = _habit(
      id: 'archived',
      title: 'Caminar',
      isArchived: true,
    );
    final state = HabitState(
      ownerId: 'owner-a',
      habits: [weekdayHabit, archivedHabit],
      logs: [
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 22)),
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 23)),
        HabitLog(habitId: 'weekdays', date: DateTime(2026, 7, 24)),
      ],
    );

    final detail = state.getHabitsDetailForDate(DateTime(2026, 7, 24));
    final detailById = {
      for (final entry in detail)
        (entry['habit'] as Habit).id: entry['completed'] as bool,
    };

    expect(detailById, {'weekdays': true, 'archived': false});
    expect(state.getHabitStreak('weekdays', now), 3);
    expect(state.getHabitStreak('missing', now), 0);
  });

  test('defensively freezes source and exposed collections', () {
    final habits = <Habit>[_habit(id: 'water', title: 'Beber agua')];
    final logs = <HabitLog>[
      HabitLog(habitId: 'water', date: DateTime(2026, 7, 26)),
    ];
    final completedTasks = <CompletedTask>[
      CompletedTask(
        id: 'done',
        title: 'Tarea terminada',
        category: Category.foco,
        completedAt: now,
        wasOneTime: true,
      ),
    ];
    final state = HabitState(
      ownerId: 'owner-a',
      habits: habits,
      logs: logs,
      completedTasks: completedTasks,
    );

    habits.add(_habit(id: 'late', title: 'Cambio externo'));
    logs.clear();
    completedTasks.clear();

    expect(state.habits.map((habit) => habit.id), ['water']);
    expect(state.logs, hasLength(1));
    expect(state.completedTasks, hasLength(1));
    expect(
      () => state.habits.add(_habit(id: 'blocked', title: 'Bloqueado')),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => state.logs.clear(),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => state.completedTasks.clear(),
      throwsA(isA<UnsupportedError>()),
    );
  });
}

Habit _habit({
  required String id,
  required String title,
  Frequency? frequency,
  bool isArchived = false,
  bool isOneTime = false,
  DateTime? scheduledDate,
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
  );
}
