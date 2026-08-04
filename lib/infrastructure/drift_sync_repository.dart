import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/sync/sync.dart';
import 'database/zentra_database.dart';

enum LocalMigrationStatus {
  running,
  completed,
  failed,
}

class SyncQueueState {
  final int cursor;
  final List<SyncMutation> outbox;
  final List<SyncConflict> conflicts;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastAttemptAt;

  SyncQueueState({
    required this.cursor,
    List<SyncMutation> outbox = const [],
    List<SyncConflict> conflicts = const [],
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastAttemptAt,
  })  : outbox = List.unmodifiable(
          List<SyncMutation>.of(outbox)..sort(_compareMutations),
        ),
        conflicts = List.unmodifiable(
          List<SyncConflict>.of(conflicts)
            ..sort((left, right) => left.id.compareTo(right.id)),
        ),
        lastSuccessfulSyncAt = lastSuccessfulSyncAt?.toUtc(),
        lastAttemptAt = lastAttemptAt?.toUtc() {
    if (cursor < 0) {
      throw ArgumentError.value(cursor, 'cursor', 'Cannot be negative');
    }
    if (outbox.map((mutation) => mutation.mutationId).toSet().length !=
        outbox.length) {
      throw ArgumentError('Outbox mutation IDs must be unique');
    }
    if (conflicts.map((conflict) => conflict.id).toSet().length !=
        conflicts.length) {
      throw ArgumentError('Conflict IDs must be unique');
    }
  }

  SyncSnapshot toReducerSnapshot({
    Map<SyncEntityKey, SyncLocalEntity> entities = const {},
  }) {
    return SyncSnapshot(
      entities: entities,
      outbox: outbox,
      conflicts: conflicts,
      cursor: cursor,
    );
  }
}

class LocalMigrationRecord {
  final String ownerId;
  final String migrationName;
  final LocalMigrationStatus status;
  final String? sourceChecksum;
  final String? targetChecksum;
  final Map<String, int> sourceCounts;
  final Map<String, int> targetCounts;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? failureReason;

  LocalMigrationRecord({
    required this.ownerId,
    required this.migrationName,
    required this.status,
    required DateTime startedAt,
    this.sourceChecksum,
    this.targetChecksum,
    Map<String, int> sourceCounts = const {},
    Map<String, int> targetCounts = const {},
    DateTime? completedAt,
    this.failureReason,
  })  : sourceCounts = Map.unmodifiable(sourceCounts),
        targetCounts = Map.unmodifiable(targetCounts),
        startedAt = startedAt.toUtc(),
        completedAt = completedAt?.toUtc();
}

class DriftSyncRepository {
  final ZentraDatabase _database;
  final DateTime Function() _clock;
  final String? _lockedOwnerId;
  String? _currentOwnerId;

