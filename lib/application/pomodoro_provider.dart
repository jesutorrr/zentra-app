import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/focus_repository.dart';
import '../domain/pomodoro_activity.dart';
import '../infrastructure/app_logger.dart';
import '../infrastructure/live_activity_service.dart';
import '../infrastructure/notification_service.dart';

typedef PomodoroClock = DateTime Function();
typedef PomodoroPeriodicTimerFactory = Timer Function(
  Duration duration,
  void Function(Timer timer) callback,
);
typedef LinkedNoteFocusCallback = Future<void> Function(
  String noteId,
  DateTime reviewedAt, {
  String? focusSessionId,
});

typedef PomodoroEngineFactory = PomodoroEngine Function({
  required String ownerId,
  required VoidCallback onChanged,
});

final pomodoroEngineFactoryProvider = Provider<PomodoroEngineFactory>((ref) {
  return ({
    required String ownerId,
    required VoidCallback onChanged,
  }) {
    return PomodoroEngine(
      initialUserId: ownerId,
      onChanged: onChanged,
    );
  };
});

final pomodoroControllerProvider =
    NotifierProvider.family<PomodoroController, PomodoroViewState, String>(
  PomodoroController.new,
);

class _PomodoroForegroundCoordinator {
  static const _operationTimeout = Duration(seconds: 2);

  Future<void> _operationQueue = Future<void>.value();
  Object? _owner;
  var _timedOutOperations = 0;

  bool get _isCircuitOpen => _timedOutOperations > 0;

  Future<bool> claim(
    Object owner, {
    required bool Function() isValid,
    required Future<void> Function() start,
  }) {
    return _serialize(() async {
      if (!isValid() || _isCircuitOpen) return false;
      await _runBounded(start());
      _owner = owner;
      return isValid();
    });
  }

  Future<bool> runIfOwned(
    Object owner,
    Future<void> Function() operation, {
    bool release = false,
    bool allowUnowned = false,
  }) {
    return _serialize(() async {
      if (_isCircuitOpen) return false;
      if (_owner == null && allowUnowned) {
        _owner = owner;
      }
      if (!identical(_owner, owner)) return false;
      try {
        await _runBounded(operation());
        return true;
      } finally {
        if (release && identical(_owner, owner)) {
          _owner = null;
        }
      }
    });
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _runBounded(Future<void> operation) async {
    try {
      await operation.timeout(_operationTimeout);
    } on TimeoutException {
      _timedOutOperations += 1;
      unawaited(
        operation.then<void>(
          (_) => _timedOutOperations -= 1,
          onError: (_, __) => _timedOutOperations -= 1,
        ),
      );
      rethrow;
    }
  }
}

/// Pomodoro timer states
enum PomodoroState {
  idle, // Not started
  running, // Timer is running
  paused, // Timer is paused
  finished, // Timer completed
}

/// Pomodoro session type
enum SessionType {
  work, // Work session (25 min default)
  shortBreak, // Short break (5 min default)
  longBreak, // Long break (15 min default)
}

/// User-facing ways to use the timer.
enum PomodoroMode {
  quick, // One independent focus session.
  cycle, // Four focus sessions with guided breaks.
}

/// Stateful Pomodoro engine owned by [PomodoroController].
///
/// Keeping timekeeping and platform effects in a plain service lets Riverpod
/// own the reactive lifecycle without coupling the behavior to widgets.
class PomodoroEngine {
  PomodoroEngine({
    PomodoroClock? clock,
    PomodoroPeriodicTimerFactory? periodicTimerFactory,
    Duration completionTransitionDelay = const Duration(milliseconds: 500),
    String? initialUserId,
    FocusRepository? focusRepository,
    LiveActivityService? liveActivityService,
    VoidCallback? onChanged,
  })  : _clock = clock ?? DateTime.now,
        _periodicTimerFactory = periodicTimerFactory ?? Timer.periodic,
        _completionTransitionDelay = completionTransitionDelay,
        _currentUserId = initialUserId,
        _focusRepository = focusRepository,
        _liveActivityService = liveActivityService ?? LiveActivityService(),
        _onChanged = onChanged {
    final repositoryOwnerId = focusRepository?.ownerId;
    if (repositoryOwnerId != null && repositoryOwnerId != initialUserId) {
      throw ArgumentError.value(
        initialUserId,
        'initialUserId',
        'Must match the owner-bound focus repository $repositoryOwnerId.',
      );
    }
  }

  // Static flag to track if pomodoro was recently active (for notification tap handling)
  static bool wasRecentlyActive = false;
  static const int _activeSessionSchemaVersion = 1;
  static const String _defaultSessionName = 'Sesión de enfoque';
  static final _foregroundCoordinator = _PomodoroForegroundCoordinator();

  final PomodoroClock _clock;
  final PomodoroPeriodicTimerFactory _periodicTimerFactory;
  final Duration _completionTransitionDelay;
  final FocusRepository? _focusRepository;
  final LiveActivityService _liveActivityService;
  final VoidCallback? _onChanged;
  final Object _foregroundOwner = Object();

  bool get _usesForegroundTask =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Timer configuration (in minutes)
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _activeStageDuration = 25;
  final int _pomodorosUntilLongBreak = 4;
  String? _currentUserId;
  PomodoroMode _mode = PomodoroMode.quick;
  String? _quickSessionName;
  DateTime? _quickSessionStartedAt;
  String? _linkedNoteId;
  String? _activeFocusSessionId;
  String? _lastAwardedFocusSessionId;
  bool _isAppInForeground = true;
  String? _completionToken;
  Future<void>? _completionFuture;
  Future<void>? _pendingReviewFuture;
  Future<void>? _shutdownFuture;
  int _ownerGeneration = 0;
  Future<void> _foregroundTransition = Future<void>.value();
  bool _isDisposed = false;
  final Set<Future<void>> _pendingPersistence = <Future<void>>{};
  final Set<String> _awardedFocusSessionIds = <String>{};
  final Map<String, _PendingNoteReview> _pendingNoteReviews =
      <String, _PendingNoteReview>{};

  /// Optional application-layer hook. Keeping the callback here avoids making
  /// the timer depend directly on the Notes repository.
  LinkedNoteFocusCallback? onLinkedNoteFocused;

  // Notification service
  final NotificationService _notificationService = NotificationService();
  // Foreground service flag
  bool _foregroundServiceRunning = false;

  // Alarm settings
  bool _alarmEnabled = false;

  // Storage key getters (user-specific if logged in)
  String get _totalKey => _currentUserId != null
      ? 'pomodoro_total_$_currentUserId'
      : 'pomodoro_total';
  String get _todayKey => _currentUserId != null
      ? 'pomodoro_today_$_currentUserId'
      : 'pomodoro_today';
  String get _totalMinutesKey => _currentUserId != null
      ? 'pomodoro_total_minutes_$_currentUserId'
      : 'pomodoro_total_minutes';
  String get _todayMinutesKey => _currentUserId != null
      ? 'pomodoro_today_minutes_$_currentUserId'
      : 'pomodoro_today_minutes';
  String get _lastDateKey => _currentUserId != null
      ? 'pomodoro_last_date_$_currentUserId'
      : 'pomodoro_last_date';
  String get _firstDateKey => _currentUserId != null
      ? 'pomodoro_first_date_$_currentUserId'
      : 'pomodoro_first_date';
  String get _activitiesKey => _currentUserId != null
      ? 'pomodoro_activities_$_currentUserId'
      : 'pomodoro_activities';
  String get _workDurationKey => _currentUserId != null
      ? 'pomodoro_work_duration_$_currentUserId'
      : 'pomodoro_work_duration';
  String get _shortBreakDurationKey => _currentUserId != null
      ? 'pomodoro_short_break_duration_$_currentUserId'
      : 'pomodoro_short_break_duration';
  String get _longBreakDurationKey => _currentUserId != null
      ? 'pomodoro_long_break_duration_$_currentUserId'
      : 'pomodoro_long_break_duration';
  String get _activeSessionKey => _currentUserId != null
      ? 'pomodoro_active_session_$_currentUserId'
      : 'pomodoro_active_session';
  String get _lastAwardedSessionKey => _currentUserId != null
      ? 'pomodoro_last_awarded_session_$_currentUserId'
      : 'pomodoro_last_awarded_session';
  String get _focusProgressKey => _currentUserId != null
      ? 'pomodoro_focus_progress_$_currentUserId'
      : 'pomodoro_focus_progress';

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
  int _activityMinutesCompleted = 0;
  bool _activityPendingCompletion =
      false; // Activity finished work, waiting for long break
  PomodoroActivity? _justCompletedActivity; // For showing celebration

