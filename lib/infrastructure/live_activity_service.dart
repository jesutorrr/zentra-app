import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

/// Thin ActivityKit bridge used only on supported iOS devices.
///
/// The native widget owns the visible countdown. Dart sends state transitions,
/// never one update per second, so the Live Activity remains efficient while
/// the app is suspended.
class LiveActivityService {
  static const MethodChannel _channel =
      MethodChannel('com.jesutorr.zentra/live_activity');

  final AppLogger _logger = AppLogger();

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> isEnabled() async {
    if (!isSupportedPlatform) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException catch (error, stack) {
      _logger.error(
        'LiveActivityService',
        'Could not read Live Activity authorization',
        error,
        stack,
      );
      return false;
    }
  }

  Future<String?> startPomodoroActivity({
    required DateTime? endTime,
    required String sessionType,
    required String activityName,
    required int remainingSeconds,
    required int stageDurationSeconds,
    required bool isPaused,
    required String nextLabel,
  }) async {
    if (!isSupportedPlatform || !await isEnabled()) return null;
    try {
      final activityId = await _channel.invokeMethod<String>(
        'startActivity',
        _arguments(
          endTime: endTime,
          sessionType: sessionType,
          activityName: activityName,
          remainingSeconds: remainingSeconds,
          stageDurationSeconds: stageDurationSeconds,
          isPaused: isPaused,
          nextLabel: nextLabel,
        ),
      );
      _logger.info(
        'LiveActivityService',
        'Live Activity started',
      );
      return activityId;
    } on PlatformException catch (error, stack) {
      _logger.error(
        'LiveActivityService',
        'Could not start Live Activity',
        error,
        stack,
      );
      return null;
    }
  }

  Future<void> updatePomodoroActivity({
    required DateTime? endTime,
    required String sessionType,
    required String activityName,
    required int remainingSeconds,
    required int stageDurationSeconds,
    required bool isPaused,
    required String nextLabel,
  }) async {
    if (!isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>(
        'updateActivity',
        _arguments(
          endTime: endTime,
          sessionType: sessionType,
          activityName: activityName,
          remainingSeconds: remainingSeconds,
          stageDurationSeconds: stageDurationSeconds,
          isPaused: isPaused,
          nextLabel: nextLabel,
        ),
      );
    } on PlatformException catch (error, stack) {
      _logger.error(
        'LiveActivityService',
        'Could not update Live Activity',
        error,
        stack,
      );
    }
  }

  Future<void> endPomodoroActivity() async {
    if (!isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('endActivity');
      _logger.info('LiveActivityService', 'Live Activity ended');
    } on PlatformException catch (error, stack) {
      _logger.error(
        'LiveActivityService',
        'Could not end Live Activity',
        error,
        stack,
      );
    }
  }

  Map<String, Object?> _arguments({
    required DateTime? endTime,
    required String sessionType,
    required String activityName,
    required int remainingSeconds,
    required int stageDurationSeconds,
    required bool isPaused,
    required String nextLabel,
  }) {
    return <String, Object?>{
      'endTime':
          endTime == null ? null : endTime.millisecondsSinceEpoch / 1000.0,
      'sessionType': sessionType,
      'activityName': activityName,
      'remainingSeconds': remainingSeconds,
      'stageDurationSeconds': stageDurationSeconds,
      'isPaused': isPaused,
      'nextLabel': nextLabel,
    };
  }
}
