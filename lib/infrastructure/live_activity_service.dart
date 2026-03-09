import 'package:flutter/services.dart';
import '../infrastructure/app_logger.dart';

class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('com.jesutorr.zentra/live_activity');
  final _logger = AppLogger();

  /// Inicia una Live Activity para el Pomodoro
  /// [endTime] es el timestamp (ms) cuando termina el timer
  /// [sessionType] puede ser "work", "shortBreak", "longBreak"
  Future<String?> startPomodoroActivity({
    required DateTime endTime,
    required String sessionType,
    required String activityName,
  }) async {
    try {
      final activityId = await _channel.invokeMethod<String>('startActivity', {
        'endTime': endTime.millisecondsSinceEpoch / 1000.0, // A segundos para iOS
        'sessionType': sessionType,
        'activityName': activityName,
      });
      _logger.info('LiveActivityService', 'Started activity: $activityId');
      return activityId;
    } catch (e) {
      _logger.error('LiveActivityService', 'Error starting activity', e);
      return null;
    }
  }

  /// Actualiza una Live Activity existente
  Future<void> updatePomodoroActivity({
    required DateTime? endTime,
    required String sessionType,
    required bool isPaused,
  }) async {
    try {
      await _channel.invokeMethod('updateActivity', {
        'endTime': endTime != null ? (endTime.millisecondsSinceEpoch / 1000.0) : null,
        'sessionType': sessionType,
        'isPaused': isPaused,
      });
      _logger.info('LiveActivityService', 'Updated activity');
    } catch (e) {
      _logger.error('LiveActivityService', 'Error updating activity', e);
    }
  }

  /// Termina la Live Activity
  Future<void> endPomodoroActivity() async {
    try {
      await _channel.invokeMethod('endActivity');
      _logger.info('LiveActivityService', 'Ended activity');
    } catch (e) {
      _logger.error('LiveActivityService', 'Error ending activity', e);
    }
  }
}
