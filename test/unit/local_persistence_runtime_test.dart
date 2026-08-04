import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/drift_sync_repository.dart';
import 'package:zentra/infrastructure/local_persistence_runtime.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_account_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates every known owner before routing runtime reads to Drift',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final owner = _account('owner-a');
    final createdAt = DateTime.utc(2026, 7, 27, 9);
    final profile = UserProfile(
      id: owner.id,
      name: 'Uri',
      createdAt: createdAt,
    );
    final habit = Habit(
      id: 'habit-a',
      title: 'Tomar agua',
      category: Category.agua,
      frequency: const Frequency(isWeekly: false, daysOfWeek: []),
      createdAt: createdAt,
    );

    await accountRepository.saveAccounts([owner]);
    await accountRepository.saveProfile(owner.id, profile.toJson());
    await preferences.setString(
      'habits_${owner.id}',
      jsonEncode([habit.toJson()]),
    );
    await preferences.setString(
      'habit_logs_${owner.id}',
      jsonEncode([
        HabitLog(
          habitId: habit.id,
          date: DateTime(2026, 7, 27),
        ).toJson(),
      ]),
    );

    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );

    final accounts = await runtime.initialize();

    expect(accounts.map((account) => account.id), [owner.id]);
    expect(runtime.supportsOwner(owner.id), isTrue);
    expect(runtime.legacyFallbackOwners, isEmpty);
    expect(runtime.habitRepositoryFor(owner.id), isA<DriftCoreRepository>());
    expect(
      (await runtime.profileRepositoryFor(owner.id).loadProfile())?.name,
      'Uri',
    );
    expect(
      (await runtime.habitRepositoryFor(owner.id).getHabits()).single.id,
      habit.id,
    );
    expect(
      (await runtime.habitRepositoryFor(owner.id).getAllLogs()).single.habitId,
      habit.id,
    );

    // Verification must not consume the legacy rollback source.
    expect(preferences.containsKey('habits_${owner.id}'), isTrue);
    expect(preferences.containsKey('habit_logs_${owner.id}'), isTrue);
  });

  test('routes one failed owner back to legacy without affecting another',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final ownerA = _account('owner-a');
    final ownerB = _account('owner-b');
    await accountRepository.saveAccounts([ownerA, ownerB]);
    await preferences.setString('habits_${ownerA.id}', '{malformed');
    await preferences.setString('habits_${ownerB.id}', '[]');

    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );

    await runtime.initialize();

    expect(runtime.supportsOwner(ownerA.id), isFalse);
    expect(runtime.supportsOwner(ownerB.id), isTrue);
    expect(
      runtime.habitRepositoryFor(ownerA.id),
      isA<LocalStorageRepository>(),
    );
    expect(runtime.habitRepositoryFor(ownerB.id), isA<DriftCoreRepository>());
    expect(
      runtime.noteRepositoryFor(ownerA.id),
      isA<DriftNoteRepository>(),
    );
    expect(
      await runtime.noteRepositoryFor(ownerA.id).getNotes(),
      isEmpty,
    );
  });

  test('new owners write their canonical profile directly to Drift', () async {
    final preferences = await SharedPreferences.getInstance();
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );
    await runtime.initialize();
    final owner = _account('new-owner');
    final profile = UserProfile(
      id: owner.id,
      name: 'Nuevo espacio',
      createdAt: owner.createdAt,
    );

    await runtime.accountRepository.saveAccounts([owner]);
    await runtime.accountRepository.saveProfile(owner.id, profile.toJson());

    expect(runtime.supportsOwner(owner.id), isTrue);
    expect(
      (await runtime.profileRepositoryFor(owner.id).loadProfile())?.name,
      'Nuevo espacio',
    );
    expect(preferences.containsKey('user_profile_${owner.id}'), isFalse);
  });

  test('owner cleanup removes canonical core and pending sync metadata',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );
    await runtime.initialize();
    final owner = _account('delete-owner');
    final profile = UserProfile(
      id: owner.id,
      name: 'Borrar',
      createdAt: owner.createdAt,
    );
    await runtime.accountRepository.saveProfile(owner.id, profile.toJson());
    await runtime.habitRepositoryFor(owner.id).saveHabit(
          Habit(
            id: 'delete-habit',
            title: 'Dato local',
            category: Category.foco,
            frequency: const Frequency(isWeekly: false, daysOfWeek: []),
            createdAt: owner.createdAt,
          ),
        );
    final syncRepository = DriftSyncRepository.forOwner(
      database,
      ownerId: owner.id,
    );
    await syncRepository.replaceQueueState(SyncQueueState(cursor: 9));

    await runtime.deleteOwner(owner.id);

    final core = await runtime.exportOwner(owner.id);
    expect(core.profile, isNull);
    expect(core.habits, isEmpty);
    expect((await syncRepository.loadQueueState()).cursor, 0);
  });

  test('parked runtime freezes a previous cloud link without deleting data',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final owner = _account('parked-owner');
    await accountRepository.saveAccounts([owner]);
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final syncRepository = DriftSyncRepository.forOwner(
      database,
      ownerId: owner.id,
    );
    await syncRepository.linkOwner(
      localOwnerId: owner.id,
      remoteUserId: owner.id,
    );
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
      cloudSyncAllowed: false,
    );

    await runtime.initialize();
    await runtime.habitRepositoryFor(owner.id).saveHabit(
          Habit(
            id: 'local-after-parking',
            title: 'Sigue local',
            category: Category.foco,
            frequency: const Frequency(isWeekly: false, daysOfWeek: []),
            createdAt: owner.createdAt,
          ),
        );

    expect(runtime.isSyncEnabled(owner.id), isFalse);
    expect(await syncRepository.getLinkedRemoteUserId(), owner.id);
    expect((await syncRepository.loadQueueState()).outbox, isEmpty);
    expect(
      () => runtime.prepareCloudOwner(owner.id),
      throwsA(isA<StateError>()),
    );
    expect(
      (await runtime.habitRepositoryFor(owner.id).getHabits()).single.id,
      'local-after-parking',
    );
  });
}

LocalUser _account(String id) {
  final createdAt = DateTime.utc(2026, 7, 27, 8);
  return LocalUser(
    id: id,
    username: id,
    createdAt: createdAt,
    lastLogin: createdAt,
  );
}
