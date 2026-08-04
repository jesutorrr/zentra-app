import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory, getDownloadsDirectory;

/// Bounded diagnostic logging with automatic secret and identifier redaction.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int _maxLogs = 500;
  final Queue<LogEntry> _logs = Queue<LogEntry>();

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
  void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    String fullMessage = message;
    if (error != null && kDebugMode) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null && kDebugMode) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    _addLog(LogLevel.error, tag, fullMessage);
  }

  /// Registra un mensaje de debug (solo en modo debug)
  void debug(String tag, String message) {
    _addLog(LogLevel.debug, tag, message);
  }

  void _addLog(LogLevel level, String tag, String message) {
    if (!kDebugMode && level == LogLevel.debug) return;

    final safeTag = _redact(tag);
    final safeMessage = _redact(message);
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: safeTag,
      message: safeMessage,
    );

    _logs.add(entry);

    while (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }

    if (kDebugMode) {
      debugPrint(
        '[${entry.levelString}] [${entry.tag}] ${entry.message}',
      );
    }
  }

  String _redact(String value) {
    return value
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
          '[REDACTED_TOKEN]',
        )
        .replaceAll(
          RegExp(
            r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
            caseSensitive: false,
          ),
          '[REDACTED_EMAIL]',
        )
        .replaceAll(
          RegExp(
            r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
            caseSensitive: false,
          ),
          '[REDACTED_ID]',
        )
        .replaceAllMapped(
          RegExp(r'(https?://[^\s?]+)\?[^\s]+', caseSensitive: false),
          (match) => '${match.group(1)}?[REDACTED_QUERY]',
        );
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
      buffer.writeln(
        '${_dateFormat.format(log.timestamp)} '
        '[${log.levelString}] [${log.tag}]',
      );
      buffer.writeln(log.message);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Exporta los logs guardando en Descargas y compartiendo
  Future<String?> exportLogs() async {
    final logsText = getLogsAsText();
    final fileName =
        'zentra_logs_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.txt';

    String? savedPath;

    // Intentar guardar en archivo
    try {
      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = await getDownloadsDirectory();
        saveDir ??= await getApplicationDocumentsDirectory();
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${saveDir.path}/$fileName');
      await file.writeAsString(logsText);
      savedPath = file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving logs to file: $e');
      }
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: logsText,
          subject:
              'Zentra App Logs - ${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sharing logs: $e');
      }
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
