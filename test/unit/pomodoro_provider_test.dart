import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/domain/focus_repository.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/infrastructure/live_activity_service.dart';

class _MutableClock {
  DateTime now;

  _MutableClock(this.now);

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

class _ManualTimer implements Timer {
  final void Function(Timer timer) callback;
  bool _isActive = true;
  int _tick = 0;

  _ManualTimer(this.callback);

  void fire() {
    if (!_isActive) return;
    _tick++;
    callback(this);
  }

  @override
  void cancel() => _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;
}

class _ManualTimerFactory {
  _ManualTimer? latest;

  Timer create(Duration duration, void Function(Timer timer) callback) {
    return latest = _ManualTimer(callback);
  }
}

class _FakeLiveActivityService extends LiveActivityService {
  String? startedActivityName;
  String? updatedActivityName;
  bool? updatedIsPaused;
  DateTime? updatedEndTime;
  int endedCount = 0;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<String?> startPomodoroActivity({
    required DateTime? endTime,
    required String sessionType,
    required String activityName,
    required int remainingSeconds,
    required int stageDurationSeconds,
    required bool isPaused,
    required String nextLabel,
  }) async {
    startedActivityName = activityName;
    return 'live-activity-test';
  }

  @override
  Future<void> updatePomodoroActivity({
    required DateTime? endTime,
    required String sessionType,
    required String activityName,
    required int remainingSeconds,
    required int stageDurationSeconds,
    required bool isPaused,
    required String nextLabel,
  }) async {
    updatedActivityName = activityName;
    updatedIsPaused = isPaused;
    updatedEndTime = endTime;
  }

