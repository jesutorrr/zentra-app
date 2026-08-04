import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/core_owner_snapshot.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);
  late ZentraDatabase database;
  late DriftCoreRepository repository;

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
    repository = DriftCoreRepository(
      database,
      clock: () => now,
    )..setCurrentUser('uri');
  });

  tearDown(() => database.close());

  Habit habit({
    String id = 'habit-1',
    String title = 'Caminar',
    List<int> days = const [1, 3, 5],
    bool archived = false,
  }) {
    return Habit(
      id: id,
      title: title,
      category: Category.movimiento,
      frequency: Frequency(isWeekly: true, daysOfWeek: days),
      createdAt: DateTime.utc(2026, 7, 20, 8),
      isArchived: archived,
      scheduledDate: DateTime(2026, 7, 30),
      hasReminder: true,
      reminderHour: 8,
      reminderMinute: 30,
    );
  }

  CoreOwnerSnapshot snapshot({
    String ownerId = 'uri',
    List<HabitLog>? logs,
  }) {
    return CoreOwnerSnapshot(
      ownerId: ownerId,
      profile: UserProfile(
        id: 'profile-1',
        name: 'Uri',
        avatarEmoji: ':)',
        createdAt: DateTime.utc(2026, 7, 1),
        totalHabitsCompleted: 1,
      ),
      habits: [habit()],
      logs: logs ??
          [
            HabitLog(
              habitId: 'habit-1',
              date: DateTime(2026, 7, 26),
            ),
          ],
      completedTasks: [
        CompletedTask(
          id: 'task-1',
          title: 'Entregar reporte',
          category: Category.foco,
          completedAt: DateTime.utc(2026, 7, 25, 18),
          wasOneTime: true,
        ),
      ],
      focusSessions: [
        PomodoroActivity(
          id: 'focus-1',
          name: 'Lectura',
          startTime: DateTime.utc(2026, 7, 26, 10),
          endTime: DateTime.utc(2026, 7, 26, 10, 25),
          cyclesCompleted: 1,
          totalMinutes: 25,
          isCompleted: true,
        ),
      ],
      focusProgress: const {
        'version': 1,
        'totalPomodoros': 1,
        'totalMinutes': 25,
        'awardedSessionIds': ['focus-1'],
      },
    );
  }

  test('requires an active owner for every read and write', () async {
    repository.setCurrentUser(null);

    await expectLater(repository.getHabits(), throwsA(isA<StateError>()));
    await expectLater(
      repository.saveHabit(habit()),
      throwsA(isA<StateError>()),
    );
    await expectLater(repository.exportOwner(), throwsA(isA<StateError>()));
  });

  test('forOwner locks identity and isolates core rows', () async {
    final ownerA = DriftCoreRepository.forOwner(
      database,
      ownerId: 'owner-a',
      clock: () => now,
    );
    final ownerB = DriftCoreRepository.forOwner(
      database,
      ownerId: 'owner-b',
      clock: () => now,
    );

    expect(ownerA.currentUserId, 'owner-a');
    expect(() => ownerA.setCurrentUser('owner-a'), returnsNormally);
    expect(
      () => ownerA.setCurrentUser('owner-b'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => ownerA.setCurrentUser(null),
      throwsA(isA<StateError>()),
    );
    expect(ownerA.currentUserId, 'owner-a');

    await ownerA.saveHabit(habit(id: 'habit-a'));
    await ownerB.saveHabit(habit(id: 'habit-b'));

    expect((await ownerA.getHabits()).map((entry) => entry.id), ['habit-a']);
    expect((await ownerB.getHabits()).map((entry) => entry.id), ['habit-b']);
  });

  test('forOwner rejects a blank identity', () {
    expect(
      () => DriftCoreRepository.forOwner(
        database,
        ownerId: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('habit repository preserves schedule and explicit local dates',
      () async {
    await repository.saveHabit(habit());
    await repository.toggleLog('habit-1', DateTime(2026, 7, 26, 23, 59));

    final restored = (await repository.getHabits()).single;
    expect(restored.title, 'Caminar');
    expect(restored.frequency.daysOfWeek, [1, 3, 5]);
    expect(restored.scheduledDate, DateTime(2026, 7, 30));
    expect(restored.hasReminder, isTrue);
    expect(restored.reminderHour, 8);
    expect(restored.reminderMinute, 30);
    expect(
      (await repository.getAllLogs()).single.date,
      DateTime(2026, 7, 26),
    );

    await repository.toggleLog('habit-1', DateTime(2026, 7, 26, 1));
    expect(await repository.getAllLogs(), isEmpty);
  });

  test('verified owner replacement preserves counts and checksums', () async {
    final source = snapshot();
    final stored = await repository.replaceOwnerVerified(source);

    expect(stored.counts, source.counts);
    expect(stored.checksum, source.checksum);
    expect((await repository.getProfile())?.name, 'Uri');
    expect((await repository.getCompletedTasks()).single.id, 'task-1');
    expect((await repository.getFocusSessions()).single.id, 'focus-1');
    expect((await repository.getFocusProgress())['totalMinutes'], 25);
    final backup = stored.toBackupPayload();
    expect(backup['habits'], hasLength(1));
    expect(
      backup['pomodoroStats'],
      containsPair('total', 1),
    );
    expect(
      backup['pomodoroStats'],
      containsPair('totalPomodoros', 1),
    );
  });

  test('habit updates preserve sync metadata and exact user content', () async {
    await repository.saveHabit(habit());
    await (database.update(database.habitEntries)
          ..where((row) => row.id.equals('habit-1')))
        .write(
      const HabitEntriesCompanion(
        version: Value(7),
        serverRevision: Value(41),
      ),
    );
    await (database.update(database.habitScheduleEntries)
          ..where((row) => row.habitId.equals('habit-1')))
        .write(
      const HabitScheduleEntriesCompanion(
        version: Value(8),
        serverRevision: Value(42),
        timeZone: Value('America/Mexico_City'),
      ),
    );

    await repository.updateHabit(
      habit(title: '  Caminar lento  ', days: const [2, 4]),
    );

    final storedHabit = await (database.select(database.habitEntries)
          ..where((row) => row.id.equals('habit-1')))
        .getSingle();
    final storedSchedule = await (database.select(database.habitScheduleEntries)
          ..where((row) => row.habitId.equals('habit-1')))
        .getSingle();
    expect(storedHabit.title, '  Caminar lento  ');
    expect(storedHabit.version, 7);
    expect(storedHabit.serverRevision, 41);
    expect(storedSchedule.version, 8);
    expect(storedSchedule.serverRevision, 42);
    expect(storedSchedule.timeZone, 'America/Mexico_City');
  });

  test('failed verified replacement rolls back the previous owner snapshot',
      () async {
    final initial = snapshot();
    await repository.replaceOwnerVerified(initial);
    final invalid = snapshot(
      logs: [
        HabitLog(
          habitId: 'missing-habit',
          date: DateTime(2026, 7, 26),
        ),
      ],
    );

    await expectLater(
      repository.replaceOwnerVerified(invalid),
      throwsA(anything),
    );

    final afterFailure = await repository.exportOwner();
    expect(afterFailure.checksum, initial.checksum);
    expect(afterFailure.counts, initial.counts);
  });

  test('owners cannot read or reuse another owner entity ID', () async {
    await repository.saveHabit(habit());

    repository.setCurrentUser('other');
    expect(await repository.getHabits(), isEmpty);
    await expectLater(
      repository.saveHabit(habit(title: 'Intruso')),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.toggleLog('habit-1', DateTime(2026, 7, 26)),
      throwsA(isA<StateError>()),
    );
  });

  test('deleteOwner removes only the selected owner core rows', () async {
    await repository.replaceOwnerVerified(snapshot());
    repository.setCurrentUser('other');
    await repository.replaceOwnerVerified(
      CoreOwnerSnapshot(
        ownerId: 'other',
        habits: [habit(id: 'habit-other')],
      ),
    );

    repository.setCurrentUser('uri');
    await repository.deleteOwner();
    expect((await repository.exportOwner()).counts['habits'], 0);

    repository.setCurrentUser('other');
    expect((await repository.getHabits()).single.id, 'habit-other');
  });
}
