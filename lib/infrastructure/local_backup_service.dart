import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account_repository.dart';
import '../domain/auth_models.dart';
import '../domain/backup_gateways.dart';
import '../domain/backup_service.dart';
import '../domain/core_owner_snapshot.dart';
import '../domain/core_owner_store.dart';
import '../domain/models.dart';
import '../domain/note_models.dart';
import '../domain/note_repository.dart';
import '../domain/pomodoro_activity.dart';
import '../domain/user_profile.dart';
import 'encrypted_backup_protector.dart';

class LocalBackupService implements BackupService {
  final AccountRepository _accountRepository;
  final BackupFileGateway _fileGateway;
  final AppVersionGateway _appVersionGateway;
  final BackupProtector _backupProtector;
  final CoreOwnerStore? _coreOwnerStore;
  final NoteRepository? _noteRepository;
  final SharedPreferences? _preferences;
  final DateTime Function() _clock;

  LocalBackupService({
    required AccountRepository accountRepository,
    required BackupFileGateway fileGateway,
    required AppVersionGateway appVersionGateway,
    BackupProtector? backupProtector,
    CoreOwnerStore? coreOwnerStore,
    NoteRepository? noteRepository,
    SharedPreferences? preferences,
    DateTime Function()? clock,
  })  : _accountRepository = accountRepository,
        _fileGateway = fileGateway,
        _appVersionGateway = appVersionGateway,
        _backupProtector = backupProtector ?? EncryptedBackupProtector(),
        _coreOwnerStore = coreOwnerStore,
        _noteRepository = noteRepository,
        _preferences = preferences,
        _clock = clock ?? DateTime.now;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? await SharedPreferences.getInstance();

  @override
  Future<String> exportBackup({
    required String? userId,
    required String passphrase,
  }) async {
    final prefs = await _prefs;
    final currentAccount = await _accountRepository.loadCurrentAccount();
    if (currentAccount == null) {
      throw Exception('No hay datos para exportar');
    }

    final coreSnapshot =
        userId != null && _coreOwnerStore?.supportsOwner(userId) == true
            ? await _coreOwnerStore!.exportOwner(userId)
            : null;
    final profile = coreSnapshot?.profile?.toJson() ??
        await _accountRepository.loadProfile(userId);
    final habits = coreSnapshot?.habits
            .map((habit) => habit.toJson())
            .toList(growable: false) ??
        _decodeList(prefs.getString(_ownerKey('habits', userId)));
    final logs =
        coreSnapshot?.logs.map((log) => log.toJson()).toList(growable: false) ??
            _decodeList(prefs.getString(_ownerKey('habit_logs', userId)));
    final pomodoroActivities = coreSnapshot?.focusSessions
            .map((session) => session.toJson())
            .toList(growable: false) ??
        _decodeList(
          prefs.getString(_ownerKey('pomodoro_activities', userId)),
        );
    final completedTasks = coreSnapshot?.completedTasks
            .map((task) => task.toJson())
            .toList(growable: false) ??
        _decodeList(prefs.getString(_ownerKey('completed_tasks', userId)));
    final exportedAt = _clock();
    final backup = BackupData(
      user: currentAccount,
      profile: profile ?? const {},
      habits: habits,
      logs: logs,
      pomodoroActivities: pomodoroActivities,
      completedTasks: completedTasks,
      pomodoroStats: coreSnapshot == null
          ? _pomodoroStatsForExport(prefs, userId)
          : _backupFocusProgress(coreSnapshot.focusProgress),
      noteSnapshot: await _exportNotes(userId),
      exportedAt: exportedAt,
      appVersion: await _appVersionGateway.loadAppVersion(),
    );
    final timestamp =
        exportedAt.toIso8601String().replaceAll(':', '-').split('.').first;
    final protectedContents = await _backupProtector.protect(
      plaintext: jsonEncode(backup.toJson()),
      passphrase: passphrase,
    );
    return _fileGateway.saveJson(
      contents: protectedContents,
      fileName: 'zentra_backup_$timestamp.json',
    );
  }

