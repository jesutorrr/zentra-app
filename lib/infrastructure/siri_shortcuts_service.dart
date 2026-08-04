import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio para manejar Siri Shortcuts de iOS
class SiriShortcutsService {
  static final SiriShortcutsService _instance =
      SiriShortcutsService._internal();
  factory SiriShortcutsService() => _instance;
  SiriShortcutsService._internal();

  static const _channel = MethodChannel('com.zentra.app/siri');

  /// Callback cuando se activa un shortcut
  Function(String)? onShortcutActivated;

  /// Inicializa el servicio
  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shortcutActivated') {
        final shortcutType = call.arguments as String?;
        if (shortcutType != null && onShortcutActivated != null) {
          onShortcutActivated!(shortcutType);
        }
      }
    });
  }

  /// Dona un shortcut para "Completar hábito"
  Future<void> donateCompleteHabitShortcut(
    String habitId,
    String habitTitle,
  ) async {
    // Only available on iOS
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod('donateShortcut', {
        'type': 'completeHabit',
        'habitId': habitId,
        'title': 'Completar $habitTitle',
        'phrase': 'Completé $habitTitle',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to donate shortcut: $e');
      }
    }
  }

  /// Dona un shortcut para "Iniciar Pomodoro"
  Future<void> donateStartPomodoroShortcut(String activityName) async {
    // Only available on iOS
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod('donateShortcut', {
        'type': 'startPomodoro',
        'activityName': activityName,
        'title': 'Iniciar Pomodoro: $activityName',
        'phrase': 'Iniciar pomodoro de $activityName',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to donate shortcut: $e');
      }
    }
  }

  /// Dona un shortcut para "Ver progreso"
  Future<void> donateViewProgressShortcut() async {
    // Only available on iOS
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod('donateShortcut', {
        'type': 'viewProgress',
        'title': 'Ver mi progreso',
        'phrase': 'Muéstrame mi progreso de hábitos',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to donate shortcut: $e');
      }
    }
  }

  /// Tipos de shortcuts
  static const String completeHabitType = 'completeHabit';
  static const String startPomodoroType = 'startPomodoro';
  static const String viewProgressType = 'viewProgress';
}
