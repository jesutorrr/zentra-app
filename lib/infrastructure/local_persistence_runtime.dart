import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/account_repository.dart';
import '../domain/auth_models.dart';
import '../domain/cloud_link.dart';
import '../domain/completed_task_repository.dart';
import '../domain/core_owner_snapshot.dart';
import '../domain/core_owner_store.dart';
import '../domain/focus_repository.dart';
import '../domain/models.dart';
import '../domain/note_models.dart';
import '../domain/profile_repository.dart';
import '../domain/portable_preferences.dart';
import '../domain/user_profile.dart';
import 'database/zentra_database.dart';
import 'drift_core_repository.dart';
import 'drift_note_repository.dart';
import 'drift_sync_repository.dart';
import 'drift_sync_workspace.dart';
import 'legacy_core_migrator.dart';
import 'local_storage_repository.dart';
import 'shared_preferences_account_repository.dart';
import 'shared_preferences_completed_task_repository.dart';
import 'shared_preferences_profile_repository.dart';

/// Selects the canonical local store per owner after verifying legacy data.
///
/// Existing accounts use Drift only after their legacy snapshot is copied and
/// checksum-verified. A failed owner remains on SharedPreferences so startup
/// never exposes an empty workspace. Newly created owners start directly in
/// Drift.
class LocalPersistenceRuntime implements CoreOwnerStore {
  static const _deviceIdKey = 'zentra_sync_device_id_v1';

  final SharedPreferences preferences;
  final ZentraDatabase database;
  final bool cloudSyncAllowed;
  final SharedPreferencesAccountRepository _legacyAccountRepository;
  final Set<String> _legacyFallbackOwners = <String>{};
  final Set<String> _syncEnabledOwners = <String>{};
  final Map<String, void Function()> _syncCallbacks =
      <String, void Function()>{};
  final Map<String, LegacyCoreMigrationResult> _migrationResults =
      <String, LegacyCoreMigrationResult>{};

  late final AccountRepository accountRepository =
      _RoutedAccountRepository(this, _legacyAccountRepository);
  late String _deviceId;

  LocalPersistenceRuntime({
    required this.preferences,
    required this.database,
    this.cloudSyncAllowed = true,
  }) : _legacyAccountRepository = SharedPreferencesAccountRepository(
          preferences: preferences,
        );

  Map<String, LegacyCoreMigrationResult> get migrationResults =>
      Map.unmodifiable(_migrationResults);

  Set<String> get legacyFallbackOwners =>
      Set.unmodifiable(_legacyFallbackOwners);

  Future<List<LocalUser>> initialize() async {
    _deviceId = preferences.getString(_deviceIdKey) ?? const Uuid().v4();
    await preferences.setString(_deviceIdKey, _deviceId);
    if (cloudSyncAllowed) {
      final linkedOwners =
          await database.select(database.localOwnerLinkEntries).get();
      _syncEnabledOwners.addAll(
        linkedOwners
            .where(
              (link) =>
                  link.state == 'linked' &&
                  link.remoteUserId != null &&
                  link.localOwnerId == link.remoteUserId,
            )
            .map((link) => link.localOwnerId),
      );
    }
    final accounts = await _legacyAccountRepository.loadAccounts();
    final allowUnscopedFallback = accounts.length == 1;

    for (final account in accounts) {
      final ownerId = account.id;
      try {
        final result = await LegacyCoreMigrator(
          legacy: SharedPreferencesLegacyReader(preferences),
          coreRepository: _driftCore(ownerId),
          syncRepository: _driftSync(ownerId),
          allowUnscopedFallback: allowUnscopedFallback,
        ).migrateOwner(ownerId);
        _migrationResults[ownerId] = result;
        if (result.outcome == LegacyCoreMigrationOutcome.failed) {
          _legacyFallbackOwners.add(ownerId);
        }
      } catch (_) {
        _legacyFallbackOwners.add(ownerId);
      }
    }

    return accounts;
  }

  @override
  bool supportsOwner(String ownerId) =>
      !_legacyFallbackOwners.contains(ownerId);

  HabitRepository habitRepositoryFor(String ownerId) {
    if (supportsOwner(ownerId)) return _driftCore(ownerId);
    return LocalStorageRepository.forOwner(
      preferences,
      ownerId: ownerId,
    );
  }

