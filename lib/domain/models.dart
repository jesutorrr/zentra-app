// Pure Dart - No Flutter dependencies

/// Categories for organizing habits
enum Category {
  agua('Agua'),
  movimiento('Movimiento'),
  sueno('Sueño'),
  foco('Enfoque'),
  varios('Varios');

  final String label;
  const Category(this.label);

  static Category fromString(String value) {
    return Category.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Category.varios,
    );
  }
}

/// Weekday enum for frequency selection
enum Weekday {
  monday(1, 'Lun', 'L'),
  tuesday(2, 'Mar', 'M'),
  wednesday(3, 'Mié', 'X'),
  thursday(4, 'Jue', 'J'),
  friday(5, 'Vie', 'V'),
  saturday(6, 'Sáb', 'S'),
  sunday(7, 'Dom', 'D');

  final int value;
  final String label;
  final String shortLabel;
  const Weekday(this.value, this.label, this.shortLabel);

  static Weekday fromValue(int value) {
    return Weekday.values.firstWhere((w) => w.value == value);
  }
}

/// Frequency configuration for habits
class Frequency {
  final bool isWeekly;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday (DateTime standard)

  const Frequency({
    required this.isWeekly,
    required this.daysOfWeek,
  });

  /// Factory: Create a daily frequency (all days)
  factory Frequency.daily() {
    return const Frequency(
      isWeekly: true,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    );
  }

  /// Factory: Create a weekdays frequency (Mon-Fri)
  factory Frequency.weekdays() {
    return const Frequency(
      isWeekly: true,
      daysOfWeek: [1, 2, 3, 4, 5],
    );
  }

  /// Factory: Create a weekends frequency (Sat-Sun)
  factory Frequency.weekends() {
    return const Frequency(
      isWeekly: true,
      daysOfWeek: [6, 7],
    );
  }

  /// Factory: Create a manual frequency (no specific days)
  factory Frequency.manual() {
    return const Frequency(
      isWeekly: false,
      daysOfWeek: [],
    );
  }

  /// Check if this frequency applies to a given date
  bool appliesTo(DateTime date) {
    if (!isWeekly) {
      // Manual frequency always applies
      return true;
    }
    return daysOfWeek.contains(date.weekday);
  }

  Map<String, dynamic> toJson() {
    return {
      'isWeekly': isWeekly,
      'daysOfWeek': daysOfWeek,
    };
  }

  factory Frequency.fromJson(Map<String, dynamic> json) {
    return Frequency(
      isWeekly: json['isWeekly'] as bool,
      daysOfWeek: (json['daysOfWeek'] as List).cast<int>(),
    );
  }

  Frequency copyWith({
    bool? isWeekly,
    List<int>? daysOfWeek,
  }) {
    return Frequency(
      isWeekly: isWeekly ?? this.isWeekly,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }
}

/// Habit entity
class Habit {
  final String id;
  final String title;
  final Category category;
  final Frequency frequency;
  final DateTime createdAt;
  final bool isArchived;
  final bool isOneTime; // Tarea única - desaparece al completarse
  final DateTime?
      scheduledDate; // Fecha específica para tareas únicas en calendario
  final bool hasReminder; // Si tiene recordatorio activo
  final int? reminderHour; // Hora del recordatorio (0-23)
  final int? reminderMinute; // Minuto del recordatorio (0-59)

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    required this.createdAt,
    this.isArchived = false,
    this.isOneTime = false,
    this.scheduledDate,
    this.hasReminder = false,
    this.reminderHour,
    this.reminderMinute,
  });

  /// Check if this habit is scheduled for a specific date
  /// Returns false if the habit is archived
  /// For one-time tasks with scheduledDate, only returns true on that exact date
  bool isScheduledFor(DateTime date) {
    if (isArchived) return false;

    // Tareas únicas con fecha específica: solo aparecen ese día
    if (isOneTime && scheduledDate != null) {
      return scheduledDate!.year == date.year &&
          scheduledDate!.month == date.month &&
          scheduledDate!.day == date.day;
    }

    return frequency.appliesTo(date);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'frequency': frequency.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
      'isOneTime': isOneTime,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'hasReminder': hasReminder,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      category: Category.fromString(json['category'] as String),
      frequency: Frequency.fromJson(json['frequency'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      isOneTime: json['isOneTime'] as bool? ?? false,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      hasReminder: json['hasReminder'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int?,
      reminderMinute: json['reminderMinute'] as int?,
    );
  }

  Habit copyWith({
    String? id,
    String? title,
    Category? category,
    Frequency? frequency,
    DateTime? createdAt,
    bool? isArchived,
    bool? isOneTime,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    bool? hasReminder,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminderTime = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      isOneTime: isOneTime ?? this.isOneTime,
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      hasReminder: hasReminder ?? this.hasReminder,
      reminderHour:
          clearReminderTime ? null : (reminderHour ?? this.reminderHour),
      reminderMinute:
          clearReminderTime ? null : (reminderMinute ?? this.reminderMinute),
    );
  }
}

/// Log entry for habit completion
class HabitLog {
  final String habitId;
  final DateTime date;

  const HabitLog({
    required this.habitId,
    required this.date,
  });

  /// Create a normalized date (date only, no time)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check if this log matches a specific habit and date
  bool matches(String habitId, DateTime date) {
    final normalizedLogDate = normalizeDate(this.date);
    final normalizedTargetDate = normalizeDate(date);
    return this.habitId == habitId &&
        normalizedLogDate.isAtSameMomentAs(normalizedTargetDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'date': date.toIso8601String(),
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Repository interface - Pure Dart contract
abstract class HabitRepository {
  /// Set the current user ID for data isolation
  void setCurrentUser(String? userId);

  /// Get all habits
  Future<List<Habit>> getHabits();

  /// Save a new habit
  Future<void> saveHabit(Habit habit);

  /// Update an existing habit
  Future<void> updateHabit(Habit habit);

  /// Delete a habit
  Future<void> deleteHabit(String habitId);

  /// Get all logs for a specific date
  Future<List<HabitLog>> getLogsForDate(DateTime date);

  /// Get all logs
  Future<List<HabitLog>> getAllLogs();

  /// Toggle a habit log (add if not exists, remove if exists)
  Future<void> toggleLog(String habitId, DateTime date);
}

/// Completed/Deleted task for history (trash)
class CompletedTask {
  final String id;
  final String title;
  final Category category;
  final DateTime completedAt;
  final bool
      wasOneTime; // true = tarea única completada, false = recurrente eliminada

  const CompletedTask({
    required this.id,
    required this.title,
    required this.category,
    required this.completedAt,
    required this.wasOneTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'completedAt': completedAt.toIso8601String(),
      'wasOneTime': wasOneTime,
    };
  }

  factory CompletedTask.fromJson(Map<String, dynamic> json) {
    return CompletedTask(
      id: json['id'] as String,
      title: json['title'] as String,
      category: Category.fromString(json['category'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      wasOneTime: json['wasOneTime'] as bool? ?? false,
    );
  }
}