  // Getters
  PomodoroState get state => _state;
  SessionType get sessionType => _sessionType;
  int get remainingSeconds => _remainingSeconds;
  int get completedPomodoros => _completedPomodoros;
  int get todayPomodoros => _todayPomodoros;
  int get totalPomodoros => _totalPomodoros;
  DateTime? get firstPomodoroDate => _firstPomodoroDate;
  PomodoroMode get mode => _mode;
  String? get quickSessionName => _quickSessionName;
  String? get linkedNoteId => _linkedNoteId;
  String? get activeFocusSessionId => _activeFocusSessionId;
  int get activeStageDuration => _activeStageDuration;
  bool get isQuickMode => _mode == PomodoroMode.quick;
  bool get isCycleMode => _mode == PomodoroMode.cycle;
  bool get canShowLauncher =>
      _state == PomodoroState.idle &&
      _sessionType == SessionType.work &&
      _currentActivity == null;

  /// Actual minutes of focus today, including independent quick sessions.
  int get todayMinutes => _todayRealMinutes;

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
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    return _activityHistory
        .where(
          (a) => a.isCompleted && a.dateOnly == today,
        )
        .length;
  }

  /// Total activities completed
  int get totalActivities =>
      _activityHistory.where((a) => a.isCompleted).length;

  /// Clear the just completed activity (call after showing celebration)
  void clearJustCompletedActivity() {
    _justCompletedActivity = null;
    _emit();
  }

  /// True if we're in the final long break of an activity (ready to complete)
  /// This is when we have 3 cycles done and are in the long break (4th cycle's break)
  bool get isActivityFinalBreak =>
      _currentActivity != null &&
      _activityCyclesCompleted >= _pomodorosUntilLongBreak &&
      _sessionType == SessionType.longBreak;

  // Formatted time
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Progress (0.0 to 1.0)
  double get progress {
    final totalSeconds = _activeStageDuration * 60;
    if (totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  // Session label
  String get sessionLabel {
    switch (_sessionType) {
      case SessionType.work:
        return _currentActivity?.name ??
            _quickSessionName ??
            _defaultSessionName;
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
    // Group by date
    final Map<DateTime, List<PomodoroActivity>> grouped = {};
    for (final activity in _activityHistory) {
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
    final now = _clock();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final activities = _activityHistory
          .where(
            (a) => a.dateOnly == date && a.isCompleted,
          )
          .toList();

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
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    await _loadConfiguration();
    if (!_isGenerationActive(generation)) return;
    await _loadStats();
    if (!_isGenerationActive(generation)) return;
    await _loadActivities();
    if (!_isGenerationActive(generation)) return;
    _checkNewDay();
    await _initForegroundService();
    if (!_isGenerationActive(generation)) return;
    final restoredExpiredSession = await _restoreActiveSession();
    if (!_isGenerationActive(generation)) return;
    if (restoredExpiredSession) {
      await _onSessionComplete(notificationAlreadyDelivered: true);
    } else if (_state == PomodoroState.running) {
      _restartPeriodicTimer();
      await _startForegroundService();
      if (!_isGenerationActive(generation)) return;
      await _startLiveActivity(expectedGeneration: generation);
    }
    if (!_isGenerationActive(generation)) return;
    await _drainPendingNoteReviews(
      expectedGeneration: generation,
    );
    if (!_isGenerationActive(generation)) return;
    _emit();
  }

  /// Reloads completed sessions materialized by sync without touching the
  /// active timer, device configuration or foreground service.
  Future<void> refreshAfterSync() async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    await _loadActivities();
    if (!_isGenerationActive(generation)) return;

    final completed =
        _activityHistory.where((activity) => activity.isCompleted).toList();
    final derivedPomodoros = completed.fold<int>(
      0,
      (total, activity) => total + activity.cyclesCompleted,
    );
    final derivedMinutes = completed.fold<int>(
      0,
      (total, activity) => total + activity.totalMinutes,
    );
    if (derivedPomodoros > _totalPomodoros) {
      _totalPomodoros = derivedPomodoros;
    }
    if (derivedMinutes > _totalRealMinutes) {
      _totalRealMinutes = derivedMinutes;
    }

    final now = _clock();
    final today = completed.where((activity) {
      final completedAt = activity.endTime ?? activity.startTime;
      return completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    });
    final derivedTodayPomodoros = today.fold<int>(
      0,
      (total, activity) => total + activity.cyclesCompleted,
    );
    final derivedTodayMinutes = today.fold<int>(
      0,
      (total, activity) => total + activity.totalMinutes,
    );
    if (derivedTodayPomodoros > _todayPomodoros) {
      _todayPomodoros = derivedTodayPomodoros;
    }
    if (derivedTodayMinutes > _todayRealMinutes) {
      _todayRealMinutes = derivedTodayMinutes;
    }
    _emit();
  }

  /// Initialize the foreground service for background timer support
  Future<void> _initForegroundService() async {
    if (!_usesForegroundTask) return;
    final logger = AppLogger();
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'pomodoro_timer_channel',
          channelName: 'Pomodoro Timer',
          channelDescription: 'Mantiene el temporizador Pomodoro activo',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility.VISIBILITY_PRIVATE,
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
      logger.error(
        'Pomodoro',
        'Error initializing foreground service',
        e,
        stack,
      );
    }
  }

  /// Start the foreground service to keep timer alive in background
  Future<void> _startForegroundService() async {
    if (_foregroundServiceRunning || _isDisposed) return;

    final logger = AppLogger();
    final sessionName = _getSessionNotificationTitle();
    final generation = _ownerGeneration;

    try {
      final claimed = await _foregroundCoordinator.claim(
        _foregroundOwner,
        isValid: () => _isGenerationActive(generation),
        start: () async {
          if (_usesForegroundTask) {
            await FlutterForegroundTask.startService(
              notificationTitle: sessionName,
              notificationText: formattedTime,
              callback: _foregroundCallback,
            );
          }
        },
      );
      if (!claimed || !_isGenerationActive(generation)) return;
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
    if (!_usesForegroundTask || !_foregroundServiceRunning || _isDisposed) {
      return;
    }
    final generation = _ownerGeneration;

    try {
      final sessionName = _getSessionNotificationTitle();
      await _foregroundCoordinator.runIfOwned(
        _foregroundOwner,
        () async {
          if (!_isGenerationActive(generation)) return;
          await FlutterForegroundTask.updateService(
            notificationTitle: sessionName,
            notificationText: formattedTime,
          );
        },
      );
    } catch (e) {
      // Silently fail - don't spam logs every second
    }
  }

  /// Stop the foreground service
  Future<void> _stopForegroundService({
    bool cancelNotifications = false,
    bool releaseOwnership = false,
    bool allowUnowned = false,
  }) async {
    if (!_foregroundServiceRunning &&
        !cancelNotifications &&
        !releaseOwnership) {
      return;
    }
    var handled = false;
    try {
      handled = await _foregroundCoordinator.runIfOwned(
        _foregroundOwner,
        () async {
          if (_foregroundServiceRunning && _usesForegroundTask) {
            await FlutterForegroundTask.stopService();
          }
          if (cancelNotifications) {
            await _notificationService.cancelPomodoroNotifications();
          }
        },
        release: releaseOwnership,
        allowUnowned: allowUnowned,
      );
    } catch (e) {
      // Ignore errors when stopping
    }
    _foregroundServiceRunning = false;
    if (handled) {
      PomodoroEngine.wasRecentlyActive = false;
    }
  }

  bool _isGenerationActive(int generation) =>
      !_isDisposed && generation == _ownerGeneration;

  /// Get notification title based on session type
  String _getSessionNotificationTitle() {
    switch (_sessionType) {
      case SessionType.work:
        return 'Enfoque';
      case SessionType.shortBreak:
        return 'Descanso corto';
      case SessionType.longBreak:
        return 'Descanso largo';
    }
  }

  String get _liveActivityNextLabel {
    switch (_sessionType) {
      case SessionType.work:
        if (isQuickMode) return 'Al terminar: sesión completada';
        final completesWorkCycle =
            _activityCyclesCompleted + 1 >= _pomodorosUntilLongBreak;
        return completesWorkCycle
            ? 'Después: descanso largo'
            : 'Después: descanso corto';
      case SessionType.shortBreak:
        return 'Después: enfoque';
      case SessionType.longBreak:
        return _activityPendingCompletion
            ? 'Al terminar: ciclo completado'
            : 'Después: enfoque';
    }
  }

  Future<void> _startLiveActivity({
    required int expectedGeneration,
  }) async {
    if (!_isGenerationActive(expectedGeneration) ||
        !_liveActivityService.isSupportedPlatform) {
      return;
    }
    await _foregroundCoordinator.runIfOwned(
      _foregroundOwner,
      () async {
        if (!_isGenerationActive(expectedGeneration)) return;
        await _liveActivityService.startPomodoroActivity(
          endTime: _state == PomodoroState.running ? _timerEndTime : null,
          sessionType: _sessionType.name,
          activityName: _defaultSessionName,
          remainingSeconds: _remainingSeconds,
          stageDurationSeconds: _activeStageDuration * 60,
          isPaused: _state == PomodoroState.paused,
          nextLabel: _liveActivityNextLabel,
        );
      },
    );
  }

  Future<void> _updateLiveActivity({
    required int expectedGeneration,
  }) async {
    if (!_isGenerationActive(expectedGeneration) ||
        !_liveActivityService.isSupportedPlatform) {
      return;
    }
    await _foregroundCoordinator.runIfOwned(
      _foregroundOwner,
      () async {
        if (!_isGenerationActive(expectedGeneration)) return;
        await _liveActivityService.updatePomodoroActivity(
          endTime: _state == PomodoroState.running ? _timerEndTime : null,
          sessionType: _sessionType.name,
          activityName: _defaultSessionName,
          remainingSeconds: _remainingSeconds,
          stageDurationSeconds: _activeStageDuration * 60,
          isPaused: _state == PomodoroState.paused,
          nextLabel: _liveActivityNextLabel,
        );
      },
    );
  }

  Future<void> _endLiveActivity() async {
    if (!_liveActivityService.isSupportedPlatform) return;
    await _foregroundCoordinator.runIfOwned(
      _foregroundOwner,
      _liveActivityService.endPomodoroActivity,
    );
  }

  /// Set the current user and reload data
  Future<void> setCurrentUser(String? userId) async {
    if (_isDisposed) return;
    final repositoryOwnerId = _focusRepository?.ownerId;
    if (repositoryOwnerId != null && userId != repositoryOwnerId) {
      throw StateError(
        'The focus repository is locked to $repositoryOwnerId '
        'and cannot switch to ${userId ?? 'no owner'}.',
      );
    }
    final outgoingSessionKey = _activeSessionKey;
    _ownerGeneration++;
    final generation = _ownerGeneration;
    final pendingCompletion = _completionFuture;
    if (pendingCompletion != null) {
      await pendingCompletion;
    }
    if (!_isGenerationActive(generation)) return;
    _completionToken = null;
    _timer?.cancel();
    _timer = null;
    _timerEndTime = null;
    _sessionStartTime = null;
    await _endLiveActivity();
    if (!_isGenerationActive(generation)) return;
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: true,
    );
    if (!_isGenerationActive(generation)) return;
    await _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.remove(outgoingSessionKey);
    });
    if (!_isGenerationActive(generation)) return;

    // Clear current data
    _totalPomodoros = 0;
    _todayPomodoros = 0;
    _totalRealMinutes = 0;
    _todayRealMinutes = 0;
    _lastPomodoroDate = null;
    _firstPomodoroDate = null;
    _activityHistory = [];
    _currentActivity = null;
    _mode = PomodoroMode.quick;
    _quickSessionName = null;
    _quickSessionStartedAt = null;
    _linkedNoteId = null;
    _activeFocusSessionId = null;
    _lastAwardedFocusSessionId = null;
    _awardedFocusSessionIds.clear();
    _pendingNoteReviews.clear();
    _completedPomodoros = 0;
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;
    _state = PomodoroState.idle;
    _sessionType = SessionType.work;
    _currentUserId = userId;
    _emit();

    // Reload data for the new user
    await initialize();
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _workDuration = (prefs.getInt(_workDurationKey) ?? 25).clamp(5, 60).toInt();
    _shortBreakDuration =
        (prefs.getInt(_shortBreakDurationKey) ?? 5).clamp(1, 15).toInt();
    _longBreakDuration =
        (prefs.getInt(_longBreakDurationKey) ?? 15).clamp(5, 30).toInt();
    _activeStageDuration = _workDuration;
  }

