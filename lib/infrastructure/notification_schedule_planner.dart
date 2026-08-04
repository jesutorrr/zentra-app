import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

typedef TimezoneClock = tz.TZDateTime Function(tz.Location location);

enum ReminderRepeatPattern {
  oneTime,
  daily,
  weekly,
}

class PlannedReminder {
  final int idSlot;
  final tz.TZDateTime scheduledDate;
  final ReminderRepeatPattern repeatPattern;

  const PlannedReminder({
    required this.idSlot,
    required this.scheduledDate,
    required this.repeatPattern,
  });
}

/// Pure scheduling logic shared by the platform notification implementation.
class NotificationSchedulePlanner {
  final tz.Location location;
  final TimezoneClock _clock;

  NotificationSchedulePlanner({
    required this.location,
    TimezoneClock? clock,
  }) : _clock = clock ?? tz.TZDateTime.now;

  tz.TZDateTime nextDailyTime({
    required int hour,
    required int minute,
  }) {
    final now = _clock(location);
    final today = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (today.isAfter(now)) return today;

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tz.TZDateTime(
      location,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour,
      minute,
    );
  }

  List<PlannedReminder> planHabitReminder({
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
  }) {
    final validDays = daysOfWeek
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet()
        .toList()
      ..sort();
    if (validDays.isEmpty) return const [];

    if (validDays.length == DateTime.daysPerWeek) {
      return [
        PlannedReminder(
          idSlot: 0,
          scheduledDate: nextDailyTime(hour: hour, minute: minute),
          repeatPattern: ReminderRepeatPattern.daily,
        ),
      ];
    }

    return [
      for (final day in validDays)
        PlannedReminder(
          idSlot: day,
          scheduledDate: _nextWeeklyTime(
            dayOfWeek: day,
            hour: hour,
            minute: minute,
          ),
          repeatPattern: ReminderRepeatPattern.weekly,
        ),
    ];
  }

  List<PlannedReminder> planOneTimeReminder({
    required int hour,
    required int minute,
    DateTime? scheduledDate,
  }) {
    final now = _clock(location);
    final candidate = scheduledDate == null
        ? nextDailyTime(hour: hour, minute: minute)
        : tz.TZDateTime(
            location,
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            hour,
            minute,
          );
    if (!candidate.isAfter(now)) return const [];

    return [
      PlannedReminder(
        idSlot: 0,
        scheduledDate: candidate,
        repeatPattern: ReminderRepeatPattern.oneTime,
      ),
    ];
  }

  tz.TZDateTime _nextWeeklyTime({
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final now = _clock(location);

    for (var dayOffset = 0; dayOffset <= DateTime.daysPerWeek; dayOffset++) {
      final calendarDate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
      );
      if (calendarDate.weekday != dayOfWeek) continue;

      final candidate = tz.TZDateTime(
        location,
        calendarDate.year,
        calendarDate.month,
        calendarDate.day,
        hour,
        minute,
      );
      if (candidate.isAfter(now)) return candidate;
    }

    throw StateError('Unable to calculate the next weekly reminder.');
  }
}

/// Keeps room for Zentra's daily and Pomodoro notifications on iOS.
abstract final class NotificationPendingBudget {
  static const int iosPendingLimit = 64;
  static const int reservedSystemSlots = 6;

  static int allowedHabitReminders({
    required bool appliesIosLimit,
    required int pendingCount,
    required int requestedCount,
  }) {
    if (!appliesIosLimit) return requestedCount;

    final available = iosPendingLimit - reservedSystemSlots - pendingCount;
    return available.clamp(0, requestedCount).toInt();
  }
}

/// Produces a stable signed 32-bit-safe notification ID across app launches.
///
/// Dart's `String.hashCode` is not a persistence contract, so scheduled
/// notification identifiers must not depend on it.
int stableHabitNotificationId(String habitId, int slot) {
  if (slot < 0 || slot >= DateTime.daysPerWeek + 1) {
    throw RangeError.range(slot, 0, DateTime.daysPerWeek, 'slot');
  }

  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(habitId)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }

  const maxHabitBaseId = 250000000;
  return (hash % maxHabitBaseId) * (DateTime.daysPerWeek + 1) + slot;
}

/// Stable positive ID in a range reserved for one-shot note reminders.
int stableNoteNotificationId(String noteId) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode('note:$noteId')) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }

  const noteRangeStart = 2000000000;
  const noteRangeSize = 147000000;
  return noteRangeStart + (hash % noteRangeSize);
}