  CompletedTaskRepository completedTaskRepositoryFor(String ownerId) {
    if (supportsOwner(ownerId)) return _driftCore(ownerId);
    return SharedPreferencesCompletedTaskRepository(
      preferences,
      ownerId: ownerId,
    );
  }

  ProfileRepository profileRepositoryFor(String ownerId) {
    if (supportsOwner(ownerId)) return _driftCore(ownerId);
    return SharedPreferencesProfileRepository(
      preferences,
      ownerId: ownerId,
    );
  }

  FocusRepository? focusRepositoryFor(String ownerId) {
    return supportsOwner(ownerId) ? _driftCore(ownerId) : null;
  }

  PortablePreferencesRepository portablePreferencesRepositoryFor(
    String ownerId,
  ) {
    _requireDriftOwner(ownerId);
    return _driftCore(ownerId);
  }

  Future<void> ensurePortableTheme(
    String ownerId,
    String themeMode,
  ) async {
    final repository = portablePreferencesRepositoryFor(ownerId);
    if (await repository.loadPortablePreferences() == null) {
      await repository.savePortableThemeMode(themeMode);
    }
  }

  DriftNoteRepository noteRepositoryFor(String ownerId) {
    // Notes never lived in the legacy core SharedPreferences payload. They
    // remain independently available in Drift even when habits/profile/focus
    // must temporarily use the verified legacy fallback.
    return _driftNote(ownerId);
  }

  bool isSyncEnabled(String ownerId) =>
      cloudSyncAllowed && _syncEnabledOwners.contains(ownerId);

  Future<CloudLinkPreview> previewCloudLink(String ownerId) async {
    _requireDriftOwner(ownerId);
    final core = await _driftCore(ownerId).exportOwner();
    final notes = await DriftNoteRepository.forOwner(
      database,
      ownerId: ownerId,
    ).exportOwner();
    return CloudLinkPreview(
      sourceOwnerId: ownerId,
      counts: _combinedCounts(core, notes),
      checksum: _cloudLinkChecksum(core, notes, ownerId),
    );
  }

  void prepareCloudOwner(String ownerId) {
    if (!cloudSyncAllowed) {
      throw StateError('Cloud sync is parked for this runtime.');
    }
    _requireDriftOwner(ownerId);
    _syncEnabledOwners.add(ownerId);
  }

  Future<void> enableCloudOwner(String ownerId) async {
    prepareCloudOwner(ownerId);
    await _driftSync(ownerId).linkOwner(
      localOwnerId: ownerId,
      remoteUserId: ownerId,
    );
  }

