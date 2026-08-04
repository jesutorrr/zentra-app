const Object _syncUnset = Object();

enum SyncEntityType {
  profile('profile'),
  habit('habit'),
  habitSchedule('habit_schedule'),
  habitDayState('habit_day_state'),
  completedTask('completed_task'),
  note('note'),
  noteReminder('note_reminder'),
  noteReview('note_review'),
  focusSession('focus_session'),
  userPreferences('user_preferences');

  final String wireName;

  const SyncEntityType(this.wireName);

  static SyncEntityType fromWire(String value) {
    return SyncEntityType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported sync entity type: $value',
      ),
    );
  }
}

enum SyncMutationOperation {
  profileUpsert(
    'profile_upsert',
    SyncEntityType.profile,
  ),
  habitUpsert(
    'habit_upsert',
    SyncEntityType.habit,
  ),
  habitArchive(
    'habit_archive',
    SyncEntityType.habit,
  ),
  habitRestore(
    'habit_restore',
    SyncEntityType.habit,
  ),
  habitDelete(
    'habit_delete',
    SyncEntityType.habit,
  ),
  habitScheduleSet(
    'habit_schedule_set',
    SyncEntityType.habitSchedule,
  ),
  habitCompletionSet(
    'habit_completion_set',
    SyncEntityType.habitDayState,
  ),
  completedTaskUpsert(
    'completed_task_upsert',
    SyncEntityType.completedTask,
  ),
  completedTaskDelete(
    'completed_task_delete',
    SyncEntityType.completedTask,
  ),
  noteUpsert(
    'note_upsert',
    SyncEntityType.note,
  ),
  noteArchive(
    'note_archive',
    SyncEntityType.note,
  ),
  noteRestore(
    'note_restore',
    SyncEntityType.note,
  ),
  noteDelete(
    'note_delete',
    SyncEntityType.note,
  ),
  noteReminderSet(
    'note_reminder_set',
    SyncEntityType.noteReminder,
  ),
  noteReviewAdd(
    'note_review_add',
    SyncEntityType.noteReview,
  ),
  focusSessionComplete(
    'focus_session_complete',
    SyncEntityType.focusSession,
  ),
  preferencesPatch(
    'preferences_patch',
    SyncEntityType.userPreferences,
  );

  final String wireName;
  final SyncEntityType entityType;

  const SyncMutationOperation(this.wireName, this.entityType);

  static SyncMutationOperation fromWire(String value) {
    return SyncMutationOperation.values.firstWhere(
      (operation) => operation.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported sync mutation operation: $value',
      ),
    );
  }
}

enum SyncServerOperation {
  upsert('upsert'),
  archive('archive'),
  restore('restore'),
  delete('delete');

  final String wireName;

  const SyncServerOperation(this.wireName);

  static SyncServerOperation fromWire(String value) {
    return SyncServerOperation.values.firstWhere(
      (operation) => operation.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported server operation: $value',
      ),
    );
  }
}

enum SyncMutationLifecycle {
  pending,
  retryScheduled,
  blockedByConflict,
  blockedByFailure,
}

enum SyncAcknowledgementStatus {
  applied('applied'),
  noOp('no_op');

  final String wireName;

  const SyncAcknowledgementStatus(this.wireName);

  static SyncAcknowledgementStatus fromWire(String value) {
    return SyncAcknowledgementStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported acknowledgement status: $value',
      ),
    );
  }
}

enum SyncConflictKind {
  remoteDelete,
  concurrentUpdate,
  malformedRemoteChange,
}

class SyncEntityKey {
  final SyncEntityType type;
  final String id;

  const SyncEntityKey({
    required this.type,
    required this.id,
  });

  String get stableKey => '${type.wireName}:$id';

