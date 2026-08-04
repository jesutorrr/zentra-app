import 'sync_models.dart';

enum SyncFailureKind {
  offline,
  timeout,
  rateLimited,
  serverUnavailable,
  authExpired,
  versionConflict,
  invalidRequest,
  forbidden,
  unknown,
}

enum SyncRetryAction {
  retry,
  waitForAuthentication,
  pullAndRebase,
  block,
}

class SyncFailure {
  final SyncFailureKind kind;
  final String code;
  final Duration? retryAfter;

  const SyncFailure({
    required this.kind,
    required this.code,
    this.retryAfter,
  });
}

class SyncRetryDecision {
  final SyncRetryAction action;
  final SyncMutation mutation;
  final Duration? delay;

  const SyncRetryDecision({
    required this.action,
    required this.mutation,
    this.delay,
  });
}

class SyncRetryPolicy {
  final Duration baseDelay;
  final Duration maximumDelay;
  final int maximumAttempts;
  final double jitterFraction;

  const SyncRetryPolicy({
    this.baseDelay = const Duration(seconds: 2),
    this.maximumDelay = const Duration(minutes: 5),
    this.maximumAttempts = 8,
    this.jitterFraction = 0.2,
  })  : assert(maximumAttempts > 0),
        assert(jitterFraction >= 0),
        assert(jitterFraction < 1);

  SyncRetryDecision decide({
    required SyncMutation mutation,
    required SyncFailure failure,
    required DateTime now,
  }) {
    switch (failure.kind) {
      case SyncFailureKind.authExpired:
        return SyncRetryDecision(
          action: SyncRetryAction.waitForAuthentication,
          mutation: mutation.copyWith(
            lifecycle: SyncMutationLifecycle.pending,
            nextAttemptAt: null,
          ),
        );
      case SyncFailureKind.versionConflict:
        return SyncRetryDecision(
          action: SyncRetryAction.pullAndRebase,
          mutation: mutation.copyWith(
            lifecycle: SyncMutationLifecycle.pending,
            nextAttemptAt: null,
          ),
        );
      case SyncFailureKind.invalidRequest:
      case SyncFailureKind.forbidden:
        return SyncRetryDecision(
          action: SyncRetryAction.block,
          mutation: mutation.copyWith(
            attemptCount: mutation.attemptCount + 1,
            lifecycle: SyncMutationLifecycle.blockedByFailure,
            nextAttemptAt: null,
          ),
        );
      case SyncFailureKind.offline:
      case SyncFailureKind.timeout:
      case SyncFailureKind.rateLimited:
      case SyncFailureKind.serverUnavailable:
      case SyncFailureKind.unknown:
        return _scheduleRetry(
          mutation: mutation,
          failure: failure,
          now: now,
        );
    }
  }

  Duration delayForAttempt({
    required int attempt,
    required String seed,
  }) {
    if (attempt < 1) {
      throw ArgumentError.value(attempt, 'attempt', 'Must be positive');
    }

    final exponent = (attempt - 1).clamp(0, 20).toInt();
    final rawMilliseconds = baseDelay.inMilliseconds * (1 << exponent);
    final cappedMilliseconds = rawMilliseconds
        .clamp(
          0,
          maximumDelay.inMilliseconds,
        )
        .toInt();
    final unit = _stableUnitInterval('$seed:$attempt');
    final jitter = 1 - jitterFraction + (unit * jitterFraction * 2);
    final jittered = (cappedMilliseconds * jitter).round();

    return Duration(
      milliseconds: jittered
          .clamp(
            0,
            maximumDelay.inMilliseconds,
          )
          .toInt(),
    );
  }

  SyncRetryDecision _scheduleRetry({
    required SyncMutation mutation,
    required SyncFailure failure,
    required DateTime now,
  }) {
    final nextAttemptCount = mutation.attemptCount + 1;
    if (nextAttemptCount >= maximumAttempts) {
      return SyncRetryDecision(
        action: SyncRetryAction.block,
        mutation: mutation.copyWith(
          attemptCount: nextAttemptCount,
          lifecycle: SyncMutationLifecycle.blockedByFailure,
          nextAttemptAt: null,
        ),
      );
    }

    var delay = delayForAttempt(
      attempt: nextAttemptCount,
      seed: mutation.mutationId,
    );
    if (failure.retryAfter != null && failure.retryAfter! > delay) {
      delay = failure.retryAfter!;
    }

    return SyncRetryDecision(
      action: SyncRetryAction.retry,
      delay: delay,
      mutation: mutation.copyWith(
        attemptCount: nextAttemptCount,
        lifecycle: SyncMutationLifecycle.retryScheduled,
        nextAttemptAt: now.toUtc().add(delay),
      ),
    );
  }
}

double _stableUnitInterval(String value) {
  var hash = 2166136261;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 16777619) & 0xffffffff;
  }
  return hash / 0xffffffff;
}
