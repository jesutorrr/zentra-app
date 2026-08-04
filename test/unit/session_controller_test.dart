import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/account_repository.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/domain/backup_service.dart';
import 'package:zentra/domain/cloud_auth_gateway.dart';
import 'package:zentra/domain/cloud_link.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_account_repository.dart';

import '../support/riverpod_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('build restores the active account and exposes its owner', () async {
    final now = DateTime.utc(2026, 7, 26, 18);
    final ownerA = _account(
      'owner-a',
      now: now.subtract(const Duration(days: 2)),
    );
    final ownerB = _account(
      'owner-b',
      now: now.subtract(const Duration(days: 1)),
    );
    final repository = _MemoryAccountRepository(
      accounts: [ownerA, ownerB],
      activeUserId: ownerA.id,
    );
    final container = _container(repository, clock: () => now);

    final session = await container.read(sessionControllerProvider.future);

    expect(session.isAuthenticated, isTrue);
    expect(session.currentUser?.id, ownerA.id);
    expect(session.currentUser?.lastLogin, now);
    expect(container.read(activeOwnerIdProvider), ownerA.id);
    expect(repository.activeUserId, ownerA.id);
  });

  test('local-only startup parks a cloud owner without changing its id',
      () async {
    final linkedAt = DateTime.utc(2026, 7, 27, 8);
    final parkedAt = DateTime.utc(2026, 8, 3, 12);
    final cloudOwner = LocalUser(
      id: 'supabase-owner',
      username: 'Uri',
      email: 'uri@example.com',
      remoteIdentityProvider: 'google',
      createdAt: linkedAt,
      lastLogin: linkedAt,
    );
    final repository = _MemoryAccountRepository(
      accounts: [cloudOwner],
      activeUserId: cloudOwner.id,
    )..currentAccount = cloudOwner;
    final container = _container(repository, clock: () => parkedAt);

    final session = await container.read(sessionControllerProvider.future);

    expect(session.isAuthenticated, isTrue);
    expect(session.currentUser?.id, cloudOwner.id);
    expect(session.currentUser?.isCloudLinked, isFalse);
    expect(session.currentUser?.parkedRemoteIdentityProvider, 'google');
    expect(session.currentUser?.cloudParkedAt, parkedAt);
    expect(repository.accounts.single.id, cloudOwner.id);
    expect(repository.currentAccount?.isCloudLinked, isFalse);
    expect(repository.activeUserId, cloudOwner.id);
  });

  test('parking is idempotent across restarts', () async {
    final parkedAt = DateTime.utc(2026, 8, 3, 12);
    final restartedAt = parkedAt.add(const Duration(hours: 1));
    final parkedOwner = LocalUser(
      id: 'parked-owner',
      username: 'Uri',
      parkedRemoteIdentityProvider: 'google',
      cloudParkedAt: parkedAt,
      createdAt: parkedAt.subtract(const Duration(days: 7)),
      lastLogin: parkedAt,
    );
    final repository = _MemoryAccountRepository(
      accounts: [parkedOwner],
      activeUserId: parkedOwner.id,
    );
    final container = _container(repository, clock: () => restartedAt);

    final session = await container.read(sessionControllerProvider.future);

    expect(session.currentUser?.id, parkedOwner.id);
    expect(session.currentUser?.cloudParkedAt, parkedAt);
    expect(session.currentUser?.parkedRemoteIdentityProvider, 'google');
  });

  test('local entry uses injected UUID and logout keeps the account', () async {
    final now = DateTime.utc(2026, 7, 26, 19);
    final repository = _MemoryAccountRepository();
    final container = _container(
      repository,
      clock: () => now,
      uuid: () => 'local-owner',
    );
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);

    expect(await controller.continueLocally(), isTrue);

    var session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.currentUser?.id, 'local-owner');
    expect(session.entryKind, SessionEntryKind.newLocal);
    expect(controller.consumeEntryKind(), SessionEntryKind.newLocal);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.entryKind,
      SessionEntryKind.existing,
    );

    await controller.logout();

    session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.currentUser, isNull);
    expect(session.allUsers.single.id, 'local-owner');
    expect(repository.activeUserId, isNull);
    expect(container.read(activeOwnerIdProvider), isNull);

    final restartedContainer = _container(
      repository,
      clock: () => now.add(const Duration(minutes: 1)),
    );
    final restarted =
        await restartedContainer.read(sessionControllerProvider.future);

    expect(restarted.isAuthenticated, isFalse);
    expect(restarted.currentUser, isNull);
    expect(restarted.allUsers.single.id, 'local-owner');
    expect(repository.activeUserId, isNull);
  });

  test('valid cloud session uses auth uid as the isolated local owner',
      () async {
    final now = DateTime.utc(2026, 7, 27, 9);
    final localOwner = _account('local-owner', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [localOwner],
      activeUserId: localOwner.id,
    );
    final gateway = _FakeCloudAuthGateway(
      currentIdentity: const CloudIdentity(
        userId: 'supabase-owner',
        displayName: 'Uri',
        email: 'uri@example.com',
        provider: 'google',
      ),
    );
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
    );

    final session = await container.read(sessionControllerProvider.future);

    expect(session.currentUser?.id, 'supabase-owner');
    expect(session.currentUser?.remoteIdentityProvider, 'google');
    expect(session.isAuthenticated, isTrue);
    expect(session.entryKind, SessionEntryKind.newLocal);
    expect(repository.accounts.map((account) => account.id), [
      'local-owner',
      'supabase-owner',
    ]);
    expect(repository.profiles['supabase-owner']?['name'], 'Uri');
    expect(repository.activeUserId, 'supabase-owner');
  });

  test('existing cloud profile skips first-run gates on a fresh device',
      () async {
    final now = DateTime.utc(2026, 7, 27, 9, 30);
    final repository = _MemoryAccountRepository();
    repository.profiles['supabase-owner'] = UserProfile(
      id: 'supabase-owner',
      name: 'Uri',
      createdAt: now.subtract(const Duration(days: 10)),
    ).toJson();
    final gateway = _FakeCloudAuthGateway(
      currentIdentity: const CloudIdentity(
        userId: 'supabase-owner',
        displayName: 'Uri',
        provider: 'google',
      ),
    );
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
    );

    await container.read(sessionControllerProvider.future);
    final preferences = await SharedPreferences.getInstance();

    expect(
      preferences.getBool('profile_setup_completed_supabase-owner'),
      isTrue,
    );
    expect(
      preferences.getBool('onboarding_completed_supabase-owner'),
      isTrue,
    );
  });

  test('build waits for cloud restoration before exposing signed-out state',
      () async {
    final now = DateTime.utc(2026, 7, 30, 7);
    final remote = LocalUser(
      id: 'remote-owner',
      username: 'Uri',
      email: 'uri@example.com',
      remoteIdentityProvider: 'google',
      createdAt: now.subtract(const Duration(days: 30)),
      lastLogin: now.subtract(const Duration(hours: 8)),
    );
    final repository = _MemoryAccountRepository(
      accounts: [remote],
      activeUserId: remote.id,
    );
    final restoration = Completer<CloudIdentity?>();
    final gateway = _FakeCloudAuthGateway(
      identityRestoration: restoration.future,
    );
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
    );

    final sessionFuture = container.read(sessionControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sessionControllerProvider).isLoading, isTrue);
    expect(repository.activeUserId, remote.id);

    restoration.complete(
      const CloudIdentity(
        userId: 'remote-owner',
        displayName: 'Uri',
        email: 'uri@example.com',
        provider: 'google',
      ),
    );

    final session = await sessionFuture;
    expect(session.isAuthenticated, isTrue);
    expect(session.currentUser?.id, remote.id);
    expect(repository.activeUserId, remote.id);
  });

  test('cloud sign-in launch, callback and logout keep the remote shadow',
      () async {
    final now = DateTime.utc(2026, 7, 27, 10);
    final repository = _MemoryAccountRepository();
    final gateway = _FakeCloudAuthGateway();
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
    );
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);

    expect(
      await controller.signInWithCloud(CloudAuthProvider.google),
      isTrue,
    );
    expect(gateway.signInProviders, [CloudAuthProvider.google]);

    const identity = CloudIdentity(
      userId: 'remote-owner',
      displayName: 'Uri',
      email: 'uri@example.com',
      provider: 'google',
    );
    await controller.applyCloudIdentity(identity);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.currentUser?.id,
      'remote-owner',
    );
    expect(
      container.read(sessionControllerProvider).valueOrNull?.entryKind,
      SessionEntryKind.newLocal,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('profile_setup_completed_remote-owner'),
      isFalse,
    );

    await controller.applyCloudIdentity(identity);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.entryKind,
      SessionEntryKind.newLocal,
    );

    await controller.logout();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(gateway.signOutCalls, 1);
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers.single.id, 'remote-owner');
    expect(session.allUsers.single.isCloudLinked, isTrue);
    expect(repository.activeUserId, isNull);
  });

  test('local cloud link previews data and activates with its source owner',
      () async {
    final now = DateTime.utc(2026, 7, 27, 10, 30);
    final localOwner = _account('local-owner', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [localOwner],
      activeUserId: localOwner.id,
    );
    final gateway = _FakeCloudAuthGateway();
    final activations = <(String, String?)>[];
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
      cloudLinkPreviewLoader: (ownerId) async => CloudLinkPreview(
        sourceOwnerId: ownerId,
        counts: const {'habits': 2, 'notes': 1},
        checksum: 'verified-preview',
      ),
      cloudWorkspaceActivation: (remoteOwnerId, sourceOwnerId) async {
        activations.add((remoteOwnerId, sourceOwnerId));
      },
    );
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      'profile_setup_completed_${localOwner.id}',
      true,
    );
    await preferences.setBool('onboarding_completed_${localOwner.id}', true);

    final preview = await controller.previewCloudLink();
    expect(preview?.sourceOwnerId, localOwner.id);
    expect(preview?.totalRecords, 3);
    expect(
      await controller.signInWithCloud(CloudAuthProvider.google),
      isTrue,
    );
    await controller.applyCloudIdentity(
      const CloudIdentity(
        userId: 'remote-owner',
        displayName: 'Uri',
        provider: 'google',
      ),
    );

    expect(activations, [('remote-owner', localOwner.id)]);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.currentUser?.id,
      'remote-owner',
    );
    expect(
      preferences.getBool('profile_setup_completed_remote-owner'),
      isTrue,
    );
    expect(
      preferences.getBool('onboarding_completed_remote-owner'),
      isTrue,
    );
    expect(await controller.previewCloudLink(), isNull);
  });

  test('failed cloud migration signs out and keeps the local owner active',
      () async {
    final now = DateTime.utc(2026, 7, 27, 10, 45);
    final localOwner = _account('local-owner', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [localOwner],
      activeUserId: localOwner.id,
    );
    final gateway = _FakeCloudAuthGateway();
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
      cloudWorkspaceActivation: (_, __) async {
        throw StateError('checksum mismatch');
      },
    );
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);

    expect(
      await controller.signInWithCloud(CloudAuthProvider.google),
      isTrue,
    );
    await controller.applyCloudIdentity(
      const CloudIdentity(
        userId: 'remote-owner',
        displayName: 'Uri',
        provider: 'google',
      ),
    );

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.currentUser?.id, localOwner.id);
    expect(session.isAuthenticated, isTrue);
    expect(session.error, contains('checksum mismatch'));
    expect(session.allUsers.map((user) => user.id), [localOwner.id]);
    expect(repository.activeUserId, localOwner.id);
    expect(gateway.signOutCalls, 1);
  });

  test('stored cloud account never unlocks without a valid remote session',
      () async {
    final now = DateTime.utc(2026, 7, 27, 11);
    final remote = LocalUser(
      id: 'remote-owner',
      username: 'Uri',
      email: 'uri@example.com',
      remoteIdentityProvider: 'google',
      createdAt: now,
      lastLogin: now,
    );
    final repository = _MemoryAccountRepository(
      accounts: [remote],
      activeUserId: remote.id,
    );
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: _FakeCloudAuthGateway(),
    );

    final session = await container.read(sessionControllerProvider.future);

    expect(session.isAuthenticated, isFalse);
    expect(session.currentUser, isNull);
    expect(session.allUsers.single.id, remote.id);
    expect(repository.activeUserId, isNull);
  });

  test('an existing local workspace reopens without a credential gate',
      () async {
    final now = DateTime.utc(2026, 7, 26, 20);
    final account = _account(
      'existing-local-owner',
      now: now,
      email: 'uri@zentra.local',
    );
    final repository = _MemoryAccountRepository(accounts: [account]);
    final container = _container(repository, clock: () => now);
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);

    final didOpen = await controller.continueLocally();

    expect(didOpen, isTrue);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.currentUser?.id,
      account.id,
    );
    expect(repository.activeUserId, account.id);
  });

  test('restore switches A to B, marks reload, and logout waits for restore',
      () async {
    final now = DateTime.utc(2026, 7, 26, 23);
    final ownerA = _account('owner-a', now: now);
    final ownerB = _account('owner-b', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [ownerA],
      activeUserId: ownerA.id,
    );
    final restoreStarted = Completer<void>();
    final releaseRestore = Completer<void>();
    final backupService = _FakeBackupService(
      restoreStarted: restoreStarted,
      restoreGate: releaseRestore,
      restoreResult: BackupRestoreResult(
        targetUserId: ownerB.id,
        currentUser: ownerB,
        accounts: [ownerA, ownerB],
        restoredAccount: true,
      ),
    );
    final container = _container(
      repository,
      clock: () => now,
      backupService: backupService,
    );
    await container.read(sessionControllerProvider.future);
    final controller = container.read(sessionControllerProvider.notifier);
    final backup = _backup(ownerB, now);

    final restore = controller.restoreBackup(backup);
    await restoreStarted.future;
    final logout = controller.logout();
    releaseRestore.complete();

    expect(await restore, isTrue);
    var session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.currentUser?.id, ownerB.id);
    expect(session.entryKind, SessionEntryKind.restored);
    expect(session.needsDataReload, isTrue);

    await logout;
    session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.currentUser, isNull);
    expect(session.needsDataReload, isTrue);
    expect(container.read(activeOwnerIdProvider), isNull);
  });

  test('workspace deletion stays local even for a cloud-linked owner',
      () async {
    final now = DateTime.utc(2026, 7, 27, 8);
    final account = LocalUser(
      id: 'remote-owner',
      username: 'Uri',
      email: 'uri@example.com',
      remoteIdentityProvider: 'google',
      createdAt: now,
      lastLogin: now,
    );
    final repository = _MemoryAccountRepository(
      accounts: [account],
      activeUserId: account.id,
    );
    final gateway = _FakeCloudAuthGateway(
      currentIdentity: const CloudIdentity(
        userId: 'remote-owner',
        displayName: 'Uri',
        email: 'uri@example.com',
        provider: 'google',
      ),
    );
    final deactivatedOwners = <String>[];
    final container = _container(
      repository,
      clock: () => now,
      cloudAuthGateway: gateway,
      cloudWorkspaceDeactivation: (ownerId) async {
        deactivatedOwners.add(ownerId);
      },
    );
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).deleteAccount();

    expect(gateway.deleteAccountCalls, 0);
    expect(deactivatedOwners, [account.id]);
    expect(repository.accounts, isEmpty);
    expect(repository.activeUserId, isNull);
    expect(
      container.read(sessionControllerProvider).valueOrNull?.isAuthenticated,
      isFalse,
    );
  });

  test('workspace deletion continues when notification cleanup fails',
      () async {
    final now = DateTime.utc(2026, 8, 3, 16);
    final account = _account('local-delete-after-notification-error', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [account],
      activeUserId: account.id,
    );
    final cleanedOwners = <String>[];
    final container = _container(
      repository,
      clock: () => now,
      notificationCleanup: () async {
        throw StateError('notifications unavailable');
      },
      localDataCleanup: (ownerId) async {
        cleanedOwners.add(ownerId);
      },
    );
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).deleteAccount();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers, isEmpty);
    expect(repository.accounts, isEmpty);
    expect(repository.activeUserId, isNull);
    expect(cleanedOwners, [account.id]);
  });

  test('workspace deletion times out stuck notification cleanup', () async {
    final now = DateTime.utc(2026, 8, 3, 16, 30);
    final account =
        _account('local-delete-after-notification-timeout', now: now);
    final repository = _MemoryAccountRepository(
      accounts: [account],
      activeUserId: account.id,
    );
    final cleanedOwners = <String>[];
    final container = _container(
      repository,
      clock: () => now,
      notificationCleanup: () => Completer<void>().future,
      localDataCleanup: (ownerId) async {
        cleanedOwners.add(ownerId);
      },
    );
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).deleteAccount();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers, isEmpty);
    expect(repository.accounts, isEmpty);
    expect(repository.activeUserId, isNull);
    expect(cleanedOwners, [account.id]);
  });

  test('delete cleans notifications, notes, and every owner preference',
      () async {
    final now = DateTime.utc(2026, 7, 27);
    final account = _account('owner-delete', now: now);
    final ownerKeys = [
      'habits_${account.id}',
      'habit_logs_${account.id}',
      'pomodoro_activities_${account.id}',
      'completed_tasks_${account.id}',
      'pomodoro_total_${account.id}',
      'pomodoro_today_${account.id}',
      'pomodoro_total_minutes_${account.id}',
      'pomodoro_today_minutes_${account.id}',
      'pomodoro_first_date_${account.id}',
      'pomodoro_last_date_${account.id}',
      'pomodoro_focus_progress_${account.id}',
      'pomodoro_active_session_${account.id}',
      'pomodoro_last_awarded_session_${account.id}',
      'pomodoro_work_duration_${account.id}',
      'pomodoro_short_break_duration_${account.id}',
      'pomodoro_long_break_duration_${account.id}',
      'pomodoro_alarm_${account.id}',
      'onboarding_completed_${account.id}',
      'user_profile_${account.id}',
    ];
    const legacyKeys = [
      'habits',
      'habit_logs',
      'completed_tasks',
      'pomodoro_activities',
      'pomodoro_total',
      'pomodoro_today',
      'pomodoro_total_minutes',
      'pomodoro_today_minutes',
      'pomodoro_first_date',
      'pomodoro_last_date',
      'pomodoro_focus_progress',
      'pomodoro_active_session',
      'pomodoro_last_awarded_session',
      'pomodoro_work_duration',
      'pomodoro_short_break_duration',
      'pomodoro_long_break_duration',
      'pomodoro_alarm',
      'onboarding_completed',
    ];
    SharedPreferences.setMockInitialValues({
      'all_users': '[${_accountJson(account)}]',
      'local_user': _accountJson(account),
      'user_profile': '{}',
      'active_session_user_id': account.id,
      for (final key in ownerKeys) key: 'owner-value',
      for (final key in legacyKeys) key: 'legacy-value',
      'unrelated_preference': 'keep-me',
    });
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final noteRepository = DriftNoteRepository(database);
    noteRepository.setCurrentUser(account.id);
    await noteRepository.upsertNote(
      Note(
        id: 'note-delete',
        userId: account.id,
        title: 'Eliminar',
        body: 'Pertenece a la cuenta',
        createdAt: now,
        updatedAt: now,
        accentKey: 'focus',
      ),
    );
    noteRepository.setCurrentUser('previous-owner');
    var notificationCleanupCalls = 0;
    final cleanedLocalOwners = <String>[];
    final container = createTestProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepository),
        backupServiceProvider.overrideWithValue(_FakeBackupService()),
        sessionClockProvider.overrideWithValue(() => now),
        sessionUuidProvider.overrideWithValue(() => 'unused'),
        sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
        accountNotificationCleanupProvider.overrideWithValue(() async {
          notificationCleanupCalls += 1;
        }),
        accountLocalDataCleanupProvider.overrideWithValue((ownerId) async {
          cleanedLocalOwners.add(ownerId);
        }),
      ],
    );
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).deleteAccount();

    final session = container.read(sessionControllerProvider).valueOrNull!;
    expect(session.isAuthenticated, isFalse);
    expect(session.allUsers, isEmpty);
    expect(notificationCleanupCalls, 1);
    expect(cleanedLocalOwners, [account.id]);
    for (final key in [...ownerKeys, ...legacyKeys]) {
      expect(preferences.containsKey(key), isFalse, reason: key);
    }
    expect(preferences.getString('unrelated_preference'), 'keep-me');
    expect(noteRepository.currentUserId, 'previous-owner');
    noteRepository.setCurrentUser(account.id);
    expect(await noteRepository.getNotes(includeArchived: true), isEmpty);
  });

  test('LocalUser discards a legacy password hash when decoding JSON', () {
    final now = DateTime.utc(2026, 7, 26);
    final local = LocalUser.fromJson({
      'id': 'local',
      'username': 'Mi espacio',
      'createdAt': now.toIso8601String(),
      'lastLogin': now.toIso8601String(),
    });
    final legacy = LocalUser.fromJson({
      'id': 'legacy',
      'username': 'Uri',
      'email': 'uri@zentra.local',
      'passwordHash': 'legacy-unsalted-sha256-value',
      'createdAt': now.toIso8601String(),
      'lastLogin': now.toIso8601String(),
    });

    expect(local.toJson(), isNot(contains('passwordHash')));
    expect(legacy.toJson(), isNot(contains('passwordHash')));
    expect(legacy.email, 'uri@zentra.local');
  });
}

