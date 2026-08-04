/// A foreground snapshot that can safely make the next reminder specific.
class DailyReminderSnapshot {
  final DateTime capturedAt;
  final int totalHabits;
  final int completedHabits;
  final String? firstPendingHabit;

  const DailyReminderSnapshot({
    required this.capturedAt,
    required this.totalHabits,
    required this.completedHabits,
    this.firstPendingHabit,
  });

  int get remainingHabits {
    final remaining = totalHabits - completedHabits;
    return remaining < 0 ? 0 : remaining;
  }
}

/// Result of scheduling the notifications for one habit.
class HabitReminderScheduleResult {
  final int requestedCount;
  final int scheduledCount;

  const HabitReminderScheduleResult({
    required this.requestedCount,
    required this.scheduledCount,
  });

  bool get wasLimited => scheduledCount < requestedCount;
}

/// Application-facing contract for habit reminder side effects.
abstract class HabitReminderService {
  Future<void> initialize();

  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    bool isOneTime = false,
    DateTime? scheduledDate,
  });

  Future<void> cancelHabitReminder(String habitId);
}
