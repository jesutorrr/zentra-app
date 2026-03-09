import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../domain/models.dart';
import '../infrastructure/siri_shortcuts_service.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/app_logger.dart';

/// State management for habits using ChangeNotifier
class HabitProvider with ChangeNotifier {
  final HabitRepository _repository;

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  List<CompletedTask> _completedTasks = []; // Historial de tareas terminadas/eliminadas
  bool _isLoading = false;
  bool _isImporting = false; // Flag para evitar celebraciones durante importación
  String? _error;
  String? _currentUserId;

  HabitProvider(this._repository);

  // Getters
  List<Habit> get habits => _habits;
  List<HabitLog> get logs => _logs;
  List<CompletedTask> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get error => _error;

  /// Initialize and load data
  Future<void> initialize() async {
    await loadHabits();
    await loadLogs();
    await loadCompletedTasks();
  }

  /// Set the current user and reload data
  Future<void> setCurrentUser(String? userId, {bool isImporting = false}) async {
    // Set importing flag to prevent celebration dialogs
    _isImporting = isImporting;
    
    // Clear current data
    _habits = [];
    _logs = [];
    _completedTasks = [];
    _currentUserId = userId;
    notifyListeners();

    // Set the user in repository and reload data
    _repository.setCurrentUser(userId);
    await initialize();
    
    // Clear importing flag after a short delay to let UI settle
    if (isImporting) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isImporting = false;
        notifyListeners();
      });
    }
  }

  /// Get the storage key for completed tasks (user-specific if logged in)
  String get _completedTasksKey => _currentUserId != null 
      ? 'completed_tasks_$_currentUserId' 
      : 'completed_tasks';

  /// Load all habits from repository
  Future<void> loadHabits() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _habits = await _repository.getHabits();
    } catch (e) {
      _error = 'Error loading habits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all logs from repository
  Future<void> loadLogs() async {
    try {
      _logs = await _repository.getAllLogs();
      notifyListeners();
    } catch (e) {
      _error = 'Error loading logs: $e';
      notifyListeners();
    }
  }

  /// Load completed tasks history from SharedPreferences
  Future<void> loadCompletedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_completedTasksKey);
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        _completedTasks = data
            .map((e) => CompletedTask.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort by most recent first
        _completedTasks.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error loading completed tasks: $e';
    }
  }

  /// Save completed tasks to SharedPreferences
  Future<void> _saveCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_completedTasks.map((t) => t.toJson()).toList());
    await prefs.setString(_completedTasksKey, json);
  }

  /// Add task to completed history
  Future<void> _addToCompletedTasks(Habit habit, bool wasOneTime) async {
    final completedTask = CompletedTask(
      id: habit.id,
      title: habit.title,
      category: habit.category,
      completedAt: DateTime.now(),
      wasOneTime: wasOneTime,
    );
    _completedTasks.insert(0, completedTask);
    await _saveCompletedTasks();
    notifyListeners();
  }

  /// Clear all completed tasks (empty trash)
  Future<void> clearCompletedTasks() async {
    _completedTasks.clear();
    await _saveCompletedTasks();
    notifyListeners();
  }

  /// Get habits scheduled for a specific date
  List<Habit> getHabitsForDate(DateTime date) {
    return _habits.where((habit) => habit.isScheduledFor(date)).toList();
  }

  /// Get habits scheduled for today
  List<Habit> getTodayHabits() {
    final today = DateTime.now();
    return getHabitsForDate(today);
  }

  /// Check if a habit is completed on a specific date
  bool isHabitCompleted(String habitId, DateTime date) {
    return _logs.any((log) => log.matches(habitId, date));
  }

  /// Check if a habit is completed today
  bool isHabitCompletedToday(String habitId) {
    return isHabitCompleted(habitId, DateTime.now());
  }

  /// Get completion count for a specific date
  int getCompletionCount(DateTime date) {
    final habitsForDate = getHabitsForDate(date);
    return habitsForDate.where((habit) => isHabitCompleted(habit.id, date)).length;
  }

  /// Get total habits count for a specific date
  int getTotalHabitsCount(DateTime date) {
    return getHabitsForDate(date).length;
  }

  /// Calculate daily progress (0.0 to 1.0)
  double getDailyProgress(DateTime date) {
    final total = getTotalHabitsCount(date);
    if (total == 0) return 0.0;
    
    final completed = getCompletionCount(date);
    return completed / total;
  }

  /// Get today's progress
  double getTodayProgress() {
    return getDailyProgress(DateTime.now());
  }

  /// Get today's completion stats
  Map<String, int> getTodayStats() {
    final today = DateTime.now();
    return {
      'completed': getCompletionCount(today),
      'total': getTotalHabitsCount(today),
    };
  }

  /// Toggle habit completion for today
  Future<void> toggleHabitToday(String habitId) async {
    await toggleHabit(habitId, DateTime.now());
  }

  /// Toggle habit completion for a specific date
  /// If it's a one-time task and being completed, move it to history
  Future<void> toggleHabit(String habitId, DateTime date) async {
    try {
      final logger = AppLogger();
      final habit = getHabitById(habitId);
      final wasCompleted = isHabitCompleted(habitId, date);
      final statsBefore = getTodayStats();
      logger.info(
        'HabitProvider',
        'toggleHabit: id=$habitId, wasCompleted=$wasCompleted, before stats=${statsBefore['completed']}/${statsBefore['total']}',
      );
      
      await _repository.toggleLog(habitId, date);
      await loadLogs();

      final statsAfter = getTodayStats();
      logger.info(
        'HabitProvider',
        'toggleHabit: id=$habitId, after stats=${statsAfter['completed']}/${statsAfter['total']}',
      );
      
      // Donate Siri Shortcut when completing a habit (not uncompleting)
      if (habit != null && !wasCompleted) {
        SiriShortcutsService().donateCompleteHabitShortcut(habitId, habit.title);
      }
      
      // If this is a one-time task being completed (not uncompleted)
      if (habit != null && habit.isOneTime && !wasCompleted) {
        // Add to completed tasks history
        await _addToCompletedTasks(habit, true);
        // Cancel any scheduled notifications for this task
        try {
          final notificationService = NotificationService();
          await notificationService.initialize();
          await notificationService.cancelHabitReminder(habitId);
        } catch (e) {
          logger.error('HabitProvider', 'Error canceling notification for completed one-time task', e);
        }
        // Delete the habit (it's done)
        await _repository.deleteHabit(habitId);
        await loadHabits();
      }
    } catch (e) {
      _error = 'Error toggling habit: $e';
      notifyListeners();
    }
  }

  /// Create a new habit
  Future<void> createHabit(Habit habit) async {
    final logger = AppLogger();
    logger.info('HabitProvider', 'createHabit called for habit: ${habit.title}');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      logger.info('HabitProvider', 'Calling repository.saveHabit...');
      await _repository.saveHabit(habit);
      logger.info('HabitProvider', 'saveHabit completed, calling loadHabits...');
      await loadHabits();
      logger.info('HabitProvider', 'loadHabits completed, habits count: ${_habits.length}');
    } catch (e, stack) {
      logger.error('HabitProvider', 'Error in createHabit', e, stack);
      _error = 'Error creating habit: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateHabit(habit);
      await loadHabits();
    } catch (e) {
      _error = 'Error updating habit: $e';
      _isLoading = false;
      notifyListeners();
      rethrow; // Propagate error to caller
    }
  }

  /// Delete a habit (adds to history if it's a recurring task)
  Future<void> deleteHabit(String habitId, {bool addToHistory = true}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Add to completed tasks history if it's a recurring habit being deleted
      if (addToHistory) {
        final habit = getHabitById(habitId);
        if (habit != null && !habit.isOneTime) {
          await _addToCompletedTasks(habit, false);
        }
      }

      await _repository.deleteHabit(habitId);
      await loadHabits();
      await loadLogs();
    } catch (e) {
      _error = 'Error deleting habit: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get habit by ID
  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((habit) => habit.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Toggle archive status of a habit
  Future<void> toggleArchive(String habitId) async {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    final updatedHabit = habit.copyWith(isArchived: !habit.isArchived);
    await updateHabit(updatedHabit);
  }

  /// Get only active (non-archived) habits
  List<Habit> get activeHabits => _habits.where((h) => !h.isArchived).toList();

  /// Get only archived habits
  List<Habit> get archivedHabits => _habits.where((h) => h.isArchived).toList();

  /// Get progress data for the last N days (for charts)
  /// Returns a list of maps with date, completed, total, and progress
  List<Map<String, dynamic>> getProgressHistory(int days) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final habitsForDate = _getActiveHabitsForDate(date);
      final total = habitsForDate.length;
      final completed = habitsForDate
          .where((habit) => isHabitCompleted(habit.id, date))
          .length;

      result.add({
        'date': date,
        'completed': completed,
        'total': total,
        'progress': total > 0 ? completed / total : 0.0,
      });
    }

    return result;
  }

  /// Get active habits that were scheduled for a specific date
  /// (ignoring current archive status for historical accuracy)
  List<Habit> _getActiveHabitsForDate(DateTime date) {
    return _habits.where((habit) {
      // For historical data, we check if the frequency applies
      // regardless of current archive status
      return habit.frequency.appliesTo(date);
    }).toList();
  }

  /// Get weekly average progress (0.0 to 1.0)
  double getWeeklyAverageProgress() {
    final history = getProgressHistory(kWeeklyProgressDays);
    final validDays = history.where((d) => d['total'] > 0).toList();
    
    if (validDays.isEmpty) return 0.0;
    
    final totalProgress = validDays.fold<double>(
      0.0,
      (sum, day) => sum + (day['progress'] as double),
    );
    
    return totalProgress / validDays.length;
  }

  /// Get habits detail for a specific date with completion status
  /// Returns list of maps with habit and its completion status for that day
  List<Map<String, dynamic>> getHabitsDetailForDate(DateTime date) {
    final habitsForDate = _getActiveHabitsForDate(date);
    return habitsForDate.map((habit) {
      return {
        'habit': habit,
        'completed': isHabitCompleted(habit.id, date),
      };
    }).toList();
  }

  /// Calculate current streak for a habit (consecutive days completed)
  int getHabitStreak(String habitId) {
    final habit = getHabitById(habitId);
    if (habit == null) return 0;

    int streak = 0;
    final now = DateTime.now();
    
    // Start from yesterday (today might not be completed yet)
    // But if today is completed, we count from today
    final startOffset = isHabitCompleted(habitId, now) ? 0 : 1;
    
    for (int i = startOffset; i < 365; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      
      // Check if the habit was scheduled for this date
      if (!habit.frequency.appliesTo(date)) {
        continue; // Skip days when habit wasn't scheduled
      }
      
      // Check if completed
      if (isHabitCompleted(habitId, date)) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    
    return streak;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
