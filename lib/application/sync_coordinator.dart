import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sync/sync.dart';
import '../infrastructure/drift_sync_workspace.dart';

typedef SyncCoordinatorFactory = SyncCoordinator Function(String ownerId);

final syncCoordinatorFactoryProvider =
    Provider<SyncCoordinatorFactory?>((ref) => null);

final syncMachineStateProvider =
    StreamProvider.autoDispose.family<SyncMachineState, String>((ref, ownerId) {
  final factory = ref.watch(syncCoordinatorFactoryProvider);
  if (factory == null) {
    return Stream.value(SyncMachineState.localOnly());
  }
  final coordinator = factory(ownerId);
  return (() async* {
    yield coordinator.state;
    yield* coordinator.states;
  })();
});

class SyncRunResult {
  final SyncMachineState state;
  final int pulledChanges;
  final int pushedMutations;

  const SyncRunResult({
    required this.state,
    required this.pulledChanges,
    required this.pushedMutations,
  });
}

class SyncCoordinator {
  final String ownerId;
  final DriftSyncWorkspace _workspace;
  final SyncTransport _transport;
  final SyncRetryPolicy _retryPolicy;
  final DateTime Function() _clock;
  final Duration _remoteWakeDebounce;
  final StreamController<SyncMachineState> _stateController =
      StreamController.broadcast();

  SyncMachineState _state = SyncMachineState.localOnly();
  Future<SyncRunResult>? _activeRun;
  StreamSubscription<void>? _remoteWakeSubscription;
  Timer? _debounce;
  bool _runAgain = false;
  bool _disposed = false;

  SyncCoordinator({
    required this.ownerId,
    required DriftSyncWorkspace workspace,
    required SyncTransport transport,
    SyncRetryPolicy retryPolicy = const SyncRetryPolicy(),
    DateTime Function()? clock,
    Stream<void>? remoteChanges,
    Duration remoteWakeDebounce = const Duration(milliseconds: 350),
  })  : _workspace = workspace,
        _transport = transport,
        _retryPolicy = retryPolicy,
        _clock = clock ?? DateTime.now,
        _remoteWakeDebounce = remoteWakeDebounce {
    _remoteWakeSubscription = remoteChanges?.listen(
      (_) => scheduleSync(debounce: _remoteWakeDebounce),
      // Realtime is only an accelerator. App resume, manual sync and the
      // durable cursor recover changes when the socket is unavailable.
      onError: (_) {},
    );
  }

  SyncMachineState get state => _state;

  Stream<SyncMachineState> get states => _stateController.stream;

