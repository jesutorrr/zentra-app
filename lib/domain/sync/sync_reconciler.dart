import 'sync_models.dart';

class SyncRoundInput {
  final SyncSnapshot snapshot;
  final List<SyncRemoteChange> firstPull;
  final List<SyncMutationAcknowledgement> acknowledgements;
  final List<SyncRemoteChange> secondPull;

  SyncRoundInput({
    required this.snapshot,
    List<SyncRemoteChange> firstPull = const [],
    List<SyncMutationAcknowledgement> acknowledgements = const [],
    List<SyncRemoteChange> secondPull = const [],
  })  : firstPull = List.unmodifiable(firstPull),
        acknowledgements = List.unmodifiable(acknowledgements),
        secondPull = List.unmodifiable(secondPull);
}

class SyncRoundStats {
  final int firstPullApplied;
  final int secondPullApplied;
  final int acknowledgementsApplied;
  final int mutationsRebased;
  final int mutationsSuperseded;
  final int conflictsCreated;

  const SyncRoundStats({
    required this.firstPullApplied,
    required this.secondPullApplied,
    required this.acknowledgementsApplied,
    required this.mutationsRebased,
    required this.mutationsSuperseded,
    required this.conflictsCreated,
  });

  Map<String, int> toJson() => {
        'first_pull_applied': firstPullApplied,
        'second_pull_applied': secondPullApplied,
        'acknowledgements_applied': acknowledgementsApplied,
        'mutations_rebased': mutationsRebased,
        'mutations_superseded': mutationsSuperseded,
        'conflicts_created': conflictsCreated,
      };
}

class SyncRoundResult {
  final SyncSnapshot snapshot;
  final SyncRoundStats stats;

  const SyncRoundResult({
    required this.snapshot,
    required this.stats,
  });
}

abstract final class SyncRoundReducer {
  static SyncRoundResult reduce(SyncRoundInput input) {
    final stats = _MutableSyncRoundStats();
    final afterFirstPull = _applyRemoteChanges(
      input.snapshot,
      input.firstPull,
      stats: stats,
      isSecondPull: false,
    );
    final afterPush = _applyAcknowledgements(
      afterFirstPull,
      input.acknowledgements,
      stats: stats,
    );
    final afterSecondPull = _applyRemoteChanges(
      afterPush,
      input.secondPull,
      stats: stats,
      isSecondPull: true,
    );

    return SyncRoundResult(
      snapshot: afterSecondPull,
      stats: stats.freeze(),
    );
  }

  static SyncSnapshot applyRemoteChanges(
    SyncSnapshot snapshot,
    List<SyncRemoteChange> changes,
  ) {
    return _applyRemoteChanges(
      snapshot,
      changes,
      stats: _MutableSyncRoundStats(),
      isSecondPull: false,
    );
  }

  static SyncSnapshot applyAcknowledgements(
    SyncSnapshot snapshot,
    List<SyncMutationAcknowledgement> acknowledgements,
  ) {
    return _applyAcknowledgements(
      snapshot,
      acknowledgements,
      stats: _MutableSyncRoundStats(),
    );
  }

