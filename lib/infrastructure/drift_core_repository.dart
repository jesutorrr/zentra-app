import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/completed_task_repository.dart';
import '../domain/core_owner_snapshot.dart';
import '../domain/focus_repository.dart';
import '../domain/models.dart';
import '../domain/pomodoro_activity.dart';
import '../domain/portable_preferences.dart';
import '../domain/profile_repository.dart';
import '../domain/sync/sync.dart';
import '../domain/user_profile.dart';
import 'database/zentra_database.dart';
import 'drift_sync_repository.dart';

class DriftCoreRepository
    implements
        HabitRepository,
        CompletedTaskRepository,
        FocusRepository,
        ProfileRepository,
        PortablePreferencesRepository {
  final ZentraDatabase _database;
  final DateTime Function() _clock;
  final String? _syncDeviceId;
  final void Function()? _onSyncNeeded;
  final String? _lockedOwnerId;
  String? _currentUserId;

  DriftCoreRepository(
    this._database, {
    DateTime Function()? clock,
    String? syncDeviceId,
    void Function()? onSyncNeeded,
  })  : _clock = clock ?? DateTime.now,
        _syncDeviceId = syncDeviceId,
        _onSyncNeeded = onSyncNeeded,
        _lockedOwnerId = null;

  /// Creates a repository instance permanently scoped to [ownerId].
  DriftCoreRepository.forOwner(
    this._database, {
    required String ownerId,
    DateTime Function()? clock,
    String? syncDeviceId,
    void Function()? onSyncNeeded,
  })  : _clock = clock ?? DateTime.now,
        _syncDeviceId = syncDeviceId,
        _onSyncNeeded = onSyncNeeded,
        _lockedOwnerId = _validateOwnerId(ownerId),
        _currentUserId = ownerId;

  String? get currentUserId => _currentUserId;

  @override
  String get ownerId => _requireOwner();

  @override
  void setCurrentUser(String? userId) {
    final lockedOwnerId = _lockedOwnerId;
    if (lockedOwnerId != null && userId != lockedOwnerId) {
      throw StateError(
        'This repository is locked to owner $lockedOwnerId '
        'and cannot switch to ${userId ?? 'no owner'}.',
      );
    }
    _currentUserId = userId;
  }

  @override
  Future<List<Habit>> getHabits() async {
    final ownerId = _requireOwner();
    final habitQuery = _database.select(_database.habitEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.createdAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    final scheduleQuery = _database.select(_database.habitScheduleEntries)
      ..where((row) => row.userId.equals(ownerId));
    final schedules = {
      for (final row in await scheduleQuery.get()) row.habitId: row,
    };
    return [
      for (final row in await habitQuery.get())
        _mapHabit(row, schedules[row.id]),
    ];
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final ownerId = _requireOwner();
    final existing = await _habitById(habit.id);
    if (existing != null) {
      throw StateError('Habit ${habit.id} already exists.');
    }
    await _database.transaction(() async {
      await _upsertHabit(habit, ownerId);
      await _enqueueHabitMutations(
        habit: habit,
        ownerId: ownerId,
        previousHabit: null,
        previousSchedule: null,
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final ownerId = _requireOwner();
    final existing = await _habitById(habit.id);
    if (existing == null) return;
    _assertOwner(existing.userId, ownerId, entity: 'habit');
    final previousSchedule = await _scheduleForHabit(ownerId, habit.id);
    await _database.transaction(() async {
      await _upsertHabit(habit, ownerId);
      await _enqueueHabitMutations(
        habit: habit,
        ownerId: ownerId,
        previousHabit: existing,
        previousSchedule: previousSchedule,
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final ownerId = _requireOwner();
    final existing = await _habitById(habitId);
    if (existing == null || existing.userId != ownerId) return;
    await _database.transaction(() async {
      if (_syncDeviceId == null) {
        await (_database.delete(_database.habitEntries)
              ..where(
                (row) => row.id.equals(habitId) & row.userId.equals(ownerId),
              ))
            .go();
        return;
      }
      final deletedAt = _clock().toUtc();
      await (_database.update(_database.habitEntries)
            ..where(
              (row) => row.id.equals(habitId) & row.userId.equals(ownerId),
            ))
          .write(
        HabitEntriesCompanion(
          isArchived: const Value(true),
          deletedAt: Value(deletedAt),
        ),
      );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.habit,
        entityId: habitId,
        operation: SyncMutationOperation.habitDelete,
        baseVersion: _baseVersion(existing.version, existing.serverRevision),
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<List<HabitLog>> getAllLogs() async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.habitDayStateEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.completed.equals(true),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.localDate),
        (row) => OrderingTerm.asc(row.habitId),
      ]);
    return (await query.get())
        .map(
          (row) => HabitLog(
            habitId: row.habitId,
            date: _parseLocalDate(row.localDate),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final ownerId = _requireOwner();
    final localDate = _formatLocalDate(date);
    final query = _database.select(_database.habitDayStateEntries)
      ..where(
        (row) =>
            row.userId.equals(ownerId) &
            row.localDate.equals(localDate) &
            row.completed.equals(true),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.habitId),
      ]);
    return (await query.get())
        .map(
          (row) => HabitLog(
            habitId: row.habitId,
            date: _parseLocalDate(row.localDate),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {
    final ownerId = _requireOwner();
    await _ensureOwnedHabit(habitId, ownerId);
    final localDate = _formatLocalDate(date);
    final query = _database.select(_database.habitDayStateEntries)
      ..where(
        (row) =>
            row.userId.equals(ownerId) &
            row.habitId.equals(habitId) &
            row.localDate.equals(localDate),
      );
    final existing = await query.getSingleOrNull();
    final completed = !(existing?.completed ?? false);
    final completedAt = completed ? _clock().toUtc() : null;
    final entityId =
        existing?.id ?? _habitDayStateId(ownerId, habitId, localDate);
    await _database.transaction(() async {
      await _database
          .into(_database.habitDayStateEntries)
          .insertOnConflictUpdate(
            HabitDayStateEntriesCompanion(
              id: Value(entityId),
              habitId: Value(habitId),
              userId: Value(ownerId),
              localDate: Value(localDate),
              completed: Value(completed),
              completedAt: Value(completedAt),
              version: Value(existing?.version ?? 1),
              serverRevision: Value(existing?.serverRevision ?? 0),
            ),
          );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.habitDayState,
        entityId: entityId,
        operation: SyncMutationOperation.habitCompletionSet,
        payload: {
          'habit_id': habitId,
          'local_date': localDate,
          'completed': completed,
        },
        baseVersion: existing == null
            ? null
            : _baseVersion(existing.version, existing.serverRevision),
      );
    });
    _notifySyncNeeded();
  }

  Future<UserProfile?> getProfile() async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.profileEntries)
      ..where((row) => row.userId.equals(ownerId));
    final row = await query.getSingleOrNull();
    return row == null
        ? null
        : UserProfile.fromJson(_decodeMap(row.payloadJson));
  }

  @override
  Future<UserProfile?> loadProfile() => getProfile();

  Future<void> upsertProfile(UserProfile profile) async {
    final ownerId = _requireOwner();
    final existing = await (_database.select(_database.profileEntries)
          ..where((row) => row.id.equals(profile.id)))
        .getSingleOrNull();
    if (existing != null) {
      _assertOwner(existing.userId, ownerId, entity: 'profile');
    }
    await _database.transaction(() async {
      await _database.into(_database.profileEntries).insertOnConflictUpdate(
            ProfileEntriesCompanion(
              id: Value(profile.id),
              userId: Value(ownerId),
              payloadJson: Value(jsonEncode(profile.toJson())),
              updatedAt: Value(_clock().toUtc()),
              version: Value(existing?.version ?? 1),
              serverRevision: Value(existing?.serverRevision ?? 0),
            ),
          );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.profile,
        entityId: profile.id,
        operation: SyncMutationOperation.profileUpsert,
        payload: {
          'name': profile.name,
          'avatar_emoji': profile.avatarEmoji,
          'talisman_id': profile.talismanId,
        },
        baseVersion: existing == null
            ? null
            : _baseVersion(existing.version, existing.serverRevision),
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> saveProfile(UserProfile profile) => upsertProfile(profile);

  @override
  Future<void> deleteProfile() async {
    final ownerId = _requireOwner();
    await (_database.delete(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
  }

  Future<List<CompletedTask>> getCompletedTasks() async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.completedTaskEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.completedAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return (await query.get())
        .map(
          (row) => CompletedTask(
            id: row.id,
            title: row.title,
            category: Category.fromString(row.category),
            completedAt: row.completedAt,
            wasOneTime: row.wasOneTime,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<CompletedTask>> loadCompletedTasks() => getCompletedTasks();

  @override
  Future<void> replaceCompletedTasks(List<CompletedTask> tasks) async {
    final ownerId = _requireOwner();
    final existingRows = await (_database.select(_database.completedTaskEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final existingById = {
      for (final row in existingRows) row.id: row,
    };
    final desiredIds = tasks.map((task) => task.id).toSet();
    var changed = false;
    await _database.transaction(() async {
      if (_syncDeviceId == null) {
        await (_database.delete(_database.completedTaskEntries)
              ..where((row) => row.userId.equals(ownerId)))
            .go();
      } else {
        for (final existing in existingRows) {
          if (existing.deletedAt != null || desiredIds.contains(existing.id)) {
            continue;
          }
          final deletedAt = _clock().toUtc();
          await (_database.update(_database.completedTaskEntries)
                ..where(
                  (row) =>
                      row.id.equals(existing.id) & row.userId.equals(ownerId),
                ))
              .write(
            CompletedTaskEntriesCompanion(
              deletedAt: Value(deletedAt),
            ),
          );
          await _enqueueMutation(
            ownerId: ownerId,
            entityType: SyncEntityType.completedTask,
            entityId: existing.id,
            operation: SyncMutationOperation.completedTaskDelete,
            baseVersion: _baseVersion(
              existing.version,
              existing.serverRevision,
            ),
          );
          changed = true;
        }
      }
      for (final task in tasks) {
        final previous = existingById[task.id];
        if (previous != null) {
          _assertOwner(previous.userId, ownerId, entity: 'completed task');
        }
        if (_syncDeviceId != null && _sameCompletedTask(previous, task)) {
          continue;
        }
        await _insertCompletedTask(
          task,
          ownerId,
          previous: previous,
        );
        await _enqueueMutation(
          ownerId: ownerId,
          entityType: SyncEntityType.completedTask,
          entityId: task.id,
          operation: SyncMutationOperation.completedTaskUpsert,
          payload: _completedTaskPayload(task),
          baseVersion: previous == null
              ? null
              : _baseVersion(previous.version, previous.serverRevision),
        );
        changed = true;
      }
    });
    if (changed) _notifySyncNeeded();
  }

  Future<List<PomodoroActivity>> getFocusSessions() async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.focusSessionEntries)
      ..where((row) => row.userId.equals(ownerId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.startedAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return (await query.get())
        .map(
          (row) => PomodoroActivity(
            id: row.id,
            name: row.name,
            startTime: row.startedAt,
            endTime: row.endedAt,
            cyclesCompleted: row.cyclesCompleted,
            totalMinutes: row.totalMinutes,
            isCompleted: row.isCompleted,
            noteId: row.noteId,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<PomodoroActivity>> loadFocusSessions() => getFocusSessions();

  @override
  Future<void> replaceFocusSessions(
    List<PomodoroActivity> sessions,
  ) async {
    final ownerId = _requireOwner();
    final existingRows = await (_database.select(_database.focusSessionEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final existingById = {
      for (final row in existingRows) row.id: row,
    };
    var changed = false;
    await _database.transaction(() async {
      if (_syncDeviceId == null) {
        await (_database.delete(_database.focusSessionEntries)
              ..where((row) => row.userId.equals(ownerId)))
            .go();
      }
      for (final session in sessions) {
        final previous = existingById[session.id];
        if (previous != null) {
          _assertOwner(previous.userId, ownerId, entity: 'focus session');
        }
        if (_syncDeviceId != null && _sameFocusSession(previous, session)) {
          continue;
        }
        await _insertFocusSession(
          session,
          ownerId,
          previous: previous,
        );
        if (session.isCompleted && session.endTime != null) {
          await _enqueueMutation(
            ownerId: ownerId,
            entityType: SyncEntityType.focusSession,
            entityId: session.id,
            operation: SyncMutationOperation.focusSessionComplete,
            payload: _focusSessionPayload(session),
            baseVersion: previous == null
                ? null
                : _baseVersion(previous.version, previous.serverRevision),
          );
        }
        changed = true;
      }
    });
    if (changed) _notifySyncNeeded();
  }

  Future<Map<String, Object?>> getFocusProgress() async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.focusProgressEntries)
      ..where((row) => row.userId.equals(ownerId));
    final row = await query.getSingleOrNull();
    return row == null ? const {} : _decodeMap(row.payloadJson);
  }

  @override
  Future<Map<String, Object?>> loadFocusProgress() => getFocusProgress();

  @override
  Future<PortablePreferences?> loadPortablePreferences() async {
    final ownerId = _requireOwner();
    final row = await (_database.select(_database.userPreferenceEntries)
          ..where((entry) => entry.userId.equals(ownerId)))
        .getSingleOrNull();
    if (row == null) return null;
    return PortablePreferences(
      ownerId: ownerId,
      themeMode: row.themeMode,
    );
  }

  @override
  Future<void> savePortableThemeMode(String themeMode) async {
    if (!portableThemeModes.contains(themeMode)) {
      throw ArgumentError.value(themeMode, 'themeMode', 'Unsupported mode');
    }
    final ownerId = _requireOwner();
    final existing = await (_database.select(_database.userPreferenceEntries)
          ..where((entry) => entry.userId.equals(ownerId)))
        .getSingleOrNull();
    if (existing?.themeMode == themeMode) return;

    await _database.transaction(() async {
      await _database
          .into(_database.userPreferenceEntries)
          .insertOnConflictUpdate(
            UserPreferenceEntriesCompanion(
              userId: Value(ownerId),
              themeMode: Value(themeMode),
              updatedAt: Value(_clock().toUtc()),
              version: Value(existing?.version ?? 1),
              serverRevision: Value(existing?.serverRevision ?? 0),
            ),
          );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.userPreferences,
        entityId: ownerId,
        operation: SyncMutationOperation.preferencesPatch,
        payload: {'theme_mode': themeMode},
        baseVersion: existing == null
            ? null
            : _baseVersion(existing.version, existing.serverRevision),
      );
    });
    _notifySyncNeeded();
  }

  Future<void> upsertFocusProgress(Map<String, Object?> progress) async {
    final ownerId = _requireOwner();
    await _database.into(_database.focusProgressEntries).insertOnConflictUpdate(
          FocusProgressEntriesCompanion(
            userId: Value(ownerId),
            payloadJson: Value(jsonEncode(progress)),
            updatedAt: Value(_clock().toUtc()),
          ),
        );
  }

  @override
  Future<void> saveFocusProgress(Map<String, Object?> progress) =>
      upsertFocusProgress(progress);

  Future<CoreOwnerSnapshot> exportOwner() async {
    return _exportOwner(_requireOwner());
  }

  Future<CoreOwnerSnapshot> replaceOwnerVerified(
    CoreOwnerSnapshot snapshot,
  ) async {
    final ownerId = _requireOwner();
    if (snapshot.ownerId != ownerId) {
      throw StateError(
        'Snapshot owner ${snapshot.ownerId} does not match $ownerId.',
      );
    }

    return _database.transaction(() async {
      await _deleteOwnerRows(ownerId);
      await _insertSnapshot(snapshot, ownerId);
      final stored = await _exportOwner(ownerId);
      if (!_sameCounts(stored.counts, snapshot.counts) ||
          stored.checksum != snapshot.checksum) {
        throw StateError('Core snapshot verification failed.');
      }
      return stored;
    });
  }

  Future<void> deleteOwner() {
    return _database.transaction(
      () => _deleteOwnerRows(_requireOwner()),
    );
  }

  Future<Map<SyncEntityKey, SyncLocalEntity>> loadSyncEntities() async {
    final ownerId = _requireOwner();
    final profiles = await (_database.select(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final habits = await (_database.select(_database.habitEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final schedules = await (_database.select(_database.habitScheduleEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final dayStates = await (_database.select(_database.habitDayStateEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final completedTasks =
        await (_database.select(_database.completedTaskEntries)
              ..where((row) => row.userId.equals(ownerId)))
            .get();
    final focusSessions = await (_database.select(_database.focusSessionEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final preferences = await (_database.select(_database.userPreferenceEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();

    return {
      for (final row in profiles)
        SyncEntityKey(type: SyncEntityType.profile, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.profile, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _profileWireRecord(row),
        ),
      for (final row in habits)
        SyncEntityKey(type: SyncEntityType.habit, id: row.id): SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.habit, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _habitWireRecord(row),
        ),
      for (final row in schedules)
        SyncEntityKey(type: SyncEntityType.habitSchedule, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.habitSchedule, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _scheduleWireRecord(row),
        ),
      for (final row in dayStates)
        SyncEntityKey(type: SyncEntityType.habitDayState, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.habitDayState, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _dayStateWireRecord(row),
        ),
      for (final row in completedTasks)
        SyncEntityKey(type: SyncEntityType.completedTask, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.completedTask, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _completedTaskWireRecord(row),
        ),
      for (final row in focusSessions)
        SyncEntityKey(type: SyncEntityType.focusSession, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.focusSession, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _focusSessionWireRecord(row),
        ),
      for (final row in preferences)
        SyncEntityKey(
          type: SyncEntityType.userPreferences,
          id: row.userId,
        ): SyncLocalEntity(
          key: SyncEntityKey(
            type: SyncEntityType.userPreferences,
            id: row.userId,
          ),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _preferenceWireRecord(row),
        ),
    };
  }

  Future<void> replaceSyncEntities(
    Map<SyncEntityKey, SyncLocalEntity> entities,
  ) async {
    final ownerId = _requireOwner();
    final previousProfile = await (_database.select(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .getSingleOrNull();

    await (_database.delete(_database.habitDayStateEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.habitScheduleEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.habitEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.completedTaskEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.focusSessionEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.userPreferenceEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();

    final ordered = entities.values.toList()
      ..sort(
        (left, right) => left.key.type.index.compareTo(right.key.type.index),
      );
    for (final entity in ordered) {
      switch (entity.key.type) {
        case SyncEntityType.profile:
          await _insertSyncedProfile(entity, ownerId, previousProfile);
        case SyncEntityType.habit:
          await _insertSyncedHabit(entity, ownerId);
        case SyncEntityType.habitSchedule:
          await _insertSyncedSchedule(entity, ownerId);
        case SyncEntityType.habitDayState:
          await _insertSyncedDayState(entity, ownerId);
        case SyncEntityType.completedTask:
          await _insertSyncedCompletedTask(entity, ownerId);
        case SyncEntityType.focusSession:
          await _insertSyncedFocusSession(entity, ownerId);
        case SyncEntityType.userPreferences:
          await _insertSyncedPreferences(entity, ownerId);
        case SyncEntityType.note:
        case SyncEntityType.noteReminder:
        case SyncEntityType.noteReview:
          throw StateError(
            'Unsupported local sync entity ${entity.key.type.wireName}.',
          );
      }
    }
  }

  Future<void> _enqueueHabitMutations({
    required Habit habit,
    required String ownerId,
    required HabitRow? previousHabit,
    required HabitScheduleRow? previousSchedule,
  }) async {
    if (_syncDeviceId == null) return;
    final currentSchedule = await _scheduleForHabit(ownerId, habit.id);
    if (currentSchedule == null) {
      throw StateError('Habit ${habit.id} is missing its local schedule.');
    }
    final mutationTime = _clock().toUtc();

    await _enqueueMutation(
      ownerId: ownerId,
      entityType: SyncEntityType.habit,
      entityId: habit.id,
      operation: SyncMutationOperation.habitUpsert,
      payload: {
        'title': habit.title,
        'category': habit.category.name,
        'is_one_time': habit.isOneTime,
      },
      baseVersion: previousHabit == null
          ? null
          : _baseVersion(
              previousHabit.version,
              previousHabit.serverRevision,
            ),
      createdAt: mutationTime,
    );
    await _enqueueMutation(
      ownerId: ownerId,
      entityType: SyncEntityType.habitSchedule,
      entityId: currentSchedule.id,
      operation: SyncMutationOperation.habitScheduleSet,
      payload: {
        'habit_id': habit.id,
        'is_weekly': habit.frequency.isWeekly,
        'days_of_week': habit.frequency.daysOfWeek,
        'scheduled_date': habit.scheduledDate == null
            ? null
            : _formatLocalDate(habit.scheduledDate!),
        'reminder_enabled': habit.hasReminder,
        'reminder_hour': habit.reminderHour,
        'reminder_minute': habit.reminderMinute,
        'time_zone': currentSchedule.timeZone,
      },
      baseVersion: previousSchedule == null
          ? null
          : _baseVersion(
              previousSchedule.version,
              previousSchedule.serverRevision,
            ),
      createdAt: mutationTime.add(const Duration(milliseconds: 1)),
    );

    if (habit.isArchived != (previousHabit?.isArchived ?? false)) {
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.habit,
        entityId: habit.id,
        operation: habit.isArchived
            ? SyncMutationOperation.habitArchive
            : SyncMutationOperation.habitRestore,
        baseVersion: previousHabit == null
            ? null
            : _baseVersion(
                previousHabit.version,
                previousHabit.serverRevision,
              ),
        createdAt: mutationTime.add(const Duration(milliseconds: 2)),
      );
    }
  }

  Future<void> _enqueueMutation({
    required String ownerId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncMutationOperation operation,
    Map<String, Object?> payload = const {},
    int? baseVersion,
    DateTime? createdAt,
  }) async {
    final deviceId = _syncDeviceId;
    if (deviceId == null) return;
    var orderedCreatedAt = (createdAt ?? _clock()).toUtc();
    final latest = await (_database.select(_database.syncOutboxEntries)
          ..where((row) => row.ownerId.equals(ownerId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (latest != null) {
      // Drift's default SQLite DateTime converter persists whole seconds.
      // Reserve the next second so dependent mutations keep their order after
      // a database round-trip instead of falling back to random UUID order.
      final minimumNextTimestamp =
          latest.createdAt.toUtc().add(const Duration(seconds: 1));
      if (orderedCreatedAt.isBefore(minimumNextTimestamp)) {
        orderedCreatedAt = minimumNextTimestamp;
      }
    }
    await DriftSyncRepository.forOwner(
      _database,
      ownerId: ownerId,
      clock: _clock,
    ).enqueue(
      SyncMutation(
        mutationId: const Uuid().v4(),
        ownerId: ownerId,
        deviceId: deviceId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        baseVersion: baseVersion,
        createdAt: orderedCreatedAt,
      ),
    );
  }

  void _notifySyncNeeded() {
    if (_syncDeviceId != null) _onSyncNeeded?.call();
  }

  Future<void> _insertSyncedProfile(
    SyncLocalEntity entity,
    String ownerId,
    ProfileRow? previous,
  ) async {
    final record = entity.record;
    final previousJson = previous == null
        ? <String, dynamic>{}
        : _decodeMap(previous.payloadJson).cast<String, dynamic>();
    final createdAt = _wireDateTime(record['created_at']) ??
        _wireDateTime(previousJson['createdAt']) ??
        _clock().toUtc();
    final payload = <String, dynamic>{
      ...previousJson,
      'id': entity.key.id,
      'name': (record['name'] as String?)?.trim().isNotEmpty == true
          ? record['name']
          : (previousJson['name'] ?? 'Mi espacio'),
      'avatarEmoji': record['avatar_emoji'],
      'talismanId': record['talisman_id'],
      'createdAt': createdAt.toIso8601String(),
    };
    await _database.into(_database.profileEntries).insert(
          ProfileEntriesCompanion.insert(
            id: entity.key.id,
            userId: ownerId,
            payloadJson: jsonEncode(payload),
            updatedAt: _wireDateTime(record['updated_at']) ?? _clock().toUtc(),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedHabit(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    await _database.into(_database.habitEntries).insert(
          HabitEntriesCompanion.insert(
            id: entity.key.id,
            userId: ownerId,
            title: record['title']! as String,
            category: record['category']! as String,
            createdAt: _wireDateTime(record['created_at']) ?? _clock().toUtc(),
            isArchived: Value(record['is_archived'] as bool? ?? false),
            isOneTime: Value(record['is_one_time'] as bool? ?? false),
            deletedAt: Value(_wireDateTime(record['deleted_at'])),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedSchedule(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    if (record['deleted_at'] != null) return;
    await _database.into(_database.habitScheduleEntries).insert(
          HabitScheduleEntriesCompanion.insert(
            id: entity.key.id,
            habitId: record['habit_id']! as String,
            userId: ownerId,
            isWeekly: record['is_weekly'] as bool? ?? true,
            daysOfWeekJson: jsonEncode(
              (record['days_of_week'] as List? ?? const []).cast<int>(),
            ),
            scheduledDate: Value(_wireLocalDate(record['scheduled_date'])),
            reminderEnabled:
                Value(record['reminder_enabled'] as bool? ?? false),
            reminderHour: Value((record['reminder_hour'] as num?)?.toInt()),
            reminderMinute: Value((record['reminder_minute'] as num?)?.toInt()),
            timeZone: Value(record['time_zone'] as String?),
            updatedAt: _wireDateTime(record['updated_at']) ?? _clock().toUtc(),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedDayState(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    if (record['deleted_at'] != null) return;
    await _database.into(_database.habitDayStateEntries).insert(
          HabitDayStateEntriesCompanion.insert(
            id: entity.key.id,
            habitId: record['habit_id']! as String,
            userId: ownerId,
            localDate: record['local_date']! as String,
            completed: record['completed']! as bool,
            completedAt: Value(_wireDateTime(record['completed_at'])),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedCompletedTask(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    await _database.into(_database.completedTaskEntries).insert(
          CompletedTaskEntriesCompanion.insert(
            id: entity.key.id,
            userId: ownerId,
            title: record['title']! as String,
            category: record['category']! as String,
            completedAt:
                _wireDateTime(record['completed_at']) ?? _clock().toUtc(),
            wasOneTime: record['was_one_time'] as bool? ?? false,
            deletedAt: Value(_wireDateTime(record['deleted_at'])),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedFocusSession(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    await _database.into(_database.focusSessionEntries).insert(
          FocusSessionEntriesCompanion.insert(
            id: entity.key.id,
            userId: ownerId,
            name: record['name']! as String,
            startedAt: _wireDateTime(record['started_at']) ?? _clock().toUtc(),
            endedAt: Value(_wireDateTime(record['ended_at'])),
            cyclesCompleted: (record['cycles_completed'] as num?)?.toInt() ?? 0,
            totalMinutes: (record['total_minutes'] as num?)?.toInt() ?? 0,
            isCompleted: record['is_completed'] as bool? ?? true,
            noteId: Value(record['note_id'] as String?),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedPreferences(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    if (entity.key.id != ownerId) {
      throw StateError('Portable preferences must use the owner UUID.');
    }
    final themeMode = entity.record['theme_mode'] as String?;
    if (themeMode == null || !portableThemeModes.contains(themeMode)) {
      throw const FormatException('Invalid portable theme mode.');
    }
    await _database.into(_database.userPreferenceEntries).insert(
          UserPreferenceEntriesCompanion.insert(
            userId: ownerId,
            themeMode: Value(themeMode),
            updatedAt:
                _wireDateTime(entity.record['updated_at']) ?? _clock().toUtc(),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _upsertHabit(Habit habit, String ownerId) async {
    final existing = await _habitById(habit.id);
    if (existing != null) {
      _assertOwner(existing.userId, ownerId, entity: 'habit');
    }

    await _database.into(_database.habitEntries).insertOnConflictUpdate(
          HabitEntriesCompanion(
            id: Value(habit.id),
            userId: Value(ownerId),
            title: Value(habit.title),
            category: Value(habit.category.name),
            createdAt: Value(habit.createdAt),
            isArchived: Value(habit.isArchived),
            isOneTime: Value(habit.isOneTime),
            deletedAt: Value(existing?.deletedAt),
            version: Value(existing?.version ?? 1),
            serverRevision: Value(existing?.serverRevision ?? 0),
          ),
        );

    final scheduleQuery = _database.select(_database.habitScheduleEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.habitId.equals(habit.id),
      );
    final existingSchedule = await scheduleQuery.getSingleOrNull();
    await _database.into(_database.habitScheduleEntries).insertOnConflictUpdate(
          HabitScheduleEntriesCompanion(
            id: Value(existingSchedule?.id ?? habit.id),
            habitId: Value(habit.id),
            userId: Value(ownerId),
            isWeekly: Value(habit.frequency.isWeekly),
            daysOfWeekJson: Value(jsonEncode(habit.frequency.daysOfWeek)),
            scheduledDate: Value(habit.scheduledDate),
            reminderEnabled: Value(habit.hasReminder),
            reminderHour: Value(habit.reminderHour),
            reminderMinute: Value(habit.reminderMinute),
            timeZone: Value(existingSchedule?.timeZone),
            updatedAt: Value(_clock().toUtc()),
            version: Value(existingSchedule?.version ?? 1),
            serverRevision: Value(existingSchedule?.serverRevision ?? 0),
          ),
        );
  }

  Future<void> _insertSnapshot(
    CoreOwnerSnapshot snapshot,
    String ownerId,
  ) async {
    final profile = snapshot.profile;
    if (profile != null) {
      await _database.into(_database.profileEntries).insert(
            ProfileEntriesCompanion.insert(
              id: profile.id,
              userId: ownerId,
              payloadJson: jsonEncode(profile.toJson()),
              updatedAt: _clock().toUtc(),
            ),
          );
    }
    for (final habit in snapshot.habits) {
      await _upsertHabit(habit, ownerId);
    }
    for (final log in snapshot.logs) {
      await _ensureOwnedHabit(log.habitId, ownerId);
      final localDate = _formatLocalDate(log.date);
      await _database.into(_database.habitDayStateEntries).insert(
            HabitDayStateEntriesCompanion.insert(
              id: _habitDayStateId(ownerId, log.habitId, localDate),
              habitId: log.habitId,
              userId: ownerId,
              localDate: localDate,
              completed: true,
              completedAt: Value(
                DateTime(
                  log.date.year,
                  log.date.month,
                  log.date.day,
                  12,
                ).toUtc(),
              ),
            ),
          );
    }
    for (final task in snapshot.completedTasks) {
      await _insertCompletedTask(task, ownerId);
    }
    for (final session in snapshot.focusSessions) {
      await _insertFocusSession(session, ownerId);
    }
    if (snapshot.focusProgress.isNotEmpty) {
      await _database.into(_database.focusProgressEntries).insert(
            FocusProgressEntriesCompanion.insert(
              userId: ownerId,
              payloadJson: jsonEncode(snapshot.focusProgress),
              updatedAt: _clock().toUtc(),
            ),
          );
    }
  }

  Future<CoreOwnerSnapshot> _exportOwner(String ownerId) async {
    final profileRow = await (_database.select(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .getSingleOrNull();

    final habitQuery = _database.select(_database.habitEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      );
    final scheduleQuery = _database.select(_database.habitScheduleEntries)
      ..where((row) => row.userId.equals(ownerId));
    final schedules = {
      for (final row in await scheduleQuery.get()) row.habitId: row,
    };
    final habits = [
      for (final row in await habitQuery.get())
        _mapHabit(row, schedules[row.id]),
    ];

    final logQuery = _database.select(_database.habitDayStateEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.completed.equals(true),
      );
    final taskQuery = _database.select(_database.completedTaskEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      );
    final focusQuery = _database.select(_database.focusSessionEntries)
      ..where((row) => row.userId.equals(ownerId));
    final progressRow = await (_database.select(_database.focusProgressEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .getSingleOrNull();

    return CoreOwnerSnapshot(
      ownerId: ownerId,
      profile: profileRow == null
          ? null
          : UserProfile.fromJson(_decodeMap(profileRow.payloadJson)),
      habits: habits,
      logs: [
        for (final row in await logQuery.get())
          HabitLog(
            habitId: row.habitId,
            date: _parseLocalDate(row.localDate),
          ),
      ],
      completedTasks: [
        for (final row in await taskQuery.get())
          CompletedTask(
            id: row.id,
            title: row.title,
            category: Category.fromString(row.category),
            completedAt: row.completedAt,
            wasOneTime: row.wasOneTime,
          ),
      ],
      focusSessions: [
        for (final row in await focusQuery.get())
          PomodoroActivity(
            id: row.id,
            name: row.name,
            startTime: row.startedAt,
            endTime: row.endedAt,
            cyclesCompleted: row.cyclesCompleted,
            totalMinutes: row.totalMinutes,
            isCompleted: row.isCompleted,
            noteId: row.noteId,
          ),
      ],
      focusProgress:
          progressRow == null ? const {} : _decodeMap(progressRow.payloadJson),
    );
  }

  Habit _mapHabit(HabitRow row, HabitScheduleRow? schedule) {
    final days = schedule == null
        ? const <int>[]
        : (jsonDecode(schedule.daysOfWeekJson) as List).cast<int>();
    return Habit(
      id: row.id,
      title: row.title,
      category: Category.fromString(row.category),
      frequency: Frequency(
        isWeekly: schedule?.isWeekly ?? false,
        daysOfWeek: days,
      ),
      createdAt: row.createdAt,
      isArchived: row.isArchived,
      isOneTime: row.isOneTime,
      scheduledDate: schedule?.scheduledDate,
      hasReminder: schedule?.reminderEnabled ?? false,
      reminderHour: schedule?.reminderHour,
      reminderMinute: schedule?.reminderMinute,
    );
  }

  Future<void> _insertCompletedTask(
    CompletedTask task,
    String ownerId, {
    CompletedTaskRow? previous,
  }) async {
    final existing = previous ??
        await (_database.select(_database.completedTaskEntries)
              ..where((row) => row.id.equals(task.id)))
            .getSingleOrNull();
    if (existing != null) {
      _assertOwner(existing.userId, ownerId, entity: 'completed task');
    }
    await _database.into(_database.completedTaskEntries).insertOnConflictUpdate(
          CompletedTaskEntriesCompanion(
            id: Value(task.id),
            userId: Value(ownerId),
            title: Value(task.title),
            category: Value(task.category.name),
            completedAt: Value(task.completedAt),
            wasOneTime: Value(task.wasOneTime),
            deletedAt: const Value(null),
            version: Value(existing?.version ?? 1),
            serverRevision: Value(existing?.serverRevision ?? 0),
          ),
        );
  }

  Future<void> _insertFocusSession(
    PomodoroActivity session,
    String ownerId, {
    FocusSessionRow? previous,
  }) async {
    final existing = previous ??
        await (_database.select(_database.focusSessionEntries)
              ..where((row) => row.id.equals(session.id)))
            .getSingleOrNull();
    if (existing != null) {
      _assertOwner(existing.userId, ownerId, entity: 'focus session');
    }
    await _database.into(_database.focusSessionEntries).insertOnConflictUpdate(
          FocusSessionEntriesCompanion(
            id: Value(session.id),
            userId: Value(ownerId),
            name: Value(session.name),
            startedAt: Value(session.startTime),
            endedAt: Value(session.endTime),
            cyclesCompleted: Value(session.cyclesCompleted),
            totalMinutes: Value(session.totalMinutes),
            isCompleted: Value(session.isCompleted),
            noteId: Value(session.noteId),
            version: Value(existing?.version ?? 1),
            serverRevision: Value(existing?.serverRevision ?? 0),
          ),
        );
  }

  Future<void> _deleteOwnerRows(String ownerId) async {
    await (_database.delete(_database.habitDayStateEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.habitScheduleEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.habitEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.profileEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.completedTaskEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.focusSessionEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.focusProgressEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.userPreferenceEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
  }

  Future<HabitRow?> _habitById(String habitId) {
    return (_database.select(_database.habitEntries)
          ..where((row) => row.id.equals(habitId)))
        .getSingleOrNull();
  }

  Future<HabitScheduleRow?> _scheduleForHabit(
    String ownerId,
    String habitId,
  ) {
    return (_database.select(_database.habitScheduleEntries)
          ..where(
            (row) => row.userId.equals(ownerId) & row.habitId.equals(habitId),
          ))
        .getSingleOrNull();
  }

  Future<void> _ensureOwnedHabit(String habitId, String ownerId) async {
    final habit = await _habitById(habitId);
    if (habit == null) {
      throw StateError('Habit $habitId does not exist.');
    }
    _assertOwner(habit.userId, ownerId, entity: 'habit');
  }

  String _requireOwner() {
    final ownerId = _currentUserId;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError('An active owner is required.');
    }
    return ownerId;
  }

  void _assertOwner(
    String actual,
    String expected, {
    required String entity,
  }) {
    if (actual != expected) {
      throw StateError('Cannot reuse a $entity owned by another user.');
    }
  }
}

String _validateOwnerId(String ownerId) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'Must not be blank.');
  }
  return ownerId;
}

Map<String, Object?> _decodeMap(String value) {
  return (jsonDecode(value) as Map).cast<String, Object?>();
}

Map<String, Object?> _profileWireRecord(ProfileRow row) {
  final profile = UserProfile.fromJson(_decodeMap(row.payloadJson));
  return {
    'id': row.id,
    'name': profile.name,
    'avatar_emoji': profile.avatarEmoji,
    'talisman_id': profile.talismanId,
    'created_at': profile.createdAt.toUtc().toIso8601String(),
    'updated_at': row.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };
}

Map<String, Object?> _habitWireRecord(HabitRow row) => {
      'id': row.id,
      'title': row.title,
      'category': row.category,
      'is_one_time': row.isOneTime,
      'is_archived': row.isArchived,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'updated_at': row.createdAt.toUtc().toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };

Map<String, Object?> _scheduleWireRecord(HabitScheduleRow row) => {
      'id': row.id,
      'habit_id': row.habitId,
      'is_weekly': row.isWeekly,
      'days_of_week': (jsonDecode(row.daysOfWeekJson) as List).cast<int>(),
      'scheduled_date': row.scheduledDate == null
          ? null
          : _formatLocalDate(row.scheduledDate!),
      'reminder_enabled': row.reminderEnabled,
      'reminder_hour': row.reminderHour,
      'reminder_minute': row.reminderMinute,
      'time_zone': row.timeZone,
      'created_at': row.updatedAt.toUtc().toIso8601String(),
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': null,
    };

Map<String, Object?> _dayStateWireRecord(HabitDayStateRow row) => {
      'id': row.id,
      'habit_id': row.habitId,
      'local_date': row.localDate,
      'completed': row.completed,
      'completed_at': row.completedAt?.toUtc().toIso8601String(),
      'deleted_at': null,
    };

Map<String, Object?> _completedTaskPayload(CompletedTask task) => {
      'title': task.title,
      'category': task.category.name,
      'completed_at': task.completedAt.toUtc().toIso8601String(),
      'was_one_time': task.wasOneTime,
    };

Map<String, Object?> _focusSessionPayload(PomodoroActivity session) => {
      'name': session.name,
      'started_at': session.startTime.toUtc().toIso8601String(),
      'ended_at': session.endTime?.toUtc().toIso8601String(),
      'cycles_completed': session.cyclesCompleted,
      'total_minutes': session.totalMinutes,
      'is_completed': session.isCompleted,
      'note_id': session.noteId,
    };

Map<String, Object?> _completedTaskWireRecord(CompletedTaskRow row) => {
      'id': row.id,
      'title': row.title,
      'category': row.category,
      'completed_at': row.completedAt.toUtc().toIso8601String(),
      'was_one_time': row.wasOneTime,
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };

Map<String, Object?> _focusSessionWireRecord(FocusSessionRow row) => {
      'id': row.id,
      'name': row.name,
      'started_at': row.startedAt.toUtc().toIso8601String(),
      'ended_at': row.endedAt?.toUtc().toIso8601String(),
      'cycles_completed': row.cyclesCompleted,
      'total_minutes': row.totalMinutes,
      'is_completed': row.isCompleted,
      'note_id': row.noteId,
      'deleted_at': null,
    };

Map<String, Object?> _preferenceWireRecord(UserPreferenceRow row) => {
      'theme_mode': row.themeMode,
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
    };

bool _sameCompletedTask(CompletedTaskRow? row, CompletedTask task) {
  return row != null &&
      row.deletedAt == null &&
      row.title == task.title &&
      row.category == task.category.name &&
      row.completedAt.toUtc() == task.completedAt.toUtc() &&
      row.wasOneTime == task.wasOneTime;
}

bool _sameFocusSession(FocusSessionRow? row, PomodoroActivity session) {
  return row != null &&
      row.name == session.name &&
      row.startedAt.toUtc() == session.startTime.toUtc() &&
      row.endedAt?.toUtc() == session.endTime?.toUtc() &&
      row.cyclesCompleted == session.cyclesCompleted &&
      row.totalMinutes == session.totalMinutes &&
      row.isCompleted == session.isCompleted &&
      row.noteId == session.noteId;
}

int? _baseVersion(int version, int serverRevision) {
  return serverRevision == 0 ? null : version;
}

DateTime? _wireDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.parse(value as String).toUtc();
}

DateTime? _wireLocalDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  return _parseLocalDate(value as String);
}

String _formatLocalDate(DateTime date) {
  final normalized = HabitLog.normalizeDate(date);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

DateTime _parseLocalDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid local date: $value');
  }
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String _habitDayStateId(
  String ownerId,
  String habitId,
  String localDate,
) {
  return const Uuid().v5(
    Namespace.url.value,
    'zentra://habit-day/$ownerId/$habitId/$localDate',
  );
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