  /// Load canonical focus progress, with SharedPreferences as legacy fallback.
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProgress = await _focusRepository?.loadFocusProgress();
    final rawProgress = storedProgress == null || storedProgress.isEmpty
        ? prefs.getString(_focusProgressKey)
        : jsonEncode(storedProgress);
    var loadedCanonicalProgress = false;

    if (rawProgress != null) {
      try {
        final progress = jsonDecode(rawProgress) as Map<String, dynamic>;
        if (progress['version'] != 1) {
          throw const FormatException('Unsupported focus progress version');
        }
        _totalPomodoros = progress['totalPomodoros'] as int? ?? 0;
        _todayPomodoros = progress['todayPomodoros'] as int? ?? 0;
        _totalRealMinutes = progress['totalMinutes'] as int? ?? 0;
        _todayRealMinutes = progress['todayMinutes'] as int? ?? 0;
        _lastPomodoroDate = _parseSnapshotDate(progress['lastPomodoroDate']);
        _firstPomodoroDate = _parseSnapshotDate(progress['firstPomodoroDate']);
        _awardedFocusSessionIds
          ..clear()
          ..addAll(
            (progress['awardedSessionIds'] as List<dynamic>? ?? const [])
                .whereType<String>(),
          );
        _pendingNoteReviews.clear();
        final pendingReviews =
            progress['pendingNoteReviews'] as List<dynamic>? ?? const [];
        for (final entry in pendingReviews) {
          if (entry is! Map) continue;
          final review = _PendingNoteReview.tryFromJson(
            Map<String, dynamic>.from(entry),
          );
          if (review != null) {
            _pendingNoteReviews[review.sessionId] = review;
          }
        }
        loadedCanonicalProgress = true;
      } catch (error, stack) {
        AppLogger().error(
          'Pomodoro',
          'Discarding invalid focus progress record',
          error,
          stack,
        );
      }
    }

    if (!loadedCanonicalProgress) {
      _totalPomodoros = prefs.getInt(_totalKey) ?? 0;
      _todayPomodoros = prefs.getInt(_todayKey) ?? 0;
      _totalRealMinutes = prefs.getInt(_totalMinutesKey) ?? 0;
      _todayRealMinutes = prefs.getInt(_todayMinutesKey) ?? 0;

      final lastDateStr = prefs.getString(_lastDateKey);
      if (lastDateStr != null) {
        _lastPomodoroDate = DateTime.tryParse(lastDateStr);
      }

      final firstDateStr = prefs.getString(_firstDateKey);
      if (firstDateStr != null) {
        _firstPomodoroDate = DateTime.tryParse(firstDateStr);
      }

      final legacyAwarded = prefs.getString(_lastAwardedSessionKey);
      if (legacyAwarded != null) {
        _awardedFocusSessionIds.add(legacyAwarded);
      }
    }

    // Migration: if we have pomodoros but no minutes, estimate from pomodoros
    if (_totalPomodoros > 0 && _totalRealMinutes == 0) {
      _totalRealMinutes = _totalPomodoros * _workDuration;
    }
    if (_todayPomodoros > 0 && _todayRealMinutes == 0) {
      _todayRealMinutes = _todayPomodoros * _workDuration;
    }

    // Load alarm setting
    final alarmKey = _currentUserId != null
        ? 'pomodoro_alarm_$_currentUserId'
        : 'pomodoro_alarm';
    _alarmEnabled = prefs.getBool(alarmKey) ?? false;
    _lastAwardedFocusSessionId = prefs.getString(_lastAwardedSessionKey);
    if (_lastAwardedFocusSessionId != null) {
      _awardedFocusSessionIds.add(_lastAwardedFocusSessionId!);
    }

    if (!loadedCanonicalProgress) {
      await _saveStats();
    }