  static SyncSnapshot _applyRemoteChanges(
    SyncSnapshot snapshot,
    List<SyncRemoteChange> changes, {
    required _MutableSyncRoundStats stats,
    required bool isSecondPull,
  }) {
    _validatePullOrder(snapshot.cursor, changes);

    final entities = Map<SyncEntityKey, SyncLocalEntity>.from(
      snapshot.entities,
    );
    var outbox = List<SyncMutation>.from(snapshot.outbox);
    final conflicts = {
      for (final conflict in snapshot.conflicts) conflict.id: conflict,
    };
    var cursor = snapshot.cursor;

    for (final change in changes) {
      if (change.serverRevision <= cursor) continue;

      final local = _findEntityByIdentity(
        entities,
        change.logicalIdentity,
      );
      final matching = outbox
          .where(
            (mutation) =>
                mutation.canSend &&
                (mutation.logicalIdentity == change.logicalIdentity ||
                    _isChildOfDeletedHabit(mutation, change)),
          )
          .toList(growable: false);

      if (local != null && local.serverRevision >= change.serverRevision) {
        _removeIdentityAliases(
          entities,
          logicalIdentity: change.logicalIdentity,
          keep: change.key,
        );
        entities[change.key] = local.copyWith(key: change.key);
        cursor = change.serverRevision;
        continue;
      }

      _removeIdentityAliases(
        entities,
        logicalIdentity: change.logicalIdentity,
        keep: change.key,
      );

      var remoteEntity = change.toLocalEntity();
      var active = matching;

      if (_isRemoteDelete(change)) {
        final restores = <SyncMutation>[];
        for (final mutation in matching) {
          if (_isMatchingDelete(mutation, change)) {
            outbox.removeWhere(
              (item) => item.mutationId == mutation.mutationId,
            );
            conflicts.removeWhere(
              (_, conflict) => conflict.mutationId == mutation.mutationId,
            );
            stats.mutationsSuperseded++;
            continue;
          }
          if (_isExplicitRestore(mutation)) {
            final rebased = _rebaseMutation(
              mutation,
              change.entityVersion,
            );
            outbox = _replaceMutation(outbox, rebased);
            restores.add(rebased);
            stats.mutationsRebased++;
            continue;
          }

          final blocked = mutation.copyWith(
            lifecycle: SyncMutationLifecycle.blockedByConflict,
            nextAttemptAt: null,
          );
          outbox = _replaceMutation(outbox, blocked);
          active = active
              .where((item) => item.mutationId != mutation.mutationId)
              .toList(growable: false);
          final conflict = SyncConflict.remoteDelete(
            mutation: mutation,
            change: change,
            localRecord: _findEntityByIdentity(
                  entities,
                  mutation.logicalIdentity,
                )?.record ??
                mutation.payload,
          );
          if (!conflicts.containsKey(conflict.id)) {
            conflicts[conflict.id] = conflict;
            stats.conflictsCreated++;
          }
        }
        active = restores;
      } else {
        final supersededIds = matching
            .where(
              (mutation) => _remoteAlreadyHasDesiredState(
                mutation,
                change,
              ),
            )
            .map((mutation) => mutation.mutationId)
            .toSet();

        if (supersededIds.isNotEmpty) {
          outbox.removeWhere(
            (mutation) => supersededIds.contains(mutation.mutationId),
          );
          conflicts.removeWhere(
            (_, conflict) =>
                conflict.mutationId != null &&
                supersededIds.contains(conflict.mutationId),
          );
          stats.mutationsSuperseded += supersededIds.length;
        }

        final conflictedIds = <String>{};
        for (final mutation in matching) {
          if (supersededIds.contains(mutation.mutationId) ||
              !_requiresConcurrentConflict(mutation, change)) {
            continue;
          }
          final blocked = mutation.copyWith(
            lifecycle: SyncMutationLifecycle.blockedByConflict,
            nextAttemptAt: null,
          );
          outbox = _replaceMutation(outbox, blocked);
          conflictedIds.add(mutation.mutationId);
          final conflict = SyncConflict.concurrentUpdate(
            mutation: mutation,
            change: change,
            localRecord: _findEntityByIdentity(
                  entities,
                  mutation.logicalIdentity,
                )?.record ??
                mutation.payload,
          );
          if (!conflicts.containsKey(conflict.id)) {
            conflicts[conflict.id] = conflict;
            stats.conflictsCreated++;
          }
        }

        active = matching
            .where(
              (mutation) =>
                  !supersededIds.contains(mutation.mutationId) &&
                  !conflictedIds.contains(mutation.mutationId),
            )
            .map(
              (mutation) => _rebaseMutation(
                mutation,
                change.entityVersion,
              ),
            )
            .toList(growable: false);

        for (final mutation in active) {
          outbox = _replaceMutation(outbox, mutation);
          stats.mutationsRebased++;
        }
      }

      for (final mutation in active) {
        remoteEntity = _overlayMutation(remoteEntity, mutation);
      }
      entities[change.key] = remoteEntity;
      cursor = change.serverRevision;

      if (isSecondPull) {
        stats.secondPullApplied++;
      } else {
        stats.firstPullApplied++;
      }
    }

    return SyncSnapshot(
      entities: entities,
      outbox: outbox,
      conflicts: conflicts.values.toList(growable: false),
      cursor: cursor,
    );
  }

