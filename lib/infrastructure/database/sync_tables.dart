import 'package:drift/drift.dart';

@DataClassName('SyncOutboxRow')
@TableIndex(
  name: 'sync_outbox_owner_lifecycle_attempt_idx',
  columns: {#ownerId, #lifecycle, #nextAttemptAt, #createdAt},
)
class SyncOutboxEntries extends Table {
  TextColumn get mutationId => text()();
  TextColumn get ownerId => text()();
  TextColumn get deviceId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  IntColumn get baseVersion => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lifecycle => text()();

  @override
  Set<Column<Object>> get primaryKey => {mutationId};

  @override
  String get tableName => 'sync_outbox';
}

@DataClassName('SyncStateRow')
class SyncStateEntries extends Table {
  TextColumn get ownerId => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};

  @override
  String get tableName => 'sync_state';
}

@DataClassName('SyncConflictRow')
@TableIndex(
  name: 'sync_conflict_owner_created_idx',
  columns: {#ownerId, #createdAt},
)
class SyncConflictEntries extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get mutationId => text().nullable()();
  TextColumn get localRecordJson => text()();
  TextColumn get remoteRecordJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'sync_conflicts';
}

@DataClassName('LocalOwnerLinkRow')
@TableIndex(
  name: 'local_owner_remote_user_idx',
  columns: {#remoteUserId},
  unique: true,
)
class LocalOwnerLinkEntries extends Table {
  TextColumn get localOwnerId => text()();
  TextColumn get remoteUserId => text().nullable()();
  TextColumn get state => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localOwnerId};

  @override
  String get tableName => 'local_owner_links';
}

@DataClassName('LocalNotificationBindingRow')
@TableIndex(
  name: 'local_notification_owner_device_idx',
  columns: {#ownerId, #deviceId},
)
class LocalNotificationBindingEntries extends Table {
  TextColumn get logicalId => text()();
  TextColumn get ownerId => text()();
  TextColumn get deviceId => text()();
  IntColumn get notificationId => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {logicalId, ownerId, deviceId};

  @override
  String get tableName => 'local_notification_bindings';
}

@DataClassName('LocalMigrationStateRow')
@TableIndex(
  name: 'local_migration_owner_status_idx',
  columns: {#ownerId, #status},
)
class LocalMigrationStateEntries extends Table {
  TextColumn get ownerId => text()();
  TextColumn get migrationName => text()();
  TextColumn get status => text()();
  TextColumn get sourceChecksum => text().nullable()();
  TextColumn get targetChecksum => text().nullable()();
  TextColumn get sourceCountsJson => text().nullable()();
  TextColumn get targetCountsJson => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get failureReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, migrationName};

  @override
  String get tableName => 'local_migration_state';
}