    _emit();
  }

  /// Save canonical focus progress.
  Future<void> _saveStats({int? expectedGeneration}) {
    final generation = expectedGeneration ?? _ownerGeneration;
    final focusProgressKey = _focusProgressKey;
    final totalKey = _totalKey;
    final todayKey = _todayKey;
    final totalMinutesKey = _totalMinutesKey;
    final todayMinutesKey = _todayMinutesKey;
    final lastDateKey = _lastDateKey;
    final firstDateKey = _firstDateKey;
    final lastAwardedSessionKey = _lastAwardedSessionKey;
    final totalPomodoros = _totalPomodoros;
    final todayPomodoros = _todayPomodoros;
    final totalMinutes = _totalRealMinutes;
    final todayMinutes = _todayRealMinutes;
    final lastPomodoroDate = _lastPomodoroDate;
    final firstPomodoroDate = _firstPomodoroDate;
    final lastAwardedFocusSessionId = _lastAwardedFocusSessionId;
    final progress = <String, Object?>{
      'version': 1,
      'totalPomodoros': totalPomodoros,
      'todayPomodoros': todayPomodoros,
      'totalMinutes': totalMinutes,
      'todayMinutes': todayMinutes,
      'lastPomodoroDate': lastPomodoroDate?.toUtc().toIso8601String(),
      'firstPomodoroDate': firstPomodoroDate?.toUtc().toIso8601String(),
      'awardedSessionIds': _awardedFocusSessionIds.toList(growable: false),
      'pendingNoteReviews': _pendingNoteReviews.values
          .map((review) => review.toJson())
          .toList(growable: false),
    };

    return _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final focusRepository = _focusRepository;
      if (focusRepository != null) {
        await focusRepository.saveFocusProgress(progress);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;

      // This single value is the canonical commit point for a focus reward.
      await prefs.setString(focusProgressKey, jsonEncode(progress));
      if (!_isGenerationActive(generation)) return;

      // Keep the legacy scalar keys for backup compatibility during migration.
      await prefs.setInt(totalKey, totalPomodoros);
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(todayKey, todayPomodoros);
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(totalMinutesKey, totalMinutes);
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(todayMinutesKey, todayMinutes);
      if (!_isGenerationActive(generation)) return;
      if (lastPomodoroDate != null) {
        await prefs.setString(lastDateKey, lastPomodoroDate.toIso8601String());
        if (!_isGenerationActive(generation)) return;
      }
      if (firstPomodoroDate != null) {
        await prefs.setString(
          firstDateKey,
          firstPomodoroDate.toIso8601String(),
        );
        if (!_isGenerationActive(generation)) return;
      }
      if (lastAwardedFocusSessionId != null) {
        await prefs.setString(
          lastAwardedSessionKey,
          lastAwardedFocusSessionId,
        );
      }
    });
  }

  /// Load canonical completed focus sessions.
  Future<void> _loadActivities() async {
    final focusRepository = _focusRepository;
    if (focusRepository != null) {
      _activityHistory = await focusRepository.loadFocusSessions();
      _activityHistory.sort((a, b) => b.startTime.compareTo(a.startTime));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString(_activitiesKey);

    if (activitiesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(activitiesJson);
        _activityHistory = decoded
            .map(
              (entry) => PomodoroActivity.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
        _activityHistory.sort((a, b) => b.startTime.compareTo(a.startTime));
      } catch (error, stack) {
        AppLogger().error(
          'Pomodoro',
          'Ignoring invalid focus history',
          error,
          stack,
        );
        _activityHistory = [];
      }
    }
  }

  /// Save canonical completed focus sessions.
  Future<void> _saveActivities({int? expectedGeneration}) {
    final generation = expectedGeneration ?? _ownerGeneration;
    final activities = List<PomodoroActivity>.of(_activityHistory);
    final activitiesKey = _activitiesKey;
    final activitiesJson = jsonEncode(
      activities.map((activity) => activity.toJson()).toList(),
    );
    return _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final focusRepository = _focusRepository;
      if (focusRepository != null) {
        await focusRepository.replaceFocusSessions(activities);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.setString(activitiesKey, activitiesJson);
    });
  }

  void _emit() {
    if (!_isDisposed) _onChanged?.call();
  }

  Future<bool> _restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSnapshot = prefs.getString(_activeSessionKey);
    if (rawSnapshot == null) {
      _resetToWorkSession();
      return false;
    }

    try {
      final snapshot = jsonDecode(rawSnapshot) as Map<String, dynamic>;
      if (snapshot['version'] != _activeSessionSchemaVersion) {
        throw const FormatException('Unsupported Pomodoro session snapshot');
      }

      _mode = PomodoroMode.values.byName(snapshot['mode'] as String);
      _sessionType =
          SessionType.values.byName(snapshot['sessionType'] as String);
      _state = PomodoroState.values.byName(snapshot['state'] as String);
      _remainingSeconds = snapshot['remainingSeconds'] as int;
      _activeStageDuration =
          (snapshot['activeStageDuration'] as int).clamp(1, 60).toInt();
      final maximumStageSeconds = _activeStageDuration * 60;
      if (_remainingSeconds < 0 ||
          _remainingSeconds > maximumStageSeconds ||
          (_state == PomodoroState.paused && _remainingSeconds == 0)) {
        throw const FormatException('Invalid remaining focus time');
      }
      _completedPomodoros = snapshot['completedPomodoros'] as int? ?? 0;
      _activityCyclesCompleted =
          snapshot['activityCyclesCompleted'] as int? ?? 0;
      _activityMinutesCompleted =
          snapshot['activityMinutesCompleted'] as int? ?? 0;
      _activityPendingCompletion =
          snapshot['activityPendingCompletion'] as bool? ?? false;
      _quickSessionName = snapshot['quickSessionName'] as String?;
      _linkedNoteId = snapshot['linkedNoteId'] as String?;
      _activeFocusSessionId = snapshot['activeFocusSessionId'] as String?;
      _timerEndTime = _parseSnapshotDate(snapshot['timerEndTime']);
      _sessionStartTime = _parseSnapshotDate(snapshot['sessionStartTime']);
      _quickSessionStartedAt =
          _parseSnapshotDate(snapshot['quickSessionStartedAt']);

      final activityJson = snapshot['currentActivity'];
      _currentActivity = activityJson is Map<String, dynamic>
          ? PomodoroActivity.fromJson(activityJson)
          : activityJson is Map
              ? PomodoroActivity.fromJson(
                  Map<String, dynamic>.from(activityJson),
                )
              : null;

      if (_state == PomodoroState.running) {
        final endTime = _timerEndTime;
        if (endTime == null) {
          throw const FormatException('Running session without end time');
        }
        _remainingSeconds = endTime
            .difference(_clock())
            .inSeconds
            .clamp(0, maximumStageSeconds)
            .toInt();
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _state = PomodoroState.finished;
          return true;
        }
      }
      if (_state == PomodoroState.finished && _remainingSeconds == 0) {
        return true;
      }

      _emit();
      return false;
    } catch (error, stack) {
      AppLogger().error(
        'Pomodoro',
        'Discarding invalid active session snapshot',
        error,
        stack,
      );
      await prefs.remove(_activeSessionKey);
      _resetToWorkSession();
      return false;
    }
  }

  DateTime? _parseSnapshotDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _saveActiveSession({int? expectedGeneration}) {
    final generation = expectedGeneration ?? _ownerGeneration;
    final activeSessionKey = _activeSessionKey;
    final shouldRemove = canShowLauncher;
    final snapshot = shouldRemove
        ? null
        : <String, dynamic>{
            'version': _activeSessionSchemaVersion,
            'mode': _mode.name,
            'sessionType': _sessionType.name,
            'state': _state.name,
            'remainingSeconds': _remainingSeconds,
            'activeStageDuration': _activeStageDuration,
            'completedPomodoros': _completedPomodoros,
            'activityCyclesCompleted': _activityCyclesCompleted,
            'activityMinutesCompleted': _activityMinutesCompleted,
            'activityPendingCompletion': _activityPendingCompletion,
            'quickSessionName': _quickSessionName,
            'linkedNoteId': _linkedNoteId,
            'activeFocusSessionId': _activeFocusSessionId,
            'timerEndTime': _timerEndTime?.toUtc().toIso8601String(),
            'sessionStartTime': _sessionStartTime?.toUtc().toIso8601String(),
            'quickSessionStartedAt':
                _quickSessionStartedAt?.toUtc().toIso8601String(),
            'currentActivity': _currentActivity?.toJson(),
          };
    return _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      if (shouldRemove) {
        await prefs.remove(activeSessionKey);
        return;
      }
      await prefs.setString(activeSessionKey, jsonEncode(snapshot));
    });
  }

  Future<void> _clearActiveSession() {
    final generation = _ownerGeneration;
    final activeSessionKey = _activeSessionKey;
    return _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.remove(activeSessionKey);
    });
  }

  void _restartPeriodicTimer() {
    _timer?.cancel();
    _timer = _periodicTimerFactory(const Duration(seconds: 1), _tick);
  }

  Future<void> _waitForPendingCompletion() async {
    final pendingCompletion = _completionFuture;
    if (pendingCompletion != null) {
      await pendingCompletion;
    }
  }

  String _newSessionId(String _) => const Uuid().v4();

  void selectMode(PomodoroMode mode) {
    if (!canShowLauncher) return;
    _mode = mode;
    _resetToWorkSession();
    _emit();
  }

  /// Starts one independent focus session.
  Future<void> startQuickSession({String? name, String? noteId}) async {
    await _waitForPendingCompletion();
    if (_isDisposed) return;
    if (!canShowLauncher) return;
    _mode = PomodoroMode.quick;
    final trimmedName = name?.trim();
    _quickSessionName =
        trimmedName == null || trimmedName.isEmpty ? null : trimmedName;
    _quickSessionStartedAt = _clock();
    _linkedNoteId = noteId;
    _currentActivity = null;
    _completedPomodoros = 0;
    _resetToWorkSession();
    _emit();
    await start();
  }

  /// Starts a full four-session Pomodoro cycle.
  Future<void> startCycleActivity(String name, {String? noteId}) async {
    await _waitForPendingCompletion();
    if (_isDisposed) return;
    final trimmedName = name.trim();
    if (!canShowLauncher) return;

    _mode = PomodoroMode.cycle;
    _quickSessionName = null;
    _quickSessionStartedAt = null;
    _linkedNoteId = noteId;
    final id = _newSessionId('cycle');
    _currentActivity = PomodoroActivity(
      id: id,
      name: trimmedName.isEmpty ? _defaultSessionName : trimmedName,
      startTime: _clock(),
      noteId: noteId,
    );
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;

    _completedPomodoros = 0;
    _resetToWorkSession();
    _emit();
    await start();
  }

  /// Compatibility entry point for older callers.
  Future<void> startActivity(String name) => startCycleActivity(name);

  /// Cancel current activity
  Future<void> cancelActivity() async {
    if (_isDisposed) return;
    _timer?.cancel();
    _timerEndTime = null;
    _sessionStartTime = null;
    await _endLiveActivity();
    if (_isDisposed) return;
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: true,
    );
    if (_isDisposed) return;
    _currentActivity = null;
    _quickSessionName = null;
    _quickSessionStartedAt = null;
    _linkedNoteId = null;
    _activeFocusSessionId = null;
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;
    _resetToWorkSession();
    await _clearActiveSession();
    _emit();
  }

  /// Complete and save current activity
  Future<void> _completeActivity({bool showNotification = true}) async {
    final completedActivity = _completeActivityInMemory();
    if (completedActivity == null) return;
    await _saveActivities();

    if (showNotification) {
      await _notificationService.showPomodoroCompleteNotification(
        activityName: completedActivity.name,
        cycles: completedActivity.cyclesCompleted,
        totalTime: Duration(minutes: completedActivity.totalMinutes),
      );
    }

    _emit();
  }

  PomodoroActivity? _completeActivityInMemory() {
    final currentActivity = _currentActivity;
    if (currentActivity == null) return null;

    final completedActivity = currentActivity.copyWith(
      endTime: _clock(),
      cyclesCompleted: _activityCyclesCompleted,
      totalMinutes: _activityMinutesCompleted,
      isCompleted: true,
    );
    final existingIndex = _activityHistory.indexWhere(
      (activity) => activity.id == completedActivity.id,
    );
    if (existingIndex == -1) {
      _activityHistory.insert(0, completedActivity);
    } else {
      _activityHistory[existingIndex] = completedActivity;
    }
    _justCompletedActivity = completedActivity;
    _currentActivity = null;
    _linkedNoteId = null;
    _activeFocusSessionId = null;
    _activityCyclesCompleted = 0;
    _activityMinutesCompleted = 0;
    _activityPendingCompletion = false;
    return completedActivity;
  }

  /// Start or resume the timer
  Future<void> start() async {
    await _waitForPendingCompletion();
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    final logger = AppLogger();
    logger.info(
      'Pomodoro',
      'start() called, state=$_state, sessionType=$_sessionType, remainingSeconds=$_remainingSeconds',
    );

    if (_state == PomodoroState.running) {
      logger.warning('Pomodoro', 'start() blocked - already running');
      return;
    }

    // Cancel any existing timer to prevent duplicates
    _timer?.cancel();

    // Cancel completion/alarm notification from previous session
    await _notificationService.cancelCompletionNotification();
    if (!_isGenerationActive(generation)) return;

    // Track session start time for calculating real minutes
    _sessionStartTime ??= _clock();
    if (_sessionType == SessionType.work) {
      _activeFocusSessionId ??= _newSessionId('focus');
    }

    // Calculate when timer should end (for background support)
    _timerEndTime = _clock().add(Duration(seconds: _remainingSeconds));

    _state = PomodoroState.running;
    _restartPeriodicTimer();
    await _saveActiveSession();
    if (!_isGenerationActive(generation)) return;
    logger.info('Pomodoro', 'Timer started, endTime=$_timerEndTime');

    // Start foreground service to keep app alive in background
    try {
      await _startForegroundService();
      if (!_isGenerationActive(generation)) return;
      logger.info('Pomodoro', 'Foreground service started');
    } catch (e) {
      logger.error('Pomodoro', 'Error starting foreground service', e);
    }
    await _startLiveActivity(expectedGeneration: generation);
    if (!_isGenerationActive(generation)) return;

    // Native scheduling is only needed while the app is in background.
    if (!_isAppInForeground) {
      await _scheduleTimerEndNotification(expectedGeneration: generation);
      if (!_isGenerationActive(generation)) return;
      logger.info('Pomodoro', 'End notification scheduled');
    }
    _emit();
  }

  /// Called when app returns from background - recalculates remaining time
  Future<void> onAppResumed() async {
    if (_isDisposed ||
        _state != PomodoroState.running ||
        _timerEndTime == null) {
      return;
    }

    final now = _clock();
    final remaining = _timerEndTime!.difference(now).inSeconds;

    if (remaining <= 0) {
      // Timer should have finished while in background
      _remainingSeconds = 0;
      _timer?.cancel();
      await _onSessionComplete(notificationAlreadyDelivered: true);
    } else {
      // Update remaining time
      _remainingSeconds = remaining;
      _restartPeriodicTimer();
      await _saveActiveSession();
      _emit();
    }
  }

  /// Schedule notification for when current timer ends
  Future<void> _scheduleTimerEndNotification({
    int? expectedGeneration,
  }) async {
    final generation = expectedGeneration ?? _ownerGeneration;
    if (!_isGenerationActive(generation)) return;
    final duration = Duration(seconds: _remainingSeconds);
    final activityName =
        _currentActivity?.name ?? _quickSessionName ?? 'Enfoque';

    await _foregroundCoordinator.runIfOwned(
      _foregroundOwner,
      () async {
        if (!_isGenerationActive(generation)) return;
        if (_sessionType == SessionType.work) {
          await _notificationService.schedulePomodoroWorkEnd(
            duration: duration,
            activityName: activityName,
            isQuickSession: isQuickMode,
          );
        } else {
          await _notificationService.schedulePomodoroBreakEnd(
            duration: duration,
            activityName: activityName,
            completesCycle: isActivityFinalBreak,
          );
        }
      },
    );
  }

  Future<void> _cancelOwnedPomodoroNotifications({
    required int expectedGeneration,
  }) {
    return _foregroundCoordinator.runIfOwned(
      _foregroundOwner,
      () async {
        if (!_isGenerationActive(expectedGeneration)) return;
        await _notificationService.cancelPomodoroNotifications();
      },
    ).then<void>((_) {});
  }

  /// Pause the timer
  Future<void> pause() async {
    if (_isDisposed || _state != PomodoroState.running) return;
    final endTime = _timerEndTime;
    if (endTime != null) {
      _remainingSeconds =
          endTime.difference(_clock()).inSeconds.clamp(0, 3600).toInt();
    }
    _timer?.cancel();
    _timerEndTime = null; // Clear end time when paused
    _state = PomodoroState.paused;
    // Publish the interaction before waiting on native cleanup or disk I/O.
    // Those effects can be noticeably slower on a real device.
    _emit();
    await _updateLiveActivity(expectedGeneration: _ownerGeneration);
    if (_isDisposed) return;
    // Stop foreground service when paused
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: false,
    );
    if (_isDisposed) return;
    await _saveActiveSession();
  }

  /// Reset current session
  Future<void> reset() async {
    if (_isDisposed) return;
    _timer?.cancel();
    _timerEndTime = null; // Clear end time when reset
    _sessionStartTime = null;
    _state = PomodoroState.idle;
    _activeFocusSessionId = null;
    _activeStageDuration = _getConfiguredSessionDuration();
    _remainingSeconds = _activeStageDuration * 60;
    await _endLiveActivity();
    if (_isDisposed) return;
    // Stop foreground service when reset
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: true,
    );
    if (_isDisposed) return;
    await _saveActiveSession();
    _emit();
  }

  /// Ends the current focus early or skips a break without awarding focus.
  Future<void> skip() async {
    if (_isDisposed) return;
    _timer?.cancel();
    _timerEndTime = null;
    _sessionStartTime = null;

    await _endLiveActivity();
    if (_isDisposed) return;
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: true,
    );
    if (_isDisposed) return;

    if (_sessionType == SessionType.work) {
      _state = PomodoroState.idle;
      _remainingSeconds = _workDuration * 60;
      _activeStageDuration = _workDuration;
      _activeFocusSessionId = null;
      if (isQuickMode) {
        _quickSessionName = null;
        _quickSessionStartedAt = null;
        _linkedNoteId = null;
      }
    } else if (_sessionType == SessionType.longBreak) {
      if (_currentActivity != null && _activityPendingCompletion) {
        await _completeActivity(showNotification: false);
      }
      _resetToWorkSession();
    } else {
      _resetToWorkSession();
    }

    await _saveActiveSession();
    _emit();
  }

  /// Set and persist work duration (in minutes)
  Future<void> setWorkDuration(int minutes) async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    _workDuration = minutes.clamp(5, 60).toInt();
    if (_sessionType == SessionType.work && _state == PomodoroState.idle) {
      _activeStageDuration = _workDuration;
      _remainingSeconds = _workDuration * 60;
    }
    final key = _workDurationKey;
    final value = _workDuration;
    await _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(key, value);
    });
    _emit();
  }

  /// Set and persist short break duration (in minutes)
  Future<void> setShortBreakDuration(int minutes) async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    _shortBreakDuration = minutes.clamp(1, 15).toInt();
    if (_sessionType == SessionType.shortBreak &&
        _state == PomodoroState.idle) {
      _activeStageDuration = _shortBreakDuration;
      _remainingSeconds = _shortBreakDuration * 60;
    }
    final key = _shortBreakDurationKey;
    final value = _shortBreakDuration;
    await _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(key, value);
    });
    _emit();
  }

  /// Set and persist long break duration (in minutes)
  Future<void> setLongBreakDuration(int minutes) async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    _longBreakDuration = minutes.clamp(5, 30).toInt();
    if (_sessionType == SessionType.longBreak && _state == PomodoroState.idle) {
      _activeStageDuration = _longBreakDuration;
      _remainingSeconds = _longBreakDuration * 60;
    }
    final key = _longBreakDurationKey;
    final value = _longBreakDuration;
    await _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.setInt(key, value);
    });
    _emit();
  }

  /// Toggle alarm sound for pomodoro completion
  Future<void> toggleAlarm(bool enabled) async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    _alarmEnabled = enabled;
    final alarmKey = _currentUserId != null
        ? 'pomodoro_alarm_$_currentUserId'
        : 'pomodoro_alarm';
    await _trackPersistence(() async {
      if (!_isGenerationActive(generation)) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_isGenerationActive(generation)) return;
      await prefs.setBool(alarmKey, enabled);
    });
    _emit();
  }

  /// Manually select session type
  void selectSessionType(SessionType type) {
    if (_state == PomodoroState.running) return;
    if (_currentActivity != null) return; // Can't change type during activity

    _timer?.cancel();
    _sessionType = type;
    _state = PomodoroState.idle;
    _activeStageDuration = _getConfiguredSessionDuration();
    _remainingSeconds = _activeStageDuration * 60;
    _emit();
  }

  // Private methods
  void _tick(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    final logger = AppLogger();
    final endTime = _timerEndTime;
    if (_state != PomodoroState.running || endTime == null) return;

    final remaining = endTime.difference(_clock()).inSeconds;
    _remainingSeconds = remaining.clamp(0, _activeStageDuration * 60).toInt();

    if (_remainingSeconds % 60 == 0) {
      logger.info('Pomodoro', '_tick: remainingSeconds=$_remainingSeconds');
    }

    unawaited(_updateForegroundNotification());
    _emit();

    if (_remainingSeconds == 0) {
      logger.info(
        'Pomodoro',
        '_tick: Deadline reached, completing current session',
      );
      timer.cancel();
      unawaited(_onSessionComplete());
    }
  }

  /// Keeps one notification path active: in-app while visible, native while
  /// in background.
  Future<void> setAppInForeground(bool inForeground) async {
    if (_isDisposed) return;
    final generation = _ownerGeneration;
    final targetInForeground = inForeground;
    _isAppInForeground = targetInForeground;
    _foregroundTransition =
        _foregroundTransition.catchError((_) {}).then((_) async {
      if (!_isGenerationActive(generation)) return;
      if (_state != PomodoroState.running) {
        await _cancelOwnedPomodoroNotifications(
          expectedGeneration: generation,
        );
        return;
      }
      if (targetInForeground) {
        await _cancelOwnedPomodoroNotifications(
          expectedGeneration: generation,
        );
      } else {
        await _scheduleTimerEndNotification(
          expectedGeneration: generation,
        );
      }
    });
    await _foregroundTransition;
  }

  Future<void> _onSessionComplete({
    bool notificationAlreadyDelivered = false,
  }) {
    if (_isDisposed) return Future<void>.value();
    final pendingCompletion = _completionFuture;
    if (pendingCompletion != null) return pendingCompletion;

    late final Future<void> completion;
    completion = _performSessionCompletion(
      notificationAlreadyDelivered: notificationAlreadyDelivered,
    ).whenComplete(() {
      if (identical(_completionFuture, completion)) {
        _completionFuture = null;
      }
    });
    _completionFuture = completion;
    return completion;
  }

  Future<void> _performSessionCompletion({
    required bool notificationAlreadyDelivered,
  }) async {
    final generation = _ownerGeneration;
    if (!_isGenerationActive(generation)) return;
    final completedSessionType = _sessionType;
    final focusSessionId = _activeFocusSessionId;
    final token =
        '$generation:${focusSessionId ?? completedSessionType.name}:$_remainingSeconds';
    if (_completionToken != null) return;
    _completionToken = token;

    final logger = AppLogger();
    final activityName =
        _currentActivity?.name ?? _quickSessionName ?? _defaultSessionName;
    final shouldShowImmediateNotification =
        _isAppInForeground && !notificationAlreadyDelivered;
    final completedAt = _clock();
    final linkedNoteId = _linkedNoteId;
    var historyChanged = false;
    var completedCyclesForNotification = _activityCyclesCompleted;
    var completedMinutesForNotification = _activityMinutesCompleted;

    try {
      logger.info(
        'Pomodoro',
        '_onSessionComplete() called, sessionType=$completedSessionType',
      );

      _timer?.cancel();
      _timerEndTime = null;
      _state = PomodoroState.finished;
      await _endLiveActivity();
      if (!_isGenerationActive(generation)) return;

      if (completedSessionType == SessionType.work) {
        final stableFocusId = focusSessionId ?? _newSessionId('focus');
        final shouldAward = _awardedFocusSessionIds.add(stableFocusId);

        if (shouldAward) {
          _checkNewDay();
          _completedPomodoros++;
          _todayPomodoros++;
          _totalPomodoros++;
          _todayRealMinutes += _activeStageDuration;
          _totalRealMinutes += _activeStageDuration;
          _lastPomodoroDate = completedAt;
          _firstPomodoroDate ??= completedAt;
          _lastAwardedFocusSessionId = stableFocusId;
          if (linkedNoteId != null) {
            _pendingNoteReviews[stableFocusId] = _PendingNoteReview(
              sessionId: stableFocusId,
              noteId: linkedNoteId,
              reviewedAt: completedAt.toUtc(),
            );
          }
        }

        if (isCycleMode && _currentActivity != null) {
          // A stale finished snapshot is replayed only when its stage counters
          // were not persisted. Advancing here repairs that snapshot without
          // awarding the canonical progress record twice.
          _activityCyclesCompleted++;
          _activityMinutesCompleted += _activeStageDuration;
          _activityPendingCompletion =
              _activityCyclesCompleted >= _pomodorosUntilLongBreak;
        } else {
          final existingIndex = _activityHistory.indexWhere(
            (activity) => activity.id == stableFocusId,
          );
          final completedQuickSession = PomodoroActivity(
            id: stableFocusId,
            name: activityName,
            startTime: _quickSessionStartedAt ??
                _sessionStartTime ??
                completedAt.subtract(
                  Duration(minutes: _activeStageDuration),
                ),
            endTime: completedAt,
            cyclesCompleted: 1,
            totalMinutes: _activeStageDuration,
            isCompleted: true,
            noteId: linkedNoteId,
          );
          if (existingIndex == -1) {
            _activityHistory.insert(0, completedQuickSession);
            historyChanged = true;
          }
          if (shouldAward) {
            _justCompletedActivity = completedQuickSession;
          }
        }
        _sessionStartTime = null;
      } else if (completedSessionType == SessionType.longBreak &&
          _currentActivity != null &&
          _activityPendingCompletion) {
        completedCyclesForNotification = _activityCyclesCompleted;
        completedMinutesForNotification = _activityMinutesCompleted;
        historyChanged = _completeActivityInMemory() != null;
      }

      // Finish the canonical state transition before running any integration
      // effect. A failed haptic, note callback or notification must never
      // strand the timer in PomodoroState.finished.
      _moveToNextSession();
      _emit();

      await _saveStats(expectedGeneration: generation);
      if (!_isGenerationActive(generation)) return;
      if (historyChanged) {
        await _saveActivities(expectedGeneration: generation);
        if (!_isGenerationActive(generation)) return;
      }
      await _saveActiveSession(expectedGeneration: generation);
      if (!_isGenerationActive(generation)) return;

      await _drainPendingNoteReviews(expectedGeneration: generation);
      if (!_isGenerationActive(generation)) return;

      if (_completionTransitionDelay > Duration.zero) {
        await Future.delayed(_completionTransitionDelay);
        if (!_isGenerationActive(generation)) return;
      }

      await _runCompletionEffect(
        'stop foreground service',
        () async {
          if (!_isGenerationActive(generation)) return;
          await _stopForegroundService(cancelNotifications: true);
        },
        expectedGeneration: generation,
      );
      if (!_isGenerationActive(generation)) return;

      if (_isAppInForeground) {
        await _runCompletionEffect(
          'completion haptic',
          HapticFeedback.heavyImpact,
          expectedGeneration: generation,
        );
        if (!_isGenerationActive(generation)) return;
      }

      if (shouldShowImmediateNotification) {
        await _foregroundCoordinator.runIfOwned(
          _foregroundOwner,
          () async {
            if (!_isGenerationActive(generation)) return;
            await _showCompletionNotification(
              expectedGeneration: generation,
              completedSessionType: completedSessionType,
              activityName: activityName,
              completedCycles: completedCyclesForNotification,
              completedMinutes: completedMinutesForNotification,
            );
          },
        );
        if (!_isGenerationActive(generation)) return;
      }
      logger.info('Pomodoro', 'Session complete');
    } finally {
      if (_completionToken == token) {
        _completionToken = null;
      }
    }
  }

  Future<void> retryPendingNoteReviews() {
    if (_isDisposed) return Future<void>.value();
    return _drainPendingNoteReviews(
      expectedGeneration: _ownerGeneration,
    );
  }

  Future<void> _drainPendingNoteReviews({
    required int expectedGeneration,
  }) {
    final pendingReview = _pendingReviewFuture;
    if (pendingReview != null) return pendingReview;

    late final Future<void> review;
    review = _performPendingNoteReviews(
      expectedGeneration: expectedGeneration,
    ).whenComplete(() {
      if (identical(_pendingReviewFuture, review)) {
        _pendingReviewFuture = null;
      }
    });
    _pendingReviewFuture = review;
    return review;
  }

  Future<void> _performPendingNoteReviews({
    required int expectedGeneration,
  }) async {
    if (!_isGenerationActive(expectedGeneration)) return;
    final callback = onLinkedNoteFocused;
    if (callback == null || _pendingNoteReviews.isEmpty) return;

    for (final review in _pendingNoteReviews.values.toList()) {
      if (!_isGenerationActive(expectedGeneration)) return;
      try {
        await callback(
          review.noteId,
          review.reviewedAt,
          focusSessionId: review.sessionId,
        );
        if (!_isGenerationActive(expectedGeneration)) return;
        _pendingNoteReviews.remove(review.sessionId);
        await _saveStats(expectedGeneration: expectedGeneration);
        if (!_isGenerationActive(expectedGeneration)) return;
      } catch (error, stack) {
        AppLogger().error(
          'Pomodoro',
          'Could not apply linked note review; it will be retried',
          error,
          stack,
        );
        return;
      }
    }
  }

  Future<void> _runCompletionEffect(
    String label,
    Future<void> Function() effect, {
    required int expectedGeneration,
  }) async {
    if (!_isGenerationActive(expectedGeneration)) return;
    try {
      await effect();
    } catch (error, stack) {
      AppLogger().error(
        'Pomodoro',
        'Completion effect failed: $label',
        error,
        stack,
      );
    }
  }

  Future<void> _showCompletionNotification({
    required int expectedGeneration,
    required SessionType completedSessionType,
    required String activityName,
    required int completedCycles,
    required int completedMinutes,
  }) async {
    await _runCompletionEffect(
      'completion notification',
      () async {
        if (!_isGenerationActive(expectedGeneration)) return;
        if (completedSessionType == SessionType.work) {
          final breakLabel = isQuickMode
              ? 'Tu sesión terminó. Elige qué quieres hacer ahora.'
              : _activityPendingCompletion
                  ? 'Tu enfoque terminó. Inicia tu descanso largo.'
                  : 'Tu enfoque terminó. Inicia tu descanso corto.';
          if (_alarmEnabled) {
            await _notificationService.showAlarmNotification(
              title: 'Enfoque completado',
              body: breakLabel,
            );
          } else {
            await _notificationService.showInstantNotification(
              title: 'Enfoque completado',
              body: breakLabel,
            );
          }
          return;
        }

        if (completedSessionType == SessionType.longBreak &&
            completedCycles >= _pomodorosUntilLongBreak) {
          if (_alarmEnabled) {
            await _notificationService.showAlarmNotification(
              title: 'Ciclo Pomodoro completado',
              body: '$completedCycles enfoques completados.',
            );
          } else {
            await _notificationService.showPomodoroCompleteNotification(
              activityName: activityName,
              cycles: completedCycles,
              totalTime: Duration(minutes: completedMinutes),
            );
          }
          return;
        }

        final isLongBreak = completedSessionType == SessionType.longBreak;
        final title =
            isLongBreak ? 'Descanso largo terminado' : 'Descanso terminado';
        const body = 'Es momento de volver al enfoque.';
        if (_alarmEnabled) {
          await _notificationService.showAlarmNotification(
            title: title,
            body: body,
          );
        } else {
          await _notificationService.showInstantNotification(
            title: title,
            body: body,
          );
        }
      },
      expectedGeneration: expectedGeneration,
    );
  }

  void _moveToNextSession() {
    if (_sessionType == SessionType.work) {
      if (isQuickMode) {
        _quickSessionName = null;
        _quickSessionStartedAt = null;
        _linkedNoteId = null;
        _sessionType = SessionType.work;
      } else if (_activityPendingCompletion) {
        _sessionType = SessionType.longBreak;
      } else {
        _sessionType = SessionType.shortBreak;
      }
    } else if (_sessionType == SessionType.longBreak) {
      _completedPomodoros = 0;
      _sessionType = SessionType.work;
    } else {
      _sessionType = SessionType.work;
    }

    _state = PomodoroState.idle;
    _sessionStartTime = null;
    _activeFocusSessionId = null;
    _activeStageDuration = _getConfiguredSessionDuration();
    _remainingSeconds = _activeStageDuration * 60;
  }

  void _resetToWorkSession() {
    _sessionType = SessionType.work;
    _state = PomodoroState.idle;
    _activeStageDuration = _workDuration;
    _remainingSeconds = _workDuration * 60;
  }

  int _getConfiguredSessionDuration() {
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
    final now = _clock();
    if (_lastPomodoroDate == null) return;

    if (now.day != _lastPomodoroDate!.day ||
        now.month != _lastPomodoroDate!.month ||
        now.year != _lastPomodoroDate!.year) {
      _todayPomodoros = 0;
      _todayRealMinutes = 0;
    }
  }

  Future<void> _trackPersistence(Future<void> Function() operation) {
    late final Future<void> pending;
    pending = Future<void>.sync(operation).whenComplete(() {
      _pendingPersistence.remove(pending);
    });
    _pendingPersistence.add(pending);
    return pending;
  }

  Future<void> _waitForPendingPersistence() async {
    while (_pendingPersistence.isNotEmpty) {
      final pending = _pendingPersistence.toList(growable: false);
      for (final operation in pending) {
        try {
          await operation;
        } catch (error, stack) {
          AppLogger().error(
            'Pomodoro',
            'Persistence failed while shutting down',
            error,
            stack,
          );
        }
      }
    }
  }

  void _invalidateLifecycle() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ownerGeneration++;
    _timer?.cancel();
    _timer = null;
    onLinkedNoteFocused = null;
  }

  Future<void> shutdown() {
    final pendingShutdown = _shutdownFuture;
    if (pendingShutdown != null) return pendingShutdown;

    _invalidateLifecycle();
    final shutdown = _performShutdown();
    _shutdownFuture = shutdown;
    return shutdown;
  }

  Future<void> _performShutdown() async {
    final completion = _completionFuture;
    final review = _pendingReviewFuture;
    try {
      if (completion != null) await completion;
      if (review != null && !identical(review, completion)) await review;
    } catch (error, stack) {
      AppLogger().error(
        'Pomodoro',
        'Lifecycle work failed while shutting down',
        error,
        stack,
      );
    }

    await _waitForPendingPersistence();
    await _endLiveActivity();
    try {
      await _foregroundTransition;
    } catch (error, stack) {
      AppLogger().error(
        'Pomodoro',
        'Foreground transition failed while shutting down',
        error,
        stack,
      );
    }
    await _stopForegroundService(
      cancelNotifications: true,
      releaseOwnership: true,
    );
    await _waitForPendingPersistence();
  }

  void dispose() {
    unawaited(
      shutdown().catchError((Object error, StackTrace stack) {
        AppLogger().error(
          'Pomodoro',
          'Could not shut down Pomodoro while disposing',
          error,
          stack,
        );
      }),
    );
  }

  /// Cleans up any stale notifications (call on app startup)
  Future<void> cleanupStaleNotifications() async {
    if (_isDisposed) return;
    if (_state != PomodoroState.running) {
      await _endLiveActivity();
      await _stopForegroundService(
        cancelNotifications: true,
        releaseOwnership: true,
        allowUnowned: true,
      );
    }
  }
}

