import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/core_owner_snapshot.dart';
import '../domain/models.dart';
import '../domain/pomodoro_activity.dart';
import '../domain/user_profile.dart';
import 'drift_core_repository.dart';
import 'drift_sync_repository.dart';

abstract interface class LegacyPreferenceReader {
  bool containsKey(String key);

  String? getString(String key);

  int? getInt(String key);
}

class SharedPreferencesLegacyReader implements LegacyPreferenceReader {
  final SharedPreferences preferences;

  const SharedPreferencesLegacyReader(this.preferences);

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  int? getInt(String key) => preferences.getInt(key);

  @override
  String? getString(String key) => preferences.getString(key);
}

enum LegacyCoreMigrationOutcome {
  migrated,
  alreadyCompleted,
  noLegacyData,
  failed,
}

class LegacyCoreMigrationResult {
  final LegacyCoreMigrationOutcome outcome;
  final Map<String, int> counts;
  final String? checksum;
  final String? failureCode;
  final String? failureMessage;

  LegacyCoreMigrationResult({
    required this.outcome,
    Map<String, int> counts = const {},
    this.checksum,
    this.failureCode,
    this.failureMessage,
  }) : counts = Map.unmodifiable(counts);
}

class LegacyCoreMigrator {
  static const migrationName = 'shared_preferences_to_drift_v1';
  static const _sourceKeys = [
    'user_profile',
    'habits',
    'habit_logs',
    'completed_tasks',
    'pomodoro_activities',
    'pomodoro_focus_progress',
    'pomodoro_total',
    'pomodoro_today',
    'pomodoro_total_minutes',
    'pomodoro_today_minutes',
    'pomodoro_first_date',
    'pomodoro_last_date',
    'pomodoro_last_awarded_session',
  ];

  final LegacyPreferenceReader _legacy;
  final DriftCoreRepository _coreRepository;
  final DriftSyncRepository _syncRepository;
  final DateTime Function() _clock;
  final bool allowUnscopedFallback;

  LegacyCoreMigrator({
    required LegacyPreferenceReader legacy,
    required DriftCoreRepository coreRepository,
    required DriftSyncRepository syncRepository,
    DateTime Function()? clock,
    this.allowUnscopedFallback = false,
  })  : _legacy = legacy,
        _coreRepository = coreRepository,
        _syncRepository = syncRepository,
        _clock = clock ?? DateTime.now;

