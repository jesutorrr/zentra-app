import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/sync/sync.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_sync_repository.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);
  late ZentraDatabase database;
  late DriftSyncRepository repository;

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
    repository = DriftSyncRepository(
      database,
      clock: () => now,
    )..setCurrentOwner('uri');
  });

  tearDown(() => database.close());

  SyncMutation mutation({
    String id = 'mutation-1',
    String ownerId = 'uri',
    SyncMutationLifecycle lifecycle = SyncMutationLifecycle.pending,
  }) {
    return SyncMutation(
      mutationId: id,
      ownerId: ownerId,
      deviceId: 'mobile-1',
      entityType: SyncEntityType.habit,
      entityId: 'habit-1',
      operation: SyncMutationOperation.habitUpsert,
      payload: const {'title': 'Caminar'},
      baseVersion: 2,
      createdAt: now,
      attemptCount: lifecycle == SyncMutationLifecycle.retryScheduled ? 1 : 0,
      nextAttemptAt: lifecycle == SyncMutationLifecycle.retryScheduled
          ? now.add(const Duration(seconds: 5))
          : null,
      lifecycle: lifecycle,
    );
  }

  SyncConflict conflict() {
    return SyncConflict(
      id: 'conflict-1',
      kind: SyncConflictKind.concurrentUpdate,
      entityKey: const SyncEntityKey(
        type: SyncEntityType.note,
        id: 'note-1',
      ),
      mutationId: 'note-mutation-1',
      localRecord: const {'body': 'Móvil'},
      remoteRecord: const {'body': 'Web'},
    );
  }

  test('requires an active owner', () async {
    repository.setCurrentOwner(null);

    await expectLater(
      repository.loadQueueState(),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.enqueue(mutation()),
      throwsA(isA<StateError>()),
    );
  });

  test('forOwner locks identity and isolates sync queues', () async {
    final ownerA = DriftSyncRepository.forOwner(
      database,
      ownerId: 'owner-a',
      clock: () => now,
    );
    final ownerB = DriftSyncRepository.forOwner(
      database,
      ownerId: 'owner-b',
      clock: () => now,
    );

    expect(ownerA.currentOwnerId, 'owner-a');
    expect(() => ownerA.setCurrentOwner('owner-a'), returnsNormally);
    expect(
      () => ownerA.setCurrentOwner('owner-b'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => ownerA.setCurrentOwner(null),
      throwsA(isA<StateError>()),
    );
    expect(ownerA.currentOwnerId, 'owner-a');

    await ownerA.replaceQueueState(
      SyncQueueState(
        cursor: 1,
        outbox: [mutation(id: 'mutation-a', ownerId: 'owner-a')],
      ),
    );
    await ownerB.replaceQueueState(
      SyncQueueState(
        cursor: 2,
        outbox: [mutation(id: 'mutation-b', ownerId: 'owner-b')],
      ),
    );

    final stateA = await ownerA.loadQueueState();
    final stateB = await ownerB.loadQueueState();
    expect(stateA.cursor, 1);
    expect(stateA.outbox.single.mutationId, 'mutation-a');
    expect(stateB.cursor, 2);
    expect(stateB.outbox.single.mutationId, 'mutation-b');
  });

  test('forOwner rejects a blank identity', () {
    expect(
      () => DriftSyncRepository.forOwner(
        database,
        ownerId: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('queue state rejects duplicate durable IDs', () {
    expect(
      () => SyncQueueState(
        cursor: 0,
        outbox: [mutation(), mutation()],
      ),
      throwsArgumentError,
    );
    expect(
      () => SyncQueueState(
        cursor: 0,
        conflicts: [conflict(), conflict()],
      ),
      throwsArgumentError,
    );
  });

  test('round-trips outbox, conflicts, cursor and sync timestamps', () async {
    final state = SyncQueueState(
      cursor: 7,
      outbox: [
        mutation(
          lifecycle: SyncMutationLifecycle.retryScheduled,
        ),
      ],
      conflicts: [conflict()],
      lastSuccessfulSyncAt: now.subtract(const Duration(minutes: 1)),
      lastAttemptAt: now,
    );
    await repository.replaceQueueState(state);
    final restored = await repository.loadQueueState();

    expect(restored.cursor, 7);
    expect(restored.outbox.single.toJson(), state.outbox.single.toJson());
    expect(
      restored.conflicts.single.toJson(),
      state.conflicts.single.toJson(),
    );
    expect(restored.lastSuccessfulSyncAt, state.lastSuccessfulSyncAt);
    expect(restored.lastAttemptAt, state.lastAttemptAt);
  });

  test('persists reducer metadata without silently owning entity storage',
      () async {
    final reducerResult = SyncSnapshot(
      cursor: 4,
      outbox: [mutation()],
      conflicts: [conflict()],
      entities: {
        const SyncEntityKey(
          type: SyncEntityType.habit,
          id: 'habit-1',
        ): SyncLocalEntity(
          key: const SyncEntityKey(
            type: SyncEntityType.habit,
            id: 'habit-1',
          ),
          version: 2,
          serverRevision: 4,
          record: const {'title': 'Caminar'},
        ),
      },
    );

    await repository.saveReducerMetadata(
      reducerResult,
      lastSuccessfulSyncAt: now,
    );
    final restored = await repository.loadQueueState();

    expect(restored.cursor, 4);
    expect(restored.outbox.single.mutationId, 'mutation-1');
    expect(restored.conflicts.single.id, 'conflict-1');
    expect(restored.toReducerSnapshot().entities, isEmpty);
  });

  test('queue replacement is atomic when a foreign mutation ID collides',
      () async {
    await repository.replaceQueueState(
      SyncQueueState(
        cursor: 1,
        outbox: [mutation()],
      ),
    );

    repository.setCurrentOwner('other');
    await expectLater(
      repository.replaceQueueState(
        SyncQueueState(
          cursor: 9,
          outbox: [
            mutation(ownerId: 'other'),
          ],
        ),
      ),
      throwsA(anything),
    );

    repository.setCurrentOwner('uri');
    final original = await repository.loadQueueState();
    expect(original.cursor, 1);
    expect(original.outbox.single.ownerId, 'uri');
  });

  test('owner links and migration evidence are owner scoped', () async {
    await repository.linkOwner(
      localOwnerId: 'uri',
      remoteUserId: 'remote-uri',
    );
    await repository.recordMigration(
      LocalMigrationRecord(
        ownerId: 'uri',
        migrationName: 'shared_preferences_to_drift_v1',
        status: LocalMigrationStatus.completed,
        sourceChecksum: 'abc',
        targetChecksum: 'abc',
        sourceCounts: const {'habits': 2},
        targetCounts: const {'habits': 2},
        startedAt: now.subtract(const Duration(seconds: 1)),
        completedAt: now,
      ),
    );

    expect(await repository.getLinkedRemoteUserId(), 'remote-uri');
    final migration = await repository.getMigration(
      'shared_preferences_to_drift_v1',
    );
    expect(migration?.status, LocalMigrationStatus.completed);
    expect(migration?.sourceCounts, {'habits': 2});

    repository.setCurrentOwner('other');
    expect(await repository.getLinkedRemoteUserId(), isNull);
    expect(
      await repository.getMigration('shared_preferences_to_drift_v1'),
      isNull,
    );
  });

  test('deleteOwnerMetadata preserves another owner queue', () async {
    await repository.replaceQueueState(
      SyncQueueState(cursor: 1, outbox: [mutation()]),
    );
    repository.setCurrentOwner('other');
    await repository.replaceQueueState(
      SyncQueueState(
        cursor: 2,
        outbox: [mutation(id: 'mutation-other', ownerId: 'other')],
      ),
    );

    repository.setCurrentOwner('uri');
    await repository.deleteOwnerMetadata();
    expect((await repository.loadQueueState()).outbox, isEmpty);

    repository.setCurrentOwner('other');
    expect(
      (await repository.loadQueueState()).outbox.single.mutationId,
      'mutation-other',
    );
  });
}
