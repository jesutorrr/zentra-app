import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/sync_coordinator.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/sync/sync.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';
import 'package:zentra/infrastructure/drift_sync_workspace.dart';

void main() {
  const ownerId = 'a0000000-0000-4000-8000-000000000001';
  const habitId = 'a0000000-0000-4000-8000-000000000002';
  final now = DateTime.utc(2026, 7, 27, 12);

  late ZentraDatabase database;
  late DriftCoreRepository core;
  late DriftSyncWorkspace workspace;
  late _MemorySyncTransport transport;

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
    core = DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: 'device-1',
      clock: () => now,
    );
    workspace = DriftSyncWorkspace(database: database, ownerId: ownerId);
    transport = _MemorySyncTransport(ownerId);
  });

  tearDown(() => database.close());

  Habit habit() => Habit(
        id: habitId,
        title: 'Caminar',
        category: Category.movimiento,
        frequency: Frequency.weekdays(),
        createdAt: now,
      );

  test('pushes outbox, performs second pull and survives coordinator restart',
      () async {
    await core.saveHabit(habit());
    final first = SyncCoordinator(
      ownerId: ownerId,
      workspace: workspace,
      transport: transport,
      clock: () => now,
    );

    final result = await first.syncNow();

    expect(result.state.experienceState, SyncExperienceState.synced);
    expect(result.pushedMutations, 2);
    expect(result.pulledChanges, 2);
    final persisted = await workspace.loadSnapshot();
    expect(persisted.outbox, isEmpty);
    expect(persisted.cursor, 2);
    expect(
      persisted.entities.values.every((entity) => entity.serverRevision > 0),
      isTrue,
    );

    final restarted = SyncCoordinator(
      ownerId: ownerId,
      workspace: workspace,
      transport: transport,
      clock: () => now.add(const Duration(minutes: 1)),
    );
    final afterRestart = await restarted.syncNow();
    expect(afterRestart.state.experienceState, SyncExperienceState.synced);
    expect(afterRestart.pushedMutations, 0);
    expect((await workspace.loadSnapshot()).cursor, 2);
  });

  test('offline pull preserves outbox and a later run recovers', () async {
    await core.saveHabit(habit());
    transport.isOffline = true;
    final coordinator = SyncCoordinator(
      ownerId: ownerId,
      workspace: workspace,
      transport: transport,
      clock: () => now,
    );

    final offline = await coordinator.syncNow();
    expect(
      offline.state.experienceState,
      SyncExperienceState.offlineWithPending,
    );
    expect((await workspace.loadSnapshot()).outbox, hasLength(2));

    transport.isOffline = false;
    final recovered = await coordinator.syncNow();
    expect(recovered.state.experienceState, SyncExperienceState.synced);
    expect((await workspace.loadSnapshot()).outbox, isEmpty);
  });

  test('Realtime signals coalesce into a durable incremental sync', () async {
    final remoteChanges = StreamController<void>.broadcast();
    final coordinator = SyncCoordinator(
      ownerId: ownerId,
      workspace: workspace,
      transport: transport,
      clock: () => now,
      remoteChanges: remoteChanges.stream,
      remoteWakeDebounce: Duration.zero,
    );

    remoteChanges
      ..add(null)
      ..add(null)
      ..add(null);
    await pumpEventQueue(times: 20);

    expect(transport.pullCalls, 2);
    expect(coordinator.state.experienceState, SyncExperienceState.synced);

    await coordinator.dispose();
    transport.pullCalls = 0;
    remoteChanges.add(null);
    await pumpEventQueue(times: 5);
    expect(transport.pullCalls, 0);
    await remoteChanges.close();
  });

  test('dispose waits for an active sync before its database may close',
      () async {
    final gatedTransport = _GatedSyncTransport(ownerId);
    final coordinator = SyncCoordinator(
      ownerId: ownerId,
      workspace: workspace,
      transport: gatedTransport,
      clock: () => now,
    );

    final run = coordinator.syncNow();
    await gatedTransport.pullStarted.future;
    var disposalCompleted = false;
    final disposal = coordinator.dispose().then((_) {
      disposalCompleted = true;
    });
    await pumpEventQueue(times: 5);

    expect(disposalCompleted, isFalse);

    gatedTransport.releasePull.complete();
    await run;
    await disposal;
    expect(disposalCompleted, isTrue);

    final pullsAfterDispose = gatedTransport.pullCalls;
    final ignored = await coordinator.syncNow();
    expect(ignored.pulledChanges, 0);
    expect(gatedTransport.pullCalls, pullsAfterDispose);
  });
}

