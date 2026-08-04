import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/domain/backup_gateways.dart';
import 'package:zentra/domain/account_repository.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/local_backup_service.dart';
import 'package:zentra/infrastructure/local_persistence_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('export reads canonical core data from Drift instead of stale legacy',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );
    await runtime.initialize();
    final now = DateTime.utc(2026, 7, 27, 12);
    final account = _account('owner-a', now);
    await runtime.accountRepository.saveAccounts([account]);
    await runtime.accountRepository.saveCurrentAccount(account);
    await runtime.accountRepository.saveProfile(
      account.id,
      UserProfile(
        id: account.id,
        name: 'Uri',
        createdAt: now,
      ).toJson(),
    );
    await runtime.habitRepositoryFor(account.id).saveHabit(
          Habit(
            id: 'drift-habit',
            title: 'Dato canónico',
            category: Category.foco,
            frequency: const Frequency(isWeekly: false, daysOfWeek: []),
            createdAt: now,
          ),
        );
    await preferences.setString(
      'habits_${account.id}',
      jsonEncode([
        {'id': 'legacy-stale'},
      ]),
    );
    final files = _MemoryBackupFileGateway();
    final service = LocalBackupService(
      accountRepository: runtime.accountRepository,
      fileGateway: files,
      appVersionGateway: const _FixedVersionGateway(),
      backupProtector: const _PassthroughBackupProtector(),
      coreOwnerStore: runtime,
      preferences: preferences,
    );

    await service.exportBackup(
      userId: account.id,
      passphrase: 'a-secure-test-passphrase',
    );

    final json = jsonDecode(files.savedContents!) as Map<String, dynamic>;
    expect((json['habits'] as List).single['id'], 'drift-habit');
    expect((json['profile'] as Map)['name'], 'Uri');
  });

  test('restore replaces one Drift owner and remaps the profile identity',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );
    await runtime.initialize();
    final now = DateTime.utc(2026, 7, 27, 12);
    final current = _account('current-owner', now);
    await runtime.accountRepository.saveAccounts([current]);
    await runtime.accountRepository.saveCurrentAccount(current);
    await runtime.accountRepository.saveProfile(
      current.id,
      UserProfile(
        id: current.id,
        name: 'Antes',
        createdAt: now,
      ).toJson(),
    );
    final backupUser = _account('backup-owner', now);
    final backup = BackupData(
      user: backupUser,
      profile: {
        'id': backupUser.id,
        'name': 'Después',
        'createdAt': now.toIso8601String(),
      },
      habits: [
        Habit(
          id: 'restored-habit',
          title: 'Restaurado',
          category: Category.agua,
          frequency: const Frequency(isWeekly: false, daysOfWeek: []),
          createdAt: now,
        ).toJson(),
      ],
      logs: const [],
      pomodoroActivities: const [],
      completedTasks: const [],
      pomodoroStats: const {
        'total': 3,
        'today': 1,
        'totalMinutes': 75,
        'todayMinutes': 25,
      },
      exportedAt: now,
      appVersion: '2.0.0+25',
    );
    final service = LocalBackupService(
      accountRepository: runtime.accountRepository,
      fileGateway: _MemoryBackupFileGateway(),
      appVersionGateway: const _FixedVersionGateway(),
      coreOwnerStore: runtime,
      preferences: preferences,
    );

    final result = await service.restoreBackup(
      backup,
      currentUser: current,
      accounts: [current],
      preserveCurrentUser: true,
    );

    expect(result.targetUserId, current.id);
    final restored = await runtime.exportOwner(current.id);
    expect(restored.profile?.id, current.id);
    expect(restored.profile?.name, 'Después');
    expect(restored.habits.single.id, 'restored-habit');
    expect(restored.focusProgress['totalPomodoros'], 3);
  });

  test('restore rolls Drift and account state back after a later failure',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final runtime = LocalPersistenceRuntime(
      preferences: preferences,
      database: database,
    );
    await runtime.initialize();
    final now = DateTime.utc(2026, 7, 27, 12);
    final current = _account('current-owner', now);
    final backupUser = _account('backup-owner', now);
    await runtime.accountRepository.saveAccounts([current]);
    await runtime.accountRepository.saveCurrentAccount(current);
    await runtime.accountRepository.saveActiveSessionUserId(current.id);
    final failingAccounts = _FailOnceActiveSessionRepository(
      runtime.accountRepository,
    );
    final backup = BackupData(
      user: backupUser,
      profile: {
        'id': backupUser.id,
        'name': 'No debe quedar',
        'createdAt': now.toIso8601String(),
      },
      habits: [
        Habit(
          id: 'temporary-habit',
          title: 'Temporal',
          category: Category.foco,
          frequency: const Frequency(isWeekly: false, daysOfWeek: []),
          createdAt: now,
        ).toJson(),
      ],
      logs: const [],
      pomodoroActivities: const [],
      completedTasks: const [],
      pomodoroStats: const {},
      exportedAt: now,
      appVersion: '2.0.0+25',
    );
    final service = LocalBackupService(
      accountRepository: failingAccounts,
      fileGateway: _MemoryBackupFileGateway(),
      appVersionGateway: const _FixedVersionGateway(),
      coreOwnerStore: runtime,
      preferences: preferences,
    );

    await expectLater(
      service.restoreBackup(
        backup,
        currentUser: current,
        accounts: [current],
        preserveCurrentUser: false,
      ),
      throwsStateError,
    );

    final restoredCore = await runtime.exportOwner(backupUser.id);
    expect(restoredCore.profile, isNull);
    expect(restoredCore.habits, isEmpty);
    expect(
      (await runtime.accountRepository.loadAccounts())
          .map((account) => account.id),
      [current.id],
    );
    expect(
      (await runtime.accountRepository.loadCurrentAccount())?.id,
      current.id,
    );
    expect(
      await runtime.accountRepository.loadActiveSessionUserId(),
      current.id,
    );
  });
}