  Future<CloudLinkResult> migrateLocalOwnerToCloud({
    required String sourceOwnerId,
    required String remoteOwnerId,
  }) async {
    if (sourceOwnerId == remoteOwnerId) {
      await enableCloudOwner(remoteOwnerId);
      final preview = await previewCloudLink(remoteOwnerId);
      return CloudLinkResult(
        sourceOwnerId: sourceOwnerId,
        remoteOwnerId: remoteOwnerId,
        sourceCounts: preview.counts,
        targetCounts: preview.counts,
        sourceChecksum: preview.checksum,
        targetChecksum: preview.checksum,
        remoteWasEmpty: false,
      );
    }
    _requireDriftOwner(sourceOwnerId);
    prepareCloudOwner(remoteOwnerId);

    final sourceCore = await _driftCore(sourceOwnerId).exportOwner();
    final sourceNotes = await DriftNoteRepository.forOwner(
      database,
      ownerId: sourceOwnerId,
    ).exportOwner();
    final sourceCounts = _combinedCounts(sourceCore, sourceNotes);
    final sourceChecksum = _cloudLinkChecksum(
      sourceCore,
      sourceNotes,
      sourceOwnerId,
    );
    final migrationName = 'local_to_supabase_v1:$remoteOwnerId';
    final sourceSync = _driftSync(sourceOwnerId);
    final previous = await sourceSync.getMigration(migrationName);
    if (previous?.status == LocalMigrationStatus.completed &&
        previous?.sourceChecksum == sourceChecksum &&
        await sourceSync.getLinkedRemoteUserId() == remoteOwnerId) {
      final targetCore = await _driftCore(remoteOwnerId).exportOwner();
      final targetNotes = await DriftNoteRepository.forOwner(
        database,
        ownerId: remoteOwnerId,
      ).exportOwner();
      return CloudLinkResult(
        sourceOwnerId: sourceOwnerId,
        remoteOwnerId: remoteOwnerId,
        sourceCounts: sourceCounts,
        targetCounts: _combinedCounts(targetCore, targetNotes),
        sourceChecksum: sourceChecksum,
        targetChecksum:
            _cloudLinkChecksum(targetCore, targetNotes, remoteOwnerId),
        remoteWasEmpty: false,
      );
    }

    final startedAt = DateTime.now().toUtc();
    try {
      return await database.transaction(() async {
        await sourceSync.recordMigration(
          LocalMigrationRecord(
            ownerId: sourceOwnerId,
            migrationName: migrationName,
            status: LocalMigrationStatus.running,
            sourceChecksum: sourceChecksum,
            sourceCounts: sourceCounts,
            startedAt: startedAt,
          ),
        );

        final remoteCoreRepository = _driftCore(remoteOwnerId);
        final remoteBefore = await remoteCoreRepository.exportOwner();
        final remoteNotesRepository = _driftNote(remoteOwnerId);
        final remoteNotesBefore = await remoteNotesRepository.exportOwner();
        final remoteWasEmpty =
            _combinedCounts(remoteBefore, remoteNotesBefore).values.every(
                  (count) => count == 0,
                );
        final remappedSourceCore = _remapCore(sourceCore, remoteOwnerId);
        final remappedSourceNotes = _remapNotes(sourceNotes, remoteOwnerId);

        await _mergeCoreIntoRemote(
          source: remappedSourceCore,
          remote: remoteBefore,
          repository: remoteCoreRepository,
        );
        await remoteNotesRepository.importOwner(
          remappedSourceNotes,
          replaceExisting: false,
        );

        final targetCore = await remoteCoreRepository.exportOwner();
        final targetNotes = await remoteNotesRepository.exportOwner();
        _verifySourceContained(
          sourceCore: remappedSourceCore,
          sourceNotes: remappedSourceNotes,
          targetCore: targetCore,
          targetNotes: targetNotes,
        );
        final targetCounts = _combinedCounts(targetCore, targetNotes);
        final targetChecksum = _cloudLinkChecksum(
          targetCore,
          targetNotes,
          remoteOwnerId,
        );
        if (remoteWasEmpty) {
          final expectedChecksum = _cloudLinkChecksum(
            remappedSourceCore,
            remappedSourceNotes,
            remoteOwnerId,
          );
          if (expectedChecksum != targetChecksum) {
            throw StateError('Cloud migration checksum verification failed.');
          }
        }

        await _driftSync(remoteOwnerId).unlinkOwner();
        await sourceSync.linkOwner(
          localOwnerId: sourceOwnerId,
          remoteUserId: remoteOwnerId,
        );
        final completedAt = DateTime.now().toUtc();
        await sourceSync.recordMigration(
          LocalMigrationRecord(
            ownerId: sourceOwnerId,
            migrationName: migrationName,
            status: LocalMigrationStatus.completed,
            sourceChecksum: sourceChecksum,
            targetChecksum: targetChecksum,
            sourceCounts: sourceCounts,
            targetCounts: targetCounts,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
        );

        return CloudLinkResult(
          sourceOwnerId: sourceOwnerId,
          remoteOwnerId: remoteOwnerId,
          sourceCounts: sourceCounts,
          targetCounts: targetCounts,
          sourceChecksum: sourceChecksum,
          targetChecksum: targetChecksum,
          remoteWasEmpty: remoteWasEmpty,
        );
      });
    } catch (error) {
      await sourceSync.recordMigration(
        LocalMigrationRecord(
          ownerId: sourceOwnerId,
          migrationName: migrationName,
          status: LocalMigrationStatus.failed,
          sourceChecksum: sourceChecksum,
          sourceCounts: sourceCounts,
          startedAt: startedAt,
          completedAt: DateTime.now().toUtc(),
          failureReason: error.runtimeType.toString(),
        ),
      );
      rethrow;
    }
  }

  void registerSyncCallback(String ownerId, void Function() callback) {
    _syncCallbacks[ownerId] = callback;
  }

  void unregisterSyncCallback(String ownerId) {
    _syncCallbacks.remove(ownerId);
  }

  DriftSyncWorkspace syncWorkspaceFor(String ownerId) {
    _requireDriftOwner(ownerId);
    return DriftSyncWorkspace(database: database, ownerId: ownerId);
  }

  @override
  Future<CoreOwnerSnapshot> exportOwner(String ownerId) {
    _requireDriftOwner(ownerId);
    return _driftCore(ownerId).exportOwner();
  }

  @override
  Future<CoreOwnerSnapshot> replaceOwner(CoreOwnerSnapshot snapshot) {
    _requireDriftOwner(snapshot.ownerId);
    return _driftCore(snapshot.ownerId).replaceOwnerVerified(snapshot);
  }

  @override
  Future<void> deleteOwner(String ownerId) async {
    if (!supportsOwner(ownerId)) return;
    await database.transaction(() async {
      await _driftCore(ownerId).deleteOwner();
      await _driftSync(ownerId).deleteOwnerMetadata();
    });
  }

  DriftCoreRepository _driftCore(String ownerId) {
    final syncEnabled = isSyncEnabled(ownerId);
    return DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: syncEnabled ? _deviceId : null,
      onSyncNeeded: syncEnabled ? _syncCallbacks[ownerId] : null,
    );
  }

