import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/models.dart';
import 'isar_schemas.dart';

/// High-performance Isar implementation of HabitRepository.
///
/// Replaces SharedPreferences JSON storage with indexed NoSQL queries.
/// Supports user-scoped data, efficient date-range queries, and
/// category-based filtering without full deserialization.
class IsarRepository implements HabitRepository {
  final Isar _isar;
  String? _currentUserId;

  IsarRepository._(this._isar);

  /// Initialize Isar and open the database.
  static Future<IsarRepository> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        HabitSchemaSchema,
        HabitLogSchemaSchema,
        CompletedTaskSchemaSchema,
        PomodoroActivitySchemaSchema,
      ],
      directory: dir.path,
    );
    return IsarRepository._(isar);
  }

  @override
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  // ---------- Habits ----------

  @override
  Future<List<Habit>> getHabits() async {
    final results = await _isar.habitSchemas
        .filter()
        .userIdEqualTo(_currentUserId)
        .findAll();

    return results.map(_schemaToHabit).toList();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    await _isar.writeTxn(() async {
      await _isar.habitSchemas.put(_habitToSchema(habit));
    });
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.habitSchemas
          .filter()
          .idEqualTo(habit.id)
          .findFirst();
      if (existing != null) {
        final updated = _habitToSchema(habit)..isarId = existing.isarId;
        await _isar.habitSchemas.put(updated);
      }
    });
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _isar.writeTxn(() async {
      await _isar.habitSchemas.filter().idEqualTo(habitId).deleteAll();
      await _isar.habitLogSchemas.filter().habitIdEqualTo(habitId).deleteAll();
    });
  }

  // ---------- Logs ----------

  @override
  Future<List<HabitLog>> getAllLogs() async {
    final results = await _isar.habitLogSchemas
        .filter()
        .userIdEqualTo(_currentUserId)
        .findAll();

    return results
        .map((s) => HabitLog(habitId: s.habitId, date: s.date))
        .toList();
  }

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final nextDay = normalized.add(const Duration(days: 1));

    final results = await _isar.habitLogSchemas
        .filter()
        .userIdEqualTo(_currentUserId)
        .dateBetween(normalized, nextDay, includeLower: true, includeUpper: false)
        .findAll();

    return results
        .map((s) => HabitLog(habitId: s.habitId, date: s.date))
        .toList();
  }

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final compositeKey = '${habitId}_${normalized.toIso8601String()}';

    await _isar.writeTxn(() async {
      final existing = await _isar.habitLogSchemas
          .filter()
          .habitIdDateEqualTo(compositeKey)
          .findFirst();

      if (existing != null) {
        await _isar.habitLogSchemas.delete(existing.isarId);
      } else {
        final schema = HabitLogSchema()
          ..habitId = habitId
          ..date = normalized
          ..userId = _currentUserId
          ..habitIdDate = compositeKey;
        await _isar.habitLogSchemas.put(schema);
      }
    });
  }

  // ---------- Converters ----------

  HabitSchema _habitToSchema(Habit habit) {
    return HabitSchema()
      ..id = habit.id
      ..title = habit.title
      ..category = _categoryToIsar(habit.category)
      ..isWeekly = habit.frequency.isWeekly
      ..daysOfWeek = habit.frequency.daysOfWeek
      ..createdAt = habit.createdAt
      ..isArchived = habit.isArchived
      ..isOneTime = habit.isOneTime
      ..scheduledDate = habit.scheduledDate
      ..hasReminder = habit.hasReminder
      ..reminderHour = habit.reminderHour
      ..reminderMinute = habit.reminderMinute
      ..userId = _currentUserId;
  }

  Habit _schemaToHabit(HabitSchema s) {
    return Habit(
      id: s.id,
      title: s.title,
      category: _isarToCategory(s.category),
      frequency: Frequency(isWeekly: s.isWeekly, daysOfWeek: s.daysOfWeek),
      createdAt: s.createdAt,
      isArchived: s.isArchived,
      isOneTime: s.isOneTime,
      scheduledDate: s.scheduledDate,
      hasReminder: s.hasReminder,
      reminderHour: s.reminderHour,
      reminderMinute: s.reminderMinute,
    );
  }

  HabitCategory _categoryToIsar(Category c) {
    switch (c) {
      case Category.agua:
        return HabitCategory.agua;
      case Category.movimiento:
        return HabitCategory.movimiento;
      case Category.sueno:
        return HabitCategory.sueno;
      case Category.foco:
        return HabitCategory.foco;
      case Category.varios:
        return HabitCategory.varios;
    }
  }

  Category _isarToCategory(HabitCategory c) {
    switch (c) {
      case HabitCategory.agua:
        return Category.agua;
      case HabitCategory.movimiento:
        return Category.movimiento;
      case HabitCategory.sueno:
        return Category.sueno;
      case HabitCategory.foco:
        return Category.foco;
      case HabitCategory.varios:
        return Category.varios;
    }
  }

  /// Close the Isar database.
  Future<void> close() async {
    await _isar.close();
  }
}