  static SyncSnapshot _applyAcknowledgements(
    SyncSnapshot snapshot,
    List<SyncMutationAcknowledgement> acknowledgements, {
    required _MutableSyncRoundStats stats,
  }) {
    final entities = Map<SyncEntityKey, SyncLocalEntity>.from(
      snapshot.entities,
    );
    var outbox = List<SyncMutation>.from(snapshot.outbox);
    final conflicts = List<SyncConflict>.from(snapshot.conflicts);

    for (final acknowledgement in acknowledgements) {
      outbox.removeWhere(
        (mutation) => mutation.mutationId == acknowledgement.mutationId,
      );
      conflicts.removeWhere(
        (conflict) => conflict.mutationId == acknowledgement.mutationId,
      );

      final current = _findEntityByIdentity(
        entities,
        acknowledgement.logicalIdentity,
      );
      _removeIdentityAliases(
        entities,
        logicalIdentity: acknowledgement.logicalIdentity,
        keep: acknowledgement.key,
      );

      var acknowledged = acknowledgement.toLocalEntity();
      if (current != null &&
          current.serverRevision > acknowledged.serverRevision) {
        acknowledged = current.copyWith(key: acknowledgement.key);
      }

      final remaining = outbox
          .where(
            (mutation) =>
                mutation.logicalIdentity == acknowledgement.logicalIdentity &&
                mutation.canSend,
          )
          .map(
            (mutation) => _rebaseMutation(
              mutation,
              acknowledged.version,
            ),
          )
          .toList(growable: false);

      for (final mutation in remaining) {
        outbox = _replaceMutation(outbox, mutation);
        acknowledged = _overlayMutation(acknowledged, mutation);
        stats.mutationsRebased++;
      }

      entities[acknowledgement.key] = acknowledged;
      stats.acknowledgementsApplied++;
    }

    return SyncSnapshot(
      entities: entities,
      outbox: outbox,
      conflicts: conflicts,
      cursor: snapshot.cursor,
    );
  }

  static void _validatePullOrder(
    int cursor,
    List<SyncRemoteChange> changes,
  ) {
    var previous = cursor;
    for (final change in changes) {
      if (change.serverRevision <= cursor) continue;
      if (change.serverRevision <= previous) {
        throw FormatException(
          'Pull revisions must be strictly increasing after cursor $cursor',
        );
      }
      previous = change.serverRevision;
    }
  }

  static SyncLocalEntity? _findEntityByIdentity(
    Map<SyncEntityKey, SyncLocalEntity> entities,
    String logicalIdentity,
  ) {
    for (final entity in entities.values) {
      if (entity.logicalIdentity == logicalIdentity) return entity;
    }
    return null;
  }

