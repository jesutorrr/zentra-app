import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_freezed.freezed.dart';
part 'habit_freezed.g.dart';

/// Freezed version of Frequency - immutable with generated copyWith, ==, hashCode
@freezed
class FrequencyModel with _$FrequencyModel {
  const FrequencyModel._();

  const factory FrequencyModel({
    required bool isWeekly,
    required List<int> daysOfWeek,
  }) = _FrequencyModel;

  factory FrequencyModel.daily() =>
      const FrequencyModel(isWeekly: true, daysOfWeek: [1, 2, 3, 4, 5, 6, 7]);

  factory FrequencyModel.weekdays() =>
      const FrequencyModel(isWeekly: true, daysOfWeek: [1, 2, 3, 4, 5]);

  factory FrequencyModel.weekends() =>
      const FrequencyModel(isWeekly: true, daysOfWeek: [6, 7]);

  factory FrequencyModel.manual() =>
      const FrequencyModel(isWeekly: false, daysOfWeek: []);

  factory FrequencyModel.fromJson(Map<String, dynamic> json) =>
      _$FrequencyModelFromJson(json);

  bool appliesTo(DateTime date) {
    if (!isWeekly) return true;
    return daysOfWeek.contains(date.weekday);
  }
}

/// Freezed version of Habit entity - immutable with generated serialization
@freezed
class HabitModel with _$HabitModel {
  const HabitModel._();

  const factory HabitModel({
    required String id,
    required String title,
    required String category,
    required FrequencyModel frequency,
    required DateTime createdAt,
    @Default(false) bool isArchived,
    @Default(false) bool isOneTime,
    DateTime? scheduledDate,
    @Default(false) bool hasReminder,
    int? reminderHour,
    int? reminderMinute,
  }) = _HabitModel;

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);

  bool isScheduledFor(DateTime date) {
    if (isArchived) return false;
    if (isOneTime && scheduledDate != null) {
      return scheduledDate!.year == date.year &&
          scheduledDate!.month == date.month &&
          scheduledDate!.day == date.day;
    }
    return frequency.appliesTo(date);
  }
}

/// Freezed version of HabitLog - immutable with value equality
@freezed
class HabitLogModel with _$HabitLogModel {
  const HabitLogModel._();

  const factory HabitLogModel({
    required String habitId,
    required DateTime date,
  }) = _HabitLogModel;

  factory HabitLogModel.fromJson(Map<String, dynamic> json) =>
      _$HabitLogModelFromJson(json);

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool matches(String habitId, DateTime date) {
    final normalizedLogDate = normalizeDate(this.date);
    final normalizedTargetDate = normalizeDate(date);
    return this.habitId == habitId &&
        normalizedLogDate.isAtSameMomentAs(normalizedTargetDate);
  }
}

/// Freezed version of CompletedTask
@freezed
class CompletedTaskModel with _$CompletedTaskModel {
  const factory CompletedTaskModel({
    required String id,
    required String title,
    required String category,
    required DateTime completedAt,
    required bool wasOneTime,
  }) = _CompletedTaskModel;

  factory CompletedTaskModel.fromJson(Map<String, dynamic> json) =>
      _$CompletedTaskModelFromJson(json);
}

/// Freezed version of PomodoroActivity
@freezed
class PomodoroActivityModel with _$PomodoroActivityModel {
  const PomodoroActivityModel._();

  const factory PomodoroActivityModel({
    required String id,
    required String name,
    required DateTime startTime,
    DateTime? endTime,
    @Default(0) int cyclesCompleted,
    @Default(0) int totalMinutes,
    @Default(false) bool isCompleted,
  }) = _PomodoroActivityModel;

  factory PomodoroActivityModel.fromJson(Map<String, dynamic> json) =>
      _$PomodoroActivityModelFromJson(json);

  String get formattedStartTime =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  String get formattedEndTime {
    if (endTime == null) return '--:--';
    return '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  String get durationString {
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}h ${mins}m';
  }

  DateTime get dateOnly =>
      DateTime(startTime.year, startTime.month, startTime.day);
}
