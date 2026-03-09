import 'dart:async';
import 'package:flutter/widgets.dart';

/// Mixin para agregar protección contra múltiples toques rápidos
mixin DebounceMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;
  
  /// Verifica si se puede ejecutar una acción (no está procesando)
  bool get canProcess => !_isProcessing;
  
  /// Ejecuta una acción con protección de debounce
  /// [action] - La acción a ejecutar
  /// [debounceMs] - Tiempo de espera antes de permitir otra acción (default 300ms)
  Future<void> debounceAction(
    Future<void> Function() action, {
    int debounceMs = 300,
  }) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    if (mounted) setState(() {});
    
    try {
      await action();
    } finally {
      await Future.delayed(Duration(milliseconds: debounceMs));
      if (mounted) {
        _isProcessing = false;
        setState(() {});
      }
    }
  }
  
  /// Ejecuta una acción síncrona con protección de debounce
  void debounceSync(
    void Function() action, {
    int debounceMs = 300,
  }) {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    action();
    
    Future.delayed(Duration(milliseconds: debounceMs), () {
      if (mounted) {
        _isProcessing = false;
      }
    });
  }
}

/// Clase para debounce de funciones (útil en StatelessWidget o fuera de widgets)
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  bool _isProcessing = false;
  
  Debouncer({this.milliseconds = 300});
  
  /// Ejecuta la acción con debounce (cancela llamadas anteriores)
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  
  /// Ejecuta la acción solo si no está procesando (para evitar múltiples toques)
  bool runOnce(void Function() action) {
    if (_isProcessing) return false;
    
    _isProcessing = true;
    action();
    
    Timer(Duration(milliseconds: milliseconds), () {
      _isProcessing = false;
    });
    
    return true;
  }
  
  /// Ejecuta una acción async solo si no está procesando
  Future<bool> runOnceAsync(Future<void> Function() action) async {
    if (_isProcessing) return false;
    
    _isProcessing = true;
    try {
      await action();
    } finally {
      await Future.delayed(Duration(milliseconds: milliseconds));
      _isProcessing = false;
    }
    
    return true;
  }
  
  void dispose() {
    _timer?.cancel();
  }
}