  Future<LegacyCoreMigrationResult> migrateOwner(String ownerId) async {
    if (ownerId.isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
    if (_coreRepository.currentUserId != ownerId ||
        _syncRepository.currentOwnerId != ownerId) {
      throw StateError('Migration repositories must use the requested owner.');
    }

    final previous = await _syncRepository.getMigration(migrationName);
    if (previous?.status == LocalMigrationStatus.completed) {
      return LegacyCoreMigrationResult(
        outcome: LegacyCoreMigrationOutcome.alreadyCompleted,
        counts: previous!.targetCounts,
        checksum: previous.targetChecksum,
      );
    }

    final startedAt = _clock().toUtc();
    CoreOwnerSnapshot? source;
    try {
      if (!_hasLegacyData(ownerId)) {
        final stored = await _coreRepository.exportOwner();
        await _syncRepository.recordMigration(
          LocalMigrationRecord(
            ownerId: ownerId,
            migrationName: migrationName,
            status: LocalMigrationStatus.completed,
            targetChecksum: stored.checksum,
            targetCounts: stored.counts,
            startedAt: startedAt,
            completedAt: _clock().toUtc(),
          ),
        );
        return LegacyCoreMigrationResult(
          outcome: LegacyCoreMigrationOutcome.noLegacyData,
          counts: stored.counts,
          checksum: stored.checksum,
        );
      }

      source = _readSnapshot(ownerId);
      await _syncRepository.recordMigration(
        LocalMigrationRecord(
          ownerId: ownerId,
          migrationName: migrationName,
          status: LocalMigrationStatus.running,
          sourceChecksum: source.checksum,
          sourceCounts: source.counts,
          startedAt: startedAt,
        ),
      );

      final existing = await _coreRepository.exportOwner();
      final hasExistingData = existing.counts.values.any((count) => count > 0);
      if (hasExistingData && existing.checksum != source.checksum) {
        throw StateError(
          'Refusing to overwrite a non-empty Drift owner during migration.',
        );
      }
      final stored = hasExistingData
          ? existing
          : await _coreRepository.replaceOwnerVerified(source);
      await _syncRepository.recordMigration(
        LocalMigrationRecord(
          ownerId: ownerId,
          migrationName: migrationName,
          status: LocalMigrationStatus.completed,
          sourceChecksum: source.checksum,
          targetChecksum: stored.checksum,
          sourceCounts: source.counts,
          targetCounts: stored.counts,
          startedAt: startedAt,
          completedAt: _clock().toUtc(),
        ),
      );
      return LegacyCoreMigrationResult(
        outcome: LegacyCoreMigrationOutcome.migrated,
        counts: stored.counts,
        checksum: stored.checksum,
      );
    } catch (error) {
      final failureCode = error.runtimeType.toString();
      await _syncRepository.recordMigration(
        LocalMigrationRecord(
          ownerId: ownerId,
          migrationName: migrationName,
          status: LocalMigrationStatus.failed,
          sourceChecksum: source?.checksum,
          sourceCounts: source?.counts ?? const {},
          startedAt: startedAt,
          completedAt: _clock().toUtc(),
          failureReason: failureCode,
        ),
      );
      return LegacyCoreMigrationResult(
        outcome: LegacyCoreMigrationOutcome.failed,
        counts: source?.counts ?? const {},
        checksum: source?.checksum,
        failureCode: failureCode,
        failureMessage: error.toString(),
      );
    }
  }

  bool _hasLegacyData(String ownerId) {
    return _sourceKeys.any(
      (baseKey) => _keys(baseKey, ownerId).any(_legacy.containsKey),
    );
  }

  CoreOwnerSnapshot _readSnapshot(String ownerId) {
    final profileJson = _readString('user_profile', ownerId);
    final habitsJson = _readString('habits', ownerId);
    final logsJson = _readString('habit_logs', ownerId);
    final completedTasksJson = _readString('completed_tasks', ownerId);
    final focusSessionsJson = _readString('pomodoro_activities', ownerId);
    final focusProgressJson = _readString('pomodoro_focus_progress', ownerId);

    return CoreOwnerSnapshot(
      ownerId: ownerId,
      profile: profileJson == null
          ? null
          : UserProfile.fromJson(_decodeObject(profileJson)),
      habits:
          _decodeList(habitsJson).map(Habit.fromJson).toList(growable: false),
      logs:
          _decodeList(logsJson).map(HabitLog.fromJson).toList(growable: false),
      completedTasks: _decodeList(completedTasksJson)
          .map(CompletedTask.fromJson)
          .toList(growable: false),
      focusSessions: _decodeList(focusSessionsJson)
          .map(PomodoroActivity.fromJson)
          .toList(growable: false),
      focusProgress: focusProgressJson == null
          ? _readLegacyFocusProgress(ownerId)
          : _decodeObject(focusProgressJson),
    );
  }

  Map<String, Object?> _readLegacyFocusProgress(String ownerId) {
    final totalPomodoros = _readInt('pomodoro_total', ownerId) ?? 0;
    final todayPomodoros = _readInt('pomodoro_today', ownerId) ?? 0;
    final totalMinutes = _readInt('pomodoro_total_minutes', ownerId) ?? 0;
    final todayMinutes = _readInt('pomodoro_today_minutes', ownerId) ?? 0;
    final firstDate = _readString('pomodoro_first_date', ownerId);
    final lastDate = _readString('pomodoro_last_date', ownerId);
    final awardedSession = _readString(
      'pomodoro_last_awarded_session',
      ownerId,
    );

    final hasProgress = totalPomodoros != 0 ||
        todayPomodoros != 0 ||
        totalMinutes != 0 ||
        todayMinutes != 0 ||
        firstDate != null ||
        lastDate != null ||
        awardedSession != null;
    if (!hasProgress) return const {};

    return {
      'version': 1,
      'totalPomodoros': totalPomodoros,
      'todayPomodoros': todayPomodoros,
      'totalMinutes': totalMinutes,
      'todayMinutes': todayMinutes,
      'firstPomodoroDate': firstDate,
      'lastPomodoroDate': lastDate,
      'awardedSessionIds': [
        if (awardedSession != null) awardedSession,
      ],
      'pendingNoteReviews': const <Object?>[],
    };
  }

  String? _readString(String baseKey, String ownerId) {
    for (final key in _keys(baseKey, ownerId)) {
      if (_legacy.containsKey(key)) return _legacy.getString(key);
    }
    return null;
  }

  int? _readInt(String baseKey, String ownerId) {
    for (final key in _keys(baseKey, ownerId)) {
      if (_legacy.containsKey(key)) return _legacy.getInt(key);
    }
    return null;
  }

  Iterable<String> _keys(String baseKey, String ownerId) sync* {
    yield '${baseKey}_$ownerId';
    if (allowUnscopedFallback) yield baseKey;
  }
}

Map<String, dynamic> _decodeObject(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

List<Map<String, dynamic>> _decodeList(String? value) {
  if (value == null) return const [];
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    throw const FormatException('Expected a JSON list');
  }
  return [
    for (final entry in decoded)
      if (entry is Map)
        Map<String, dynamic>.from(entry)
      else
        throw const FormatException('Expected JSON object list entries'),
  ];
}