ProviderContainer _container(
  _MemoryAccountRepository repository, {
  required DateTime Function() clock,
  String Function()? uuid,
  BackupService? backupService,
  CloudAuthGateway? cloudAuthGateway,
  CloudWorkspaceActivation? cloudWorkspaceActivation,
  CloudWorkspaceDeactivation? cloudWorkspaceDeactivation,
  CloudLinkPreviewLoader? cloudLinkPreviewLoader,
  AccountNotificationCleanup? notificationCleanup,
  AccountLocalDataCleanup? localDataCleanup,
}) {
  return createTestProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(repository),
      backupServiceProvider.overrideWithValue(
        backupService ?? _FakeBackupService(),
      ),
      sessionClockProvider.overrideWithValue(clock),
      sessionUuidProvider.overrideWithValue(uuid ?? () => 'generated-owner'),
      cloudAuthGatewayProvider.overrideWithValue(cloudAuthGateway),
      cloudWorkspaceActivationProvider.overrideWithValue(
        cloudWorkspaceActivation ?? (_, __) async {},
      ),
      cloudWorkspaceDeactivationProvider.overrideWithValue(
        cloudWorkspaceDeactivation ?? (_) async {},
      ),
      cloudLinkPreviewLoaderProvider.overrideWithValue(
        cloudLinkPreviewLoader,
      ),
      accountNotificationCleanupProvider.overrideWithValue(
        notificationCleanup ?? () async {},
      ),
      accountLocalDataCleanupProvider.overrideWithValue(
        localDataCleanup ?? (_) async {},
      ),
    ],
  );
}

