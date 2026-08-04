enum SyncPhase {
  localOnly,
  migrationRequired,
  idle,
  pulling,
  reconciling,
  pushing,
  secondPull,
  synced,
  offlineWithPending,
  authRequired,
  conflict,
  errorRecoverable,
  errorBlocking,
}

enum SyncEventType {
  enterLocalMode,
  migrationRequired,
  sessionAvailable,
  syncRequested,
  firstPullCompleted,
  reconciliationCompleted,
  pushCompleted,
  secondPullCompleted,
  networkUnavailable,
  authExpired,
  retryableFailure,
  blockingFailure,
  conflictsResolved,
}

enum SyncExperienceState {
  localOnly,
  syncing,
  synced,
  offlineWithPending,
  authRequired,
  migrationRequired,
  conflict,
  errorRecoverable,
  errorBlocking,
}

class SyncMachineEvent {
  final SyncEventType type;
  final int pendingCount;
  final int conflictCount;
  final DateTime occurredAt;
  final String? message;

  SyncMachineEvent({
    required this.type,
    required DateTime occurredAt,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.message,
  }) : occurredAt = occurredAt.toUtc() {
    if (pendingCount < 0 || conflictCount < 0) {
      throw ArgumentError('Sync counts cannot be negative');
    }
  }
}

class SyncMachineState {
  final SyncPhase phase;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSuccessfulSyncAt;
  final String? message;

  SyncMachineState({
    required this.phase,
    this.pendingCount = 0,
    this.conflictCount = 0,
    DateTime? lastSuccessfulSyncAt,
    this.message,
  }) : lastSuccessfulSyncAt = lastSuccessfulSyncAt?.toUtc() {
    if (pendingCount < 0 || conflictCount < 0) {
      throw ArgumentError('Sync counts cannot be negative');
    }
  }

  factory SyncMachineState.localOnly() {
    return SyncMachineState(phase: SyncPhase.localOnly);
  }

  SyncExperienceState get experienceState {
    switch (phase) {
      case SyncPhase.localOnly:
        return SyncExperienceState.localOnly;
      case SyncPhase.migrationRequired:
        return SyncExperienceState.migrationRequired;
      case SyncPhase.idle:
      case SyncPhase.pulling:
      case SyncPhase.reconciling:
      case SyncPhase.pushing:
      case SyncPhase.secondPull:
        return SyncExperienceState.syncing;
      case SyncPhase.synced:
        return SyncExperienceState.synced;
      case SyncPhase.offlineWithPending:
        return SyncExperienceState.offlineWithPending;
      case SyncPhase.authRequired:
        return SyncExperienceState.authRequired;
      case SyncPhase.conflict:
        return SyncExperienceState.conflict;
      case SyncPhase.errorRecoverable:
        return SyncExperienceState.errorRecoverable;
      case SyncPhase.errorBlocking:
        return SyncExperienceState.errorBlocking;
    }
  }

  SyncMachineState copyWith({
    SyncPhase? phase,
    int? pendingCount,
    int? conflictCount,
    DateTime? lastSuccessfulSyncAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncMachineState(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'pending_count': pendingCount,
        'conflict_count': conflictCount,
        'last_successful_sync_at': lastSuccessfulSyncAt?.toIso8601String(),
        'message': message,
      };
}

abstract final class SyncStateMachine {
  static SyncMachineState reduce(
    SyncMachineState current,
    SyncMachineEvent event,
  ) {
    switch (event.type) {
      case SyncEventType.enterLocalMode:
        return SyncMachineState.localOnly();
      case SyncEventType.migrationRequired:
        return current.copyWith(
          phase: SyncPhase.migrationRequired,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          message: event.message ?? 'migration_required',
        );
      case SyncEventType.sessionAvailable:
        return SyncMachineState(
          phase: SyncPhase.idle,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          lastSuccessfulSyncAt: current.lastSuccessfulSyncAt,
        );
      case SyncEventType.networkUnavailable:
        return current.copyWith(
          phase: SyncPhase.offlineWithPending,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          message: event.message ?? 'network_unavailable',
        );
      case SyncEventType.authExpired:
        return current.copyWith(
          phase: SyncPhase.authRequired,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          message: event.message ?? 'authentication_required',
        );
      case SyncEventType.retryableFailure:
        return current.copyWith(
          phase: SyncPhase.errorRecoverable,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          message: event.message ?? 'sync_retryable_failure',
        );
      case SyncEventType.blockingFailure:
        return current.copyWith(
          phase: SyncPhase.errorBlocking,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          message: event.message ?? 'sync_blocking_failure',
        );
      case SyncEventType.syncRequested:
        _requirePhase(
          current,
          const {
            SyncPhase.idle,
            SyncPhase.synced,
            SyncPhase.offlineWithPending,
            SyncPhase.errorRecoverable,
          },
          event,
        );
        return current.copyWith(
          phase: SyncPhase.pulling,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          clearMessage: true,
        );
      case SyncEventType.firstPullCompleted:
        _requirePhase(current, const {SyncPhase.pulling}, event);
        return current.copyWith(
          phase: SyncPhase.reconciling,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          clearMessage: true,
        );
      case SyncEventType.reconciliationCompleted:
        _requirePhase(current, const {SyncPhase.reconciling}, event);
        if (event.conflictCount > 0) {
          return current.copyWith(
            phase: SyncPhase.conflict,
            pendingCount: event.pendingCount,
            conflictCount: event.conflictCount,
            message: 'sync_conflict',
          );
        }
        return current.copyWith(
          phase:
              event.pendingCount > 0 ? SyncPhase.pushing : SyncPhase.secondPull,
          pendingCount: event.pendingCount,
          conflictCount: 0,
          clearMessage: true,
        );
      case SyncEventType.pushCompleted:
        _requirePhase(current, const {SyncPhase.pushing}, event);
        return current.copyWith(
          phase: SyncPhase.secondPull,
          pendingCount: event.pendingCount,
          conflictCount: event.conflictCount,
          clearMessage: true,
        );
      case SyncEventType.secondPullCompleted:
        _requirePhase(current, const {SyncPhase.secondPull}, event);
        if (event.conflictCount > 0) {
          return current.copyWith(
            phase: SyncPhase.conflict,
            pendingCount: event.pendingCount,
            conflictCount: event.conflictCount,
            message: 'sync_conflict',
          );
        }
        return SyncMachineState(
          phase: event.pendingCount == 0 ? SyncPhase.synced : SyncPhase.idle,
          pendingCount: event.pendingCount,
          conflictCount: 0,
          lastSuccessfulSyncAt: event.occurredAt,
        );
      case SyncEventType.conflictsResolved:
        _requirePhase(current, const {SyncPhase.conflict}, event);
        if (event.conflictCount > 0) {
          return current.copyWith(
            pendingCount: event.pendingCount,
            conflictCount: event.conflictCount,
          );
        }
        return current.copyWith(
          phase: SyncPhase.idle,
          pendingCount: event.pendingCount,
          conflictCount: 0,
          clearMessage: true,
        );
    }
  }

  static void _requirePhase(
    SyncMachineState current,
    Set<SyncPhase> allowed,
    SyncMachineEvent event,
  ) {
    if (allowed.contains(current.phase)) return;
    throw StateError(
      'Event ${event.type.name} is invalid while ${current.phase.name}',
    );
  }
}
