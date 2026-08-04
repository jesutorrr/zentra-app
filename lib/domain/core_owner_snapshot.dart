import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'pomodoro_activity.dart';
import 'user_profile.dart';

class CoreOwnerSnapshot {
  static const schemaVersion = 1;

  final String ownerId;
  final UserProfile? profile;
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<CompletedTask> completedTasks;
  final List<PomodoroActivity> focusSessions;
  final Map<String, Object?> focusProgress;

  CoreOwnerSnapshot({
    required this.ownerId,
    this.profile,
    List<Habit> habits = const [],
    List<HabitLog> logs = const [],
    List<CompletedTask> completedTasks = const [],
    List<PomodoroActivity> focusSessions = const [],
    Map<String, Object?> focusProgress = const {},
  })  : habits = List.unmodifiable(
          List<Habit>.of(habits)
            ..sort((left, right) => left.id.compareTo(right.id)),
        ),
        logs = List.unmodifiable(
          List<HabitLog>.of(logs)..sort(_compareHabitLogs),
        ),
        completedTasks = List.unmodifiable(
          List<CompletedTask>.of(completedTasks)
            ..sort((left, right) => left.id.compareTo(right.id)),
        ),
        focusSessions = List.unmodifiable(
          List<PomodoroActivity>.of(focusSessions)
            ..sort((left, right) => left.id.compareTo(right.id)),
        ),
        focusProgress = _immutableJsonMap(focusProgress) {
    if (ownerId.isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
    _requireUnique(habits.map((habit) => habit.id), 'habit');
    _requireUnique(
      logs.map(
        (log) =>
            '${log.habitId}:${_formatLocalDate(HabitLog.normalizeDate(log.date))}',
      ),
      'habit log',
    );
    _requireUnique(completedTasks.map((task) => task.id), 'completed task');
    _requireUnique(focusSessions.map((session) => session.id), 'focus session');
  }

  Map<String, int> get counts => Map.unmodifiable({
        'profiles': profile == null ? 0 : 1,
        'habits': habits.length,
        'habit_logs': logs.length,
        'completed_tasks': completedTasks.length,
        'focus_sessions': focusSessions.length,
        'focus_progress': focusProgress.isEmpty ? 0 : 1,
      });

  String get checksum {
    final bytes = utf8.encode(
      jsonEncode(_canonicalizeJson(toCanonicalJson())),
    );
    return sha256.convert(bytes).toString();
  }

  Map<String, Object?> toCanonicalJson() => {
        'schema_version': schemaVersion,
        'owner_id': ownerId,
        'profile': profile == null ? null : _profileJson(profile!),
        'habits': habits.map(_habitJson).toList(growable: false),
        'logs': logs.map(_habitLogJson).toList(growable: false),
        'completed_tasks':
            completedTasks.map(_completedTaskJson).toList(growable: false),
        'focus_sessions':
            focusSessions.map(_focusSessionJson).toList(growable: false),
        'focus_progress': focusProgress,
      };

  Map<String, Object?> toBackupPayload() => {
        'profile': profile?.toJson() ?? const <String, Object?>{},
        'habits': habits.map((habit) => habit.toJson()).toList(growable: false),
        'logs': logs.map((log) => log.toJson()).toList(growable: false),
        'completedTasks':
            completedTasks.map((task) => task.toJson()).toList(growable: false),
        'pomodoroActivities':
            focusSessions.map((session) => session.toJson()).toList(
                  growable: false,
                ),
        'pomodoroStats': _backupFocusProgress(focusProgress),
      };
}

Map<String, Object?> _backupFocusProgress(
  Map<String, Object?> progress,
) {
  if (progress.isEmpty) return const {};
  return {
    ...progress,
    'total': progress['totalPomodoros'],
    'today': progress['todayPomodoros'],
    'firstDate': progress['firstPomodoroDate'],
    'lastDate': progress['lastPomodoroDate'],
  };
}

Map<String, Object?> _profileJson(UserProfile profile) {
  return {
    ...profile.toJson(),
    'createdAt': _utcIso(profile.createdAt),
  };
}

Map<String, Object?> _habitJson(Habit habit) {
  return {
    ...habit.toJson(),
    'createdAt': _utcIso(habit.createdAt),
    'scheduledDate': habit.scheduledDate == null
        ? null
        : _formatLocalDate(habit.scheduledDate!),
  };
}

Map<String, Object?> _habitLogJson(HabitLog log) => {
      'habitId': log.habitId,
      'date': _formatLocalDate(HabitLog.normalizeDate(log.date)),
    };

Map<String, Object?> _completedTaskJson(CompletedTask task) => {
      ...task.toJson(),
      'completedAt': _utcIso(task.completedAt),
    };

Map<String, Object?> _focusSessionJson(PomodoroActivity session) => {
      ...session.toJson(),
      'startTime': _utcIso(session.startTime),
      'endTime': session.endTime == null ? null : _utcIso(session.endTime!),
    };

Map<String, Object?> _immutableJsonMap(Map<String, Object?> source) {
  return Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: _immutableJsonValue(entry.value),
  });
}

Object? _immutableJsonValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is double && value.isFinite) return value;
  if (value is Map) {
    return _immutableJsonMap(value.cast<String, Object?>());
  }
  if (value is List) {
    return List.unmodifiable(value.map(_immutableJsonValue));
  }
  throw ArgumentError.value(value, 'value', 'Unsupported JSON value');
}

Object? _canonicalizeJson(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalizeJson(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalizeJson).toList(growable: false);
  }
  return value;
}

int _compareHabitLogs(HabitLog left, HabitLog right) {
  final byHabit = left.habitId.compareTo(right.habitId);
  if (byHabit != 0) return byHabit;
  return HabitLog.normalizeDate(left.date).compareTo(
    HabitLog.normalizeDate(right.date),
  );
}

void _requireUnique(Iterable<String> values, String entity) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError('Duplicate $entity identity: $value');
    }
  }
}

String _formatLocalDate(DateTime date) {
  final normalized = HabitLog.normalizeDate(date);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

String _utcIso(DateTime date) {
  // Drift's default SQLite DateTime converter persists whole seconds. Use
  // that same precision in migration checksums so a safe database round-trip
  // does not look like data loss when legacy values contain subsecond parts.
  final utc = date.toUtc();
  final secondsSinceEpoch = utc.millisecondsSinceEpoch ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch(
    secondsSinceEpoch * 1000,
    isUtc: true,
  ).toIso8601String();
}