  static void _removeIdentityAliases(
    Map<SyncEntityKey, SyncLocalEntity> entities, {
    required String logicalIdentity,
    required SyncEntityKey keep,
  }) {
    final aliases = entities.entries
        .where(
          (entry) =>
              entry.key != keep &&
              entry.value.logicalIdentity == logicalIdentity,
        )
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final alias in aliases) {
      entities.remove(alias);
    }
  }

  static bool _isRemoteDelete(SyncRemoteChange change) {
    return change.operation == SyncServerOperation.delete ||
        change.record['deleted_at'] != null;
  }

  static bool _isChildOfDeletedHabit(
    SyncMutation mutation,
    SyncRemoteChange change,
  ) {
    if (!_isRemoteDelete(change) || change.entityType != SyncEntityType.habit) {
      return false;
    }
    if (mutation.entityType != SyncEntityType.habitSchedule &&
        mutation.entityType != SyncEntityType.habitDayState) {
      return false;
    }
    return mutation.payload['habit_id'] == change.entityId;
  }

  static bool _isExplicitRestore(SyncMutation mutation) {
    return mutation.operation == SyncMutationOperation.habitRestore ||
        mutation.operation == SyncMutationOperation.noteRestore;
  }

  static bool _isMatchingDelete(
    SyncMutation mutation,
    SyncRemoteChange change,
  ) {
    return (mutation.operation == SyncMutationOperation.habitDelete &&
            change.entityType == SyncEntityType.habit) ||
        (mutation.operation == SyncMutationOperation.completedTaskDelete &&
            change.entityType == SyncEntityType.completedTask) ||
        (mutation.operation == SyncMutationOperation.noteDelete &&
            change.entityType == SyncEntityType.note);
  }

  static bool _remoteAlreadyHasDesiredState(
    SyncMutation mutation,
    SyncRemoteChange change,
  ) {
    switch (mutation.operation) {
      case SyncMutationOperation.habitCompletionSet:
        return mutation.payload['completed'] == change.record['completed'];
      case SyncMutationOperation.habitArchive:
      case SyncMutationOperation.noteArchive:
        return change.record['is_archived'] == true &&
            change.record['deleted_at'] == null;
      case SyncMutationOperation.habitRestore:
      case SyncMutationOperation.noteRestore:
        return change.record['is_archived'] == false &&
            change.record['deleted_at'] == null;
      case SyncMutationOperation.profileUpsert:
      case SyncMutationOperation.habitUpsert:
      case SyncMutationOperation.habitDelete:
      case SyncMutationOperation.habitScheduleSet:
      case SyncMutationOperation.completedTaskUpsert:
      case SyncMutationOperation.completedTaskDelete:
      case SyncMutationOperation.noteUpsert:
      case SyncMutationOperation.noteDelete:
      case SyncMutationOperation.noteReminderSet:
      case SyncMutationOperation.noteReviewAdd:
      case SyncMutationOperation.focusSessionComplete:
      case SyncMutationOperation.preferencesPatch:
        return false;
    }
  }

  static bool _requiresConcurrentConflict(
    SyncMutation mutation,
    SyncRemoteChange change,
  ) {
    return mutation.operation == SyncMutationOperation.noteUpsert &&
        mutation.baseVersion != change.entityVersion;
  }

  static SyncMutation _rebaseMutation(
    SyncMutation mutation,
    int version,
  ) {
    return mutation.copyWith(
      baseVersion: version,
      lifecycle: SyncMutationLifecycle.pending,
      nextAttemptAt: null,
    );
  }

  static List<SyncMutation> _replaceMutation(
    List<SyncMutation> outbox,
    SyncMutation replacement,
  ) {
    return [
      for (final mutation in outbox)
        if (mutation.mutationId == replacement.mutationId)
          replacement
        else
          mutation,
    ];
  }

  static SyncLocalEntity _overlayMutation(
    SyncLocalEntity entity,
    SyncMutation mutation,
  ) {
    final record = Map<String, Object?>.from(entity.record);

    switch (mutation.operation) {
      case SyncMutationOperation.habitArchive:
      case SyncMutationOperation.noteArchive:
        record['is_archived'] = true;
      case SyncMutationOperation.habitRestore:
      case SyncMutationOperation.noteRestore:
        record['is_archived'] = false;
        record['deleted_at'] = null;
      case SyncMutationOperation.habitDelete:
      case SyncMutationOperation.noteDelete:
        record['is_archived'] = true;
        record['deleted_at'] = mutation.createdAt.toIso8601String();
      case SyncMutationOperation.completedTaskDelete:
        record['deleted_at'] = mutation.createdAt.toIso8601String();
      case SyncMutationOperation.profileUpsert:
      case SyncMutationOperation.habitUpsert:
      case SyncMutationOperation.habitScheduleSet:
      case SyncMutationOperation.habitCompletionSet:
      case SyncMutationOperation.completedTaskUpsert:
      case SyncMutationOperation.noteUpsert:
      case SyncMutationOperation.noteReminderSet:
      case SyncMutationOperation.noteReviewAdd:
      case SyncMutationOperation.focusSessionComplete:
      case SyncMutationOperation.preferencesPatch:
        record.addAll(mutation.payload);
    }

    return entity.copyWith(record: record);
  }
}

abstract final class SyncPushPlanner {
  static List<SyncMutation> readyMutations({
    required SyncSnapshot snapshot,
    required DateTime now,
    int limit = 50,
  }) {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }

    final identities = <String>{};
    final ready = <SyncMutation>[];
    final currentTime = now.toUtc();

    for (final mutation in snapshot.outbox) {
      if (!mutation.canSend) continue;
      if (mutation.nextAttemptAt?.isAfter(currentTime) ?? false) continue;
      if (!identities.add(mutation.logicalIdentity)) continue;
      ready.add(mutation);
      if (ready.length == limit) break;
    }

    return List.unmodifiable(ready);
  }
}

class _MutableSyncRoundStats {
  int firstPullApplied = 0;
  int secondPullApplied = 0;
  int acknowledgementsApplied = 0;
  int mutationsRebased = 0;
  int mutationsSuperseded = 0;
  int conflictsCreated = 0;

  SyncRoundStats freeze() => SyncRoundStats(
        firstPullApplied: firstPullApplied,
        secondPullApplied: secondPullApplied,
        acknowledgementsApplied: acknowledgementsApplied,
        mutationsRebased: mutationsRebased,
        mutationsSuperseded: mutationsSuperseded,
        conflictsCreated: conflictsCreated,
      );
}
