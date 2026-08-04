import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/drift_sync_repository.dart';
import 'package:zentra/infrastructure/local_persistence_runtime.dart';

void main() {
  const sourceOwnerId = '10000000-0000-4000-8000-000000000001';
  const remoteOwnerId = '20000000-0000-4000-8000-000000000001';
  const habitId = '10000000-0000-4000-8000-000000000002';
  const noteId = '10000000-0000-4000-8000-000000000003';
  const remoteHabitId = '20000000-0000-4000-8000-000000000002';
  final now = DateTime.utc(2026, 7, 27, 12);

  late ZentraDatabase database;
  late LocalPersistenceRuntime runtime;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = ZentraDatabase(NativeDatabase.memory());
    runtime = LocalPersistenceRuntime(
      preferences: await SharedPreferences.getInstance(),
      database: database,
    );
    await runtime.initialize();
  });

  tearDown(() => database.close());

  test('previewed local owner migrates transactionally and idempotently',
      () async {
    await runtime.profileRepositoryFor(sourceOwnerId).saveProfile(
          UserProfile(
            id: sourceOwnerId,
            name: 'Uri local',
            createdAt: now,
          ),
        );
    await runtime.habitRepositoryFor(sourceOwnerId).saveHabit(
          Habit(
            id: habitId,
            title: 'Caminar',
            category: Category.movimiento,
            frequency: Frequency.weekdays(),
            createdAt: now,
          ),
        );
    final sourceNotes = DriftNoteRepository.forOwner(
      database,
      ownerId: sourceOwnerId,
    );
    await sourceNotes.upsertNote(
      Note(
        id: noteId,
        userId: sourceOwnerId,
        title: 'Idea local',
        body: 'Conservar esta nota',
        createdAt: now,
        updatedAt: now,
        accentKey: 'lavender',
      ),
    );

    final preview = await runtime.previewCloudLink(sourceOwnerId);
    expect(preview.counts['profiles'], 1);
    expect(preview.counts['habits'], 1);
    expect(preview.counts['notes'], 1);

    runtime.prepareCloudOwner(remoteOwnerId);
    final result = await runtime.migrateLocalOwnerToCloud(
      sourceOwnerId: sourceOwnerId,
      remoteOwnerId: remoteOwnerId,
    );

    expect(result.remoteWasEmpty, isTrue);
    expect(result.sourceCounts['notes'], 1);
    expect((await runtime.exportOwner(sourceOwnerId)).habits, hasLength(1));
    final remoteHabit =
        (await runtime.exportOwner(remoteOwnerId)).habits.single;
    expect(remoteHabit.id, isNot(habitId));
    expect(remoteHabit.title, 'Caminar');
    expect(
      (await runtime.exportOwner(sourceOwnerId)).habits.single.id,
      habitId,
    );
    final remoteNote = (await DriftNoteRepository.forOwner(
      database,
      ownerId: remoteOwnerId,
    ).getNotes())
        .single;
    expect(remoteNote.id, isNot(noteId));
    expect(remoteNote.title, 'Idea local');
    expect(
      (await DriftNoteRepository.forOwner(
        database,
        ownerId: sourceOwnerId,
      ).getNotes())
          .single
          .id,
      noteId,
    );
    final sourceSync = DriftSyncRepository.forOwner(
      database,
      ownerId: sourceOwnerId,
    );
    final remoteSync = DriftSyncRepository.forOwner(
      database,
      ownerId: remoteOwnerId,
    );
    expect(await sourceSync.getLinkedRemoteUserId(), remoteOwnerId);
    expect(await remoteSync.getLinkedRemoteUserId(), isNull);
    final pendingBeforeRetry =
        (await remoteSync.loadQueueState()).outbox.length;
    expect(pendingBeforeRetry, 4);
    expect(
      (await remoteSync.loadQueueState())
          .outbox
          .map((mutation) => mutation.operation.name),
      [
        'profileUpsert',
        'habitUpsert',
        'habitScheduleSet',
        'noteUpsert',
      ],
    );

    final repeated = await runtime.migrateLocalOwnerToCloud(
      sourceOwnerId: sourceOwnerId,
      remoteOwnerId: remoteOwnerId,
    );
    expect(repeated.sourceChecksum, result.sourceChecksum);
    expect(
      (await remoteSync.loadQueueState()).outbox.length,
      pendingBeforeRetry,
    );
  });

  test('merge keeps existing cloud profile and adds local entities', () async {
    await runtime.profileRepositoryFor(sourceOwnerId).saveProfile(
          UserProfile(
            id: sourceOwnerId,
            name: 'Uri local',
            createdAt: now,
          ),
        );
    await runtime.habitRepositoryFor(sourceOwnerId).saveHabit(
          Habit(
            id: habitId,
            title: 'Hábito local',
            category: Category.movimiento,
            frequency: Frequency.daily(),
            createdAt: now,
          ),
        );
    await runtime.profileRepositoryFor(remoteOwnerId).saveProfile(
          UserProfile(
            id: remoteOwnerId,
            name: 'Perfil que ya estaba en nube',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        );
    await runtime.habitRepositoryFor(remoteOwnerId).saveHabit(
          Habit(
            id: remoteHabitId,
            title: 'Hábito que ya estaba en nube',
            category: Category.foco,
            frequency: Frequency.weekdays(),
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        );

    runtime.prepareCloudOwner(remoteOwnerId);
    final result = await runtime.migrateLocalOwnerToCloud(
      sourceOwnerId: sourceOwnerId,
      remoteOwnerId: remoteOwnerId,
    );

    expect(result.remoteWasEmpty, isFalse);
    expect(
      (await runtime.profileRepositoryFor(remoteOwnerId).loadProfile())?.name,
      'Perfil que ya estaba en nube',
    );
    final remoteHabits =
        await runtime.habitRepositoryFor(remoteOwnerId).getHabits();
    expect(remoteHabits, hasLength(2));
    expect(
      remoteHabits.map((habit) => habit.title),
      containsAll([
        'Hábito local',
        'Hábito que ya estaba en nube',
      ]),
    );
    expect(
      (await runtime.habitRepositoryFor(sourceOwnerId).getHabits()).single.id,
      habitId,
    );
    expect(
      (await DriftSyncRepository.forOwner(
        database,
        ownerId: remoteOwnerId,
      ).loadQueueState())
          .outbox
          .map((mutation) => mutation.operation.name),
      ['habitUpsert', 'habitScheduleSet'],
    );
  });
}
