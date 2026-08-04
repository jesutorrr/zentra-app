import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/sync/sync.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

  SyncMachineEvent event(
    SyncEventType type, {
    int pendingCount = 0,
    int conflictCount = 0,
    String? message,
  }) {
    return SyncMachineEvent(
      type: type,
      occurredAt: now,
      pendingCount: pendingCount,
      conflictCount: conflictCount,
      message: message,
    );
  }

  test('runs the full pull, rebase, push and second-pull cycle', () {
    var state = SyncMachineState.localOnly();
    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.sessionAvailable, pendingCount: 1),
    );
    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.syncRequested, pendingCount: 1),
    );
    expect(state.phase, SyncPhase.pulling);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.firstPullCompleted, pendingCount: 1),
    );
    expect(state.phase, SyncPhase.reconciling);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.reconciliationCompleted, pendingCount: 1),
    );
    expect(state.phase, SyncPhase.pushing);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.pushCompleted),
    );
    expect(state.phase, SyncPhase.secondPull);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.secondPullCompleted),
    );
    expect(state.phase, SyncPhase.synced);
    expect(state.lastSuccessfulSyncAt, now);
    expect(state.pendingCount, 0);
  });

  test('skips push when reconciliation has no pending mutations', () {
    var state = SyncMachineState(phase: SyncPhase.pulling);
    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.firstPullCompleted),
    );
    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.reconciliationCompleted),
    );

    expect(state.phase, SyncPhase.secondPull);
  });

  test('recovers from offline and expired authentication states', () {
    var state = SyncMachineState(
      phase: SyncPhase.pushing,
      pendingCount: 2,
    );
    state = SyncStateMachine.reduce(
      state,
      event(
        SyncEventType.networkUnavailable,
        pendingCount: 2,
      ),
    );
    expect(state.phase, SyncPhase.offlineWithPending);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.syncRequested, pendingCount: 2),
    );
    expect(state.phase, SyncPhase.pulling);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.authExpired, pendingCount: 2),
    );
    expect(state.phase, SyncPhase.authRequired);

    state = SyncStateMachine.reduce(
      state,
      event(SyncEventType.sessionAvailable, pendingCount: 2),
    );
    expect(state.phase, SyncPhase.idle);
    expect(state.message, isNull);
  });

  test('exposes the stable migration-required experience state', () {
    final state = SyncStateMachine.reduce(
      SyncMachineState.localOnly(),
      event(SyncEventType.migrationRequired),
    );

    expect(state.phase, SyncPhase.migrationRequired);
    expect(
      state.experienceState,
      SyncExperienceState.migrationRequired,
    );
    expect(state.message, 'migration_required');
  });

  test('enters conflict and returns to idle after resolution', () {
    var state = SyncMachineState(phase: SyncPhase.reconciling);
    state = SyncStateMachine.reduce(
      state,
      event(
        SyncEventType.reconciliationCompleted,
        pendingCount: 1,
        conflictCount: 1,
      ),
    );
    expect(state.phase, SyncPhase.conflict);

    state = SyncStateMachine.reduce(
      state,
      event(
        SyncEventType.conflictsResolved,
        pendingCount: 1,
      ),
    );
    expect(state.phase, SyncPhase.idle);
    expect(state.conflictCount, 0);
  });

  test('conflict resolution requires a fresh sync even without pending work',
      () {
    final state = SyncStateMachine.reduce(
      SyncMachineState(
        phase: SyncPhase.conflict,
        conflictCount: 1,
      ),
      event(SyncEventType.conflictsResolved),
    );

    expect(state.phase, SyncPhase.idle);
    expect(state.lastSuccessfulSyncAt, isNull);
  });

  test('rejects impossible workflow transitions', () {
    expect(
      () => SyncStateMachine.reduce(
        SyncMachineState.localOnly(),
        event(SyncEventType.pushCompleted),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