@immutable
class PomodoroViewState {
  final PomodoroState state;
  final SessionType sessionType;
  final int remainingSeconds;
  final int completedPomodoros;
  final int todayPomodoros;
  final int totalPomodoros;
  final DateTime? firstPomodoroDate;
  final PomodoroMode mode;
  final String? quickSessionName;
  final String? linkedNoteId;
  final String? activeFocusSessionId;
  final int activeStageDuration;
  final bool isQuickMode;
  final bool isCycleMode;
  final bool canShowLauncher;
  final int todayMinutes;
  final int totalMinutes;
  final String totalHoursFormatted;
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final PomodoroActivity? currentActivity;
  final List<PomodoroActivity> activityHistory;
  final bool hasActiveActivity;
  final bool isActivityPendingCompletion;
  final int activityCyclesCompleted;
  final PomodoroActivity? justCompletedActivity;
  final bool alarmEnabled;
  final int todayActivities;
  final int totalActivities;
  final bool isActivityFinalBreak;
  final String formattedTime;
  final double progress;
  final String sessionLabel;
  final bool isBreak;
  final List<DailyPomodoroSummary> dailySummaries;
  final List<Map<String, dynamic>> weeklyChartData;

  const PomodoroViewState({
    required this.state,
    required this.sessionType,
    required this.remainingSeconds,
    required this.completedPomodoros,
    required this.todayPomodoros,
    required this.totalPomodoros,
    required this.firstPomodoroDate,
    required this.mode,
    required this.quickSessionName,
    required this.linkedNoteId,
    required this.activeFocusSessionId,
    required this.activeStageDuration,
    required this.isQuickMode,
    required this.isCycleMode,
    required this.canShowLauncher,
    required this.todayMinutes,
    required this.totalMinutes,
    required this.totalHoursFormatted,
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.currentActivity,
    required this.activityHistory,
    required this.hasActiveActivity,
    required this.isActivityPendingCompletion,
    required this.activityCyclesCompleted,
    required this.justCompletedActivity,
    required this.alarmEnabled,
    required this.todayActivities,
    required this.totalActivities,
    required this.isActivityFinalBreak,
    required this.formattedTime,
    required this.progress,
    required this.sessionLabel,
    required this.isBreak,
    required this.dailySummaries,
    required this.weeklyChartData,
  });