  @override
  Future<void> endPomodoroActivity() async {
    endedCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  final foregroundCalls = <MethodCall>[];
  final notificationCalls = <MethodCall>[];
  var foregroundServiceRunning = false;
  Completer<void>? stopServiceGate;

  setUpAll(() {
    tz.setLocalLocation(tz.UTC);
    FlutterForegroundTask.skipServiceResponseCheck = true;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      foregroundChannel,
      (call) async {
        foregroundCalls.add(call);
        if (call.method == 'isRunningService') {
          return foregroundServiceRunning;
        }
        if (call.method == 'startService') {
          foregroundServiceRunning = true;
        } else if (call.method == 'stopService') {
          final gate = stopServiceGate;
          if (gate != null) await gate.future;
          foregroundServiceRunning = false;
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async {
        notificationCalls.add(call);
        return null;
      },
    );
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    foregroundServiceRunning = false;
    stopServiceGate = null;
    foregroundCalls.clear();
    notificationCalls.clear();
  });

  test('duration choices persist across provider instances', () async {
    final provider = PomodoroEngine();
    await provider.setWorkDuration(45);
    await provider.setShortBreakDuration(7);
    await provider.setLongBreakDuration(20);

    final restored = PomodoroEngine();
    await restored.initialize();

    expect(restored.workDuration, 45);
    expect(restored.shortBreakDuration, 7);
    expect(restored.longBreakDuration, 20);
    expect(restored.remainingSeconds, 45 * 60);
  });

  test('canonical focus history and progress load from the owner repository',
      () async {
    final startedAt = DateTime.utc(2026, 7, 26, 12);
    final repository = _MemoryFocusRepository(
      ownerId: 'owner-a',
      sessions: [
        PomodoroActivity(
          id: 'focus-a',
          name: 'Trabajo profundo',
          startTime: startedAt,
          endTime: startedAt.add(const Duration(minutes: 25)),
          cyclesCompleted: 1,
          totalMinutes: 25,
          isCompleted: true,
        ),
      ],
      progress: {
        'version': 1,
        'totalPomodoros': 7,
        'todayPomodoros': 2,
        'totalMinutes': 175,
        'todayMinutes': 50,
        'firstPomodoroDate': startedAt.toIso8601String(),
        'lastPomodoroDate': startedAt.toIso8601String(),
        'awardedSessionIds': const <String>[],
        'pendingNoteReviews': const <Object?>[],
      },
    );
    SharedPreferences.setMockInitialValues({
      'pomodoro_total_owner-a': 999,
      'pomodoro_activities_owner-a': '[]',
    });
    final provider = PomodoroEngine(
      initialUserId: 'owner-a',
      focusRepository: repository,
      clock: () => startedAt,
    );

    await provider.initialize();

    expect(provider.totalPomodoros, 7);
    expect(provider.todayPomodoros, 2);
    expect(provider.totalMinutes, 175);
    expect(provider.activityHistory.single.id, 'focus-a');
    provider.dispose();
  });

  test('owner-bound focus repositories reject cross-account reuse', () async {
    final repository = _MemoryFocusRepository(ownerId: 'owner-a');

    expect(
      () => PomodoroEngine(
        initialUserId: 'owner-b',
        focusRepository: repository,
      ),
      throwsArgumentError,
    );

    final provider = PomodoroEngine(
      initialUserId: 'owner-a',
      focusRepository: repository,
    );
    await expectLater(
      provider.setCurrentUser('owner-b'),
      throwsStateError,
    );
    provider.dispose();
  });

  test('focus duration is constrained to the supported 5 to 60 minute dial',
      () async {
    final provider = PomodoroEngine();

    await provider.setWorkDuration(90);
    expect(provider.workDuration, 60);
    expect(provider.remainingSeconds, 60 * 60);

    await provider.setWorkDuration(1);
    expect(provider.workDuration, 5);
    expect(provider.remainingSeconds, 5 * 60);
  });

  test('quick focus starts immediately and ending early awards nothing',
      () async {
    final provider = PomodoroEngine();
    await provider.setWorkDuration(15);

    await provider.startQuickSession(name: 'Preparar reporte');

    expect(provider.mode, PomodoroMode.quick);
    expect(provider.state, PomodoroState.running);
    expect(provider.sessionLabel, 'Preparar reporte');
    expect(provider.remainingSeconds, 15 * 60);

    await provider.skip();

    expect(provider.state, PomodoroState.idle);
    expect(provider.todayPomodoros, 0);
    expect(provider.todayMinutes, 0);
    expect(provider.canShowLauncher, isTrue);
  });

  test('a named quick session reaches the history under that name', () async {
    final clock = _MutableClock(DateTime.utc(2026, 8, 4, 9));
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(25);

    // Naming a session is only worth anything if the name survives into the
    // history, which is the only place the user can tell two sessions apart.
    await provider.startQuickSession(name: 'Estudiar Química');
    clock.advance(const Duration(minutes: 25));
    await provider.onAppResumed();

    expect(provider.activityHistory, hasLength(1));
    expect(provider.activityHistory.single.name, 'Estudiar Química');
    expect(provider.activityHistory.single.isCompleted, isTrue);

    // An unnamed session still lands in the history, just under the default.
    await provider.startQuickSession();
    clock.advance(const Duration(minutes: 25));
    await provider.onAppResumed();

    expect(provider.activityHistory, hasLength(2));
    expect(
      provider.activityHistory.map((a) => a.name),
      containsAll(<String>['Estudiar Química', 'Sesión de enfoque']),
    );
    provider.dispose();
  });

  test('a completed session cannot stop a newly started focus', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 27, 12));
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: const Duration(milliseconds: 40),
    );
    await provider.setWorkDuration(5);
    await provider.startQuickSession(name: 'Primera');

    clock.advance(const Duration(minutes: 5));
    final previousCompletion = provider.onAppResumed();
    final nextStart = provider.startQuickSession(name: 'Segunda');

    await Future.wait([previousCompletion, nextStart]);

