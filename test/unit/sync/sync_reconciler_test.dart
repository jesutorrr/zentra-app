import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/sync/sync.dart';

import 'fixtures/two_device_sync_fixture.dart';

void main() {
  group('SyncRoundReducer', () {
    test('merges web and mobile fields through pull, rebase, push and pull',
        () {
      final result = SyncRoundReducer.reduce(
        TwoDeviceSyncFixture.roundInput(),
      );
      final habit = result.snapshot.entities.values.single;

      expect(result.snapshot.cursor, 4);
      expect(result.snapshot.outbox, isEmpty);
      expect(result.snapshot.conflicts, isEmpty);
      expect(habit.version, 3);
      expect(habit.serverRevision, 4);
      expect(habit.record['title'], 'Caminar 30 minutos');
      expect(habit.record['category'], 'foco');
      expect(result.stats.firstPullApplied, 1);
      expect(result.stats.acknowledgementsApplied, 1);
      expect(result.stats.mutationsRebased, 1);
    });

    test('the same two-device fixture is deterministic', () {
      final first = SyncRoundReducer.reduce(
        TwoDeviceSyncFixture.roundInput(),
      );
      final second = SyncRoundReducer.reduce(
        TwoDeviceSyncFixture.roundInput(),
      );

      expect(
        first.snapshot.toDiagnosticJson(),
        second.snapshot.toDiagnosticJson(),
      );
      expect(first.stats.toJson(), second.stats.toJson());
    });

    test('retry scheduling does not change the reconciled result', () {
      final pending = SyncRoundReducer.reduce(
        TwoDeviceSyncFixture.roundInput(),
      );
      final retry = SyncRoundReducer.reduce(
        TwoDeviceSyncFixture.roundInput(
          lifecycle: SyncMutationLifecycle.retryScheduled,
          nextAttemptAt: DateTime.utc(2026, 7, 27),
        ),
      );

      expect(
        retry.snapshot.toDiagnosticJson(),
        pending.snapshot.toDiagnosticJson(),
      );
      expect(retry.stats.toJson(), pending.stats.toJson());
    });

    test('ACK never advances the cursor and a later pull cannot roll it back',
        () {
      final afterAck = SyncRoundReducer.applyAcknowledgements(
        TwoDeviceSyncFixture.baseSnapshot(),
        [TwoDeviceSyncFixture.mobileAcknowledgement()],
      );

      expect(afterAck.cursor, 2);
      expect(afterAck.entities.values.single.serverRevision, 4);

      final caughtUp = SyncRoundReducer.applyRemoteChanges(
        afterAck,
        [
          TwoDeviceSyncFixture.webCategoryChange(),
          TwoDeviceSyncFixture.acknowledgedChange(),
        ],
      );
      final habit = caughtUp.entities.values.single;

      expect(caughtUp.cursor, 4);
      expect(habit.serverRevision, 4);
      expect(habit.version, 3);
      expect(habit.record['title'], 'Caminar 30 minutos');
      expect(habit.record['category'], 'foco');
    });

    test('completion already confirmed remotely supersedes local mutation', () {
      const localKey = SyncEntityKey(
        type: SyncEntityType.habitDayState,
        id: 'local-completion',
      );
      const canonicalKey = SyncEntityKey(
        type: SyncEntityType.habitDayState,
        id: 'server-completion',
      );
      final snapshot = SyncSnapshot(
        entities: {
          localKey: SyncLocalEntity(
            key: localKey,
            version: 1,
            serverRevision: 0,
            record: const {
              'habit_id': 'habit-1',
              'local_date': '2026-07-26',
              'completed': true,
            },
          ),
        },
        outbox: [
          SyncMutation(
            mutationId: 'completion-1',
            ownerId: 'owner-1',
            deviceId: 'mobile-1',
            entityType: SyncEntityType.habitDayState,
            entityId: localKey.id,
            operation: SyncMutationOperation.habitCompletionSet,
            payload: const {
              'habit_id': 'habit-1',
              'local_date': '2026-07-26',
              'completed': true,
            },
            createdAt: DateTime.utc(2026, 7, 26),
          ),
        ],
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        snapshot,
        [
          SyncRemoteChange(
            serverRevision: 1,
            entityType: SyncEntityType.habitDayState,
            entityId: canonicalKey.id,
            operation: SyncServerOperation.upsert,
            entityVersion: 1,
            record: const {
              'habit_id': 'habit-1',
              'local_date': '2026-07-26',
              'completed': true,
            },
          ),
        ],
      );

      expect(result.outbox, isEmpty);
      expect(result.entities, isNot(contains(localKey)));
      expect(result.entities, contains(canonicalKey));
      expect(result.entities[canonicalKey]!.record['completed'], isTrue);
    });

    test('an already confirmed delete supersedes the matching local delete',
        () {
      const habitKey = SyncEntityKey(
        type: SyncEntityType.habit,
        id: 'habit-1',
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        SyncSnapshot(
          cursor: 1,
          entities: {
            habitKey: SyncLocalEntity(
              key: habitKey,
              version: 1,
              serverRevision: 1,
              record: const {
                'id': 'habit-1',
                'title': 'Leer',
                'deleted_at': null,
              },
            ),
          },
          outbox: [
            SyncMutation(
              mutationId: 'delete-1',
              ownerId: 'owner-1',
              deviceId: 'mobile-1',
              entityType: SyncEntityType.habit,
              entityId: 'habit-1',
              operation: SyncMutationOperation.habitDelete,
              baseVersion: 1,
              createdAt: DateTime.utc(2026, 7, 26),
            ),
          ],
        ),
        [
          SyncRemoteChange(
            serverRevision: 2,
            entityType: SyncEntityType.habit,
            entityId: 'habit-1',
            operation: SyncServerOperation.delete,
            entityVersion: 2,
            record: const {
              'id': 'habit-1',
              'title': 'Leer',
              'is_archived': true,
              'deleted_at': '2026-07-26T12:00:00.000Z',
            },
          ),
        ],
      );

      expect(result.outbox, isEmpty);
      expect(result.conflicts, isEmpty);
      expect(result.entities[habitKey]!.isDeleted, isTrue);
    });

    test('explicit restore rebases over a remote tombstone', () {
      const habitKey = SyncEntityKey(
        type: SyncEntityType.habit,
        id: 'habit-1',
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        SyncSnapshot(
          cursor: 1,
          entities: {
            habitKey: SyncLocalEntity(
              key: habitKey,
              version: 1,
              serverRevision: 1,
              record: const {
                'id': 'habit-1',
                'title': 'Leer',
                'deleted_at': null,
              },
            ),
          },
          outbox: [
            SyncMutation(
              mutationId: 'restore-1',
              ownerId: 'owner-1',
              deviceId: 'mobile-1',
              entityType: SyncEntityType.habit,
              entityId: 'habit-1',
              operation: SyncMutationOperation.habitRestore,
              baseVersion: 1,
              createdAt: DateTime.utc(2026, 7, 26),
            ),
          ],
        ),
        [
          SyncRemoteChange(
            serverRevision: 2,
            entityType: SyncEntityType.habit,
            entityId: 'habit-1',
            operation: SyncServerOperation.delete,
            entityVersion: 2,
            record: const {
              'id': 'habit-1',
              'title': 'Leer',
              'is_archived': true,
              'deleted_at': '2026-07-26T12:00:00.000Z',
            },
          ),
        ],
      );

      expect(result.conflicts, isEmpty);
      expect(result.outbox.single.baseVersion, 2);
      expect(result.outbox.single.lifecycle, SyncMutationLifecycle.pending);
      expect(result.entities[habitKey]!.isDeleted, isFalse);
      expect(result.entities[habitKey]!.record['is_archived'], isFalse);
    });

    test('an older pull canonicalizes an acknowledged logical alias', () {
      const localKey = SyncEntityKey(
        type: SyncEntityType.habitSchedule,
        id: 'local-schedule',
      );
      const serverKey = SyncEntityKey(
        type: SyncEntityType.habitSchedule,
        id: 'server-schedule',
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        SyncSnapshot(
          cursor: 2,
          entities: {
            localKey: SyncLocalEntity(
              key: localKey,
              version: 3,
              serverRevision: 5,
              record: const {
                'habit_id': 'habit-1',
                'days_of_week': [1, 3, 5],
              },
            ),
          },
        ),
        [
          SyncRemoteChange(
            serverRevision: 3,
            entityType: SyncEntityType.habitSchedule,
            entityId: serverKey.id,
            operation: SyncServerOperation.upsert,
            entityVersion: 2,
            record: const {
              'habit_id': 'habit-1',
              'days_of_week': [1, 3],
            },
          ),
        ],
      );

      expect(result.entities, isNot(contains(localKey)));
      expect(result.entities, contains(serverKey));
      expect(result.entities[serverKey]!.key, serverKey);
      expect(result.entities[serverKey]!.version, 3);
      expect(result.cursor, 3);
    });

    test('remote habit delete blocks pending parent and child mutations', () {
      const habitKey = SyncEntityKey(
        type: SyncEntityType.habit,
        id: 'habit-1',
      );
      final snapshot = SyncSnapshot(
        cursor: 2,
        entities: {
          habitKey: SyncLocalEntity(
            key: habitKey,
            version: 2,
            serverRevision: 2,
            record: const {
              'id': 'habit-1',
              'title': 'Leer',
              'deleted_at': null,
            },
          ),
        },
        outbox: [
          SyncMutation(
            mutationId: 'habit-edit',
            ownerId: 'owner-1',
            deviceId: 'mobile-1',
            entityType: SyncEntityType.habit,
            entityId: 'habit-1',
            operation: SyncMutationOperation.habitUpsert,
            payload: const {'title': 'Leer 20 minutos'},
            baseVersion: 2,
            createdAt: DateTime.utc(2026, 7, 26, 10),
          ),
          SyncMutation(
            mutationId: 'schedule-edit',
            ownerId: 'owner-1',
            deviceId: 'mobile-1',
            entityType: SyncEntityType.habitSchedule,
            entityId: 'schedule-1',
            operation: SyncMutationOperation.habitScheduleSet,
            payload: const {
              'habit_id': 'habit-1',
              'weekdays': [1, 3, 5],
            },
            baseVersion: 1,
            createdAt: DateTime.utc(2026, 7, 26, 11),
          ),
        ],
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        snapshot,
        [
          SyncRemoteChange(
            serverRevision: 3,
            entityType: SyncEntityType.habit,
            entityId: 'habit-1',
            operation: SyncServerOperation.delete,
            entityVersion: 3,
            record: const {
              'id': 'habit-1',
              'title': 'Leer',
              'is_archived': true,
              'deleted_at': '2026-07-26T12:00:00.000Z',
            },
          ),
        ],
      );

      expect(
        result.outbox.map((mutation) => mutation.lifecycle),
        everyElement(SyncMutationLifecycle.blockedByConflict),
      );
      expect(result.conflicts, hasLength(2));
      expect(
        result.conflicts
            .singleWhere(
              (conflict) => conflict.mutationId == 'schedule-edit',
            )
            .localRecord['weekdays'],
        [1, 3, 5],
      );
      expect(result.entities[habitKey]!.isDeleted, isTrue);
      expect(
        SyncPushPlanner.readyMutations(
          snapshot: result,
          now: DateTime.utc(2026, 7, 26, 13),
        ),
        isEmpty,
      );
    });

    test('a blocked failure stays blocked when a newer pull arrives', () {
      final blocked = TwoDeviceSyncFixture.mobileTitleMutation().copyWith(
        lifecycle: SyncMutationLifecycle.blockedByFailure,
      );
      final snapshot = TwoDeviceSyncFixture.baseSnapshot().copyWith(
        outbox: [blocked],
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        snapshot,
        [TwoDeviceSyncFixture.webCategoryChange()],
      );

      expect(
        result.outbox.single.lifecycle,
        SyncMutationLifecycle.blockedByFailure,
      );
      expect(result.outbox.single.baseVersion, 1);
      expect(result.entities.values.single.record['title'], 'Caminar');
      expect(result.entities.values.single.record['category'], 'foco');
    });

    test('parallel note edits preserve local and remote versions as conflict',
        () {
      const noteKey = SyncEntityKey(
        type: SyncEntityType.note,
        id: 'note-1',
      );
      final result = SyncRoundReducer.applyRemoteChanges(
        SyncSnapshot(
          cursor: 1,
          entities: {
            noteKey: SyncLocalEntity(
              key: noteKey,
              version: 1,
              serverRevision: 1,
              record: const {
                'id': 'note-1',
                'title': 'Idea',
                'body': 'Edición del móvil',
              },
            ),
          },
          outbox: [
            SyncMutation(
              mutationId: 'note-edit-1',
              ownerId: 'owner-1',
              deviceId: 'mobile-1',
              entityType: SyncEntityType.note,
              entityId: 'note-1',
              operation: SyncMutationOperation.noteUpsert,
              payload: const {'body': 'Edición del móvil'},
              baseVersion: 1,
              createdAt: DateTime.utc(2026, 7, 26),
            ),
          ],
        ),
        [
          SyncRemoteChange(
            serverRevision: 2,
            entityType: SyncEntityType.note,
            entityId: 'note-1',
            operation: SyncServerOperation.upsert,
            entityVersion: 2,
            record: const {
              'id': 'note-1',
              'title': 'Idea',
              'body': 'Edición desde web',
            },
          ),
        ],
      );

      expect(
        result.outbox.single.lifecycle,
        SyncMutationLifecycle.blockedByConflict,
      );
      expect(result.entities[noteKey]!.record['body'], 'Edición desde web');
      expect(result.conflicts.single.kind, SyncConflictKind.concurrentUpdate);
      expect(
        result.conflicts.single.localRecord['body'],
        'Edición del móvil',
      );
      expect(
        result.conflicts.single.remoteRecord['body'],
        'Edición desde web',
      );
      expect(
        SyncPushPlanner.readyMutations(
          snapshot: result,
          now: DateTime.utc(2026, 7, 26, 13),
        ),
        isEmpty,
      );
    });

    test('rejects non-increasing remote revisions after the cursor', () {
      expect(
        () => SyncRoundReducer.applyRemoteChanges(
          TwoDeviceSyncFixture.baseSnapshot(),
          [
            TwoDeviceSyncFixture.acknowledgedChange(),
            TwoDeviceSyncFixture.webCategoryChange(),
          ],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('push planner sends one ready mutation per logical entity', () {
    SyncMutation completion({
      required String id,
      required DateTime createdAt,
      SyncMutationLifecycle lifecycle = SyncMutationLifecycle.pending,
      DateTime? nextAttemptAt,
    }) {
      return SyncMutation(
        mutationId: id,
        ownerId: 'owner-1',
        deviceId: 'mobile-1',
        entityType: SyncEntityType.habitDayState,
        entityId: 'entity-$id',
        operation: SyncMutationOperation.habitCompletionSet,
        payload: const {
          'habit_id': 'habit-1',
          'local_date': '2026-07-26',
          'completed': true,
        },
        createdAt: createdAt,
        lifecycle: lifecycle,
        nextAttemptAt: nextAttemptAt,
      );
    }

    final now = DateTime.utc(2026, 7, 26, 12);
    final snapshot = SyncSnapshot(
      outbox: [
        completion(
          id: 'first',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        completion(
          id: 'second',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        SyncMutation(
          mutationId: 'profile-ready',
          ownerId: 'owner-1',
          deviceId: 'mobile-1',
          entityType: SyncEntityType.profile,
          entityId: 'owner-1',
          operation: SyncMutationOperation.profileUpsert,
          payload: const {'name': 'Uri'},
          createdAt: now,
        ),
        SyncMutation(
          mutationId: 'note-later',
          ownerId: 'owner-1',
          deviceId: 'mobile-1',
          entityType: SyncEntityType.note,
          entityId: 'note-1',
          operation: SyncMutationOperation.noteUpsert,
          payload: const {'title': 'Idea'},
          createdAt: now,
          lifecycle: SyncMutationLifecycle.retryScheduled,
          nextAttemptAt: now.add(const Duration(minutes: 1)),
        ),
      ],
    );

    expect(
      SyncPushPlanner.readyMutations(snapshot: snapshot, now: now)
          .map((mutation) => mutation.mutationId),
      ['first', 'profile-ready'],
    );
  });
}
