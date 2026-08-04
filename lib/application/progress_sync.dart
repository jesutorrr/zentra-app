import 'dart:math' as math;

import '../domain/progress_engine.dart';
import '../domain/pomodoro_activity.dart';
import 'habit_state.dart';

ProgressSnapshot buildProgressSnapshotFromState({
  required HabitState habitState,
  required List<PomodoroActivity> activityHistory,
  required int totalPomodoros,
  required int totalFocusMinutes,
  required DateTime now,
}) {
  final categoriesByHabitId = {
    for (final habit in habitState.habits) habit.id: habit.category.name,
    for (final task in habitState.completedTasks) task.id: task.category.name,
  };
  final habitEvents = [
    for (final log in habitState.logs)
      HabitProgressEvent(
        id: 'habit:${log.habitId}:${ProgressEngine.dayKey(log.date)}',
        completedOn: log.date,
        categoryName: categoriesByHabitId[log.habitId] ?? 'varios',
      ),
  ];
  final focusEvents = <FocusProgressEvent>[];
  for (final activity in activityHistory) {
    if (!activity.isCompleted) continue;
    for (var cycle = 1; cycle <= activity.cyclesCompleted; cycle++) {
      focusEvents.add(
        FocusProgressEvent(
          id: 'focus:${activity.id}:$cycle',
          completedOn: activity.endTime ?? activity.startTime,
        ),
      );
    }
  }

  var longestStreak = 0;
  for (final habit in habitState.habits) {
    final streak = habitState.getHabitStreak(habit.id, now);
    if (streak > longestStreak) longestStreak = streak;
  }
  final derivedPomodoros =
      activityHistory.where((activity) => activity.isCompleted).fold<int>(
            0,
            (total, activity) => total + activity.cyclesCompleted,
          );
  final derivedFocusMinutes =
      activityHistory.where((activity) => activity.isCompleted).fold<int>(
            0,
            (total, activity) => total + activity.totalMinutes,
          );

  return ProgressSnapshot(
    habitEvents: habitEvents,
    focusEvents: focusEvents,
    knownHabitIds: {
      ...habitState.habits.map((habit) => habit.id),
      ...habitState.completedTasks.map((task) => task.id),
    },
    longestStreak: longestStreak,
    totalPomodoros: math.max(totalPomodoros, derivedPomodoros),
    totalFocusMinutes: math.max(totalFocusMinutes, derivedFocusMinutes),
  );
}

int progressSourceFingerprintFromState({
  required HabitState habitState,
  required List<PomodoroActivity> activityHistory,
  required int totalPomodoros,
  required int totalFocusMinutes,
}) {
  return Object.hashAll([
    for (final habit in habitState.habits) '${habit.id}:${habit.category.name}',
    for (final task in habitState.completedTasks)
      '${task.id}:${task.category.name}',
    for (final log in habitState.logs)
      '${log.habitId}:${ProgressEngine.dayKey(log.date)}',
    totalPomodoros,
    totalFocusMinutes,
    for (final activity in activityHistory)
      '${activity.id}:${activity.cyclesCompleted}:${activity.isCompleted}',
  ]);
}