  DriftNoteRepository _driftNote(String ownerId) {
    final syncEnabled = isSyncEnabled(ownerId);
    return DriftNoteRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: syncEnabled ? _deviceId : null,
      onSyncNeeded: syncEnabled ? _syncCallbacks[ownerId] : null,
    );
  }

  DriftSyncRepository _driftSync(String ownerId) {
    return DriftSyncRepository.forOwner(
      database,
      ownerId: ownerId,
    );
  }

  void _requireDriftOwner(String ownerId) {
    if (!supportsOwner(ownerId)) {
      throw StateError(
        'Owner $ownerId is using the verified legacy fallback.',
      );
    }
  }

  Future<void> _mergeCoreIntoRemote({
    required CoreOwnerSnapshot source,
    required CoreOwnerSnapshot remote,
    required DriftCoreRepository repository,
  }) async {
    final sourceProfile = source.profile;
    if (sourceProfile != null) {
      final remoteProfile = remote.profile;
      if (remoteProfile == null) {
        await repository.saveProfile(
          _remapProfile(sourceProfile, repository.ownerId),
        );
      }
    }

    final remoteHabits = {
      for (final habit in remote.habits) habit.id: habit,
    };
    for (final habit in source.habits) {
      if (remoteHabits.containsKey(habit.id)) {
        await repository.updateHabit(habit);
      } else {
        await repository.saveHabit(habit);
      }
    }

    final remoteLogs = remote.logs.map(_habitLogKey).toSet();
    for (final log in source.logs) {
      if (remoteLogs.add(_habitLogKey(log))) {
        await repository.toggleLog(log.habitId, log.date);
      }
    }

    await repository.replaceCompletedTasks(
      _mergeById(
        remote.completedTasks,
        source.completedTasks,
        (task) => task.id,
      ),
    );
    await repository.replaceFocusSessions(
      _mergeById(
        remote.focusSessions,
        source.focusSessions,
        (session) => session.id,
      ),
    );
    if (source.focusProgress.isNotEmpty) {
      await repository.saveFocusProgress(source.focusProgress);
    }
  }
}

Map<String, int> _combinedCounts(
  CoreOwnerSnapshot core,
  NoteOwnerSnapshot notes,
) {
  return {
    ...core.counts,
    'notes': notes.notes.length,
    'note_reminders': notes.reminders.length,
    'note_reviews': notes.reviews.length,
  };
}

