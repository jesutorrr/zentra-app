import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/sync/sync.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

  SyncMutation mutation({int attemptCount = 0}) {
    return SyncMutation(
      mutationId: 'mutation-1',
      ownerId: 'owner-1',
      deviceId: 'mobile-1',
      entityType: SyncEntityType.note,
      entityId: 'note-1',
      operation: SyncMutationOperation.noteUpsert,
      payload: const {'title': 'Idea'},
      createdAt: now,
      attemptCount: attemptCount,
    );
  }

  group('SyncRetryPolicy', () {
    test('uses deterministic bounded exponential backoff', () {
      const policy = SyncRetryPolicy(
        baseDelay: Duration(seconds: 2),
        maximumDelay: Duration(seconds: 10),
      );

      expect(
        policy.delayForAttempt(attempt: 3, seed: 'mutation-1'),
        policy.delayForAttempt(attempt: 3, seed: 'mutation-1'),
      );
      expect(
        policy.delayForAttempt(attempt: 20, seed: 'mutation-1'),
        lessThanOrEqualTo(const Duration(seconds: 10)),
      );
    });

    test('schedules retry and honors a longer server retry-after', () {
      const policy = SyncRetryPolicy(jitterFraction: 0);
      final decision = policy.decide(
        mutation: mutation(),
        failure: const SyncFailure(
          kind: SyncFailureKind.rateLimited,
          code: '429',
          retryAfter: Duration(seconds: 30),
        ),
        now: now,
      );

      expect(decision.action, SyncRetryAction.retry);
      expect(decision.delay, const Duration(seconds: 30));
      expect(decision.mutation.attemptCount, 1);
      expect(
        decision.mutation.lifecycle,
        SyncMutationLifecycle.retryScheduled,
      );
      expect(
        decision.mutation.nextAttemptAt,
        now.add(const Duration(seconds: 30)),
      );
    });

    test('routes auth and version conflicts without consuming an attempt', () {
      const policy = SyncRetryPolicy();
      final auth = policy.decide(
        mutation: mutation(attemptCount: 2),
        failure: const SyncFailure(
          kind: SyncFailureKind.authExpired,
          code: '401',
        ),
        now: now,
      );
      final conflict = policy.decide(
        mutation: mutation(attemptCount: 2),
        failure: const SyncFailure(
          kind: SyncFailureKind.versionConflict,
          code: 'version_conflict',
        ),
        now: now,
      );

      expect(auth.action, SyncRetryAction.waitForAuthentication);
      expect(auth.mutation.attemptCount, 2);
      expect(conflict.action, SyncRetryAction.pullAndRebase);
      expect(conflict.mutation.attemptCount, 2);
    });

    test('blocks invalid requests immediately', () {
      const policy = SyncRetryPolicy();
      final decision = policy.decide(
        mutation: mutation(),
        failure: const SyncFailure(
          kind: SyncFailureKind.invalidRequest,
          code: 'invalid_payload',
        ),
        now: now,
      );

      expect(decision.action, SyncRetryAction.block);
      expect(
        decision.mutation.lifecycle,
        SyncMutationLifecycle.blockedByFailure,
      );
      expect(decision.mutation.attemptCount, 1);
      expect(decision.mutation.nextAttemptAt, isNull);
    });

    test('blocks after the configured maximum number of failures', () {
      const policy = SyncRetryPolicy(
        maximumAttempts: 3,
        jitterFraction: 0,
      );
      final decision = policy.decide(
        mutation: mutation(attemptCount: 2),
        failure: const SyncFailure(
          kind: SyncFailureKind.timeout,
          code: 'timeout',
        ),
        now: now,
      );

      expect(decision.action, SyncRetryAction.block);
      expect(decision.mutation.attemptCount, 3);
      expect(
        decision.mutation.lifecycle,
        SyncMutationLifecycle.blockedByFailure,
      );
    });
  });
}
