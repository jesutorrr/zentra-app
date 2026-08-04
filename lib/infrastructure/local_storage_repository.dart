import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

/// Implementation of HabitRepository using SharedPreferences
/// Supports user-specific data storage
class LocalStorageRepository implements HabitRepository {
  static const String _habitsKey = 'habits';
  static const String _logsKey = 'habit_logs';

  final SharedPreferences _prefs;
  final String? _lockedOwnerId;
  String? _currentUserId;

  LocalStorageRepository(this._prefs) : _lockedOwnerId = null;

  /// Creates a repository instance permanently scoped to [ownerId].
  LocalStorageRepository.forOwner(
    this._prefs, {
    required String ownerId,
  })  : _lockedOwnerId = _validateOwnerId(ownerId),
        _currentUserId = ownerId;

  /// Factory constructor to initialize with SharedPreferences
  static Future<LocalStorageRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageRepository(prefs);
  }

  String? get currentUserId => _currentUserId;

  /// Set the current user ID to use user-specific storage keys
  @override
  void setCurrentUser(String? userId) {
    final lockedOwnerId = _lockedOwnerId;
    if (lockedOwnerId != null && userId != lockedOwnerId) {
      throw StateError(
        'This repository is locked to owner $lockedOwnerId '
        'and cannot switch to ${userId ?? 'no owner'}.',
      );
    }
    _currentUserId = userId;
  }

  /// Get the storage key for habits (user-specific if logged in)
  String get _userHabitsKey =>
      _currentUserId != null ? '${_habitsKey}_$_currentUserId' : _habitsKey;

  /// Get the storage key for logs (user-specific if logged in)
  String get _userLogsKey =>
      _currentUserId != null ? '${_logsKey}_$_currentUserId' : _logsKey;

  @override
  Future<List<Habit>> getHabits() async {
    try {
      final String? habitsJson = _prefs.getString(_userHabitsKey);
      if (habitsJson == null || habitsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(habitsJson);
      return decodedList
          .map((json) => Habit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await _saveHabitsList(habits);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);

    if (index != -1) {
      habits[index] = habit;
      await _saveHabitsList(habits);
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == habitId);
    await _saveHabitsList(habits);

    // Also remove all logs for this habit
    final logs = await getAllLogs();
    logs.removeWhere((log) => log.habitId == habitId);
    await _saveLogsList(logs);
  }

  /// Helper method to save the habits list
  Future<void> _saveHabitsList(List<Habit> habits) async {
    final List<Map<String, dynamic>> jsonList =
        habits.map((h) => h.toJson()).toList();
    final String encoded = jsonEncode(jsonList);
    await _prefs.setString(_userHabitsKey, encoded);
  }

  @override
  Future<List<HabitLog>> getAllLogs() async {
    try {
      final String? logsJson = _prefs.getString(_userLogsKey);
      if (logsJson == null || logsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = jsonDecode(logsJson);
      return decodedList
          .map((json) => HabitLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final allLogs = await getAllLogs();
    final normalizedDate = HabitLog.normalizeDate(date);

    return allLogs.where((log) {
      final logDate = HabitLog.normalizeDate(log.date);
      return logDate.isAtSameMomentAs(normalizedDate);
    }).toList();
  }

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final logs = await getAllLogs();
    final normalizedDate = HabitLog.normalizeDate(date);

    // Check if log already exists
    final existingIndex = logs.indexWhere((log) => log.matches(habitId, date));

    if (existingIndex != -1) {
      // Remove existing log
      logs.removeAt(existingIndex);
    } else {
      // Add new log
      logs.add(HabitLog(habitId: habitId, date: normalizedDate));
    }

    await _saveLogsList(logs);
  }

  /// Helper method to save the logs list
  Future<void> _saveLogsList(List<HabitLog> logs) async {
    final List<Map<String, dynamic>> jsonList =
        logs.map((log) => log.toJson()).toList();
    final String encoded = jsonEncode(jsonList);
    await _prefs.setString(_userLogsKey, encoded);
  }
}

String _validateOwnerId(String ownerId) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'Must not be blank.');
  }
  return ownerId;
}
