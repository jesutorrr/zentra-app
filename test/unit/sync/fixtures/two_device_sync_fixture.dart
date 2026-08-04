import 'package:zentra/domain/sync/sync.dart';

abstract final class TwoDeviceSyncFixture {
  static const ownerId = 'owner-uri';
  static const mobileDeviceId = 'device-mobile';
  static const habitId = 'habit-walk';
  static const mutationId = 'mutation-mobile-title';

  static final mutationCreatedAt = DateTime.utc(2026, 7, 26, 15);

  static SyncMutation mobileTitleMutation({
    SyncMutationLifecycle lifecycle = SyncMutationLifecycle.pending,
    DateTime? nextAttemptAt,
  }) {
    return SyncMutation(
      mutationId: mutationId,
      ownerId: ownerId,
      deviceId: mobileDeviceId,
      entityType: SyncEntityType.habit,
      entityId: habitId,
      operation: SyncMutationOperation.habitUpsert,
      payload: const {'title': 'Caminar 30 minutos'},
      baseVersion: 1,
      createdAt: mutationCreatedAt,
      lifecycle: lifecycle,
      nextAttemptAt: nextAttemptAt,
    );
  }

  static SyncSnapshot baseSnapshot({
    SyncMutationLifecycle lifecycle = SyncMutationLifecycle.pending,
    DateTime? nextAttemptAt,
  }) {
    const key = SyncEntityKey(
      type: SyncEntityType.habit,
      id: habitId,
    );
    return SyncSnapshot(
      cursor: 2,
      entities: {
        key: SyncLocalEntity(
          key: key,
          version: 1,
          serverRevision: 2,
          record: const {
            'id': habitId,
            'owner_id': ownerId,
            'title': 'Caminar',
            'category': 'movimiento',
            'deleted_at': null,
          },
        ),
      },
      outbox: [
        mobileTitleMutation(
          lifecycle: lifecycle,
          nextAttemptAt: nextAttemptAt,
        ),
      ],
    );
  }

  static SyncRemoteChange webCategoryChange() {
    return SyncRemoteChange(
      serverRevision: 3,
      entityType: SyncEntityType.habit,
      entityId: habitId,
      operation: SyncServerOperation.upsert,
      entityVersion: 2,
      record: const {
        'id': habitId,
        'owner_id': ownerId,
        'title': 'Caminar',
        'category': 'foco',
        'deleted_at': null,
      },
    );
  }

  static SyncMutationAcknowledgement mobileAcknowledgement() {
    return SyncMutationAcknowledgement(
      mutationId: mutationId,
      status: SyncAcknowledgementStatus.applied,
      entityType: SyncEntityType.habit,
      entityId: habitId,
      version: 3,
      serverRevision: 4,
      record: const {
        'id': habitId,
        'owner_id': ownerId,
        'title': 'Caminar 30 minutos',
        'category': 'foco',
        'deleted_at': null,
      },
    );
  }

  static SyncRemoteChange acknowledgedChange() {
    return SyncRemoteChange(
      serverRevision: 4,
      entityType: SyncEntityType.habit,
      entityId: habitId,
      operation: SyncServerOperation.upsert,
      entityVersion: 3,
      record: const {
        'id': habitId,
        'owner_id': ownerId,
        'title': 'Caminar 30 minutos',
        'category': 'foco',
        'deleted_at': null,
      },
    );
  }

  static SyncRoundInput roundInput({
    SyncMutationLifecycle lifecycle = SyncMutationLifecycle.pending,
    DateTime? nextAttemptAt,
  }) {
    return SyncRoundInput(
      snapshot: baseSnapshot(
        lifecycle: lifecycle,
        nextAttemptAt: nextAttemptAt,
      ),
      firstPull: [webCategoryChange()],
      acknowledgements: [mobileAcknowledgement()],
      secondPull: [acknowledgedChange()],
    );
  }
}