  factory PomodoroViewState.fromEngine(PomodoroEngine engine) {
    return PomodoroViewState(
      state: engine.state,
      sessionType: engine.sessionType,
      remainingSeconds: engine.remainingSeconds,
      completedPomodoros: engine.completedPomodoros,
      todayPomodoros: engine.todayPomodoros,
      totalPomodoros: engine.totalPomodoros,
      firstPomodoroDate: engine.firstPomodoroDate,
      mode: engine.mode,
      quickSessionName: engine.quickSessionName,
      linkedNoteId: engine.linkedNoteId,
      activeFocusSessionId: engine.activeFocusSessionId,
      activeStageDuration: engine.activeStageDuration,
      isQuickMode: engine.isQuickMode,
      isCycleMode: engine.isCycleMode,
      canShowLauncher: engine.canShowLauncher,
      todayMinutes: engine.todayMinutes,
      totalMinutes: engine.totalMinutes,
      totalHoursFormatted: engine.totalHoursFormatted,
      workDuration: engine.workDuration,
      shortBreakDuration: engine.shortBreakDuration,
      longBreakDuration: engine.longBreakDuration,
      currentActivity: engine.currentActivity,
      activityHistory: List.unmodifiable(engine.activityHistory),
      hasActiveActivity: engine.hasActiveActivity,
      isActivityPendingCompletion: engine.isActivityPendingCompletion,
      activityCyclesCompleted: engine.activityCyclesCompleted,
      justCompletedActivity: engine.justCompletedActivity,
      alarmEnabled: engine.alarmEnabled,
      todayActivities: engine.todayActivities,
      totalActivities: engine.totalActivities,
      isActivityFinalBreak: engine.isActivityFinalBreak,
      formattedTime: engine.formattedTime,
      progress: engine.progress,
      sessionLabel: engine.sessionLabel,
      isBreak: engine.isBreak,
      dailySummaries: List.unmodifiable(engine.dailySummaries),
      weeklyChartData: List.unmodifiable(
        engine.weeklyChartData.map(Map<String, dynamic>.unmodifiable),
      ),
    );
  }
}

