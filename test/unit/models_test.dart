import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/models.dart';

void main() {
  group('Category', () {
    test('fromString returns correct category', () {
      expect(Category.fromString('agua'), Category.agua);
      expect(Category.fromString('movimiento'), Category.movimiento);
      expect(Category.fromString('sueno'), Category.sueno);
      expect(Category.fromString('foco'), Category.foco);
      expect(Category.fromString('varios'), Category.varios);
    });

    test('fromString returns varios for unknown', () {
      expect(Category.fromString('nonexistent'), Category.varios);
      expect(Category.fromString(''), Category.varios);
    });

    test('label returns correct Spanish name', () {
      expect(Category.agua.label, 'Agua');
      expect(Category.foco.label, 'Enfoque');
    });
  });

  group('Frequency', () {
    test('daily factory includes all days', () {
      final freq = Frequency.daily();
      expect(freq.isWeekly, isTrue);
      expect(freq.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('weekdays factory includes Mon-Fri', () {
      final freq = Frequency.weekdays();
      expect(freq.daysOfWeek, [1, 2, 3, 4, 5]);
    });

    test('weekends factory includes Sat-Sun', () {
      final freq = Frequency.weekends();
      expect(freq.daysOfWeek, [6, 7]);
    });

    test('manual frequency always applies', () {
      final freq = Frequency.manual();
      expect(freq.appliesTo(DateTime(2025, 1, 6)), isTrue); // Monday
      expect(freq.appliesTo(DateTime(2025, 1, 11)), isTrue); // Saturday
    });

    test('weekly frequency only applies on selected days', () {
      final freq = Frequency.weekdays();
      // Monday Jan 6 2025
      expect(freq.appliesTo(DateTime(2025, 1, 6)), isTrue);
      // Saturday Jan 11 2025
      expect(freq.appliesTo(DateTime(2025, 1, 11)), isFalse);
    });

    test('JSON round-trip', () {
      final freq = Frequency.weekdays();
      final json = freq.toJson();
      final restored = Frequency.fromJson(json);
      expect(restored.isWeekly, freq.isWeekly);
      expect(restored.daysOfWeek, freq.daysOfWeek);
    });

    test('copyWith preserves and overrides', () {
      final freq = Frequency.daily();
      final modified = freq.copyWith(daysOfWeek: [1, 3, 5]);
      expect(modified.isWeekly, isTrue);
      expect(modified.daysOfWeek, [1, 3, 5]);
    });
  });

  group('Habit', () {
    final baseHabit = Habit(
      id: 'test-1',
      title: 'Beber agua',
      category: Category.agua,
      frequency: Frequency.daily(),
      createdAt: DateTime(2025, 1, 1),
    );

    test('isScheduledFor returns true for daily habit on any day', () {
      expect(baseHabit.isScheduledFor(DateTime(2025, 3, 10)), isTrue);
    });

    test('isScheduledFor returns false when archived', () {
      final archived = baseHabit.copyWith(isArchived: true);
      expect(archived.isScheduledFor(DateTime(2025, 3, 10)), isFalse);
    });

    test('one-time habit only scheduled on its specific date', () {
      final oneTime = baseHabit.copyWith(
        isOneTime: true,
        scheduledDate: DateTime(2025, 6, 15),
      );
      expect(oneTime.isScheduledFor(DateTime(2025, 6, 15)), isTrue);
      expect(oneTime.isScheduledFor(DateTime(2025, 6, 16)), isFalse);
    });

    test('JSON round-trip preserves all fields', () {
      final habit = baseHabit.copyWith(
        hasReminder: true,
        reminderHour: 8,
        reminderMinute: 30,
      );
      final json = habit.toJson();
      final restored = Habit.fromJson(json);

      expect(restored.id, habit.id);
      expect(restored.title, habit.title);
      expect(restored.category, habit.category);
      expect(restored.hasReminder, isTrue);
      expect(restored.reminderHour, 8);
      expect(restored.reminderMinute, 30);
    });

    test('copyWith clearScheduledDate nullifies date', () {
      final withDate = baseHabit.copyWith(scheduledDate: DateTime(2025, 1, 1));
      expect(withDate.scheduledDate, isNotNull);
      final cleared = withDate.copyWith(clearScheduledDate: true);
      expect(cleared.scheduledDate, isNull);
    });

    test('copyWith clearReminderTime nullifies both reminder fields', () {
      final withReminder = baseHabit.copyWith(
        hasReminder: true,
        reminderHour: 8,
        reminderMinute: 30,
      );

      final cleared = withReminder.copyWith(
        hasReminder: false,
        clearReminderTime: true,
      );

      expect(cleared.hasReminder, isFalse);
      expect(cleared.reminderHour, isNull);
      expect(cleared.reminderMinute, isNull);
    });
  });

  group('HabitLog', () {
    test('normalizeDate removes time component', () {
      final date = DateTime(2025, 3, 10, 14, 30, 45);
      final normalized = HabitLog.normalizeDate(date);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.day, 10);
    });

    test('JSON round-trip', () {
      final log = HabitLog(
        habitId: 'h1',
        date: DateTime(2025, 3, 10),
      );
      final json = log.toJson();
      final restored = HabitLog.fromJson(json);
      expect(restored.habitId, 'h1');
      expect(restored.date.day, 10);
    });
  });

  group('Weekday', () {
    test('fromValue returns correct weekday', () {
      expect(Weekday.fromValue(1), Weekday.monday);
      expect(Weekday.fromValue(7), Weekday.sunday);
    });

    test('labels are in Spanish', () {
      expect(Weekday.monday.label, 'Lun');
      expect(Weekday.wednesday.shortLabel, 'X');
    });
  });
}
