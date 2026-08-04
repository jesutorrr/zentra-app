import '../core/constants.dart';
import '../domain/habit_reminder_service.dart';
import '../domain/models.dart';

const Object _habitStateUnset = Object();

/// Immutable application state for one owner's habits workspace.
class HabitState {
  final String ownerId;
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<CompletedTask> completedTasks;
  final bool isImporting;
  final String? error;
  final String? reminderWarning;

  HabitState({
    required this.ownerId,
    List<Habit> habits = const [],
    List<HabitLog> logs = const [],
    List<CompletedTask> completedTasks = const [],
    this.isImporting = false,
    this.error,
    this.reminderWarning,
  })  : habits = List.unmodifiable(habits),
        logs = List.unmodifiable(logs),
        completedTasks = List.unmodifiable(completedTasks);

  List<Habit> get activeHabits =>
      habits.where((habit) => !habit.isArchived).toList(growable: false);

  List<Habit> get archivedHabits =>
      habits.where((habit) => habit.isArchived).toList(growable: false);

  Habit? getHabitById(String habitId) {
    for (final habit in habits) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  List<Habit> getHabitsForDate(DateTime date) =>
      habits.where((habit) => habit.isScheduledFor(date)).toList(
            growable: false,
          );

  List<Habit> getTodayHabits(DateTime now) => getHabitsForDate(now);

  bool isHabitCompleted(String habitId, DateTime date) =>
      logs.any((log) => log.matches(habitId, date));

  int getCompletionCount(DateTime date) {
    return getHabitsForDate(date)
        .where((habit) => isHabitCompleted(habit.id, date))
        .length;
  }

  int getTotalHabitsCount(DateTime date) => getHabitsForDate(date).length;

  double getDailyProgress(DateTime date) {
    final total = getTotalHabitsCount(date);
    if (total == 0) return 0;
    return getCompletionCount(date) / total;
  }

  Map<String, int> getTodayStats(DateTime now) => {
        'completed': getCompletionCount(now),
        'total': getTotalHabitsCount(now),
      };

  DailyReminderSnapshot buildDailyReminderSnapshot({
    required DateTime capturedAt,
  }) {
    final todayHabits = getTodayHabits(capturedAt);
    final pendingHabits = todayHabits
        .where((habit) => !isHabitCompleted(habit.id, capturedAt))
        .toList(growable: false);
    return DailyReminderSnapshot(
      capturedAt: capturedAt,
      totalHabits: todayHabits.length,
      completedHabits: todayHabits.length - pendingHabits.length,
      firstPendingHabit:
          pendingHabits.isEmpty ? null : pendingHabits.first.title,
    );
  }

  List<Map<String, dynamic>> getProgressHistory(
    int days, {
    required DateTime now,
  }) {
    final result = <Map<String, dynamic>>[];
    for (var offset = days - 1; offset >= 0; offset--) {
      final date = DateTime(now.year, now.month, now.day - offset);
      final scheduled = _getHistoricallyActiveHabitsForDate(date);
      final completed =
          scheduled.where((habit) => isHabitCompleted(habit.id, date)).length;
      result.add({
        'date': date,
        'completed': completed,
        'total': scheduled.length,
        'progress': scheduled.isEmpty ? 0.0 : completed / scheduled.length,
      });
    }
    return result;
  }

  double getWeeklyAverageProgress(DateTime now) {
    final validDays = getProgressHistory(
      kWeeklyProgressDays,
      now: now,
    ).where((day) => (day['total'] as int) > 0).toList();
    if (validDays.isEmpty) return 0;
    final total = validDays.fold<double>(
      0,
      (sum, day) => sum + (day['progress'] as double),
    );
    return total / validDays.length;
  }

  List<Map<String, dynamic>> getHabitsDetailForDate(DateTime date) {
    return _getHistoricallyActiveHabitsForDate(date)
        .map(
          (habit) => {
            'habit': habit,
            'completed': isHabitCompleted(habit.id, date),
          },
        )
        .toList(growable: false);
  }

  int getHabitStreak(String habitId, DateTime now) {
    final habit = getHabitById(habitId);
    if (habit == null) return 0;
    var streak = 0;
    final startOffset = isHabitCompleted(habitId, now) ? 0 : 1;
    for (var offset = startOffset; offset < 365; offset++) {
      final date = DateTime(now.year, now.month, now.day - offset);
      if (!habit.frequency.appliesTo(date)) continue;
      if (!isHabitCompleted(habitId, date)) break;
      streak++;
    }
    return streak;
  }

  HabitState copyWith({
    List<Habit>? habits,
    List<HabitLog>? logs,
    List<CompletedTask>? completedTasks,
    bool? isImporting,
    Object? error = _habitStateUnset,
    Object? reminderWarning = _habitStateUnset,
  }) {
    return HabitState(
      ownerId: ownerId,
      habits: habits ?? this.habits,
      logs: logs ?? this.logs,
      completedTasks: completedTasks ?? this.completedTasks,
      isImporting: isImporting ?? this.isImporting,
      error: identical(error, _habitStateUnset) ? this.error : error as String?,
      reminderWarning: identical(reminderWarning, _habitStateUnset)
          ? this.reminderWarning
          : reminderWarning as String?,
    );
  }

  List<Habit> _getHistoricallyActiveHabitsForDate(DateTime date) {
    return habits
        .where((habit) => habit.frequency.appliesTo(date))
        .toList(growable: false);
  }
}
