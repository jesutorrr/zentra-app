import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' show getDownloadsDirectory, getApplicationDocumentsDirectory;

/// Servicio de logging para capturar eventos de la app
/// Permite exportar logs para debugging en producción
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  // Circular buffer para mantener los últimos N logs
  static const int _maxLogs = 500;
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  
  // Formato de fecha para los logs
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// Registra un mensaje de información
  void info(String tag, String message) {
    _addLog(LogLevel.info, tag, message);
  }

  /// Registra un mensaje de warning
  void warning(String tag, String message) {
    _addLog(LogLevel.warning, tag, message);
  }

  /// Registra un mensaje de error
  void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    _addLog(LogLevel.error, tag, fullMessage);
  }

  /// Registra un mensaje de debug (solo en modo debug)
  void debug(String tag, String message) {
    _addLog(LogLevel.debug, tag, message);
  }

  void _addLog(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    
    _logs.add(entry);
    
    // Mantener solo los últimos _maxLogs
    while (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
    
    // También imprimir en consola en modo debug
    if (kDebugMode) {
      debugPrint('[${entry.levelString}] [$tag] $message');
    }
  }

  /// Obtiene todos los logs como texto formateado
  String getLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Zentra App Logs ===');
    buffer.writeln('Exported: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('');
    buffer.writeln('--- Logs ---');
    buffer.writeln('');
    
    for (final log in _logs) {
      buffer.writeln('${_dateFormat.format(log.timestamp)} [${log.levelString}] [${log.tag}]');
      buffer.writeln(log.message);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Exporta los logs guardando en Descargas y compartiendo
  Future<String?> exportLogs() async {
    final logsText = getLogsAsText();
    final fileName = 'zentra_logs_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.txt';
    
    String? savedPath;
    
    // Intentar guardar en archivo
    try {
      Directory? saveDir;
      
      if (Platform.isAndroid) {
        // Usar getDownloadsDirectory que es más seguro
        saveDir = await getDownloadsDirectory();
        // Fallback a documentos si no está disponible
        saveDir ??= await getApplicationDocumentsDirectory();
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsString(logsText);
      savedPath = file.path;
    } catch (e) {
      debugPrint('Error saving logs to file: $e');
    }
    
    // Siempre compartir para que el usuario pueda enviarlo
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: logsText,
          subject: 'Zentra App Logs - ${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing logs: $e');
    }
    
    return savedPath;
  }

  /// Limpia todos los logs
  void clearLogs() {
    _logs.clear();
  }

  /// Obtiene el número de logs almacenados
  int get logCount => _logs.length;
}

/// Nivel de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Entrada de log
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get levelString {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