LocalUser _account(String id, DateTime now) {
  return LocalUser(
    id: id,
    username: id,
    createdAt: now,
    lastLogin: now,
  );
}

class _MemoryBackupFileGateway implements BackupFileGateway {
  String? savedContents;

  @override
  Future<String?> selectJson() async => null;

  @override
  Future<String> saveJson({
    required String contents,
    required String fileName,
  }) async {
    savedContents = contents;
    return '/fake/$fileName';
  }
}

class _FixedVersionGateway implements AppVersionGateway {
  const _FixedVersionGateway();

  @override
  Future<String> loadAppVersion() async => '2.0.0+25';
}

class _PassthroughBackupProtector implements BackupProtector {
  const _PassthroughBackupProtector();

  @override
  Future<String> protect({
    required String plaintext,
    required String passphrase,
  }) async =>
      plaintext;

  @override
  Future<String> unprotect({
    required String storedContents,
    required String passphrase,
  }) async =>
      storedContents;
}

class _FailOnceActiveSessionRepository implements AccountRepository {
  final AccountRepository delegate;
  bool _shouldFail = true;

  _FailOnceActiveSessionRepository(this.delegate);

  @override
  Future<void> clearActiveSession() => delegate.clearActiveSession();

  @override
  Future<void> clearCurrentAccount() => delegate.clearCurrentAccount();

  @override
  Future<void> copyProfileToCurrent(String userId) =>
      delegate.copyProfileToCurrent(userId);

  @override
  Future<void> deleteProfile(String userId) => delegate.deleteProfile(userId);

  @override
  Future<String?> loadActiveSessionUserId() =>
      delegate.loadActiveSessionUserId();

  @override
  Future<List<LocalUser>> loadAccounts() => delegate.loadAccounts();

  @override
  Future<LocalUser?> loadCurrentAccount() => delegate.loadCurrentAccount();

  @override
  Future<Map<String, dynamic>?> loadProfile(String? userId) =>
      delegate.loadProfile(userId);

  @override
  Future<void> saveAccounts(List<LocalUser> accounts) =>
      delegate.saveAccounts(accounts);

  @override
  Future<void> saveActiveSessionUserId(String userId) {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Injected active-session failure');
    }
    return delegate.saveActiveSessionUserId(userId);
  }

  @override
  Future<void> saveCurrentAccount(LocalUser account) =>
      delegate.saveCurrentAccount(account);

  @override
  Future<void> saveCurrentProfile(Map<String, dynamic> profile) =>
      delegate.saveCurrentProfile(profile);

  @override
  Future<void> saveProfile(String userId, Map<String, dynamic> profile) =>
      delegate.saveProfile(userId, profile);
}