String _cloudLinkChecksum(
  CoreOwnerSnapshot core,
  NoteOwnerSnapshot notes,
  String ownerId,
) {
  final normalizedCore = CoreOwnerSnapshot(
    ownerId: ownerId,
    profile: core.profile,
    habits: core.habits,
    logs: core.logs,
    completedTasks: core.completedTasks,
    focusSessions: core.focusSessions,
    focusProgress: core.focusProgress,
  );
  final normalizedNotes = _normalizeNoteOwners(notes, ownerId);
  final canonical = {
    'core': normalizedCore.toCanonicalJson(),
    'notes': {
      'schema_version': normalizedNotes.schemaVersion,
      'owner_id': ownerId,
      'notes': _sortedJson(
        normalizedNotes.notes.map((note) => note.toJson()),
      ),
      'reminders': _sortedJson(
        normalizedNotes.reminders.map((reminder) => reminder.toJson()),
      ),
      'reviews': _sortedJson(
        normalizedNotes.reviews.map((review) => review.toJson()),
      ),
    },
  };
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

List<Map<String, Object?>> _sortedJson(
  Iterable<Map<String, Object?>> values,
) {
  return values.toList()
    ..sort(
      (left, right) => (left['id'] as String).compareTo(right['id'] as String),
    );
}

NoteOwnerSnapshot _remapNotes(
  NoteOwnerSnapshot snapshot,
  String ownerId,
) {
  String noteId(String sourceId) => _cloudEntityId(ownerId, 'note', sourceId);
  String focusSessionId(String sourceId) =>
      _cloudEntityId(ownerId, 'focus-session', sourceId);

  return NoteOwnerSnapshot(
    ownerId: ownerId,
    exportedAt: snapshot.exportedAt,
    notes: [
      for (final note in snapshot.notes)
        note.copyWith(
          id: noteId(note.id),
          userId: ownerId,
        ),
    ],
    reminders: [
      for (final reminder in snapshot.reminders)
        reminder.copyWith(
          id: _cloudEntityId(ownerId, 'note-reminder', reminder.id),
          noteId: noteId(reminder.noteId),
          userId: ownerId,
        ),
    ],
    reviews: [
      for (final review in snapshot.reviews)
        review.copyWith(
          id: _cloudEntityId(ownerId, 'note-review', review.id),
          noteId: noteId(review.noteId),
          userId: ownerId,
          focusSessionId: review.focusSessionId == null
              ? null
              : focusSessionId(review.focusSessionId!),
        ),
    ],
  );
}

NoteOwnerSnapshot _normalizeNoteOwners(
  NoteOwnerSnapshot snapshot,
  String ownerId,
) {
  return NoteOwnerSnapshot(
    ownerId: ownerId,
    exportedAt: snapshot.exportedAt,
    notes: [
      for (final note in snapshot.notes) note.copyWith(userId: ownerId),
    ],
    reminders: [
      for (final reminder in snapshot.reminders)
        reminder.copyWith(userId: ownerId),
    ],
    reviews: [
      for (final review in snapshot.reviews) review.copyWith(userId: ownerId),
    ],
  );
}

CoreOwnerSnapshot _remapCore(
  CoreOwnerSnapshot snapshot,
  String ownerId,
) {
  String habitId(String sourceId) => _cloudEntityId(ownerId, 'habit', sourceId);
  String noteId(String sourceId) => _cloudEntityId(ownerId, 'note', sourceId);

  return CoreOwnerSnapshot(
    ownerId: ownerId,
    profile: snapshot.profile == null
        ? null
        : _remapProfile(snapshot.profile!, ownerId),
    habits: [
      for (final habit in snapshot.habits)
        habit.copyWith(id: habitId(habit.id)),
    ],
    logs: [
      for (final log in snapshot.logs)
        HabitLog(
          habitId: habitId(log.habitId),
          date: log.date,
        ),
    ],
    completedTasks: [
      for (final task in snapshot.completedTasks)
        CompletedTask(
          id: _cloudEntityId(ownerId, 'completed-task', task.id),
          title: task.title,
          category: task.category,
          completedAt: task.completedAt,
          wasOneTime: task.wasOneTime,
        ),
    ],
    focusSessions: [
      for (final session in snapshot.focusSessions)
        session.copyWith(
          id: _cloudEntityId(ownerId, 'focus-session', session.id),
          noteId: session.noteId == null ? null : noteId(session.noteId!),
        ),
    ],
    focusProgress: snapshot.focusProgress,
  );
}

String _cloudEntityId(
  String ownerId,
  String entity,
  String sourceId,
) {
  return const Uuid().v5(
    Namespace.url.value,
    'zentra://cloud-link/$ownerId/$entity/$sourceId',
  );
}

UserProfile _remapProfile(UserProfile source, String profileId) {
  return UserProfile.fromJson({
    ...source.toJson(),
    'id': profileId,
  });
}

List<T> _mergeById<T>(
  List<T> remote,
  List<T> source,
  String Function(T value) idOf,
) {
  final merged = <String, T>{
    for (final value in remote) idOf(value): value,
    for (final value in source) idOf(value): value,
  };
  return merged.values.toList(growable: false);
}

String _habitLogKey(HabitLog log) {
  final date = HabitLog.normalizeDate(log.date);
  return '${log.habitId}:${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

void _verifySourceContained({
  required CoreOwnerSnapshot sourceCore,
  required NoteOwnerSnapshot sourceNotes,
  required CoreOwnerSnapshot targetCore,
  required NoteOwnerSnapshot targetNotes,
}) {
  void requireSubset(
    Iterable<String> source,
    Iterable<String> target,
    String domain,
  ) {
    final missing = source.toSet().difference(target.toSet());
    if (missing.isNotEmpty) {
      throw StateError(
        'Cloud migration lost $domain records: ${missing.join(', ')}',
      );
    }
  }

  requireSubset(
    sourceCore.habits.map((habit) => habit.id),
    targetCore.habits.map((habit) => habit.id),
    'habit',
  );
  requireSubset(
    sourceCore.logs.map(_habitLogKey),
    targetCore.logs.map(_habitLogKey),
    'habit log',
  );
  requireSubset(
    sourceCore.completedTasks.map((task) => task.id),
    targetCore.completedTasks.map((task) => task.id),
    'completed task',
  );
  requireSubset(
    sourceCore.focusSessions.map((session) => session.id),
    targetCore.focusSessions.map((session) => session.id),
    'focus session',
  );
  requireSubset(
    sourceNotes.notes.map((note) => note.id),
    targetNotes.notes.map((note) => note.id),
    'note',
  );
  requireSubset(
    sourceNotes.reminders.map((reminder) => reminder.id),
    targetNotes.reminders.map((reminder) => reminder.id),
    'note reminder',
  );
  requireSubset(
    sourceNotes.reviews.map((review) => review.id),
    targetNotes.reviews.map((review) => review.id),
    'note review',
  );
}

class _RoutedAccountRepository implements AccountRepository {
  final LocalPersistenceRuntime _runtime;
  final AccountRepository _legacy;

  const _RoutedAccountRepository(this._runtime, this._legacy);

  @override
  Future<void> clearActiveSession() => _legacy.clearActiveSession();

  @override
  Future<void> clearCurrentAccount() => _legacy.clearCurrentAccount();

  @override
  Future<void> copyProfileToCurrent(String userId) async {
    final profile = await loadProfile(userId);
    if (profile != null) await _legacy.saveCurrentProfile(profile);
  }

  @override
  Future<void> deleteProfile(String userId) {
    if (!_runtime.supportsOwner(userId)) {
      return _legacy.deleteProfile(userId);
    }
    return _runtime._driftCore(userId).deleteProfile();
  }

  @override
  Future<String?> loadActiveSessionUserId() =>
      _legacy.loadActiveSessionUserId();

  @override
  Future<List<LocalUser>> loadAccounts() => _legacy.loadAccounts();

  @override
  Future<LocalUser?> loadCurrentAccount() => _legacy.loadCurrentAccount();

  @override
  Future<Map<String, dynamic>?> loadProfile(String? userId) async {
    if (userId == null || !_runtime.supportsOwner(userId)) {
      return _legacy.loadProfile(userId);
    }
    return (await _runtime._driftCore(userId).loadProfile())?.toJson();
  }

  @override
  Future<void> saveAccounts(List<LocalUser> accounts) =>
      _legacy.saveAccounts(accounts);

  @override
  Future<void> saveActiveSessionUserId(String userId) =>
      _legacy.saveActiveSessionUserId(userId);

  @override
  Future<void> saveCurrentAccount(LocalUser account) =>
      _legacy.saveCurrentAccount(account);

  @override
  Future<void> saveCurrentProfile(Map<String, dynamic> profile) =>
      _legacy.saveCurrentProfile(profile);

  @override
  Future<void> saveProfile(
    String userId,
    Map<String, dynamic> profile,
  ) {
    if (!_runtime.supportsOwner(userId)) {
      return _legacy.saveProfile(userId, profile);
    }
    final normalized = <String, dynamic>{
      ...profile,
      'id': userId,
    };
    return _runtime._driftCore(userId).saveProfile(
          UserProfile.fromJson(normalized),
        );
  }
}