class PomodoroController extends FamilyNotifier<PomodoroViewState, String> {
  late PomodoroEngine _engine;
  var _isReady = false;
  var _isDisposed = false;

  @override
  PomodoroViewState build(String ownerId) {
    _isReady = false;
    _isDisposed = false;
    final factory = ref.watch(pomodoroEngineFactoryProvider);
    _engine = factory(
      ownerId: ownerId,
      onChanged: _publish,
    );
    _isReady = true;
    ref.onDispose(() {
      _isDisposed = true;
      _engine.dispose();
    });
    return PomodoroViewState.fromEngine(_engine);
  }

  void _publish() {
    if (!_isReady || _isDisposed) return;
    state = PomodoroViewState.fromEngine(_engine);
  }

  LinkedNoteFocusCallback? get onLinkedNoteFocused =>
      _engine.onLinkedNoteFocused;

  set onLinkedNoteFocused(LinkedNoteFocusCallback? callback) {
    _engine.onLinkedNoteFocused = callback;
  }

  Future<void> initialize() => _engine.initialize();

  Future<void> refreshAfterSync() => _engine.refreshAfterSync();

  Future<void> setCurrentUser(String? userId) => _engine.setCurrentUser(userId);

  void clearJustCompletedActivity() => _engine.clearJustCompletedActivity();

