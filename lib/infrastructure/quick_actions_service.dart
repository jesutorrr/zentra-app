import 'package:flutter/services.dart';

/// Servicio para manejar Quick Actions de iOS (3D Touch / Haptic Touch)
class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;
  QuickActionsService._internal();

  static const _channel = MethodChannel('com.zentra.app/quickactions');
  
  // Callback para cuando se selecciona una acción
  Function(String)? onActionSelected;
  
  // Pending action (if app was launched from quick action)
  String? _pendingAction;
  String? get pendingAction => _pendingAction;
  void clearPendingAction() => _pendingAction = null;

  /// Inicializa el servicio y escucha por acciones
  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'quickActionTriggered') {
        final action = call.arguments as String?;
        if (action != null) {
          if (onActionSelected != null) {
            onActionSelected!(action);
          } else {
            // Store for later if callback not set yet
            _pendingAction = action;
          }
        }
      }
    });
  }

  /// Tipos de acciones disponibles (deben coincidir con Info.plist)
  static const String newHabitAction = 'NewHabitAction';
  static const String pomodoroAction = 'PomodoroAction';
  static const String progressAction = 'ProgressAction';
}