  @override
  bool operator ==(Object other) {
    return other is SyncEntityKey && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => stableKey;
}

abstract final class SyncLogicalIdentity {
  static String forRecord({
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, Object?> record,
  }) {
    if (entityType == SyncEntityType.habitSchedule) {
      final habitId = record['habit_id'];
      if (habitId is String && habitId.isNotEmpty) {
        return '${entityType.wireName}:habit:$habitId';
      }
    }
    if (entityType == SyncEntityType.habitDayState) {
      final habitId = record['habit_id'];
      final localDate = record['local_date'];
      if (habitId is String &&
          habitId.isNotEmpty &&
          localDate is String &&
          localDate.isNotEmpty) {
        return '${entityType.wireName}:habit:$habitId:date:$localDate';
      }
    }
    if (entityType == SyncEntityType.noteReminder) {
      final noteId = record['note_id'];
      if (noteId is String && noteId.isNotEmpty) {
        return '${entityType.wireName}:note:$noteId';
      }
    }
    return '${entityType.wireName}:id:$entityId';
  }
}

class SyncLocalEntity {
  final SyncEntityKey key;
  final int version;
  final int serverRevision;
  final Map<String, Object?> record;

  SyncLocalEntity({
    required this.key,
    required this.version,
    required this.serverRevision,
    required Map<String, Object?> record,
  }) : record = immutableSyncJsonMap(record) {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Must be positive');
    }
    if (serverRevision < 0) {
      throw ArgumentError.value(
        serverRevision,
        'serverRevision',
        'Cannot be negative',
      );
    }
  }

  bool get isDeleted => record['deleted_at'] != null;

  String get logicalIdentity => SyncLogicalIdentity.forRecord(
        entityType: key.type,
        entityId: key.id,
        record: record,
      );

  SyncLocalEntity copyWith({
    SyncEntityKey? key,
    int? version,
    int? serverRevision,
    Map<String, Object?>? record,
  }) {
    return SyncLocalEntity(
      key: key ?? this.key,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      record: record ?? this.record,
    );
  }

  Map<String, Object?> toJson() => {
        'entity_type': key.type.wireName,
        'entity_id': key.id,
        'version': version,
        'server_revision': serverRevision,
        'record': record,
      };
}

class SyncMutation {
  final String mutationId;
  final String ownerId;
  final String deviceId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncMutationOperation operation;
  final Map<String, Object?> payload;
  final int? baseVersion;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final SyncMutationLifecycle lifecycle;

  SyncMutation({
    required this.mutationId,
    required this.ownerId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required DateTime createdAt,
    Map<String, Object?> payload = const {},
    this.baseVersion,
    this.attemptCount = 0,
    DateTime? nextAttemptAt,
    this.lifecycle = SyncMutationLifecycle.pending,
  })  : payload = immutableSyncJsonMap(payload),
        createdAt = createdAt.toUtc(),
        nextAttemptAt = nextAttemptAt?.toUtc() {
    if (mutationId.isEmpty ||
        ownerId.isEmpty ||
        deviceId.isEmpty ||
        entityId.isEmpty) {
      throw ArgumentError('Sync mutation identifiers cannot be empty');
    }
    if (operation.entityType != entityType) {
      throw ArgumentError(
        '${operation.wireName} targets ${operation.entityType.wireName}, '
        'not ${entityType.wireName}',
      );
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(
        attemptCount,
        'attemptCount',
        'Cannot be negative',
      );
    }
  }

  SyncEntityKey get key => SyncEntityKey(type: entityType, id: entityId);

  String get logicalIdentity => SyncLogicalIdentity.forRecord(
        entityType: entityType,
        entityId: entityId,
        record: payload,
      );

  bool get canSend =>
      lifecycle == SyncMutationLifecycle.pending ||
      lifecycle == SyncMutationLifecycle.retryScheduled;

  SyncMutation copyWith({
    String? mutationId,
    String? ownerId,
    String? deviceId,
    SyncEntityType? entityType,
    String? entityId,
    SyncMutationOperation? operation,
    Map<String, Object?>? payload,
    Object? baseVersion = _syncUnset,
    DateTime? createdAt,
    int? attemptCount,
    Object? nextAttemptAt = _syncUnset,
    SyncMutationLifecycle? lifecycle,
  }) {
    return SyncMutation(
      mutationId: mutationId ?? this.mutationId,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      baseVersion: identical(baseVersion, _syncUnset)
          ? this.baseVersion
          : baseVersion as int?,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: identical(nextAttemptAt, _syncUnset)
          ? this.nextAttemptAt
          : nextAttemptAt as DateTime?,
      lifecycle: lifecycle ?? this.lifecycle,
    );
  }

