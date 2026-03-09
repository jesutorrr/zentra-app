import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../infrastructure/live_activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../domain/pomodoro_activity.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/app_logger.dart';

/// Pomodoro timer states
enum PomodoroState {
  idle,      // Not started
  running,   // Timer is running
  paused,    // Timer is paused
  finished,  // Timer completed
}

/// Pomodoro session type
enum SessionType {
  work,       // Work session (25 min default)
  shortBreak, // Short break (5 min default)
  longBreak,  // Long break (15 min default)
}

/// Pomodoro Timer Provider with Activity Support
class PomodoroProvider with ChangeNotifier {
  // Static flag to track if pomodoro was recently active (for notification tap handling)
  static bool wasRecentlyActive = false;
  
  // Timer configuration (in minutes)
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  final int _pomodorosUntilLongBreak = 4;
  String? _currentUserId;
  
  // Notification service
  final NotificationService _notificationService = NotificationService();
  
  // Live Activity service
  final LiveActivityService _liveActivityService = LiveActivityService();
  String? _liveActivityId;
  
  // Foreground service flag
  bool _foregroundServiceRunning = false;
  
  // Alarm settings
  bool _alarmEnabled = false;

  // Storage key getters (user-specific if logged in)
  String get _totalKey => _currentUserId != null ? 'pomodoro_total_$_currentUserId' : 'pomodoro_total';
  String get _todayKey => _currentUserId != null ? 'pomodoro_today_$_currentUserId' : 'pomodoro_today';
  String get _totalMinutesKey => _currentUserId != null ? 'pomodoro_total_minutes_$_currentUserId' : 'pomodoro_total_minutes';
  String get _todayMinutesKey => _currentUserId != null ? 'pomodoro_today_minutes_$_currentUserId' : 'pomodoro_today_minutes';
  String get _lastDateKey => _currentUserId != null ? 'pomodoro_last_date_$_currentUserId' : 'pomodoro_last_date';
  String get _firstDateKey => _currentUserId != null ? 'pomodoro_first_date_$_currentUserId' : 'pomodoro_first_date';
  String get _activitiesKey => _currentUserId != null ? 'pomodoro_activities_$_currentUserId' : 'pomodoro_activities';

  // Current state
  PomodoroState _state = PomodoroState.idle;
  SessionType _sessionType = SessionType.work;
  int _remainingSeconds = 25 * 60;
  int _completedPomodoros = 0; // Session counter (resets after long break)
  int _todayPomodoros = 0;
  int _totalPomodoros = 0;
  int _todayRealMinutes = 0; // Actual minutes worked today
  int _totalRealMinutes = 0; // Actual total minutes worked
  DateTime? _lastPomodoroDate;
  DateTime? _firstPomodoroDate;
  DateTime? _sessionStartTime; // Track when current session started
  DateTime? _timerEndTime; // When the timer should end (for background support)

  Timer? _timer;

  // Activity tracking
  PomodoroActivity? _currentActivity;
  List<PomodoroActivity> _activityHistory = [];
  int _activityCyclesCompleted = 0;
  // ignore: unused_field
  int _activityMinutesCompleted = 0;
  bool _activityPendingCompletion = false; // Activity finished work, waiting for long break
  PomodoroActivity? _justCompletedActivity; // For showing celebration

  // Getters
  PomodoroState get state => _state;
  SessionType get sessionType => _sessionType;
  int get remainingSeconds => _remainingSeconds;
  int get completedPomodoros => _completedPomodoros;
  int get todayPomodoros => _todayPomodoros;
  int get totalPomodoros => _totalPomodoros;
  DateTime? get firstPomodoroDate => _firstPomodoroDate;
  