    expect(provider.state, PomodoroState.running);
    expect(provider.remainingSeconds, 5 * 60);
    expect(provider.sessionLabel, 'Segunda');
    expect(foregroundServiceRunning, isTrue);
    final serviceCalls = foregroundCalls
        .where(
          (call) =>
              call.method == 'startService' || call.method == 'stopService',
        )
        .map((call) => call.method)
        .toList();
    expect(serviceCalls, ['startService', 'stopService', 'startService']);
    expect(
      foregroundCalls.where(
        (call) =>
            call.method == 'updateService' &&
            (call.arguments as Map<Object?, Object?>?)?['notificationText'] ==
                '00:00',
      ),
      isEmpty,
    );
    provider.dispose();
  });

  test('cycle title is optional and can be cancelled cleanly', () async {
    final provider = PomodoroEngine();

    await provider.startCycleActivity('');

    expect(provider.mode, PomodoroMode.cycle);
    expect(provider.state, PomodoroState.running);
    expect(provider.currentActivity?.name, 'Sesión de enfoque');
    expect(provider.activityCyclesCompleted, 0);

    await provider.cancelActivity();

    expect(provider.state, PomodoroState.idle);
    expect(provider.hasActiveActivity, isFalse);
    expect(provider.canShowLauncher, isTrue);
  });

  test('native timer notification is scheduled only in background', () async {
    final provider = PomodoroEngine();

    await provider.startQuickSession(name: 'Leer');

    expect(
      notificationCalls.where((call) => call.method == 'zonedSchedule'),
      isEmpty,
    );

    await provider.setAppInForeground(false);

    expect(
      notificationCalls.where((call) => call.method == 'zonedSchedule'),
      hasLength(1),
    );

    await provider.skip();
  });

  test('the scheduled notification never spells out the session name',
      () async {
    final provider = PomodoroEngine();

    await provider.startQuickSession(name: 'Terapia con Dr. Salas');
    await provider.setAppInForeground(false);

    // A notification lands on the lock screen, so it is held to the same rule
    // as the Live Activity: whatever the user typed stays inside the app. The
    // arguments are inspected rather than the method signature so that
    // interpolating the name into the title or body fails here too.
    final scheduled = notificationCalls
        .where((call) => call.method == 'zonedSchedule')
        .toList();
    expect(scheduled, hasLength(1));
    expect(
      scheduled.single.arguments.toString(),
      isNot(contains('Terapia')),
    );
    expect(provider.sessionLabel, 'Terapia con Dr. Salas');

    await provider.skip();
    provider.dispose();
  });

  test('Live Activity keeps a generic label through pause and exit', () async {
    final liveActivity = _FakeLiveActivityService();
    final provider = PomodoroEngine(
      liveActivityService: liveActivity,
      periodicTimerFactory: _ManualTimerFactory().create,
    );

    await provider.startQuickSession(name: 'Preparar reporte');

    // The lock screen and Dynamic Island are readable by anyone near the
    // phone, so the name the user typed must never reach them.
    expect(liveActivity.startedActivityName, 'Sesión de enfoque');
    expect(provider.sessionLabel, 'Preparar reporte');

    await provider.pause();

    expect(liveActivity.updatedActivityName, 'Sesión de enfoque');
    expect(liveActivity.updatedIsPaused, isTrue);
    expect(liveActivity.updatedEndTime, isNull);

    await provider.skip();

    expect(liveActivity.endedCount, 1);
    expect(provider.canShowLauncher, isTrue);
    provider.dispose();
  });

  test('pause publishes before native cleanup finishes', () async {
    final emittedStates = <PomodoroState>[];
    late final PomodoroEngine provider;
    provider = PomodoroEngine(
      onChanged: () => emittedStates.add(provider.state),
    );
    await provider.startQuickSession(name: 'Lectura');
    emittedStates.clear();
    stopServiceGate = Completer<void>();

    final pauseFuture = provider.pause();
    await Future<void>.delayed(Duration.zero);

    expect(emittedStates, contains(PomodoroState.paused));
    stopServiceGate!.complete();
    await pauseFuture;
    provider.dispose();
  });

  test('running session restores from its wall-clock deadline', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(5);
    await provider.startQuickSession(
      name: 'Repasar',
      noteId: 'note-1',
    );
    provider.dispose();

    clock.advance(const Duration(minutes: 2));
    final restoredTimers = _ManualTimerFactory();
    final restored = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: restoredTimers.create,
      completionTransitionDelay: Duration.zero,
    );
    await restored.initialize();

    expect(restored.state, PomodoroState.running);
    expect(restored.remainingSeconds, 3 * 60);
    expect(restored.quickSessionName, 'Repasar');
    expect(restored.linkedNoteId, 'note-1');
    expect(restored.activeFocusSessionId, isNotNull);
    expect(restoredTimers.latest?.isActive, isTrue);
    restored.dispose();
  });

  test('paused session restores without consuming wall-clock time', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(5);
    await provider.startQuickSession();
    clock.advance(const Duration(minutes: 1));
    timers.latest!.fire();
    await provider.pause();
    final pausedAt = provider.remainingSeconds;
    provider.dispose();

    clock.advance(const Duration(hours: 3));
    final restored = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await restored.initialize();

    expect(restored.state, PomodoroState.paused);
    expect(restored.remainingSeconds, pausedAt);
    restored.dispose();
  });

  test('expired session restores and is awarded exactly once', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(5);
    await provider.startQuickSession(name: 'Leer');
    provider.dispose();

    clock.advance(const Duration(minutes: 6));
    final restored = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await restored.initialize();

    expect(restored.todayPomodoros, 1);
    expect(restored.todayMinutes, 5);
    expect(restored.activityHistory, hasLength(1));
    expect(restored.activityHistory.single.name, 'Leer');
    expect(restored.canShowLauncher, isTrue);
    restored.dispose();

    final reopened = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await reopened.initialize();
    expect(reopened.todayPomodoros, 1);
    expect(reopened.activityHistory, hasLength(1));
    reopened.dispose();
  });

  test('completion journal repairs history without awarding focus twice',
      () async {
    final completedAt = DateTime.utc(2026, 7, 26, 12, 5);
    SharedPreferences.setMockInitialValues({
      'pomodoro_focus_progress': jsonEncode({
        'version': 1,
        'totalPomodoros': 1,
        'todayPomodoros': 1,
        'totalMinutes': 5,
        'todayMinutes': 5,
        'lastPomodoroDate': completedAt.toIso8601String(),
        'firstPomodoroDate': DateTime.utc(2026, 7, 26, 12).toIso8601String(),
        'awardedSessionIds': ['focus-recovery'],
        'pendingNoteReviews': <Object>[],
      }),
      'pomodoro_active_session': jsonEncode({
        'version': 1,
        'mode': 'quick',
        'sessionType': 'work',
        'state': 'running',
        'remainingSeconds': 300,
        'activeStageDuration': 5,
        'completedPomodoros': 0,
        'activityCyclesCompleted': 0,
        'activityMinutesCompleted': 0,
        'activityPendingCompletion': false,
        'quickSessionName': 'Recuperar historial',
        'activeFocusSessionId': 'focus-recovery',
        'timerEndTime': completedAt.toIso8601String(),
        'sessionStartTime': DateTime.utc(2026, 7, 26, 12).toIso8601String(),
        'quickSessionStartedAt':
            DateTime.utc(2026, 7, 26, 12).toIso8601String(),
      }),
    });
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12, 6));
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );

    await provider.initialize();

    expect(provider.todayPomodoros, 1);
    expect(provider.todayMinutes, 5);
    expect(provider.activityHistory, hasLength(1));
    expect(provider.activityHistory.single.id, 'focus-recovery');
    expect(provider.activityHistory.single.name, 'Recuperar historial');
    expect(provider.canShowLauncher, isTrue);
    provider.dispose();

    final reopened = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await reopened.initialize();
    expect(reopened.todayPomodoros, 1);
    expect(reopened.todayMinutes, 5);
    expect(reopened.activityHistory, hasLength(1));
    reopened.dispose();
  });

  test('cycle follows four focus stages and records one activity', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(5);
    await provider.setShortBreakDuration(1);
    await provider.setLongBreakDuration(5);
    await provider.startCycleActivity('');

    for (var focus = 1; focus <= 4; focus++) {
      clock.advance(Duration(minutes: provider.activeStageDuration));
      await provider.onAppResumed();

      expect(provider.activityCyclesCompleted, focus);
      expect(
        provider.sessionType,
        focus == 4 ? SessionType.longBreak : SessionType.shortBreak,
      );
      expect(provider.state, PomodoroState.idle);

      await provider.start();
      clock.advance(Duration(minutes: provider.activeStageDuration));
      await provider.onAppResumed();

      if (focus < 4) {
        expect(provider.sessionType, SessionType.work);
        expect(provider.state, PomodoroState.idle);
        await provider.start();
      }
    }

    expect(provider.todayPomodoros, 4);
    expect(provider.todayMinutes, 20);
    expect(provider.activityHistory, hasLength(1));
    expect(provider.activityHistory.single.cyclesCompleted, 4);
    expect(provider.activityHistory.single.totalMinutes, 20);
    expect(provider.canShowLauncher, isTrue);
    provider.dispose();
  });

  test('changing settings while paused does not alter the active stage',
      () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.setWorkDuration(15);
    await provider.startQuickSession();
    await provider.pause();

    await provider.setWorkDuration(45);

    expect(provider.activeStageDuration, 15);
    expect(provider.remainingSeconds, 15 * 60);
    provider.dispose();
  });

  test('changing user cancels the previous running session', () async {
    final timers = _ManualTimerFactory();
    final provider = PomodoroEngine(
      periodicTimerFactory: timers.create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.startQuickSession();
    final staleTimer = timers.latest!;

    await provider.setCurrentUser('other-user');
    staleTimer.fire();

    expect(staleTimer.isActive, isFalse);
    expect(provider.state, PomodoroState.idle);
    expect(provider.todayPomodoros, 0);

    await provider.setCurrentUser(null);
    expect(provider.state, PomodoroState.idle);
    expect(provider.canShowLauncher, isTrue);
    provider.dispose();
  });

  test('linked note completion is delivered once with a stable session id',
      () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    final reviews = <({String noteId, String? sessionId, DateTime at})>[];
    provider.onLinkedNoteFocused = (
      noteId,
      reviewedAt, {
      focusSessionId,
    }) async {
      reviews.add(
        (noteId: noteId, sessionId: focusSessionId, at: reviewedAt),
      );
    };

    await provider.setWorkDuration(5);
    await provider.startQuickSession(noteId: 'note-1');
    final sessionId = provider.activeFocusSessionId;
    clock.advance(const Duration(minutes: 5));
    await provider.onAppResumed();

    expect(reviews, hasLength(1));
    expect(reviews.single.noteId, 'note-1');
    expect(reviews.single.sessionId, sessionId);
    expect(reviews.single.at.isUtc, isTrue);

    final reopened = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    reopened.onLinkedNoteFocused = (
      noteId,
      reviewedAt, {
      focusSessionId,
    }) async {
      reviews.add(
        (noteId: noteId, sessionId: focusSessionId, at: reviewedAt),
      );
    };
    await reopened.initialize();

    expect(reviews, hasLength(1));
    reopened.dispose();
    provider.dispose();
  });

  test('user switch waits for an in-flight linked-note completion', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final callbackStarted = Completer<void>();
    final releaseCallback = Completer<void>();
    final provider = PomodoroEngine(
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    provider.onLinkedNoteFocused = (
      noteId,
      reviewedAt, {
      focusSessionId,
    }) async {
      callbackStarted.complete();
      await releaseCallback.future;
    };
    await provider.setWorkDuration(5);
    await provider.startQuickSession(noteId: 'note-a');
    clock.advance(const Duration(minutes: 5));

    final completion = provider.onAppResumed();
    await callbackStarted.future;
    final userSwitch = provider.setCurrentUser('other-user');
    await Future<void>.delayed(Duration.zero);
    releaseCallback.complete();
    await Future.wait([completion, userSwitch]);

    expect(provider.todayPomodoros, 0);
    expect(provider.todayMinutes, 0);
    expect(provider.activityHistory, isEmpty);
    expect(provider.canShowLauncher, isTrue);
    provider.dispose();
  });

  test('dispose invalidates an in-flight linked-note completion', () async {
    final clock = _MutableClock(DateTime.utc(2026, 7, 26, 12));
    final callbackStarted = Completer<void>();
    final releaseCallback = Completer<void>();
    final provider = PomodoroEngine(
      initialUserId: 'owner-a',
      clock: () => clock.now,
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    provider.onLinkedNoteFocused = (
      noteId,
      reviewedAt, {
      focusSessionId,
    }) async {
      callbackStarted.complete();
      await releaseCallback.future;
    };
    await provider.setWorkDuration(5);
    await provider.startQuickSession(noteId: 'note-a');
    clock.advance(const Duration(minutes: 5));

    final completion = provider.onAppResumed();
    await callbackStarted.future;
    provider.dispose();
    var shutdownCompleted = false;
    final shutdown = provider.shutdown().whenComplete(() {
      shutdownCompleted = true;
    });
    await pumpEventQueue(times: 5);
    expect(shutdownCompleted, isFalse);
    releaseCallback.complete();
    await Future.wait([completion, shutdown]);
    await pumpEventQueue(times: 20);

    final prefs = await SharedPreferences.getInstance();
    final progress = jsonDecode(
      prefs.getString('pomodoro_focus_progress_owner-a')!,
    ) as Map<String, dynamic>;
    expect(progress['pendingNoteReviews'], hasLength(1));
    expect(
      notificationCalls.where((call) => call.method == 'show'),
      isEmpty,
    );

    await prefs.remove('pomodoro_focus_progress_owner-a');
    await pumpEventQueue(times: 20);
    expect(prefs.getString('pomodoro_focus_progress_owner-a'), isNull);
  });

  test('disposing an old owner does not stop the new foreground service',
      () async {
    final ownerA = PomodoroEngine(initialUserId: 'owner-a');
    final ownerB = PomodoroEngine(initialUserId: 'owner-b');
    await ownerA.initialize();
    await ownerB.initialize();
    await ownerA.startQuickSession(name: 'Owner A');
    await ownerB.startQuickSession(name: 'Owner B');
    expect(foregroundServiceRunning, isTrue);
    foregroundCalls.clear();

    ownerA.dispose();
    await pumpEventQueue(times: 20);

    expect(foregroundServiceRunning, isTrue);
    expect(
      foregroundCalls.where((call) => call.method == 'stopService'),
      isEmpty,
    );

    await ownerB.pause();
    expect(foregroundServiceRunning, isFalse);
    expect(
      foregroundCalls.where((call) => call.method == 'stopService'),
      hasLength(1),
    );
    ownerB.dispose();
  });

  test('a hung native stop does not poison the next owner coordinator',
      () async {
    final ownerA = PomodoroEngine(initialUserId: 'owner-timeout-a');
    final ownerB = PomodoroEngine(initialUserId: 'owner-timeout-b');
    await ownerA.initialize();
    await ownerB.initialize();
    await ownerA.startQuickSession(name: 'Owner A');
    final stuckStop = Completer<void>();
    stopServiceGate = stuckStop;

    await ownerA.pause().timeout(const Duration(seconds: 4));
    stopServiceGate = null;
    foregroundCalls.clear();
    await ownerB
        .startQuickSession(name: 'Owner B')
        .timeout(const Duration(seconds: 1));

    expect(ownerB.state, PomodoroState.running);
    expect(
      foregroundCalls.where((call) => call.method == 'startService'),
      isEmpty,
    );
    stuckStop.complete();
    await pumpEventQueue(times: 5);
    ownerA.dispose();
    ownerB.dispose();
  });

  test('pending linked-note review waits until its callback is ready',
      () async {
    final reviewedAt = DateTime.utc(2026, 7, 26, 12, 5);
    SharedPreferences.setMockInitialValues({
      'pomodoro_focus_progress': jsonEncode({
        'version': 1,
        'totalPomodoros': 1,
        'todayPomodoros': 1,
        'totalMinutes': 5,
        'todayMinutes': 5,
        'lastPomodoroDate': reviewedAt.toIso8601String(),
        'firstPomodoroDate': DateTime.utc(2026, 7, 26, 12).toIso8601String(),
        'awardedSessionIds': ['focus-pending'],
        'pendingNoteReviews': [
          {
            'sessionId': 'focus-pending',
            'noteId': 'note-a',
            'reviewedAt': reviewedAt.toIso8601String(),
          },
        ],
      }),
    });
    final reviews = <String>[];
    final provider = PomodoroEngine(
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );
    await provider.initialize();
    provider.onLinkedNoteFocused = (
      noteId,
      reviewedAt, {
      focusSessionId,
    }) async {
      reviews.add('$noteId:$focusSessionId');
    };

    await provider.retryPendingNoteReviews();
    await provider.retryPendingNoteReviews();

    expect(reviews, ['note-a:focus-pending']);
    provider.dispose();
  });

  test('invalid paused snapshot is discarded safely', () async {
    SharedPreferences.setMockInitialValues({
      'pomodoro_active_session': jsonEncode({
        'version': 1,
        'mode': 'quick',
        'sessionType': 'work',
        'state': 'paused',
        'remainingSeconds': -10,
        'activeStageDuration': 25,
      }),
    });
    final provider = PomodoroEngine(
      periodicTimerFactory: _ManualTimerFactory().create,
      completionTransitionDelay: Duration.zero,
    );

    await provider.initialize();

    expect(provider.state, PomodoroState.idle);
    expect(provider.canShowLauncher, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pomodoro_active_session'), isNull);
    provider.dispose();
  });
}

class _MemoryFocusRepository implements FocusRepository {
  @override
  final String ownerId;
  List<PomodoroActivity> sessions;
  Map<String, Object?> progress;

  _MemoryFocusRepository({
    required this.ownerId,
    this.sessions = const [],
    this.progress = const {},
  });

  @override
  Future<List<PomodoroActivity>> loadFocusSessions() async => List.of(sessions);

  @override
  Future<Map<String, Object?>> loadFocusProgress() async => Map.of(progress);

  @override
  Future<void> replaceFocusSessions(List<PomodoroActivity> sessions) async {
    this.sessions = List.of(sessions);
  }

  @override
  Future<void> saveFocusProgress(Map<String, Object?> progress) async {
    this.progress = Map.of(progress);
  }
}