  Map<String, Object?> toRpcParameters({int schemaVersion = 1}) => {
        'p_mutation_id': mutationId,
        'p_operation': operation.wireName,
        'p_entity_id': entityId,
        'p_base_version': baseVersion,
        'p_payload': payload,
        'p_schema_version': schemaVersion,
      };

  Map<String, Object?> toJson() => {
        'mutation_id': mutationId,
        'owner_id': ownerId,
        'device_id': deviceId,
        'entity_type': entityType.wireName,
        'entity_id': entityId,
        'operation': operation.wireName,
        'payload': payload,
        'base_version': baseVersion,
        'created_at': createdAt.toIso8601String(),
        'attempt_count': attemptCount,
        'next_attempt_at': nextAttemptAt?.toIso8601String(),
        'lifecycle': lifecycle.name,
      };
}

class SyncRemoteChange {
  final int serverRevision;
  final SyncEntityType entityType;
  final String entityId;
  final SyncServerOperation operation;
  final int entityVersion;
  final Map<String, Object?> record;

  SyncRemoteChange({
    required this.serverRevision,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.entityVersion,
    required Map<String, Object?> record,
  }) : record = immutableSyncJsonMap(record) {
    if (serverRevision < 1 || entityVersion < 1) {
      throw ArgumentError('Remote revisions and versions must be positive');
    }
  }

  factory SyncRemoteChange.fromJson(Map<String, Object?> json) {
    return SyncRemoteChange(
      serverRevision: json['server_revision']! as int,
      entityType: SyncEntityType.fromWire(json['entity_type']! as String),
      entityId: json['entity_id']! as String,
      operation: SyncServerOperation.fromWire(json['operation']! as String),
      entityVersion: json['entity_version']! as int,
      record: (json['record_data']! as Map).cast<String, Object?>(),
    );
  }

  SyncEntityKey get key => SyncEntityKey(type: entityType, id: entityId);

  String get logicalIdentity => SyncLogicalIdentity.forRecord(
        entityType: entityType,
        entityId: entityId,
        record: record,
      );

  SyncLocalEntity toLocalEntity() => SyncLocalEntity(
        key: key,
        version: entityVersion,
        serverRevision: serverRevision,
        record: record,
      );
}

class SyncMutationAcknowledgement {
  final String mutationId;
  final SyncAcknowledgementStatus status;
  final SyncEntityType entityType;
  final String entityId;
  final int version;
  final int serverRevision;
  final Map<String, Object?> record;

  SyncMutationAcknowledgement({
    required this.mutationId,
    required this.status,
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.serverRevision,
    required Map<String, Object?> record,
  }) : record = immutableSyncJsonMap(record) {
    if (version < 1 || serverRevision < 1) {
      throw ArgumentError('Acknowledged versions must be positive');
    }
  }

  factory SyncMutationAcknowledgement.fromJson(
    Map<String, Object?> json,
  ) {
    return SyncMutationAcknowledgement(
      mutationId: json['mutation_id']! as String,
      status: SyncAcknowledgementStatus.fromWire(
        json['status']! as String,
      ),
      entityType: SyncEntityType.fromWire(json['entity_type']! as String),
      entityId: json['entity_id']! as String,
      version: json['version']! as int,
      serverRevision: json['server_revision']! as int,
      record: (json['record']! as Map).cast<String, Object?>(),
    );
  }

  SyncEntityKey get key => SyncEntityKey(type: entityType, id: entityId);

  String get logicalIdentity => SyncLogicalIdentity.forRecord(
        entityType: entityType,
        entityId: entityId,
        record: record,
      );

  SyncLocalEntity toLocalEntity() => SyncLocalEntity(
        key: key,
        version: version,
        serverRevision: serverRevision,
        record: record,
      );
}

class SyncConflict {
  final String id;
  final SyncConflictKind kind;
  final SyncEntityKey entityKey;
  final String? mutationId;
  final Map<String, Object?> localRecord;
  final Map<String, Object?> remoteRecord;

  SyncConflict({
    required this.id,
    required this.kind,
    required this.entityKey,
    required Map<String, Object?> localRecord,
    required Map<String, Object?> remoteRecord,
    this.mutationId,
  })  : localRecord = immutableSyncJsonMap(localRecord),
        remoteRecord = immutableSyncJsonMap(remoteRecord);