  DriftSyncRepository(
    this._database, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _lockedOwnerId = null;

  /// Creates a repository instance permanently scoped to [ownerId].
  DriftSyncRepository.forOwner(
    this._database, {
    required String ownerId,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _lockedOwnerId = _validateOwnerId(ownerId),
        _currentOwnerId = ownerId;

  String? get currentOwnerId => _currentOwnerId;

  void setCurrentOwner(String? ownerId) {
    final lockedOwnerId = _lockedOwnerId;
    if (lockedOwnerId != null && ownerId != lockedOwnerId) {
      throw StateError(
        'This repository is locked to owner $lockedOwnerId '
        'and cannot switch to ${ownerId ?? 'no owner'}.',
      );
    }
    _currentOwnerId = ownerId;
  }

  Future<SyncQueueState> loadQueueState() async {
    final ownerId = _requireOwner();
    final outboxQuery = _database.select(_database.syncOutboxEntries)
      ..where((row) => row.ownerId.equals(ownerId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.createdAt),
        (row) => OrderingTerm.asc(row.mutationId),
      ]);
    final conflictQuery = _database.select(_database.syncConflictEntries)
      ..where((row) => row.ownerId.equals(ownerId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.id),
      ]);
    final state = await (_database.select(_database.syncStateEntries)
          ..where((row) => row.ownerId.equals(ownerId)))
        .getSingleOrNull();

    return SyncQueueState(
      cursor: state?.cursor ?? 0,
      outbox: (await outboxQuery.get()).map(_mapMutation).toList(
            growable: false,
          ),
      conflicts: (await conflictQuery.get()).map(_mapConflict).toList(
            growable: false,
          ),
      lastSuccessfulSyncAt: state?.lastSuccessfulSyncAt,
      lastAttemptAt: state?.lastAttemptAt,
    );
  }

  Future<void> replaceQueueState(SyncQueueState state) async {
    final ownerId = _requireOwner();
    for (final mutation in state.outbox) {
      if (mutation.ownerId != ownerId) {
        throw StateError(
          'Mutation ${mutation.mutationId} belongs to another owner.',
        );
      }
    }

    await _database.transaction(() async {
      await (_database.delete(_database.syncOutboxEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.syncConflictEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();

      for (final mutation in state.outbox) {
        await _insertMutation(mutation);
      }
      for (final conflict in state.conflicts) {
        await _insertConflict(conflict, ownerId);
      }
      await _upsertState(
        ownerId: ownerId,
        cursor: state.cursor,
        lastSuccessfulSyncAt: state.lastSuccessfulSyncAt,
        lastAttemptAt: state.lastAttemptAt,
      );
    });
  }

  Future<void> enqueue(SyncMutation mutation) async {
    final ownerId = _requireOwner();
    if (mutation.ownerId != ownerId) {
      throw StateError(
        'Mutation ${mutation.mutationId} belongs to another owner.',
      );
    }
    await _insertMutation(mutation);
  }

  Future<void> saveReducerMetadata(
    SyncSnapshot snapshot, {
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastAttemptAt,
  }) {
    return replaceQueueState(
      SyncQueueState(
        cursor: snapshot.cursor,
        outbox: snapshot.outbox,
        conflicts: snapshot.conflicts,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt,
        lastAttemptAt: lastAttemptAt,
      ),
    );
  }

  Future<void> linkOwner({
    required String localOwnerId,
    required String remoteUserId,
    String state = 'linked',
  }) async {
    final ownerId = _requireOwner();
    if (localOwnerId != ownerId) {
      throw StateError('Cannot link a different local owner.');
    }
    final now = _clock().toUtc();
    final existing = await (_database.select(_database.localOwnerLinkEntries)
          ..where((row) => row.localOwnerId.equals(localOwnerId)))
        .getSingleOrNull();
    await _database
        .into(_database.localOwnerLinkEntries)
        .insertOnConflictUpdate(
          LocalOwnerLinkEntriesCompanion(
            localOwnerId: Value(localOwnerId),
            remoteUserId: Value(remoteUserId),
            state: Value(state),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<String?> getLinkedRemoteUserId() async {
    final ownerId = _requireOwner();
    final row = await (_database.select(_database.localOwnerLinkEntries)
          ..where((entry) => entry.localOwnerId.equals(ownerId)))
        .getSingleOrNull();
    return row?.remoteUserId;
  }

  Future<void> unlinkOwner() async {
    final ownerId = _requireOwner();
    await (_database.delete(_database.localOwnerLinkEntries)
          ..where((entry) => entry.localOwnerId.equals(ownerId)))
        .go();
  }

  Future<LocalMigrationRecord?> getMigration(String migrationName) async {
    final ownerId = _requireOwner();
    final row = await (_database.select(_database.localMigrationStateEntries)
          ..where(
            (entry) =>
                entry.ownerId.equals(ownerId) &
                entry.migrationName.equals(migrationName),
          ))
        .getSingleOrNull();
    return row == null ? null : _mapMigration(row);
  }

  Future<void> recordMigration(LocalMigrationRecord record) async {
    final ownerId = _requireOwner();
    if (record.ownerId != ownerId) {
      throw StateError('Cannot record a migration for another owner.');
    }
    await _database
        .into(_database.localMigrationStateEntries)
        .insertOnConflictUpdate(
          LocalMigrationStateEntriesCompanion(
            ownerId: Value(record.ownerId),
            migrationName: Value(record.migrationName),
            status: Value(record.status.name),
            sourceChecksum: Value(record.sourceChecksum),
            targetChecksum: Value(record.targetChecksum),
            sourceCountsJson: Value(
              record.sourceCounts.isEmpty
                  ? null
                  : jsonEncode(record.sourceCounts),
            ),
            targetCountsJson: Value(
              record.targetCounts.isEmpty
                  ? null
                  : jsonEncode(record.targetCounts),
            ),
            startedAt: Value(record.startedAt),
            completedAt: Value(record.completedAt),
            failureReason: Value(record.failureReason),
          ),
        );
  }

  Future<void> deleteOwnerMetadata() async {
    final ownerId = _requireOwner();
    await _database.transaction(() async {
      await (_database.delete(_database.syncOutboxEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.syncConflictEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.syncStateEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.localNotificationBindingEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.localMigrationStateEntries)
            ..where((row) => row.ownerId.equals(ownerId)))
          .go();
      await (_database.delete(_database.localOwnerLinkEntries)
            ..where(
              (row) =>
                  row.localOwnerId.equals(ownerId) |
                  row.remoteUserId.equals(ownerId),
            ))
          .go();
    });
  }

  Future<void> _insertMutation(SyncMutation mutation) async {
    final existing = await (_database.select(_database.syncOutboxEntries)
          ..where((row) => row.mutationId.equals(mutation.mutationId)))
        .getSingleOrNull();
    if (existing != null && existing.ownerId != mutation.ownerId) {
      throw StateError('Cannot reuse another owner mutation ID.');
    }
    await _database.into(_database.syncOutboxEntries).insertOnConflictUpdate(
          SyncOutboxEntriesCompanion(
            mutationId: Value(mutation.mutationId),
            ownerId: Value(mutation.ownerId),
            deviceId: Value(mutation.deviceId),
            entityType: Value(mutation.entityType.wireName),
            entityId: Value(mutation.entityId),
            operation: Value(mutation.operation.wireName),
            payloadJson: Value(jsonEncode(mutation.payload)),
            baseVersion: Value(mutation.baseVersion),
            createdAt: Value(mutation.createdAt),
            attemptCount: Value(mutation.attemptCount),
            nextAttemptAt: Value(mutation.nextAttemptAt),
            lifecycle: Value(mutation.lifecycle.name),
          ),
        );
  }

  Future<void> _insertConflict(
    SyncConflict conflict,
    String ownerId,
  ) async {
    final existing = await (_database.select(_database.syncConflictEntries)
          ..where((row) => row.id.equals(conflict.id)))
        .getSingleOrNull();
    if (existing != null && existing.ownerId != ownerId) {
      throw StateError('Cannot reuse another owner conflict ID.');
    }
    await _database.into(_database.syncConflictEntries).insertOnConflictUpdate(
          SyncConflictEntriesCompanion(
            id: Value(conflict.id),
            ownerId: Value(ownerId),
            kind: Value(conflict.kind.name),
            entityType: Value(conflict.entityKey.type.wireName),
            entityId: Value(conflict.entityKey.id),
            mutationId: Value(conflict.mutationId),
            localRecordJson: Value(jsonEncode(conflict.localRecord)),
            remoteRecordJson: Value(jsonEncode(conflict.remoteRecord)),
            createdAt: Value(existing?.createdAt ?? _clock().toUtc()),
          ),
        );
  }

  Future<void> _upsertState({
    required String ownerId,
    required int cursor,
    required DateTime? lastSuccessfulSyncAt,
    required DateTime? lastAttemptAt,
  }) async {
    await _database.into(_database.syncStateEntries).insertOnConflictUpdate(
          SyncStateEntriesCompanion(
            ownerId: Value(ownerId),
            cursor: Value(cursor),
            lastSuccessfulSyncAt: Value(lastSuccessfulSyncAt),
            lastAttemptAt: Value(lastAttemptAt),
            updatedAt: Value(_clock().toUtc()),
          ),
        );
  }

  SyncMutation _mapMutation(SyncOutboxRow row) {
    return SyncMutation(
      mutationId: row.mutationId,
      ownerId: row.ownerId,
      deviceId: row.deviceId,
      entityType: SyncEntityType.fromWire(row.entityType),
      entityId: row.entityId,
      operation: SyncMutationOperation.fromWire(row.operation),
      payload: _decodeObject(row.payloadJson),
      baseVersion: row.baseVersion,
      createdAt: row.createdAt,
      attemptCount: row.attemptCount,
      nextAttemptAt: row.nextAttemptAt,
      lifecycle: SyncMutationLifecycle.values.byName(row.lifecycle),
    );
  }

  SyncConflict _mapConflict(SyncConflictRow row) {
    return SyncConflict(
      id: row.id,
      kind: SyncConflictKind.values.byName(row.kind),
      entityKey: SyncEntityKey(
        type: SyncEntityType.fromWire(row.entityType),
        id: row.entityId,
      ),
      mutationId: row.mutationId,
      localRecord: _decodeObject(row.localRecordJson),
      remoteRecord: _decodeObject(row.remoteRecordJson),
    );
  }

  LocalMigrationRecord _mapMigration(LocalMigrationStateRow row) {
    return LocalMigrationRecord(
      ownerId: row.ownerId,
      migrationName: row.migrationName,
      status: LocalMigrationStatus.values.byName(row.status),
      sourceChecksum: row.sourceChecksum,
      targetChecksum: row.targetChecksum,
      sourceCounts: _decodeCounts(row.sourceCountsJson),
      targetCounts: _decodeCounts(row.targetCountsJson),
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      failureReason: row.failureReason,
    );
  }

  String _requireOwner() {
    final ownerId = _currentOwnerId;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError('An active owner is required.');
    }
    return ownerId;
  }
}

String _validateOwnerId(String ownerId) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'Must not be blank.');
  }
  return ownerId;
}

Map<String, Object?> _decodeObject(String value) {
  return (jsonDecode(value) as Map).cast<String, Object?>();
}

Map<String, int> _decodeCounts(String? value) {
  if (value == null) return const {};
  final decoded = jsonDecode(value) as Map;
  return decoded.map(
    (key, count) => MapEntry(key as String, count as int),
  );
}

int _compareMutations(SyncMutation left, SyncMutation right) {
  final byCreation = left.createdAt.compareTo(right.createdAt);
  if (byCreation != 0) return byCreation;
  return left.mutationId.compareTo(right.mutationId);
}