  /// Actual minutes of focus today (calculated from completed activities for consistency with history)
  int get todayMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _activityHistory
        .where((a) => a.isCompleted && a.dateOnly == today)
        .fold(0, (sum, a) => sum + a.totalMinutes);
  }
  
  /// Actual total minutes of focus
  int get totalMinutes => _totalRealMinutes;
  
  /// Total hours of focus formatted
  String get totalHoursFormatted {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '$hours hrs';
    return '$hours.${(mins * 10 ~/ 60)} hrs';
  }
  
  int get workDuration => _workDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;

  // Activity getters
  PomodoroActivity? get currentActivity => _currentActivity;
  List<PomodoroActivity> get activityHistory => _activityHistory;
  bool get hasActiveActivity => _currentActivity != null;
  bool get isActivityPendingCompletion => _activityPendingCompletion;
  int get activityCyclesCompleted => _activityCyclesCompleted;
  PomodoroActivity? get justCompletedActivity => _justCompletedActivity;
  
  // Alarm getter
  bool get alarmEnabled => _alarmEnabled;
  
  /// Activities completed today
  int get todayActivities {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _activityHistory.where(
      (a) => a.isCompleted && a.dateOnly == today,
    ).length;
  }
  
  /// Total activities completed
  int get totalActivities => _activityHistory.where((a) => a.isCompleted).length;
  
  /// Clear the just completed activity (call after showing celebration)
  void clearJustCompletedActivity() {
    _justCompletedActivity = null;
    notifyListeners();
  }
  
  /// True if we're in the final long break of an activity (ready to complete)
  /// This is when we have 3 cycles done and are in the long break (4th cycle's break)
  bool get isActivityFinalBreak => 
      _currentActivity != null && 
      _activityCyclesCompleted >= 3 && 
      _sessionType == SessionType.longBreak;

  // Formatted time
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Progress (0.0 to 1.0)
  double get progress {
    final totalSeconds = _getCurrentSessionDuration() * 60;
    if (totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  // Session label
  String get sessionLabel {
    switch (_sessionType) {
      case SessionType.work:
        return _currentActivity != null ? _currentActivity!.name : 'Enfócate';
      case SessionType.shortBreak:
        return 'Descanso corto';
      case SessionType.longBreak:
        return 'Descanso largo';
    }
  }

  // Is break?
  bool get isBreak => _sessionType != SessionType.work;

  /// Get activities grouped by day (last 30 days)
  List<DailyPomodoroSummary> get dailySummaries {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: kPomodoroRetentionDays));
    
    // Filter activities from last 30 days
    final recentActivities = _activityHistory.where((a) => 
      a.startTime.isAfter(cutoffDate),
    ).toList();

    // Group by date
    final Map<DateTime, List<PomodoroActivity>> grouped = {};
    for (final activity in recentActivities) {
      final dateKey = activity.dateOnly;
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(activity);
    }

    // Convert to summaries and sort by date (newest first)
    final summaries = grouped.entries
        .map((e) => DailyPomodoroSummary(date: e.key, activities: e.value))
        .toList();
    summaries.sort((a, b) => b.date.compareTo(a.date));

    return summaries;
  }

  /// Get chart data for last 7 days
  List<Map<String, dynamic>> get weeklyChartData {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final activities = _activityHistory.where((a) => 
        a.dateOnly == date && a.isCompleted,
      ).toList();

      final weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      data.add({
        'day': weekdays[date.weekday - 1],
        'date': date,
        'count': activities.length,
        'minutes': activities.fold(0, (sum, a) => sum + a.totalMinutes),
      });
    }

    return data;
  }

  /// Initialize timer with work session and load persisted data
  Future<void> initialize() async {
    await _loadStats();
    await _loadActivities();
    _checkNewDay();
    _resetToWorkSession();
    await _initForegroundService();
  }
  
  /// Initialize the foreground service for background timer support
  Future<void> _initForegroundService() async {
    final logger = AppLogger();
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'pomodoro_timer_channel',
          channelName: 'Pomodoro Timer',
          channelDescription: 'Mantiene el temporizador Pomodoro activo',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
      logger.info('Pomodoro', 'Foreground service initialized successfully');
    } catch (e, stack) {
      logger.error('Pomodoro', 'Error initializing foreground service', e, stack);
    }
  }
  
  /// Start the foreground service to keep timer alive in background
  Future<void> _startForegroundService() async {
    if (_foregroundServiceRunning) return;
    
    final logger = AppLogger();
    final sessionName = _getSessionNotificationTitle();
    
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: sessionName,
        notificationText: formattedTime,
        callback: _foregroundCallback,
      );
      _foregroundServiceRunning = true;
      wasRecentlyActive = true; // Mark as recently active for notification tap
      logger.info('Pomodoro', 'Foreground service started successfully');
    } catch (e, stack) {
      logger.error('Pomodoro', 'Error starting foreground service', e, stack);
      // Continue without foreground service - timer will work but may be killed in background
    }
  }
  
  /// Update the foreground notification
  Future<void> _updateForegroundNotification() async {
    if (!_foregroundServiceRunning) return;
    
    try {
      final sessionName = _getSessionNotificationTitle();
      await FlutterForegroundTask.updateService(
        notificationTitle: sessionName,
        notificationText: formattedTime,
      );
    } catch (e) {
      // Silently fail - don't spam logs every second
    }
  }
  
  /// Stop the foreground service
  Future<void> _stopForegroundService() async {
    if (!_foregroundServiceRunning) return;
    
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      // Ignore errors when stopping
    }
    _foregroundServiceRunning = false;
    PomodoroProvider.wasRecentlyActive = false;
  }
  
  /// Get notification title based on session type
  String _getSessionNotificationTitle() {
    switch (_sessionType) {
      case SessionType.work:
        final name = _currentActivity?.name ?? 'Pomodoro';
        return name;
      case SessionType.shortBreak:
        return 'Descanso corto';
      case SessionType.longBreak:
        return 'Descanso largo';
    }
  }

  /// Set the current user and reload data
  Future<void> setCurrentUser(String? userId) async {
    // Clear current data
    _totalPomodoros = 0;
    _todayPomodoros = 0;
    _totalRealMinutes = 0;
    _todayRealMinutes = 0;
    _lastPomodoroDate = null;
    _firstPomodoroDate = null;
    _activityHistory = [];
    _currentActivity = null;
    _currentUserId = userId;
    notifyListeners();

    // Reload data for the new user
    await initialize();
  }

  /// Load stats from SharedPreferences
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _totalPomodoros = prefs.getInt(_totalKey) ?? 0;
    _todayPomodoros = prefs.getInt(_todayKey) ?? 0;
    _totalRealMinutes = prefs.getInt(_totalMinutesKey) ?? 0;
    _todayRealMinutes = prefs.getInt(_todayMinutesKey) ?? 0;
    
    // Migration: if we have pomodoros but no minutes, estimate from pomodoros
    if (_totalPomodoros > 0 && _totalRealMinutes == 0) {
      _totalRealMinutes = _totalPomodoros * _workDuration;
    }
    if (_todayPomodoros > 0 && _todayRealMinutes == 0) {
      _todayRealMinutes = _todayPomodoros * _workDuration;
    }
    
    final lastDateStr = prefs.getString(_lastDateKey);
    if (lastDateStr != null) {
      _lastPomodoroDate = DateTime.tryParse(lastDateStr);
    }
    
    final firstDateStr = prefs.getString(_firstDateKey);
    if (firstDateStr != null) {
      _firstPomodoroDate = DateTime.tryParse(firstDateStr);
    }
    
    // Load alarm setting
    final alarmKey = _currentUserId != null ? 'pomodoro_alarm_$_currentUserId' : 'pomodoro_alarm';
    _alarmEnabled = prefs.getBool(alarmKey) ?? false;
    
    notifyListeners();
  }

  /// Save stats to SharedPreferences
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalKey, _totalPomodoros);
    await prefs.setInt(_todayKey, _todayPomodoros);
    await prefs.setInt(_totalMinutesKey, _totalRealMinutes);
    await prefs.setInt(_todayMinutesKey, _todayRealMinutes);
    if (_lastPomodoroDate != null) {
      await prefs.setString(_lastDateKey, _lastPomodoroDate!.toIso8601String());
    }
    if (_firstPomodoroDate != null) {
      await prefs.setString(_firstDateKey, _firstPomodoroDate!.toIso8601String());
    }
  }

  /// Load activity history from SharedPreferences
  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString(_activitiesKey);
    
    if (activitiesJson != null) {
      final List<dynamic> decoded = jsonDecode(activitiesJson);
      _activityHistory = decoded
          .map((e) => PomodoroActivity.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Clean up activities older than 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: kPomodoroRetentionDays));
      _activityHistory = _activityHistory.where((a) => 
        a.startTime.isAfter(cutoffDate),
      ).toList();
    }
  }

  /// Save activity history to SharedPreferences
  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = jsonEncode(
      _activityHistory.map((a) => a.toJson()).toList(),
    );
    await prefs.setString(_activitiesKey, activitiesJson);
  }

  /// Start a new activity session
  void startActivity(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _currentActivity = PomodoroActivity(
      id: id,
      name: name,
      startTime: DateTime.now(),
    );
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    
    // Reset to work session and start
    _completedPomodoros = 0;
    _sessionType = SessionType.work;
    _state = PomodoroState.idle;
    _remainingSeconds = _workDuration * 60;
    
    notifyListeners();
  }

  /// Cancel current activity
  void cancelActivity() {
    _currentActivity = null;
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;
    notifyListeners();
  }

  /// Complete and save current activity
  void _completeActivity() {
    if (_currentActivity == null) return;

    final endTime = DateTime.now();
    // Calculate real elapsed time (not theoretical)
    final realMinutes = endTime.difference(_currentActivity!.startTime).inMinutes;

    final completedActivity = _currentActivity!.copyWith(
      endTime: endTime,
      cyclesCompleted: _activityCyclesCompleted,
      totalMinutes: realMinutes,
      isCompleted: true,
    );

    _activityHistory.insert(0, completedActivity);
    _saveActivities();

    // Store for celebration
    _justCompletedActivity = completedActivity;
    
    // Show completion notification
    _notificationService.showPomodoroCompleteNotification(
      activityName: completedActivity.name,
      cycles: completedActivity.cyclesCompleted,
      totalTime: Duration(minutes: completedActivity.totalMinutes),
    );
    
    _currentActivity = null;
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;

    notifyListeners();
  }

  /// Start or resume the timer
  void start() async {
    final logger = AppLogger();
    logger.info('Pomodoro', 'start() called, state=$_state, sessionType=$_sessionType, remainingSeconds=$_remainingSeconds');
    
    if (_state == PomodoroState.running) {
      logger.warning('Pomodoro', 'start() blocked - already running');
      return;
    }

    // Cancel any existing timer to prevent duplicates
    _timer?.cancel();
    
    // Cancel completion/alarm notification from previous session
    await _notificationService.cancelCompletionNotification();
    
    // Track session start time for calculating real minutes
    _sessionStartTime ??= DateTime.now();
    
    // Calculate when timer should end (for background support)
    _timerEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    
    _state = PomodoroState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    logger.info('Pomodoro', 'Timer started, endTime=$_timerEndTime');
    
    // Start foreground service to keep app alive in background
    try {
      await _startForegroundService();
      logger.info('Pomodoro', 'Foreground service started');
    } catch (e) {
      logger.error('Pomodoro', 'Error starting foreground service', e);
    }
    
    // Schedule notification for when timer ends (alerts user even if app killed)
    _scheduleTimerEndNotification();
    logger.info('Pomodoro', 'End notification scheduled');
    
    // Start or Update Live Activity (iOS)
    if (Platform.isIOS) {
      final activityName = _currentActivity?.name ?? 'Pomodoro';
      final sessionTypeName = _sessionType.name; // work, shortBreak, longBreak
      
      if (_liveActivityId == null) {
        _liveActivityId = await _liveActivityService.startPomodoroActivity(
          endTime: _timerEndTime!,
          sessionType: sessionTypeName,
          activityName: activityName,
        );
      } else {
        await _liveActivityService.updatePomodoroActivity(
          endTime: _timerEndTime,
          sessionType: sessionTypeName,
          isPaused: false,
        );
      }
    }
    
    notifyListeners();
  }
  
  /// Called when app returns from background - recalculates remaining time
  void onAppResumed() {
    if (_state != PomodoroState.running || _timerEndTime == null) return;
    
    final now = DateTime.now();
    final remaining = _timerEndTime!.difference(now).inSeconds;
    
    if (remaining <= 0) {
      // Timer should have finished while in background
      _remainingSeconds = 0;
      _timer?.cancel();
      _onSessionComplete();
    } else {
      // Update remaining time
      _remainingSeconds = remaining;
      
      // Restart timer if it was stopped
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      
      notifyListeners();
    }
  }
  
  /// Schedule notification for when current timer ends
  void _scheduleTimerEndNotification() {
    final duration = Duration(seconds: _remainingSeconds);
    final activityName = _currentActivity?.name ?? 'Pomodoro';
    
    if (_sessionType == SessionType.work) {
      _notificationService.schedulePomodoroWorkEnd(
        duration: duration,
        activityName: activityName,
      );
    } else {
      _notificationService.schedulePomodoroBreakEnd(
        duration: duration,
        activityName: activityName,
      );
    }
  }

  /// Pause the timer
  void pause() async {
    _timer?.cancel();
    _timerEndTime = null; // Clear end time when paused
    _state = PomodoroState.paused;
    // Stop foreground service when paused
    await _stopForegroundService();
    // Cancel scheduled end notification
    _notificationService.cancelPomodoroNotifications();
    
    // Update Live Activity (iOS)
    if (Platform.isIOS && _liveActivityId != null) {
      await _liveActivityService.updatePomodoroActivity(
        endTime: null,
        sessionType: _sessionType.name,
        isPaused: true,
      );
    }
    
    notifyListeners();
  }

  /// Reset current session
  void reset() async {
    _timer?.cancel();
    _timerEndTime = null; // Clear end time when reset
    _state = PomodoroState.idle;
    _remainingSeconds = _getCurrentSessionDuration() * 60;
    // Stop foreground service when reset
    await _stopForegroundService();
    // Cancel scheduled end notification
    _notificationService.cancelPomodoroNotifications();
    
    // End Live Activity (iOS)
    if (Platform.isIOS && _liveActivityId != null) {
      await _liveActivityService.endPomodoroActivity();
      _liveActivityId = null;
    }
    
    notifyListeners();
  }

  /// Skip to next session
  void skip() async {
    _timer?.cancel();
    _timerEndTime = null;
    
    await _stopForegroundService();
    _notificationService.cancelPomodoroNotifications();
    
    // End Live Activity (iOS)
    if (Platform.isIOS && _liveActivityId != null) {
      await _liveActivityService.endPomodoroActivity();
      _liveActivityId = null;
    }
    
    // If skipping a work session, calculate real minutes worked
    if (_sessionType == SessionType.work) {
      final realMinutes = _calculateRealMinutesWorked();
      _completedPomodoros++;
      _todayPomodoros++;
      _totalPomodoros++;
      _todayRealMinutes += realMinutes;
      _totalRealMinutes += realMinutes;
      _lastPomodoroDate = DateTime.now();
      _firstPomodoroDate ??= DateTime.now();
      _sessionStartTime = null; // Reset for next session
      _saveStats();
      // Note: Activity cycle is NOT counted here - it counts when break ends
    } else if (_sessionType == SessionType.shortBreak) {
      // Skipping short break = cycle complete for activity
      if (_currentActivity != null) {
        _activityCyclesCompleted++;
        _activityMinutesCompleted += _workDuration;
      }
    } else if (_sessionType == SessionType.longBreak) {
      // Skipping long break = final cycle complete + activity done
      if (_currentActivity != null) {
        _activityCyclesCompleted++;
        _activityMinutesCompleted += _workDuration;
        _activityPendingCompletion = true;
      }
    }
    
    _moveToNextSession();
    notifyListeners();
  }
  
  /// Calculate real minutes worked in current session
  int _calculateRealMinutesWorked() {
    if (_sessionStartTime == null) {
      // If no start time, use the elapsed time from remaining seconds
      final totalSeconds = _getCurrentSessionDuration() * 60;
      final elapsedSeconds = totalSeconds - _remainingSeconds;
      return (elapsedSeconds / 60).ceil();
    }
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    return elapsed.inMinutes > 0 ? elapsed.inMinutes : 1; // At least 1 minute
  }

  /// Set work duration (in minutes)
  void setWorkDuration(int minutes) {
    _workDuration = minutes;
    if (_sessionType == SessionType.work && _state == PomodoroState.idle) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  /// Set short break duration (in minutes)
  void setShortBreakDuration(int minutes) {
    _shortBreakDuration = minutes;
    if (_sessionType == SessionType.shortBreak && _state == PomodoroState.idle) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  /// Set long break duration (in minutes)
  void setLongBreakDuration(int minutes) {
    _longBreakDuration = minutes;
    if (_sessionType == SessionType.longBreak && _state == PomodoroState.idle) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }
  
  /// Toggle alarm sound for pomodoro completion
  Future<void> toggleAlarm(bool enabled) async {
    _alarmEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    final alarmKey = _currentUserId != null ? 'pomodoro_alarm_$_currentUserId' : 'pomodoro_alarm';
    await prefs.setBool(alarmKey, enabled);
    notifyListeners();
  }

  /// Manually select session type
  void selectSessionType(SessionType type) {
    if (_state == PomodoroState.running) return;
    if (_currentActivity != null) return; // Can't change type during activity
    
    _timer?.cancel();
    _sessionType = type;
    _state = PomodoroState.idle;
    _remainingSeconds = _getCurrentSessionDuration() * 60;
    notifyListeners();
  }

  // Private methods
  void _tick(Timer timer) {
    final logger = AppLogger();
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      
      // Log every 60 seconds to avoid spam
      if (_remainingSeconds % 60 == 0) {
        logger.info('Pomodoro', '_tick: remainingSeconds=$_remainingSeconds');
      }
      
      // Update foreground service notification every second
      _updateForegroundNotification();
      
      notifyListeners();
      
      // Check if we just hit zero - complete immediately
      if (_remainingSeconds == 0) {
        logger.info('Pomodoro', '_tick: Timer reached 0, calling _onSessionComplete');
        _onSessionComplete();
      }
    } else {
      // Safety fallback - should not normally reach here
      logger.warning('Pomodoro', '_tick: Safety fallback triggered (remainingSeconds=$_remainingSeconds)');
      _onSessionComplete();
    }
  }
  
  /// Called when app lifecycle changes (kept for API compatibility)
  void setAppInForeground(bool inForeground) {
    // Foreground service now handles background state
    // No action needed here
  }

  void _onSessionComplete() async {
    final logger = AppLogger();
    logger.info('Pomodoro', '_onSessionComplete() called, sessionType=$_sessionType');
    
    _timer?.cancel();
    _state = PomodoroState.finished;
    
    // Update notification to show 00:00 before stopping
    if (_foregroundServiceRunning) {
      try {
        final sessionName = _getSessionNotificationTitle();
        await FlutterForegroundTask.updateService(
          notificationTitle: sessionName,
          notificationText: '00:00',
        );
        logger.info('Pomodoro', 'Notification updated to 00:00');
        // Small delay so user sees 00:00
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        logger.error('Pomodoro', 'Error updating notification to 00:00', e);
      }
    }
    
    // Stop foreground service and cancel scheduled notification
    try {
      await _stopForegroundService();
      _notificationService.cancelPomodoroNotifications();
      
      // End Live Activity (iOS)
      if (Platform.isIOS && _liveActivityId != null) {
        await _liveActivityService.endPomodoroActivity();
        _liveActivityId = null;
      }
      
      logger.info('Pomodoro', 'Foreground service stopped');
    } catch (e) {
      logger.error('Pomodoro', 'Error stopping foreground service', e);
    }

    // Wait a bit to ensure foreground service is fully stopped
    await Future.delayed(const Duration(milliseconds: 300));

    // Haptic feedback to notify user
    HapticFeedback.heavyImpact();
    
    // Show in-app notification
    final activityName = _currentActivity?.name ?? 'Pomodoro';
    logger.info('Pomodoro', 'Session complete: $activityName');

    if (_sessionType == SessionType.work) {
      // Work session complete - count pomodoro with full duration
      final realMinutes = _workDuration; // Completed = full duration
      _completedPomodoros++;
      _todayPomodoros++;
      _totalPomodoros++;
      _todayRealMinutes += realMinutes;
      _totalRealMinutes += realMinutes;
      _lastPomodoroDate = DateTime.now();
      _firstPomodoroDate ??= DateTime.now();
      _sessionStartTime = null; // Reset for next session
      _saveStats();
      
      // Show notification (alarm or normal based on preference)
      if (_alarmEnabled) {
        _notificationService.showAlarmNotification(
          title: '⏰ ¡POMODORO TERMINADO!',
          body: '$activityName - Tiempo de descanso',
        );
      } else {
        SystemSound.play(SystemSoundType.alert);
        _notificationService.showInstantNotification(
          title: '¡Pomodoro completado!',
          body: '$activityName - Tiempo de descanso',
        );
      }
    } else if (_sessionType == SessionType.shortBreak) {
      // Short break complete = one full cycle done for activity
      if (_currentActivity != null) {
        _activityCyclesCompleted++;
        _activityMinutesCompleted += _workDuration;
      }
      
      // Show notification (alarm or normal based on preference)
      if (_alarmEnabled) {
        _notificationService.showAlarmNotification(
          title: '⏰ ¡DESCANSO TERMINADO!',
          body: '$activityName - Vuelve al trabajo',
        );
      } else {
        SystemSound.play(SystemSoundType.alert);
        _notificationService.showInstantNotification(
          title: '¡Descanso terminado!',
          body: '$activityName - Vuelve al trabajo',
        );
      }
    } else if (_sessionType == SessionType.longBreak) {
      // Long break complete = final cycle done + activity complete
      if (_currentActivity != null) {
        _activityCyclesCompleted++;
        _activityMinutesCompleted += _workDuration;
        _activityPendingCompletion = true;
        _completeActivity();
      }
      
      // Show notification (alarm or normal based on preference)
      if (_alarmEnabled) {
        _notificationService.showAlarmNotification(
          title: '⏰ ¡DESCANSO LARGO TERMINADO!',
          body: 'Listo para otro ciclo',
        );
      } else {
        SystemSound.play(SystemSoundType.alert);
        _notificationService.showInstantNotification(
          title: '¡Descanso largo terminado!',
          body: 'Listo para otro ciclo',
        );
      }
    }
    
    // Auto-advance to next session after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == PomodoroState.finished) {
        _moveToNextSession();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void _moveToNextSession() {
    if (_sessionType == SessionType.work) {
      // After work, take a break
      if (_completedPomodoros > 0 && _completedPomodoros % _pomodorosUntilLongBreak == 0) {
        _sessionType = SessionType.longBreak;
      } else {
        _sessionType = SessionType.shortBreak;
      }
    } else if (_sessionType == SessionType.longBreak && _activityPendingCompletion) {
      // Long break skipped/completed with pending activity - complete it
      _completeActivity();
      _sessionType = SessionType.work;
    } else {
      // After break, back to work
      _sessionType = SessionType.work;
    }

    _state = PomodoroState.idle;
    _remainingSeconds = _getCurrentSessionDuration() * 60;
  }

  void _resetToWorkSession() {
    _sessionType = SessionType.work;
    _state = PomodoroState.idle;
    _remainingSeconds = _workDuration * 60;
  }

  int _getCurrentSessionDuration() {
    switch (_sessionType) {
      case SessionType.work:
        return _workDuration;
      case SessionType.shortBreak:
        return _shortBreakDuration;
      case SessionType.longBreak:
        return _longBreakDuration;
    }
  }

  void _checkNewDay() {
    final now = DateTime.now();
    if (_lastPomodoroDate == null) return;
    
    if (now.day != _lastPomodoroDate!.day ||
        now.month != _lastPomodoroDate!.month ||
        now.year != _lastPomodoroDate!.year) {
      _todayPomodoros = 0;
      _todayRealMinutes = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopForegroundService();
    _notificationService.cancelPomodoroNotifications();
    super.dispose();
  }
  
  /// Cleans up any stale notifications (call on app startup)
  Future<void> cleanupStaleNotifications() async {
    if (_state != PomodoroState.running) {
      await _notificationService.cancelPomodoroNotifications();
      await _stopForegroundService();
    }
  }
}

/// Callback for foreground task - required but we handle timer in main isolate
@pragma('vm:entry-point')
void _foregroundCallback() {
  FlutterForegroundTask.setTaskHandler(_PomodoroTaskHandler());
}

/// Simple task handler - the actual timer runs in main isolate
class _PomodoroTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isAppTerminated) async {}

  @override
  void onReceiveData(Object data) {}
}