  @override
  Future<BackupData?> selectBackup({
    required String passphrase,
    String? jsonData,
  }) async {
    final backupJson = jsonData ?? await _fileGateway.selectJson();
    if (backupJson == null) return null;
    final plaintext = await _backupProtector.unprotect(
      storedContents: backupJson,
      passphrase: passphrase,
    );
    return BackupData.fromJson(
      jsonDecode(plaintext) as Map<String, dynamic>,
    );
  }

  @override
  Future<BackupRestoreResult> restoreBackup(
    BackupData backupData, {
    required LocalUser? currentUser,
    required List<LocalUser> accounts,
    required bool preserveCurrentUser,
  }) async {
    final prefs = await _prefs;
    final keepsCurrentAccount = preserveCurrentUser && currentUser != null;
    final targetUserId =
        keepsCurrentAccount ? currentUser.id : backupData.user.id;
    final restoredCurrentUser =
        keepsCurrentAccount ? currentUser : backupData.user;
    final updatedAccounts = List<LocalUser>.of(accounts);
    final usesCoreStore = _coreOwnerStore?.supportsOwner(targetUserId) == true;
    final preferenceKeys =
        usesCoreStore ? const <String>[] : _restorePreferenceKeys(targetUserId);
    final previousPreferences = {
      for (final key in preferenceKeys)
        key: _StoredPreference.capture(prefs, key),
    };
    final previousCore =
        usesCoreStore ? await _coreOwnerStore!.exportOwner(targetUserId) : null;
    final incomingCore = usesCoreStore
        ? _coreSnapshotFromBackup(backupData, targetUserId)
        : null;
    final previousAccountState = keepsCurrentAccount
        ? null
        : await _StoredAccountState.capture(
            _accountRepository,
            targetUserId: targetUserId,
          );
    final incomingNotes =
        backupData.noteSnapshot.isNotEmpty && _noteRepository != null
            ? NoteOwnerSnapshot.fromJson(
                backupData.noteSnapshot.cast<String, Object?>(),
              )
            : null;
    final previousNotes = incomingNotes == null
        ? null
        : await _withNoteOwner(
            targetUserId,
            (repository) => repository.exportOwner(),
          );

    try {
      if (!keepsCurrentAccount) {
        await _accountRepository.saveCurrentAccount(backupData.user);
        if (!usesCoreStore) {
          await _accountRepository.saveProfile(
            targetUserId,
            backupData.profile,
          );
        }
        final userIndex = updatedAccounts.indexWhere(
          (user) => user.id == targetUserId,
        );
        if (userIndex == -1) {
          updatedAccounts.add(backupData.user);
        } else {
          updatedAccounts[userIndex] = backupData.user;
        }
        await _accountRepository.saveAccounts(updatedAccounts);
      }

      if (incomingCore != null) {
        await _coreOwnerStore!.replaceOwner(incomingCore);
      } else {
        await _restoreLegacyCorePreferences(
          prefs: prefs,
          targetUserId: targetUserId,
          backupData: backupData,
        );
      }

      if (incomingNotes != null) {
        await _withNoteOwner(
          targetUserId,
          (repository) => repository.importOwner(incomingNotes),
        );
      }

      if (!keepsCurrentAccount) {
        await _accountRepository.saveActiveSessionUserId(targetUserId);
      }

      return BackupRestoreResult(
        targetUserId: targetUserId,
        currentUser: restoredCurrentUser,
        accounts: updatedAccounts,
        restoredAccount: !keepsCurrentAccount,
      );
    } catch (error, stackTrace) {
      try {
        await _rollbackRestore(
          prefs: prefs,
          targetUserId: targetUserId,
          previousPreferences: previousPreferences,
          previousCore: previousCore,
          previousAccountState: previousAccountState,
          previousNotes: previousNotes,
        );
      } catch (rollbackError, rollbackStackTrace) {
        Error.throwWithStackTrace(
          StateError(
            'Backup restore failed with $error and rollback failed with '
            '$rollbackError.',
          ),
          rollbackStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  CoreOwnerSnapshot _coreSnapshotFromBackup(
    BackupData backupData,
    String ownerId,
  ) {
    final profileJson = <String, dynamic>{
      ...backupData.profile,
      'id': ownerId,
    };
    return CoreOwnerSnapshot(
      ownerId: ownerId,
      profile:
          backupData.profile.isEmpty ? null : UserProfile.fromJson(profileJson),
      habits: backupData.habits.map(Habit.fromJson).toList(growable: false),
      logs: backupData.logs.map(HabitLog.fromJson).toList(growable: false),
      completedTasks: backupData.completedTasks
          .map(CompletedTask.fromJson)
          .toList(growable: false),
      focusSessions: backupData.pomodoroActivities
          .map(PomodoroActivity.fromJson)
          .toList(growable: false),
      focusProgress: _canonicalPomodoroProgress(
        backupData.pomodoroStats,
      ),
    );
  }

  Future<void> _restoreLegacyCorePreferences({
    required SharedPreferences prefs,
    required String targetUserId,
    required BackupData backupData,
  }) async {
    await prefs.setString(
      'habits_$targetUserId',
      jsonEncode(backupData.habits),
    );
    await prefs.setString(
      'habit_logs_$targetUserId',
      jsonEncode(backupData.logs),
    );
    await prefs.setString(
      'pomodoro_activities_$targetUserId',
      jsonEncode(backupData.pomodoroActivities),
    );
    await prefs.setString(
      'completed_tasks_$targetUserId',
      jsonEncode(backupData.completedTasks),
    );

    final stats = backupData.pomodoroStats;
    final canonicalProgress = _canonicalPomodoroProgress(stats);
    await _replaceInt(
      prefs,
      'pomodoro_total_$targetUserId',
      _statValue(stats, canonical: 'totalPomodoros', legacy: 'total'),
    );
    await _replaceInt(
      prefs,
      'pomodoro_today_$targetUserId',
      _statValue(stats, canonical: 'todayPomodoros', legacy: 'today'),
    );
    await _replaceInt(
      prefs,
      'pomodoro_total_minutes_$targetUserId',
      stats['totalMinutes'],
    );
    await _replaceInt(
      prefs,
      'pomodoro_today_minutes_$targetUserId',
      stats['todayMinutes'],
    );
    await _replaceString(
      prefs,
      'pomodoro_first_date_$targetUserId',
      _statValue(
        stats,
        canonical: 'firstPomodoroDate',
        legacy: 'firstDate',
      ),
    );
    await _replaceString(
      prefs,
      'pomodoro_last_date_$targetUserId',
      _statValue(
        stats,
        canonical: 'lastPomodoroDate',
        legacy: 'lastDate',
      ),
    );
    await prefs.setString(
      'pomodoro_focus_progress_$targetUserId',
      jsonEncode(canonicalProgress),
    );
  }

  Future<void> _rollbackRestore({
    required SharedPreferences prefs,
    required String targetUserId,
    required Map<String, _StoredPreference> previousPreferences,
    required CoreOwnerSnapshot? previousCore,
    required _StoredAccountState? previousAccountState,
    required NoteOwnerSnapshot? previousNotes,
  }) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> attempt(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    if (previousNotes != null) {
      await attempt(
        () => _withNoteOwner(
          targetUserId,
          (repository) => repository.importOwner(previousNotes),
        ),
      );
    }
    if (previousCore != null) {
      await attempt(() => _coreOwnerStore!.replaceOwner(previousCore));
    }
    await attempt(() => _restorePreferences(prefs, previousPreferences));
    if (previousAccountState != null) {
      await attempt(
        () => previousAccountState.restore(_accountRepository),
      );
    }

    final error = firstError;
    final stackTrace = firstStackTrace;
    if (error != null && stackTrace != null) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Map<String, dynamic>> _exportNotes(String? userId) async {
    if (userId == null || _noteRepository == null) return const {};
    return _withNoteOwner(userId, (repository) async {
      final snapshot = await repository.exportOwner();
      return snapshot.toJson().cast<String, dynamic>();
    });
  }

  Future<T> _withNoteOwner<T>(
    String userId,
    Future<T> Function(NoteRepository repository) operation,
  ) async {
    final repository = _noteRepository;
    if (repository == null) {
      throw StateError('Notes storage is unavailable.');
    }
    final previousUserId = repository.currentUserId;
    repository.setCurrentUser(userId);
    try {
      return await operation(repository);
    } finally {
      repository.setCurrentUser(previousUserId);
    }
  }

  String _ownerKey(String base, String? userId) =>
      userId == null ? base : '${base}_$userId';

  Map<String, dynamic> _pomodoroStatsForExport(
    SharedPreferences prefs,
    String? userId,
  ) {
    final legacy = <String, dynamic>{
      'total': prefs.getInt(_ownerKey('pomodoro_total', userId)) ?? 0,
      'today': prefs.getInt(_ownerKey('pomodoro_today', userId)) ?? 0,
      'totalMinutes':
          prefs.getInt(_ownerKey('pomodoro_total_minutes', userId)) ?? 0,
      'todayMinutes':
          prefs.getInt(_ownerKey('pomodoro_today_minutes', userId)) ?? 0,
      'firstDate': prefs.getString(
        _ownerKey('pomodoro_first_date', userId),
      ),
      'lastDate': prefs.getString(
        _ownerKey('pomodoro_last_date', userId),
      ),
    };
    final rawProgress = prefs.getString(
      _ownerKey('pomodoro_focus_progress', userId),
    );
    if (rawProgress == null) return legacy;

    try {
      final progress = jsonDecode(rawProgress) as Map<String, dynamic>;
      if (progress['version'] != 1) return legacy;
      return {
        'total': _intValue(progress['totalPomodoros']),
        'today': _intValue(progress['todayPomodoros']),
        'totalMinutes': _intValue(progress['totalMinutes']),
        'todayMinutes': _intValue(progress['todayMinutes']),
        'firstDate': _stringValue(progress['firstPomodoroDate']),
        'lastDate': _stringValue(progress['lastPomodoroDate']),
        'awardedSessionIds': (progress['awardedSessionIds'] as List<dynamic>?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[],
        'pendingNoteReviews':
            (progress['pendingNoteReviews'] as List<dynamic>?)?.toList(
                  growable: false,
                ) ??
                const <Object?>[],
      };
    } catch (_) {
      return legacy;
    }
  }

  Map<String, dynamic> _backupFocusProgress(
    Map<String, Object?> progress,
  ) {
    if (progress.isEmpty) return const {};
    return <String, dynamic>{
      ...progress,
      'total': progress['totalPomodoros'],
      'today': progress['todayPomodoros'],
      'firstDate': progress['firstPomodoroDate'],
      'lastDate': progress['lastPomodoroDate'],
    };
  }

  List<String> _restorePreferenceKeys(String userId) => [
        'habits_$userId',
        'habit_logs_$userId',
        'pomodoro_activities_$userId',
        'completed_tasks_$userId',
        'pomodoro_total_$userId',
        'pomodoro_today_$userId',
        'pomodoro_total_minutes_$userId',
        'pomodoro_today_minutes_$userId',
        'pomodoro_first_date_$userId',
        'pomodoro_last_date_$userId',
        'pomodoro_focus_progress_$userId',
      ];

  Map<String, Object?> _canonicalPomodoroProgress(
    Map<String, dynamic> stats,
  ) {
    return {
      'version': 1,
      'totalPomodoros': _intValue(
        _statValue(stats, canonical: 'totalPomodoros', legacy: 'total'),
      ),
      'todayPomodoros': _intValue(
        _statValue(stats, canonical: 'todayPomodoros', legacy: 'today'),
      ),
      'totalMinutes': _intValue(stats['totalMinutes']),
      'todayMinutes': _intValue(stats['todayMinutes']),
      'lastPomodoroDate': _stringValue(
        _statValue(
          stats,
          canonical: 'lastPomodoroDate',
          legacy: 'lastDate',
        ),
      ),
      'firstPomodoroDate': _stringValue(
        _statValue(
          stats,
          canonical: 'firstPomodoroDate',
          legacy: 'firstDate',
        ),
      ),
      'awardedSessionIds': (stats['awardedSessionIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      'pendingNoteReviews':
          (stats['pendingNoteReviews'] as List<dynamic>?)?.toList(
                growable: false,
              ) ??
              const <Object?>[],
    };
  }

  Object? _statValue(
    Map<String, dynamic> stats, {
    required String canonical,
    required String legacy,
  }) {
    return stats.containsKey(canonical) ? stats[canonical] : stats[legacy];
  }

  int _intValue(Object? value) => value is num ? value.toInt() : 0;

  String? _stringValue(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  Future<void> _restorePreferences(
    SharedPreferences prefs,
    Map<String, _StoredPreference> values,
  ) async {
    for (final entry in values.entries) {
      await entry.value.restore(prefs, entry.key);
    }
  }

  List<Map<String, dynamic>> _decodeList(String? value) {
    if (value == null) return [];
    return (jsonDecode(value) as List<dynamic>)
        .map((entry) => entry as Map<String, dynamic>)
        .toList();
  }

  Future<void> _replaceInt(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value is num) {
      await prefs.setInt(key, value.toInt());
    } else {
      await prefs.remove(key);
    }
  }

  Future<void> _replaceString(
    SharedPreferences prefs,
    String key,
    Object? value,
  ) async {
    if (value is String && value.isNotEmpty) {
      await prefs.setString(key, value);
    } else {
      await prefs.remove(key);
    }
  }
}

class _StoredPreference {
  final bool existed;
  final Object? value;

  const _StoredPreference({
    required this.existed,
    required this.value,
  });

  factory _StoredPreference.capture(SharedPreferences prefs, String key) {
    return _StoredPreference(
      existed: prefs.containsKey(key),
      value: prefs.get(key),
    );
  }

  Future<void> restore(SharedPreferences prefs, String key) async {
    if (!existed) {
      await prefs.remove(key);
      return;
    }
    final storedValue = value;
    if (storedValue is String) {
      await prefs.setString(key, storedValue);
    } else if (storedValue is int) {
      await prefs.setInt(key, storedValue);
    } else if (storedValue is bool) {
      await prefs.setBool(key, storedValue);
    } else if (storedValue is double) {
      await prefs.setDouble(key, storedValue);
    } else if (storedValue is List<String>) {
      await prefs.setStringList(key, storedValue);
    } else {
      throw StateError('Unsupported SharedPreferences value for $key.');
    }
  }
}

class _StoredAccountState {
  final String targetUserId;
  final List<LocalUser> accounts;
  final LocalUser? currentAccount;
  final String? activeSessionUserId;
  final Map<String, dynamic>? targetProfile;
  final Map<String, dynamic>? currentProfile;

  const _StoredAccountState({
    required this.targetUserId,
    required this.accounts,
    required this.currentAccount,
    required this.activeSessionUserId,
    required this.targetProfile,
    required this.currentProfile,
  });

  static Future<_StoredAccountState> capture(
    AccountRepository repository, {
    required String targetUserId,
  }) async {
    final values = await Future.wait<Object?>([
      repository.loadAccounts(),
      repository.loadCurrentAccount(),
      repository.loadActiveSessionUserId(),
      repository.loadProfile(targetUserId),
      repository.loadProfile(null),
    ]);
    return _StoredAccountState(
      targetUserId: targetUserId,
      accounts: values[0]! as List<LocalUser>,
      currentAccount: values[1] as LocalUser?,
      activeSessionUserId: values[2] as String?,
      targetProfile: values[3] as Map<String, dynamic>?,
      currentProfile: values[4] as Map<String, dynamic>?,
    );
  }

  Future<void> restore(AccountRepository repository) async {
    await repository.saveAccounts(accounts);
    final profile = targetProfile;
    if (profile == null) {
      await repository.deleteProfile(targetUserId);
    } else {
      await repository.saveProfile(targetUserId, profile);
    }

    final account = currentAccount;
    if (account == null) {
      await repository.clearCurrentAccount();
      final profile = currentProfile;
      if (profile != null) {
        await repository.saveCurrentProfile(profile);
      }
    } else {
      await repository.saveCurrentAccount(account);
    }

    final activeUserId = activeSessionUserId;
    if (activeUserId == null) {
      await repository.clearActiveSession();
    } else {
      await repository.saveActiveSessionUserId(activeUserId);
    }
  }
}
