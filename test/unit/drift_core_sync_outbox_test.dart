import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/domain/sync/sync.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';
import 'package:zentra/infrastructure/drift_sync_repository.dart';

void main() {
  const ownerId = 'a0000000-0000-4000-8000-000000000001';
  const habitId = 'a0000000-0000-4000-8000-000000000002';
  final now = DateTime.utc(2026, 7, 27, 12);

  late ZentraDatabase database;

  Habit habit({
    String title = 'Caminar',
    bool isArchived = false,
  }) {
    return Habit(
      id: habitId,
      title: title,
      category: Category.movimiento,
      frequency: Frequency.weekdays(),
      createdAt: now,
      isArchived: isArchived,
      hasReminder: true,
      reminderHour: 8,
      reminderMinute: 30,
    );
  }

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('entity and outbox roll back together when mutation creation fails',
      () async {
    final repository = DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: '',
      clock: () => now,
    );

    await expectLater(repository.saveHabit(habit()), throwsArgumentError);

    expect(await repository.getHabits(), isEmpty);
    expect(
      (await DriftSyncRepository.forOwner(
        database,
        ownerId: ownerId,
      ).loadQueueState())
          .outbox,
      isEmpty,
    );
  });

  test('cloud writes enqueue explicit durable mutations in the same database',
      () async {
    var syncSignals = 0;
    final repository = DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: 'device-1',
      onSyncNeeded: () => syncSignals++,
      clock: () => now,
    );
    final sync = DriftSyncRepository.forOwner(
      database,
      ownerId: ownerId,
    );

    await repository.saveHabit(habit());
    var queue = await sync.loadQueueState();
    expect(
      queue.outbox.map((mutation) => mutation.operation),
      containsAll([
        SyncMutationOperation.habitUpsert,
        SyncMutationOperation.habitScheduleSet,
      ]),
    );
    expect(syncSignals, 1);

    await repository.toggleLog(habitId, now);
    await repository.toggleLog(habitId, now);
    queue = await sync.loadQueueState();
    final completionMutations = queue.outbox
        .where(
          (mutation) =>
              mutation.operation == SyncMutationOperation.habitCompletionSet,
        )
        .toList();
    expect(completionMutations, hasLength(2));
    expect(
      completionMutations.last.payload['completed'],
      isFalse,
      reason: completionMutations
          .map(
            (mutation) =>
                '${mutation.createdAt.toIso8601String()}:${mutation.payload}',
          )
          .join(', '),
    );
    expect(await repository.getAllLogs(), isEmpty);

    await repository.deleteHabit(habitId);
    expect(await repository.getHabits(), isEmpty);
    queue = await sync.loadQueueState();
    expect(
      queue.outbox.map((mutation) => mutation.operation),
      contains(SyncMutationOperation.habitDelete),
    );
    final tombstone = await (database.select(database.habitEntries)
          ..where((row) => row.id.equals(habitId)))
        .getSingle();
    expect(tombstone.deletedAt?.toUtc(), now);
    expect(syncSignals, 4);
  });

  test('completed history and focus sessions enqueue only durable deltas',
      () async {
    var syncSignals = 0;
    final repository = DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: 'device-1',
      onSyncNeeded: () => syncSignals++,
      clock: () => now,
    );
    final task = CompletedTask(
      id: 'a0000000-0000-4000-8000-000000000031',
      title: 'Cerrar el vertical',
      category: Category.foco,
      completedAt: now,
      wasOneTime: true,
    );
    final session = PomodoroActivity(
      id: 'a0000000-0000-4000-8000-000000000032',
      name: 'Gate 7',
      startTime: now,
      endTime: now.add(const Duration(minutes: 25)),
      cyclesCompleted: 1,
      totalMinutes: 25,
      isCompleted: true,
    );

    await repository.replaceCompletedTasks([task]);
    await repository.replaceFocusSessions([session]);
    await repository.replaceCompletedTasks([task]);
    await repository.replaceFocusSessions([session]);

    var queue = await DriftSyncRepository.forOwner(
      database,
      ownerId: ownerId,
    ).loadQueueState();
    expect(
      queue.outbox.map((mutation) => mutation.operation),
      [
        SyncMutationOperation.completedTaskUpsert,
        SyncMutationOperation.focusSessionComplete,
      ],
    );

    await repository.replaceCompletedTasks(const []);
    queue = await DriftSyncRepository.forOwner(
      database,
      ownerId: ownerId,
    ).loadQueueState();
    expect(
      queue.outbox.map((mutation) => mutation.operation),
      [
        SyncMutationOperation.completedTaskUpsert,
        SyncMutationOperation.focusSessionComplete,
        SyncMutationOperation.completedTaskDelete,
      ],
    );
    expect(await repository.getCompletedTasks(), isEmpty);
    expect((await repository.getFocusSessions()).single.id, session.id);
    final taskRow = await (database.select(database.completedTaskEntries)
          ..where((row) => row.id.equals(task.id)))
        .getSingle();
    expect(taskRow.deletedAt, isNotNull);
    expect(syncSignals, 3);
  });

  test('portable theme writes one atomic preference mutation', () async {
    var syncSignals = 0;
    final repository = DriftCoreRepository.forOwner(
      database,
      ownerId: ownerId,
      syncDeviceId: 'device-1',
      onSyncNeeded: () => syncSignals++,
      clock: () => now,
    );

    await repository.savePortableThemeMode('dark');
    await repository.savePortableThemeMode('dark');

    expect(
      (await repository.loadPortablePreferences())?.themeMode,
      'dark',
    );
    final queue = await DriftSyncRepository.forOwner(
      database,
      ownerId: ownerId,
    ).loadQueueState();
    expect(queue.outbox, hasLength(1));
    expect(
      queue.outbox.single.operation,
      SyncMutationOperation.preferencesPatch,
    );
    expect(queue.outbox.single.entityId, ownerId);
    expect(queue.outbox.single.payload, {'theme_mode': 'dark'});
    expect(syncSignals, 1);
  });
}
