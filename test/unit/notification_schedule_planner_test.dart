import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:zentra/infrastructure/notification_schedule_planner.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('NotificationSchedulePlanner', () {
    test('uses the next local occurrence of a daily time', () {
      final location = tz.getLocation('America/Mexico_City');
      final beforeTime = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 8),
      );
      final afterTime = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 10),
      );

      expect(
        beforeTime.nextDailyTime(hour: 9, minute: 30),
        tz.TZDateTime(location, 2026, 7, 25, 9, 30),
      );
      expect(
        afterTime.nextDailyTime(hour: 9, minute: 30),
        tz.TZDateTime(location, 2026, 7, 26, 9, 30),
      );
    });

    test('collapses an all-week habit into one daily request', () {
      final location = tz.getLocation('America/Mexico_City');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 8),
      );

      final reminders = planner.planHabitReminder(
        hour: 9,
        minute: 0,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.idSlot, 0);
      expect(
        reminders.single.repeatPattern,
        ReminderRepeatPattern.daily,
      );
    });

    test('deduplicates and sorts weekly reminder days', () {
      final location = tz.getLocation('America/Mexico_City');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 8),
      );

      final reminders = planner.planHabitReminder(
        hour: 9,
        minute: 0,
        daysOfWeek: const [5, 1, 5, 9, 3],
      );

      expect(reminders.map((reminder) => reminder.idSlot), [1, 3, 5]);
      expect(
        reminders.every(
          (reminder) => reminder.repeatPattern == ReminderRepeatPattern.weekly,
        ),
        isTrue,
      );
    });

    test('plans a dated task once without a repeat pattern', () {
      final location = tz.getLocation('America/Mexico_City');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 8),
      );

      final reminders = planner.planOneTimeReminder(
        scheduledDate: DateTime(2026, 7, 27),
        hour: 18,
        minute: 30,
      );

      expect(reminders, hasLength(1));
      expect(
        reminders.single.scheduledDate,
        tz.TZDateTime(location, 2026, 7, 27, 18, 30),
      );
      expect(
        reminders.single.repeatPattern,
        ReminderRepeatPattern.oneTime,
      );
    });

    test('plans an undated task only at the next matching time', () {
      final location = tz.getLocation('America/Mexico_City');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 20),
      );

      final reminders = planner.planOneTimeReminder(
        hour: 9,
        minute: 15,
      );

      expect(reminders, hasLength(1));
      expect(
        reminders.single.scheduledDate,
        tz.TZDateTime(location, 2026, 7, 26, 9, 15),
      );
      expect(
        reminders.single.repeatPattern,
        ReminderRepeatPattern.oneTime,
      );
    });

    test('does not schedule a dated task in the past', () {
      final location = tz.getLocation('America/Mexico_City');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2026, 7, 25, 20),
      );

      expect(
        planner.planOneTimeReminder(
          scheduledDate: DateTime(2026, 7, 25),
          hour: 18,
          minute: 30,
        ),
        isEmpty,
      );
    });

    test('preserves wall-clock time across a DST transition', () {
      final location = tz.getLocation('America/New_York');
      final planner = NotificationSchedulePlanner(
        location: location,
        clock: (_) => tz.TZDateTime(location, 2025, 3, 8, 12),
      );

      final next = planner.nextDailyTime(hour: 9, minute: 0);

      expect(next, tz.TZDateTime(location, 2025, 3, 9, 9));
      expect(next.hour, 9);
      expect(next.timeZoneOffset, const Duration(hours: -4));
    });

    test('uses the current location when the user travels', () {
      final mexico = tz.getLocation('America/Mexico_City');
      final tokyo = tz.getLocation('Asia/Tokyo');
      final mexicoPlanner = NotificationSchedulePlanner(
        location: mexico,
        clock: (_) => tz.TZDateTime(mexico, 2026, 7, 25, 8),
      );
      final tokyoPlanner = NotificationSchedulePlanner(
        location: tokyo,
        clock: (_) => tz.TZDateTime(tokyo, 2026, 7, 25, 8),
      );

      expect(
        mexicoPlanner.nextDailyTime(hour: 9, minute: 0).hour,
        9,
      );
      expect(
        tokyoPlanner.nextDailyTime(hour: 9, minute: 0).hour,
        9,
      );
    });
  });

  group('NotificationPendingBudget', () {
    test('reserves iOS slots for system and Pomodoro notifications', () {
      expect(
        NotificationPendingBudget.allowedHabitReminders(
          appliesIosLimit: true,
          pendingCount: 56,
          requestedCount: 7,
        ),
        2,
      );
    });

    test('does not cap Android reminder requests', () {
      expect(
        NotificationPendingBudget.allowedHabitReminders(
          appliesIosLimit: false,
          pendingCount: 100,
          requestedCount: 7,
        ),
        7,
      );
    });
  });

  group('stableHabitNotificationId', () {
    test('is stable and reserves one identifier per slot', () {
      final first = stableHabitNotificationId('habit-viaje', 0);
      final repeated = stableHabitNotificationId('habit-viaje', 0);
      final weeklySlot = stableHabitNotificationId('habit-viaje', 7);

      expect(first, repeated);
      expect(weeklySlot, first + 7);
      expect(first, inInclusiveRange(0, 2000000000));
    });

    test('rejects invalid slots', () {
      expect(
        () => stableHabitNotificationId('habit-viaje', 8),
        throwsRangeError,
      );
    });
  });

  group('stableNoteNotificationId', () {
    test('is stable and isolated from the habit identifier range', () {
      final first = stableNoteNotificationId('note-algebra');
      final repeated = stableNoteNotificationId('note-algebra');
      final other = stableNoteNotificationId('note-biologia');

      expect(first, repeated);
      expect(other, isNot(first));
      expect(first, inInclusiveRange(2000000000, 2146999999));
      expect(first, greaterThan(stableHabitNotificationId('habit', 7)));
    });
  });
}