LocalUser _account(
  String id, {
  required DateTime now,
  String? email,
}) {
  return LocalUser(
    id: id,
    username: id,
    email: email,
    createdAt: now.subtract(const Duration(days: 30)),
    lastLogin: now,
  );
}

BackupData _backup(LocalUser user, DateTime exportedAt) {
  return BackupData(
    user: user,
    profile: const {},
    habits: const [],
    logs: const [],
    exportedAt: exportedAt,
    appVersion: '2.0.0+25',
  );
}

String _accountJson(LocalUser account) {
  return jsonEncode(account.toJson());
}

class _MemoryAccountRepository implements AccountRepository {
  List<LocalUser> accounts;
  LocalUser? currentAccount;
  String? activeUserId;
  final Map<String, Map<String, dynamic>> profiles = {};
  Map<String, dynamic>? currentProfile;
  Completer<void>? nextSaveStarted;
  Completer<void>? nextSaveGate;

  _MemoryAccountRepository({
    List<LocalUser> accounts = const [],
    this.activeUserId,
  }) : accounts = [...accounts];

  @override
  Future<void> clearActiveSession() async {
    activeUserId = null;
  }

  @override
  Future<void> clearCurrentAccount() async {
    currentAccount = null;
    currentProfile = null;
  }

  @override
  Future<void> copyProfileToCurrent(String userId) async {
    currentProfile = profiles[userId] == null
        ? null
        : Map<String, dynamic>.from(profiles[userId]!);
  }

