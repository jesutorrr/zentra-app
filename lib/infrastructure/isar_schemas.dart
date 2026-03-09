import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

/// Isar schema for Habit entity.
/// Run `dart run build_runner build` to generate the adapter.
@collection
class HabitSchema {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;

  @Enumerated(EnumType.name)
  late HabitCategory category;

  late bool isWeekly;
  late List<int> daysOfWeek;

  late DateTime createdAt;
  late bool isArchived;
  late bool isOneTime;
  DateTime? scheduledDate;
  late bool hasReminder;
  int? reminderHour;
  int? reminderMinute;

  @Index()
  String? userId;
}

/// Isar schema for HabitLog.
@collection
class HabitLogSchema {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String habitId;

  @Index()
  late DateTime date;

  @Index()
  String? userId;

  @Index(composite: [CompositeIndex('date')])
  late String habitIdDate;
}

/// Isar schema for CompletedTask (trash/history).
@collection
class CompletedTaskSchema {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String title;

  @Enumerated(EnumType.name)
  late HabitCategory category;

  late DateTime completedAt;
  late bool wasOneTime;

  @Index()
  String? userId;
}

/// Isar schema for PomodoroActivity.
@collection
class PomodoroActivitySchema {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  late DateTime startTime;
  DateTime? endTime;
  late int cyclesCompleted;
  late int totalMinutes;
  late bool isCompleted;

  @Index()
  String? userId;
}

/// Enum mirroring domain Category for Isar serialization.
enum HabitCategory {
  agua,
  movimiento,
  sueno,
  foco,
  varios,
}