  void selectMode(PomodoroMode mode) => _engine.selectMode(mode);

  Future<void> startQuickSession({String? name, String? noteId}) =>
      _engine.startQuickSession(name: name, noteId: noteId);

  Future<void> startCycleActivity(String name, {String? noteId}) =>
      _engine.startCycleActivity(name, noteId: noteId);

  Future<void> startActivity(String name) => _engine.startActivity(name);

  Future<void> cancelActivity() => _engine.cancelActivity();

  Future<void> start() => _engine.start();

  Future<void> onAppResumed() => _engine.onAppResumed();

  Future<void> pause() => _engine.pause();

  Future<void> reset() => _engine.reset();

  Future<void> skip() => _engine.skip();

  Future<void> setWorkDuration(int minutes) => _engine.setWorkDuration(minutes);

  Future<void> setShortBreakDuration(int minutes) =>
      _engine.setShortBreakDuration(minutes);

  Future<void> setLongBreakDuration(int minutes) =>
      _engine.setLongBreakDuration(minutes);

  Future<void> toggleAlarm(bool enabled) => _engine.toggleAlarm(enabled);

  void selectSessionType(SessionType type) => _engine.selectSessionType(type);

  Future<void> setAppInForeground(bool inForeground) =>
      _engine.setAppInForeground(inForeground);

  Future<void> retryPendingNoteReviews() => _engine.retryPendingNoteReviews();

  Future<void> cleanupStaleNotifications() =>
      _engine.cleanupStaleNotifications();

  Future<void> shutdown() => _engine.shutdown();
}

@immutable
class _PendingNoteReview {
  final String sessionId;
  final String noteId;
  final DateTime reviewedAt;

  const _PendingNoteReview({
    required this.sessionId,
    required this.noteId,
    required this.reviewedAt,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'noteId': noteId,
        'reviewedAt': reviewedAt.toUtc().toIso8601String(),
      };

  static _PendingNoteReview? tryFromJson(Map<String, dynamic> json) {
    final sessionId = json['sessionId'];
    final noteId = json['noteId'];
    final reviewedAt = json['reviewedAt'];
    if (sessionId is! String ||
        sessionId.isEmpty ||
        noteId is! String ||
        noteId.isEmpty ||
        reviewedAt is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(reviewedAt);
    if (parsed == null) return null;
    return _PendingNoteReview(
      sessionId: sessionId,
      noteId: noteId,
      reviewedAt: parsed.toUtc(),
    );
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