  @override
  Future<void> deleteProfile(String userId) async {
    profiles.remove(userId);
  }

  @override
  Future<String?> loadActiveSessionUserId() async => activeUserId;

  @override
  Future<List<LocalUser>> loadAccounts() async => [...accounts];

  @override
  Future<LocalUser?> loadCurrentAccount() async => currentAccount;

  @override
  Future<Map<String, dynamic>?> loadProfile(String? userId) async {
    if (userId == null) return currentProfile;
    final profile = profiles[userId];
    return profile == null ? null : Map<String, dynamic>.from(profile);
  }

  @override
  Future<void> saveAccounts(List<LocalUser> value) async {
    final started = nextSaveStarted;
    final gate = nextSaveGate;
    nextSaveStarted = null;
    nextSaveGate = null;
    started?.complete();
    if (gate != null) await gate.future;
    accounts = [...value];
  }

  @override
  Future<void> saveActiveSessionUserId(String userId) async {
    activeUserId = userId;
  }

  @override
  Future<void> saveCurrentAccount(LocalUser account) async {
    currentAccount = account;
  }

  @override
  Future<void> saveCurrentProfile(Map<String, dynamic> profile) async {
    currentProfile = Map<String, dynamic>.from(profile);
  }

  @override
  Future<void> saveProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    profiles[userId] = Map<String, dynamic>.from(profile);
  }
}