  void scheduleSync({
    Duration debounce = const Duration(milliseconds: 350),
  }) {
    if (_disposed) return;
    if (_activeRun != null) {
      _runAgain = true;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      unawaited(syncNow());
    });
  }

  Future<SyncRunResult> syncNow() {
    if (_disposed) {
      return Future.value(
        SyncRunResult(
          state: _state,
          pulledChanges: 0,
          pushedMutations: 0,
        ),
      );
    }
    final active = _activeRun;
    if (active != null) return active;
    final run = _run();
    _activeRun = run;
    return run.whenComplete(() {
      if (identical(_activeRun, run)) _activeRun = null;
      if (_runAgain && !_disposed) {
        _runAgain = false;
        scheduleSync(debounce: Duration.zero);
      }
    });
  }

  Future<SyncRunResult> fullResync() async {
    final current = await _workspace.loadSnapshot();
    final reset = SyncSnapshot(
      cursor: 0,
      outbox: current.outbox,
      conflicts: current.conflicts,
      entities: {
        for (final entry in current.entities.entries)
          entry.key: entry.value.copyWith(serverRevision: 0),
      },
    );
    await _workspace.commitSnapshot(
      reset,
      lastAttemptAt: _clock().toUtc(),
    );
    return syncNow();
  }

  Future<SyncRunResult> _run() async {
    var pulled = 0;
    var pushed = 0;
    var snapshot = await _workspace.loadSnapshot();
    final now = _clock().toUtc();
    final remoteUserId = _transport.authenticatedUserId;

    if (remoteUserId == null) {
      _emit(
        _event(
          SyncEventType.authExpired,
          snapshot,
          message: 'authentication_required',
        ),
      );
      return SyncRunResult(
        state: _state,
        pulledChanges: pulled,
        pushedMutations: pushed,
      );
    }
    if (remoteUserId != ownerId) {
      _emit(
        _event(
          SyncEventType.blockingFailure,
          snapshot,
          message: 'authenticated_owner_mismatch',
        ),
      );
      return SyncRunResult(
        state: _state,
        pulledChanges: pulled,
        pushedMutations: pushed,
      );
    }

    final queue = await _workspace.loadQueueState();
    _state = SyncMachineState(
      phase: SyncPhase.idle,
      pendingCount: snapshot.outbox.length,
      conflictCount: snapshot.conflicts.length,
      lastSuccessfulSyncAt: queue.lastSuccessfulSyncAt,
    );
    _publish();
    _emit(_event(SyncEventType.syncRequested, snapshot));

    try {
      final first = await _pullAll(snapshot);
      snapshot = first.snapshot;
      pulled += first.count;
      _emit(_event(SyncEventType.firstPullCompleted, snapshot));
      _emit(_event(SyncEventType.reconciliationCompleted, snapshot));

      if (snapshot.conflicts.isNotEmpty) {
        await _workspace.commitSnapshot(snapshot, lastAttemptAt: now);
        return SyncRunResult(
          state: _state,
          pulledChanges: pulled,
          pushedMutations: pushed,
        );
      }

      if (_state.phase == SyncPhase.pushing) {
        var operations = 0;
        while (operations < 500) {
          final ready = SyncPushPlanner.readyMutations(
            snapshot: snapshot,
            now: _clock(),
          );
          if (ready.isEmpty) break;
          for (final mutation in ready) {
            try {
              final acknowledgement = await _transport.push(mutation);
              snapshot = SyncRoundReducer.applyAcknowledgements(
                snapshot,
                [acknowledgement],
              );
              pushed++;
              operations++;
              await _workspace.commitSnapshot(
                snapshot,
                lastAttemptAt: now,
              );
            } on SyncTransportException catch (error) {
              final decision = _retryPolicy.decide(
                mutation: mutation,
                failure: error.failure,
                now: _clock(),
              );
              snapshot = _replaceMutation(snapshot, decision.mutation);
              await _workspace.commitSnapshot(
                snapshot,
                lastAttemptAt: now,
              );
              _emitFailure(error.failure, snapshot);
              return SyncRunResult(
                state: _state,
                pulledChanges: pulled,
                pushedMutations: pushed,
              );
            }
          }
        }
        _emit(_event(SyncEventType.pushCompleted, snapshot));
      }

      final second = await _pullAll(snapshot);
      snapshot = second.snapshot;
      pulled += second.count;
      await _workspace.commitSnapshot(
        snapshot,
        lastSuccessfulSyncAt: _clock().toUtc(),
        lastAttemptAt: now,
      );
      _emit(_event(SyncEventType.secondPullCompleted, snapshot));
      return SyncRunResult(
        state: _state,
        pulledChanges: pulled,
        pushedMutations: pushed,
      );
    } on SyncTransportException catch (error) {
      await _workspace.commitSnapshot(snapshot, lastAttemptAt: now);
      _emitFailure(error.failure, snapshot);
      return SyncRunResult(
        state: _state,
        pulledChanges: pulled,
        pushedMutations: pushed,
      );
    } catch (_) {
      await _workspace.commitSnapshot(snapshot, lastAttemptAt: now);
      _emit(
        _event(
          SyncEventType.blockingFailure,
          snapshot,
          message: 'invalid_sync_payload',
        ),
      );
      return SyncRunResult(
        state: _state,
        pulledChanges: pulled,
        pushedMutations: pushed,
      );
    }
  }

  Future<({SyncSnapshot snapshot, int count})> _pullAll(
    SyncSnapshot initial,
  ) async {
    var snapshot = initial;
    var count = 0;
    while (true) {
      final page = await _transport.pull(afterRevision: snapshot.cursor);
      if (page.changes.isEmpty) break;
      snapshot = SyncRoundReducer.applyRemoteChanges(snapshot, page.changes);
      count += page.changes.length;
      await _workspace.commitSnapshot(
        snapshot,
        lastAttemptAt: _clock().toUtc(),
      );
      if (!page.hasMore) break;
    }
    return (snapshot: snapshot, count: count);
  }

  SyncSnapshot _replaceMutation(
    SyncSnapshot snapshot,
    SyncMutation replacement,
  ) {
    return snapshot.copyWith(
      outbox: [
        for (final mutation in snapshot.outbox)
          if (mutation.mutationId == replacement.mutationId)
            replacement
          else
            mutation,
      ],
    );
  }

  void _emitFailure(SyncFailure failure, SyncSnapshot snapshot) {
    final type = switch (failure.kind) {
      SyncFailureKind.offline => SyncEventType.networkUnavailable,
      SyncFailureKind.authExpired => SyncEventType.authExpired,
      SyncFailureKind.invalidRequest ||
      SyncFailureKind.forbidden =>
        SyncEventType.blockingFailure,
      _ => SyncEventType.retryableFailure,
    };
    _emit(_event(type, snapshot, message: failure.code));
  }

  SyncMachineEvent _event(
    SyncEventType type,
    SyncSnapshot snapshot, {
    String? message,
  }) {
    return SyncMachineEvent(
      type: type,
      occurredAt: _clock(),
      pendingCount: snapshot.outbox.length,
      conflictCount: snapshot.conflicts.length,
      message: message,
    );
  }

  void _emit(SyncMachineEvent event) {
    _state = SyncStateMachine.reduce(_state, event);
    _publish();
  }

  void _publish() {
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _runAgain = false;
    _debounce?.cancel();
    await _remoteWakeSubscription?.cancel();
    final activeRun = _activeRun;
    if (activeRun != null) {
      await activeRun;
    }
    await _stateController.close();
  }
}