  factory SyncConflict.remoteDelete({
    required SyncMutation mutation,
    required SyncRemoteChange change,
    required Map<String, Object?> localRecord,
  }) {
    return SyncConflict(
      id: 'remote_delete:${change.logicalIdentity}:${mutation.mutationId}',
      kind: SyncConflictKind.remoteDelete,
      entityKey: change.key,
      mutationId: mutation.mutationId,
      localRecord: localRecord,
      remoteRecord: change.record,
    );
  }

  factory SyncConflict.concurrentUpdate({
    required SyncMutation mutation,
    required SyncRemoteChange change,
    required Map<String, Object?> localRecord,
  }) {
    return SyncConflict(
      id: 'concurrent_update:${change.logicalIdentity}:${mutation.mutationId}',
      kind: SyncConflictKind.concurrentUpdate,
      entityKey: change.key,
      mutationId: mutation.mutationId,
      localRecord: localRecord,
      remoteRecord: change.record,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'entity_type': entityKey.type.wireName,
        'entity_id': entityKey.id,
        'mutation_id': mutationId,
        'local_record': localRecord,
        'remote_record': remoteRecord,
      };
}

class SyncSnapshot {
  final Map<SyncEntityKey, SyncLocalEntity> entities;
  final List<SyncMutation> outbox;
  final List<SyncConflict> conflicts;
  final int cursor;

  SyncSnapshot({
    Map<SyncEntityKey, SyncLocalEntity> entities = const {},
    List<SyncMutation> outbox = const [],
    List<SyncConflict> conflicts = const [],
    this.cursor = 0,
  })  : entities = Map.unmodifiable(entities),
        outbox = List.unmodifiable(
          List<SyncMutation>.of(outbox)..sort(_compareSyncMutations),
        ),
        conflicts = List.unmodifiable(
          List<SyncConflict>.of(conflicts)
            ..sort((left, right) => left.id.compareTo(right.id)),
        ) {
    if (cursor < 0) {
      throw ArgumentError.value(cursor, 'cursor', 'Cannot be negative');
    }
    for (final entry in entities.entries) {
      if (entry.key != entry.value.key) {
        throw ArgumentError(
          'Entity map key ${entry.key} does not match ${entry.value.key}',
        );
      }
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

  SyncSnapshot copyWith({
    Map<SyncEntityKey, SyncLocalEntity>? entities,
    List<SyncMutation>? outbox,
    List<SyncConflict>? conflicts,
    int? cursor,
  }) {
    return SyncSnapshot(
      entities: entities ?? this.entities,
      outbox: outbox ?? this.outbox,
      conflicts: conflicts ?? this.conflicts,
      cursor: cursor ?? this.cursor,
    );
  }

  Map<String, Object?> toDiagnosticJson() => {
        'cursor': cursor,
        'entities': _sortedEntitiesForDiagnostics(entities),
        'outbox': outbox.map((mutation) => mutation.toJson()).toList(),
        'conflicts': conflicts.map((conflict) => conflict.toJson()).toList(),
      };
}

List<Map<String, Object?>> _sortedEntitiesForDiagnostics(
  Map<SyncEntityKey, SyncLocalEntity> entities,
) {
  final sorted = entities.values.toList()
    ..sort(
      (left, right) => left.key.stableKey.compareTo(right.key.stableKey),
    );
  return sorted.map((entity) => entity.toJson()).toList(growable: false);
}

Map<String, Object?> immutableSyncJsonMap(
  Map<String, Object?> source,
) {
  return Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: _immutableSyncJsonValue(entry.value),
  });
}

Object? _immutableSyncJsonValue(Object? value) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite JSON number');
    }
    return value;
  }
  if (value is Map) {
    return immutableSyncJsonMap(value.cast<String, Object?>());
  }
  if (value is List) {
    return List.unmodifiable(
      value.map(_immutableSyncJsonValue),
    );
  }
  throw ArgumentError.value(
    value,
    'value',
    'Unsupported sync JSON value',
  );
}

int _compareSyncMutations(SyncMutation left, SyncMutation right) {
  final byCreation = left.createdAt.compareTo(right.createdAt);
  if (byCreation != 0) return byCreation;
  return left.mutationId.compareTo(right.mutationId);
}