class _FakeBackupService implements BackupService {
  final Completer<void>? restoreStarted;
  final Completer<void>? restoreGate;
  final BackupRestoreResult? restoreResult;

  _FakeBackupService({
    this.restoreStarted,
    this.restoreGate,
    this.restoreResult,
  });

  @override
  Future<String> exportBackup({
    required String? userId,
    required String passphrase,
  }) async {
    return '/fake/backup.json';
  }

  @override
  Future<BackupRestoreResult> restoreBackup(
    BackupData backupData, {
    required LocalUser? currentUser,
    required List<LocalUser> accounts,
    required bool preserveCurrentUser,
  }) async {
    restoreStarted?.complete();
    if (restoreGate != null) await restoreGate!.future;
    return restoreResult ??
        BackupRestoreResult(
          targetUserId: backupData.user.id,
          currentUser: backupData.user,
          accounts: [...accounts, backupData.user],
          restoredAccount: true,
        );
  }

  @override
  Future<BackupData?> selectBackup({
    required String passphrase,
    String? jsonData,
  }) async =>
      null;
}

class _FakeCloudAuthGateway implements CloudAuthGateway {
  @override
  Set<CloudAuthProvider> get availableProviders => const {
        CloudAuthProvider.google,
        CloudAuthProvider.apple,
      };

  @override
  CloudIdentity? currentIdentity;

  final signInProviders = <CloudAuthProvider>[];
  int signOutCalls = 0;
  int deleteAccountCalls = 0;
  final Future<CloudIdentity?>? identityRestoration;

  _FakeCloudAuthGateway({
    this.currentIdentity,
    this.identityRestoration,
  });

  @override
  Stream<CloudIdentity?> get identityChanges => const Stream.empty();

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls += 1;
    currentIdentity = null;
  }

  @override
  Future<CloudIdentity?> restoreIdentity() async {
    final restoration = identityRestoration;
    if (restoration == null) return currentIdentity;
    return restoration;
  }

  @override
  Future<void> signIn(CloudAuthProvider provider) async {
    signInProviders.add(provider);
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    currentIdentity = null;
  }
}
