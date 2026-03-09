import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modos de tema disponibles
enum AppThemeMode {
  system, // Sigue el tema del sistema
  light,  // Blanco puro minimalista
  dark,   // Negro puro minimalista (OLED)
}

/// Provider para manejar el tema de la aplicación
class ThemeProvider with ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  
  AppThemeMode get themeMode => _themeMode;
  
  /// Convierte AppThemeMode a ThemeMode de Flutter
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
  
  /// Carga el tema guardado
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_keyThemeMode);
    
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  /// Cambia el tema
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }
  
  /// Obtiene el label del tema actual
  String get themeModeLabel {
    switch (_themeMode) {
      case AppThemeMode.system:
        return 'Automático';
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Oscuro';
    }
  }
  
  /// Obtiene el icono del tema actual
  IconData get themeModeIcon {
    switch (_themeMode) {
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }
}
