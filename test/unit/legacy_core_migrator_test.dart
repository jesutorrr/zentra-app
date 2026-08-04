import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/core_owner_snapshot.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';
import 'package:zentra/infrastructure/drift_sync_repository.dart';
import 'package:zentra/infrastructure/legacy_core_migrator.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);
  late ZentraDatabase database;
  late DriftCoreRepository core;
  late DriftSyncRepository sync;
  late FakeLegacyPreferences legacy;

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
    core = DriftCoreRepository(database, clock: () => now)
      ..setCurrentUser('uri');
    sync = DriftSyncRepository(database, clock: () => now)
      ..setCurrentOwner('uri');
    legacy = FakeLegacyPreferences();
  });

  tearDown(() => database.close());

  void seedCompleteLegacyOwner() {
    legacy.values.addAll({
      'user_profile_uri': jsonEncode(
        UserProfile(
          id: 'profile-1',
          name: 'Uri',
          createdAt: DateTime.utc(2026, 7, 1),
          totalHabitsCompleted: 1,
        ).toJson(),
      ),
      'habits_uri': jsonEncode([
        Habit(
          id: 'habit-1',
          title: 'Caminar',
          category: Category.movimiento,
          frequency: Frequency.weekdays(),
          createdAt: DateTime.utc(2026, 7, 20),
        ).toJson(),
      ]),
      'habit_logs_uri': jsonEncode([
        HabitLog(
          habitId: 'habit-1',
          date: DateTime(2026, 7, 26),
        ).toJson(),
      ]),
      'completed_tasks_uri': jsonEncode([
        CompletedTask(
          id: 'task-1',
          title: 'Reporte',
          category: Category.foco,
          completedAt: DateTime.utc(2026, 7, 25),
          wasOneTime: true,
        ).toJson(),
      ]),
      'pomodoro_activities_uri': jsonEncode([
        PomodoroActivity(
          id: 'focus-1',
          name: 'Lectura',
          startTime: DateTime.utc(2026, 7, 26, 10),
          endTime: DateTime.utc(2026, 7, 26, 10, 25),
          cyclesCompleted: 1,
          totalMinutes: 25,
          isCompleted: true,
        ).toJson(),
      ]),
      'pomodoro_focus_progress_uri': jsonEncode({
        'version': 1,
        'totalPomodoros': 1,
        'todayPomodoros': 1,
        'totalMinutes': 25,
        'todayMinutes': 25,
        'awardedSessionIds': ['focus-1'],
        'pendingNoteReviews': <Object?>[],
      }),
    });
  }

  LegacyCoreMigrator migrator({
    bool allowUnscopedFallback = false,
  }) {
    return LegacyCoreMigrator(
      legacy: legacy,
      coreRepository: core,
      syncRepository: sync,
      clock: () => now,
      allowUnscopedFallback: allowUnscopedFallback,
    );
  }

  test('migrates, verifies and keeps every legacy key untouched', () async {
    seedCompleteLegacyOwner();
    final before = Map<String, Object?>.from(legacy.values);

    final result = await migrator().migrateOwner('uri');
    final stored = await core.exportOwner();
    final evidence = await sync.getMigration(
      LegacyCoreMigrator.migrationName,
    );

    expect(result.outcome, LegacyCoreMigrationOutcome.migrated);
    expect(result.counts, {
      'profiles': 1,
      'habits': 1,
      'habit_logs': 1,
      'completed_tasks': 1,
      'focus_sessions': 1,
      'focus_progress': 1,
    });
    expect(stored.checksum, result.checksum);
    expect(evidence?.status, LocalMigrationStatus.completed);
    expect(evidence?.sourceChecksum, evidence?.targetChecksum);
    expect(legacy.values, before);
  });

  test('subsecond legacy timestamps verify at SQLite precision', () async {
    final createdAt = DateTime.utc(2026, 7, 1, 8, 9, 10, 987, 654);
    final persistedAt = DateTime.utc(2026, 7, 1, 8, 9, 10);
    CoreOwnerSnapshot snapshotAt(DateTime timestamp) => CoreOwnerSnapshot(
          ownerId: 'uri',
          profile: UserProfile(
            id: 'profile-subsecond',
            name: 'Uri',
            createdAt: timestamp,
          ),
          habits: [
            Habit(
              id: 'habit-subsecond',
              title: 'Respirar',
              category: Category.foco,
              frequency: Frequency.daily(),
              createdAt: timestamp,
            ),
          ],
        );
    expect(snapshotAt(createdAt).checksum, snapshotAt(persistedAt).checksum);

    legacy.values.addAll({
      'user_profile_uri': jsonEncode(
        UserProfile(
          id: 'profile-subsecond',
          name: 'Uri',
          createdAt: createdAt,
        ).toJson(),
      ),
      'habits_uri': jsonEncode([
        Habit(
          id: 'habit-subsecond',
          title: 'Respirar',
          category: Category.foco,
          frequency: Frequency.daily(),
          createdAt: createdAt,
        ).toJson(),
      ]),
    });

    final result = await migrator().migrateOwner('uri');
    final stored = await core.exportOwner();
    final evidence = await sync.getMigration(
      LegacyCoreMigrator.migrationName,
    );

    expect(result.outcome, LegacyCoreMigrationOutcome.migrated);
    expect(evidence?.status, LocalMigrationStatus.completed);
    expect(evidence?.sourceChecksum, evidence?.targetChecksum);
    expect(stored.checksum, result.checksum);
  });

  test('repeating a verified migration is an idempotent no-op', () async {
    seedCompleteLegacyOwner();
    final first = await migrator().migrateOwner('uri');
    final second = await migrator().migrateOwner('uri');

    expect(first.outcome, LegacyCoreMigrationOutcome.migrated);
    expect(second.outcome, LegacyCoreMigrationOutcome.alreadyCompleted);
    expect(second.checksum, first.checksum);
    expect((await core.getHabits()), hasLength(1));
  });

  test('completed marker never overwrites newer Drift data with stale legacy',
      () async {
    seedCompleteLegacyOwner();
    await migrator().migrateOwner('uri');
    await core.saveHabit(
      Habit(
        id: 'drift-only',
        title: 'Creado después del corte',
        category: Category.foco,
        frequency: Frequency.daily(),
        createdAt: now,
      ),
    );

    final repeated = await migrator().migrateOwner('uri');

    expect(repeated.outcome, LegacyCoreMigrationOutcome.alreadyCompleted);
    expect(
      (await core.getHabits()).map((habit) => habit.id),
      containsAll(['habit-1', 'drift-only']),
    );
  });

  test('malformed legacy JSON leaves the existing Drift snapshot intact',
      () async {
    final existing = CoreOwnerSnapshot(
      ownerId: 'uri',
      habits: [
        Habit(
          id: 'existing',
          title: 'Existente',
          category: Category.varios,
          frequency: Frequency.manual(),
          createdAt: now,
        ),
      ],
    );
    await core.replaceOwnerVerified(existing);
    legacy.values['habits_uri'] = '{not-json';

    final result = await migrator().migrateOwner('uri');
    final afterFailure = await core.exportOwner();
    final evidence = await sync.getMigration(
      LegacyCoreMigrator.migrationName,
    );

    expect(result.outcome, LegacyCoreMigrationOutcome.failed);
    expect(result.failureCode, 'FormatException');
    expect(afterFailure.checksum, existing.checksum);
    expect(evidence?.status, LocalMigrationStatus.failed);
    expect(legacy.values['habits_uri'], '{not-json');
  });

  test('valid stale legacy cannot overwrite an unmarked Drift owner', () async {
    seedCompleteLegacyOwner();
    final existing = CoreOwnerSnapshot(
      ownerId: 'uri',
      habits: [
        Habit(
          id: 'drift-only',
          title: 'Creado en Drift',
          category: Category.foco,
          frequency: Frequency.daily(),
          createdAt: now,
        ),
      ],
    );
    await core.replaceOwnerVerified(existing);

    final result = await migrator().migrateOwner('uri');
    final afterFailure = await core.exportOwner();

    expect(result.outcome, LegacyCoreMigrationOutcome.failed);
    expect(result.failureCode, 'StateError');
    expect(afterFailure.checksum, existing.checksum);
    expect(
      (await sync.getMigration(LegacyCoreMigrator.migrationName))?.status,
      LocalMigrationStatus.failed,
    );
  });

  test('does not import unscoped data into a named owner by default', () async {
    legacy.values['habits'] = jsonEncode([
      Habit(
        id: 'unscoped',
        title: 'Sin dueño',
        category: Category.varios,
        frequency: Frequency.manual(),
        createdAt: now,
      ).toJson(),
    ]);

    final result = await migrator().migrateOwner('uri');

    expect(result.outcome, LegacyCoreMigrationOutcome.noLegacyData);
    expect(await core.getHabits(), isEmpty);
  });

  test('missing legacy data never clears an existing Drift owner', () async {
    final existing = CoreOwnerSnapshot(
      ownerId: 'uri',
      habits: [
        Habit(
          id: 'drift-only',
          title: 'Protegido',
          category: Category.foco,
          frequency: Frequency.daily(),
          createdAt: now,
        ),
      ],
    );
    await core.replaceOwnerVerified(existing);

    final result = await migrator().migrateOwner('uri');
    final after = await core.exportOwner();

    expect(result.outcome, LegacyCoreMigrationOutcome.noLegacyData);
    expect(after.checksum, existing.checksum);
  });

  test('explicit unscoped fallback supports the oldest single-user format',
      () async {
    legacy.values['habits'] = jsonEncode([
      Habit(
        id: 'unscoped',
        title: 'Legacy',
        category: Category.varios,
        frequency: Frequency.manual(),
        createdAt: now,
      ).toJson(),
    ]);

    final result = await migrator(
      allowUnscopedFallback: true,
    ).migrateOwner('uri');

    expect(result.outcome, LegacyCoreMigrationOutcome.migrated);
    expect((await core.getHabits()).single.id, 'unscoped');
  });

  test('legacy scalar Pomodoro stats become canonical focus progress',
      () async {
    legacy.values.addAll({
      'pomodoro_total_uri': 3,
      'pomodoro_today_uri': 1,
      'pomodoro_total_minutes_uri': 75,
      'pomodoro_today_minutes_uri': 25,
      'pomodoro_last_awarded_session_uri': 'focus-last',
    });

    final result = await migrator().migrateOwner('uri');
    final progress = await core.getFocusProgress();

    expect(result.outcome, LegacyCoreMigrationOutcome.migrated);
    expect(progress['version'], 1);
    expect(progress['totalPomodoros'], 3);
    expect(progress['totalMinutes'], 75);
    expect(progress['awardedSessionIds'], ['focus-last']);
  });

  test('calendar and progress results stay identical after migration',
      () async {
    seedCompleteLegacyOwner();
    final sourceHabits =
        (jsonDecode(legacy.values['habits_uri']! as String) as List)
            .map(
              (entry) => Habit.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
    final sourceLogs = (jsonDecode(
      legacy.values['habit_logs_uri']! as String,
    ) as List)
        .map(
          (entry) => HabitLog.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
    final sourceProfile = UserProfile.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(legacy.values['user_profile_uri']! as String) as Map,
      ),
    );

    await migrator().migrateOwner('uri');
    final stored = await core.exportOwner();

    for (var offset = 0; offset < 14; offset++) {
      final date = DateTime(2026, 7, 20 + offset);
      final before = sourceHabits
          .where((habit) => habit.isScheduledFor(date))
          .map((habit) => habit.id)
          .toList();
      final after = stored.habits
          .where((habit) => habit.isScheduledFor(date))
          .map((habit) => habit.id)
          .toList();
      expect(after, before, reason: 'calendar mismatch on $date');
    }

    ProgressSnapshot progressFor(
      List<Habit> habits,
      List<HabitLog> logs,
      List<PomodoroActivity> focus,
    ) {
      final habitsById = {for (final habit in habits) habit.id: habit};
      return ProgressSnapshot(
        habitEvents: [
          for (final log in logs)
            HabitProgressEvent(
              id: '${log.habitId}:${ProgressEngine.dayKey(log.date)}',
              completedOn: log.date,
              categoryName: habitsById[log.habitId]!.category.name,
            ),
        ],
        focusEvents: [
          for (final session in focus)
            if (session.isCompleted)
              FocusProgressEvent(
                id: session.id,
                completedOn: session.endTime ?? session.startTime,
              ),
        ],
        knownHabitIds: habits.map((habit) => habit.id).toSet(),
        longestStreak: 1,
        totalPomodoros: 1,
        totalFocusMinutes: 25,
      );
    }

    final before = ProgressEngine.synchronize(
      current: sourceProfile,
      snapshot: progressFor(
        sourceHabits,
        sourceLogs,
        [
          PomodoroActivity.fromJson(
            Map<String, dynamic>.from(
              (jsonDecode(
                legacy.values['pomodoro_activities_uri']! as String,
              ) as List)
                  .single as Map,
            ),
          ),
        ],
      ),
    );
    final after = ProgressEngine.synchronize(
      current: stored.profile!,
      snapshot: progressFor(
        stored.habits,
        stored.logs,
        stored.focusSessions,
      ),
    );

    expect(after.profile.toJson(), before.profile.toJson());
    expect(
      after.newlyUnlocked.map((achievement) => achievement.id),
      before.newlyUnlocked.map((achievement) => achievement.id),
    );
  });
}

class FakeLegacyPreferences implements LegacyPreferenceReader {
  final Map<String, Object?> values = {};

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  String? getString(String key) => values[key] as String?;
}