class _GatedSyncTransport extends _MemorySyncTransport {
  final Completer<void> pullStarted = Completer<void>();
  final Completer<void> releasePull = Completer<void>();

  _GatedSyncTransport(super.authenticatedUserId);

  @override
  Future<SyncPullPage> pull({
    required int afterRevision,
    int limit = 200,
  }) async {
    if (!pullStarted.isCompleted) pullStarted.complete();
    await releasePull.future;
    return super.pull(afterRevision: afterRevision, limit: limit);
  }
}

class _MemorySyncTransport implements SyncTransport {
  @override
  final String authenticatedUserId;

  bool isOffline = false;
  int pullCalls = 0;
  int _revision = 0;
  final List<SyncRemoteChange> _changes = [];
  final Map<String, SyncMutationAcknowledgement> _processed = {};
  final Map<String, int> _versions = {};

  _MemorySyncTransport(this.authenticatedUserId);

  @override
  Future<SyncPullPage> pull({
    required int afterRevision,
    int limit = 200,
  }) async {
    pullCalls++;
    if (isOffline) {
      throw const SyncTransportException(
        failure: SyncFailure(
          kind: SyncFailureKind.offline,
          code: 'offline',
        ),
        message: 'offline',
      );
    }
    final changes = _changes
        .where((change) => change.serverRevision > afterRevision)
        .take(limit)
        .toList();
    return SyncPullPage(changes: changes, requestedLimit: limit);
  }

  @override
  Future<SyncMutationAcknowledgement> push(SyncMutation mutation) async {
    final previous = _processed[mutation.mutationId];
    if (previous != null) return previous;

    final identity = mutation.logicalIdentity;
    final version = (_versions[identity] ?? 0) + 1;
    _versions[identity] = version;
    final revision = ++_revision;
    final record = switch (mutation.operation) {
      SyncMutationOperation.habitUpsert => <String, Object?>{
          'id': mutation.entityId,
          'title': mutation.payload['title'],
          'category': mutation.payload['category'],
          'is_one_time': mutation.payload['is_one_time'] ?? false,
          'is_archived': false,
          'created_at': DateTime.utc(2026, 7, 27).toIso8601String(),
          'updated_at': DateTime.utc(2026, 7, 27).toIso8601String(),
          'deleted_at': null,
        },
      SyncMutationOperation.habitScheduleSet => <String, Object?>{
          'id': mutation.entityId,
          ...mutation.payload,
          'created_at': DateTime.utc(2026, 7, 27).toIso8601String(),
          'updated_at': DateTime.utc(2026, 7, 27).toIso8601String(),
          'deleted_at': null,
        },
      _ => throw UnsupportedError(mutation.operation.wireName),
    };
    final acknowledgement = SyncMutationAcknowledgement(
      mutationId: mutation.mutationId,
      status: SyncAcknowledgementStatus.applied,
      entityType: mutation.entityType,
      entityId: mutation.entityId,
      version: version,
      serverRevision: revision,
      record: record,
    );
    _processed[mutation.mutationId] = acknowledgement;
    _changes.add(
      SyncRemoteChange(
        serverRevision: revision,
        entityType: mutation.entityType,
        entityId: mutation.entityId,
        operation: SyncServerOperation.upsert,
        entityVersion: version,
        record: record,
      ),
    );
    return acknowledgement;
  }
}
