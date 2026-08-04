import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/account_repository.dart';
import '../domain/auth_models.dart';
import '../domain/backup_service.dart';
import '../domain/cloud_auth_gateway.dart';
import '../domain/cloud_link.dart';
import '../domain/core_owner_store.dart';
import '../domain/note_repository.dart';
import '../domain/user_profile.dart';
import '../infrastructure/app_logger.dart';
import '../infrastructure/local_backup_service.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/package_info_app_version_gateway.dart';
import '../infrastructure/platform_backup_file_gateway.dart';
import '../infrastructure/shared_preferences_account_repository.dart';

typedef SessionClock = DateTime Function();
typedef SessionUuidGenerator = String Function();
typedef AccountNotificationCleanup = Future<void> Function();
typedef AccountLocalDataCleanup = Future<void> Function(String ownerId);
typedef CloudWorkspaceActivation = Future<void> Function(
  String remoteOwnerId,
  String? sourceOwnerId,
);
typedef CloudWorkspaceDeactivation = Future<void> Function(String ownerId);
typedef CloudLinkPreviewLoader = Future<CloudLinkPreview> Function(
  String ownerId,
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => const SharedPreferencesAccountRepository(),
);

final cloudAuthGatewayProvider = Provider<CloudAuthGateway?>((ref) => null);

final cloudAuthStartupErrorProvider = Provider<String?>((ref) => null);

/// Root capability switch for every cloud behavior.
///
/// Production overrides this from the compile-time runtime policy. Deriving
/// the default from the gateway keeps focused cloud tests explicit while a
/// normal build without a gateway remains safely local-only.
final cloudRuntimeEnabledProvider = Provider<bool>(
  (ref) => ref.watch(cloudAuthGatewayProvider) != null,
);

final cloudWorkspaceActivationProvider = Provider<CloudWorkspaceActivation>(
  (ref) => (_, __) async {},
);

final cloudWorkspaceDeactivationProvider =
    Provider<CloudWorkspaceDeactivation>((ref) => (_) async {});

final cloudLinkPreviewLoaderProvider = Provider<CloudLinkPreviewLoader?>(
  (ref) => null,
);

final cloudIdentityChangesProvider = StreamProvider<CloudIdentity?>((ref) {
  if (!ref.watch(cloudRuntimeEnabledProvider)) return const Stream.empty();
  final gateway = ref.watch(cloudAuthGatewayProvider);
  if (gateway == null) return const Stream.empty();
  return gateway.identityChanges;
});

/// Optional bridge used while backup and account deletion still include notes.
///
/// The app root overrides this with the mutable orchestration repository.
/// Owner-bound feature controllers use their own repository factories.
final sessionNoteRepositoryProvider = Provider<NoteRepository?>((ref) => null);

final coreOwnerStoreProvider = Provider<CoreOwnerStore?>((ref) => null);

final backupServiceProvider = Provider<BackupService>((ref) {
  return LocalBackupService(
    accountRepository: ref.watch(accountRepositoryProvider),
    fileGateway: const PlatformBackupFileGateway(),
    appVersionGateway: const PackageInfoAppVersionGateway(),
    coreOwnerStore: ref.watch(coreOwnerStoreProvider),
    noteRepository: ref.watch(sessionNoteRepositoryProvider),
  );
});

final sessionClockProvider = Provider<SessionClock>((ref) => DateTime.now);

final sessionUuidProvider = Provider<SessionUuidGenerator>(
  (ref) => const Uuid().v4,
);

final accountNotificationCleanupProvider = Provider<AccountNotificationCleanup>(
  (ref) => NotificationService().cancelAllNotifications,
);

final accountLocalDataCleanupProvider = Provider<AccountLocalDataCleanup>(
  (ref) => (_) async {},
);

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final activeOwnerIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionControllerProvider).valueOrNull?.currentUser?.id,
);

enum SessionEntryKind {
  existing,
  newLocal,
  restored,
}

class SessionState {
  static const _unset = Object();

  final LocalUser? currentUser;
  final List<LocalUser> allUsers;
  final String? error;
  final bool isSessionActive;
  final bool needsDataReload;
  final SessionEntryKind entryKind;

  SessionState({
    this.currentUser,
    List<LocalUser> allUsers = const [],
    this.error,
    this.isSessionActive = false,
    this.needsDataReload = false,
    this.entryKind = SessionEntryKind.existing,
  }) : allUsers = List.unmodifiable(allUsers);

  bool get isAuthenticated => isSessionActive && currentUser != null;
  bool get hasAccount => allUsers.isNotEmpty;
  bool get hasMultipleAccounts => allUsers.length > 1;

  SessionState copyWith({
    Object? currentUser = _unset,
    List<LocalUser>? allUsers,
    Object? error = _unset,
    bool? isSessionActive,
    bool? needsDataReload,
    SessionEntryKind? entryKind,
  }) {
    return SessionState(
      currentUser: identical(currentUser, _unset)
          ? this.currentUser
          : currentUser as LocalUser?,
      allUsers: allUsers ?? this.allUsers,
      error: identical(error, _unset) ? this.error : error as String?,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      needsDataReload: needsDataReload ?? this.needsDataReload,
      entryKind: entryKind ?? this.entryKind,
    );
  }
}

class SessionController extends AsyncNotifier<SessionState> {
  late AccountRepository _accountRepository;
  late CloudAuthGateway? _cloudAuthGateway;
  late bool _cloudRuntimeEnabled;
  late BackupService _backupService;
  late NoteRepository? _noteRepository;
  late SessionClock _clock;
  late SessionUuidGenerator _uuid;
  late AccountNotificationCleanup _cleanupAccountNotifications;
  late AccountLocalDataCleanup _cleanupAccountLocalData;
  late CloudWorkspaceActivation _activateCloudWorkspace;
  late CloudWorkspaceDeactivation _deactivateCloudWorkspace;
  late CloudLinkPreviewLoader? _loadCloudLinkPreview;
  Future<void> _mutationQueue = Future<void>.value();
  String? _pendingCloudSourceOwnerId;

  @override
  Future<SessionState> build() async {
    _accountRepository = ref.watch(accountRepositoryProvider);
    _cloudAuthGateway = ref.watch(cloudAuthGatewayProvider);
    _cloudRuntimeEnabled = ref.watch(cloudRuntimeEnabledProvider);
    _backupService = ref.watch(backupServiceProvider);
    _noteRepository = ref.watch(sessionNoteRepositoryProvider);
    _clock = ref.watch(sessionClockProvider);
    _uuid = ref.watch(sessionUuidProvider);
    _cleanupAccountNotifications =
        ref.watch(accountNotificationCleanupProvider);
    _cleanupAccountLocalData = ref.watch(accountLocalDataCleanupProvider);
    _activateCloudWorkspace = ref.watch(cloudWorkspaceActivationProvider);
    _deactivateCloudWorkspace = ref.watch(cloudWorkspaceDeactivationProvider);
    _loadCloudLinkPreview = ref.watch(cloudLinkPreviewLoaderProvider);

    var accounts = <LocalUser>[];
    try {
      accounts = await _accountRepository.loadAccounts();
      if (!_cloudRuntimeEnabled) {
        accounts = await _parkCloudAccounts(accounts);
      }
      final cloudIdentity = _cloudRuntimeEnabled
          ? await _cloudAuthGateway?.restoreIdentity()
          : null;
      if (cloudIdentity != null) {
        await _activateCloudWorkspace(cloudIdentity.userId, null);
        return _activateCloudIdentity(
          SessionState(allUsers: accounts),
          cloudIdentity,
        );
      }

      final activeUserId = await _accountRepository.loadActiveSessionUserId();
      LocalUser? userToLogin;

      if (activeUserId != null) {
        userToLogin =
            accounts.where((user) => user.id == activeUserId).firstOrNull;
      }

      if (userToLogin == null) {
        return SessionState(allUsers: accounts);
      }
      if (userToLogin.isCloudLinked) {
        await _accountRepository.clearActiveSession();
        return SessionState(allUsers: accounts);
      }

      final updatedUser = userToLogin.copyWith(lastLogin: _clock());
      final index = accounts.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        accounts[index] = updatedUser;
        await _accountRepository.saveAccounts(accounts);
      }
      await _accountRepository.saveCurrentAccount(updatedUser);
      await _accountRepository.saveActiveSessionUserId(updatedUser.id);

      return SessionState(
        currentUser: updatedUser,
        allUsers: accounts,
        isSessionActive: true,
      );
    } catch (error) {
      return SessionState(
        allUsers: accounts,
        error: 'Error initializing: $error',
      );
    }
  }

  SessionEntryKind consumeEntryKind() {
    final current = _requireState();
    final entryKind = current.entryKind;
    if (entryKind != SessionEntryKind.existing) {
      state = AsyncData(
        current.copyWith(entryKind: SessionEntryKind.existing),
      );
    }
    return entryKind;
  }

  void clearNeedsDataReload() {
    final current = state.valueOrNull;
    if (current == null || !current.needsDataReload) return;
    state = AsyncData(current.copyWith(needsDataReload: false));
  }

  Future<bool> continueLocally() {
    return _serialize(() async {
      final previous = _requireState();
      state = const AsyncLoading();

      try {
        final localUsers =
            previous.allUsers.where((user) => !user.isCloudLinked).toList()
              ..sort((left, right) {
                return right.lastLogin.compareTo(left.lastLogin);
              });

        if (localUsers.isNotEmpty) {
          final next = await _activateUser(
            previous,
            localUsers.first,
            entryKind: SessionEntryKind.existing,
          );
          state = AsyncData(next);
          return true;
        }

        final now = _clock();
        final user = LocalUser(
          id: _uuid(),
          username: 'Mi espacio',
          createdAt: now,
          lastLogin: now,
        );
        final accounts = [...previous.allUsers, user];
        await _accountRepository.saveAccounts(accounts);

        final profile = UserProfile(
          id: user.id,
          name: user.username,
          createdAt: now,
        );
        await _accountRepository.saveProfile(user.id, profile.toJson());
        await _accountRepository.saveCurrentProfile(profile.toJson());
        await _markProfileSetupPending(user.id);

        final next = await _activateUser(
          previous.copyWith(allUsers: accounts),
          user,
          entryKind: SessionEntryKind.newLocal,
        );
        state = AsyncData(next);
        return true;
      } catch (error) {
        state = AsyncData(
          previous.copyWith(
            error: 'No pudimos crear tu espacio local: $error',
            isSessionActive: false,
          ),
        );
        return false;
      }
    });
  }

  Future<bool> signInWithCloud(CloudAuthProvider provider) async {
    if (!_cloudRuntimeEnabled) {
      _updateError(
        'La cuenta en línea volverá cuando Zentra local esté completa.',
      );
      return false;
    }
    final gateway = _cloudAuthGateway;
    if (gateway == null) {
      _updateError(
        'La cuenta en línea no está configurada en esta versión de Zentra.',
      );
      return false;
    }

    clearError();
    final currentUser = state.valueOrNull?.currentUser;
    _pendingCloudSourceOwnerId =
        currentUser?.isCloudLinked == false ? currentUser?.id : null;
    try {
      await gateway.signIn(provider);
      return true;
    } catch (error) {
      _pendingCloudSourceOwnerId = null;
      _updateError('No pudimos abrir el acceso en línea: ${_message(error)}');
      return false;
    }
  }

  Future<CloudLinkPreview?> previewCloudLink() async {
    if (!_cloudRuntimeEnabled) return null;
    final currentUser = state.valueOrNull?.currentUser;
    final loader = _loadCloudLinkPreview;
    if (currentUser == null || currentUser.isCloudLinked || loader == null) {
      return null;
    }
    return loader(currentUser.id);
  }

  Future<void> applyCloudIdentity(CloudIdentity? identity) {
    return _serialize(() async {
      if (!_cloudRuntimeEnabled) return;
      final current = _requireState();
      if (identity == null) {
        final currentUser = current.currentUser;
        if (currentUser?.isCloudLinked != true) return;
        await _deactivateCloudWorkspace(currentUser!.id);
        await _accountRepository.clearActiveSession();
        state = AsyncData(
          current.copyWith(
            currentUser: null,
            error: null,
            isSessionActive: false,
            entryKind: SessionEntryKind.existing,
          ),
        );
        return;
      }
      if (current.isSessionActive &&
          current.currentUser?.isCloudLinked == true &&
          current.currentUser?.id == identity.userId) {
        return;
      }

      try {
        final sourceOwnerId = _pendingCloudSourceOwnerId;
        await _activateCloudWorkspace(identity.userId, sourceOwnerId);
        _pendingCloudSourceOwnerId = null;
        final next = await _activateCloudIdentity(
          current,
          identity,
          sourceOwnerId: sourceOwnerId,
        );
        state = AsyncData(next);
      } catch (error) {
        _pendingCloudSourceOwnerId = null;
        await _deactivateCloudWorkspace(identity.userId);
        await _cloudAuthGateway?.signOut();
        state = AsyncData(
          current.copyWith(
            error: 'No pudimos preparar la sincronización: ${_message(error)}',
          ),
        );
      }
    });
  }

  Future<void> logout() {
    return _serialize(() async {
      final current = _requireState();
      if (current.currentUser?.isCloudLinked == true) {
        final ownerId = current.currentUser!.id;
        final gateway = _cloudAuthGateway;
        if (_cloudRuntimeEnabled && gateway != null) {
          await gateway.signOut();
        }
        await _deactivateCloudWorkspace(ownerId);
      }
      await _accountRepository.clearActiveSession();
      state = AsyncData(
        current.copyWith(
          currentUser: null,
          error: null,
          isSessionActive: false,
          entryKind: SessionEntryKind.existing,
        ),
      );
    });
  }

  Future<void> updateProfile({
    String? username,
    String? avatarEmoji,
  }) {
    return _serialize(() async {
      final current = _requireState();
      final currentUser = current.currentUser;
      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        username: username,
        avatarEmoji: avatarEmoji,
      );
      final accounts = [...current.allUsers];
      final index = accounts.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        accounts[index] = updatedUser;
        await _accountRepository.saveAccounts(accounts);
      }
      await _accountRepository.saveCurrentAccount(updatedUser);
      state = AsyncData(
        current.copyWith(
          currentUser: updatedUser,
          allUsers: accounts,
        ),
      );
    });
  }

  Future<String?> exportBackup({required String passphrase}) async {
    final current = _requireState();
    try {
      return await _backupService.exportBackup(
        userId: current.currentUser?.id,
        passphrase: passphrase,
      );
    } catch (error) {
      _updateError('Error al exportar: $error');
      return null;
    }
  }

  Future<BackupData?> selectBackup({
    required String passphrase,
    String? jsonData,
  }) async {
    clearError();
    try {
      return await _backupService.selectBackup(
        jsonData: jsonData,
        passphrase: passphrase,
      );
    } catch (error) {
      _updateError('No pudimos leer este respaldo: $error');
      return null;
    }
  }

  Future<bool> restoreBackup(
    BackupData backupData, {
    bool preserveCurrentUser = false,
  }) {
    return _serialize(() async {
      final current = _requireState();
      try {
        final result = await _backupService.restoreBackup(
          backupData,
          currentUser: current.currentUser,
          accounts: current.allUsers,
          preserveCurrentUser: preserveCurrentUser,
        );
        state = AsyncData(
          current.copyWith(
            currentUser: result.currentUser,
            allUsers: result.accounts,
            isSessionActive: true,
            needsDataReload: true,
            entryKind: result.restoredAccount
                ? SessionEntryKind.restored
                : current.entryKind,
          ),
        );
        return true;
      } catch (error) {
        state = AsyncData(
          current.copyWith(error: 'Error al importar: $error'),
        );
        return false;
      }
    });
  }

  Future<bool?> importBackup({
    required String passphrase,
    String? jsonData,
    bool preserveCurrentUser = false,
  }) async {
    final backupData = await selectBackup(
      jsonData: jsonData,
      passphrase: passphrase,
    );
    if (backupData == null) {
      return state.valueOrNull?.error == null ? null : false;
    }
    return restoreBackup(
      backupData,
      preserveCurrentUser: preserveCurrentUser,
    );
  }

  Future<void> deleteAccount() => deleteLocalWorkspace();

  /// Deletes only the current device workspace.
  ///
  /// Remote identity deletion is deliberately outside the active product
  /// while cloud support is parked.
  Future<void> deleteLocalWorkspace() {
    return _serialize(() async {
      final current = _requireState();
      final currentUser = current.currentUser;
      if (currentUser == null) return;

      final userId = currentUser.id;
      if (currentUser.isCloudLinked) {
        await _deactivateCloudWorkspace(userId);
      }
      try {
        await _cleanupAccountNotifications().timeout(
          const Duration(seconds: 2),
        );
      } catch (error, stackTrace) {
        AppLogger().error(
          'SessionController',
          'Could not cancel notifications while deleting local workspace',
          error,
          stackTrace,
        );
      }

      final noteRepository = _noteRepository;
      if (noteRepository != null) {
        final previousOwnerId = noteRepository.currentUserId;
        noteRepository.setCurrentUser(userId);
        try {
          await noteRepository.deleteOwner();
        } finally {
          noteRepository.setCurrentUser(previousOwnerId);
        }
      }
      await _cleanupAccountLocalData(userId);

      final accounts = current.allUsers
          .where((user) => user.id != userId)
          .toList(growable: false);
      await _accountRepository.saveAccounts(accounts);
      await _accountRepository.deleteProfile(userId);

      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'habits_$userId',
        'habit_logs_$userId',
        'pomodoro_activities_$userId',
        'completed_tasks_$userId',
        'pomodoro_total_$userId',
        'pomodoro_today_$userId',
        'pomodoro_total_minutes_$userId',
        'pomodoro_today_minutes_$userId',
        'pomodoro_first_date_$userId',
        'pomodoro_last_date_$userId',
        'pomodoro_focus_progress_$userId',
        'pomodoro_active_session_$userId',
        'pomodoro_last_awarded_session_$userId',
        'pomodoro_work_duration_$userId',
        'pomodoro_short_break_duration_$userId',
        'pomodoro_long_break_duration_$userId',
        'pomodoro_alarm_$userId',
        'profile_setup_completed_$userId',
        'onboarding_completed_$userId',
      ]) {
        await prefs.remove(key);
      }

      await _accountRepository.clearCurrentAccount();
      for (final key in [
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
      ]) {
        await prefs.remove(key);
      }
      await _accountRepository.clearActiveSession();

      state = AsyncData(
        SessionState(
          allUsers: accounts,
          entryKind: SessionEntryKind.existing,
        ),
      );
    });
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null || current.error == null) return;
    state = AsyncData(current.copyWith(error: null));
  }

  Future<List<LocalUser>> _parkCloudAccounts(List<LocalUser> accounts) async {
    final parkedAt = _clock().toUtc();
    var changed = false;
    final parkedAccounts = accounts.map((account) {
      if (!account.isCloudLinked) return account;
      changed = true;
      return account.copyWith(
        remoteIdentityProvider: null,
        parkedRemoteIdentityProvider: account.remoteIdentityProvider,
        cloudParkedAt: parkedAt,
      );
    }).toList(growable: false);
    if (!changed) return accounts;

    await _accountRepository.saveAccounts(parkedAccounts);
    final currentAccount = await _accountRepository.loadCurrentAccount();
    if (currentAccount?.isCloudLinked == true) {
      final parkedCurrent = parkedAccounts
          .where((account) => account.id == currentAccount!.id)
          .firstOrNull;
      if (parkedCurrent != null) {
        await _accountRepository.saveCurrentAccount(parkedCurrent);
      }
    }
    return parkedAccounts;
  }

  Future<SessionState> _activateUser(
    SessionState current,
    LocalUser user, {
    required SessionEntryKind entryKind,
  }) async {
    final updatedUser = user.copyWith(lastLogin: _clock());
    final accounts = [...current.allUsers];
    final userIndex = accounts.indexWhere((item) => item.id == user.id);
    if (userIndex == -1) {
      accounts.add(updatedUser);
    } else {
      accounts[userIndex] = updatedUser;
    }
    await _accountRepository.saveAccounts(accounts);
    await _accountRepository.saveCurrentAccount(updatedUser);
    await _accountRepository.copyProfileToCurrent(updatedUser.id);
    await _accountRepository.saveActiveSessionUserId(updatedUser.id);
    return current.copyWith(
      currentUser: updatedUser,
      allUsers: accounts,
      error: null,
      isSessionActive: true,
      entryKind: entryKind,
    );
  }

  Future<SessionState> _activateCloudIdentity(
    SessionState current,
    CloudIdentity identity, {
    String? sourceOwnerId,
  }) async {
    final now = _clock();
    final accounts = [...current.allUsers];
    final userIndex = accounts.indexWhere(
      (account) => account.id == identity.userId,
    );
    final existing = userIndex == -1 ? null : accounts[userIndex];
    final user = LocalUser(
      id: identity.userId,
      username: existing?.username ?? identity.displayName,
      email: identity.email,
      avatarEmoji: existing?.avatarEmoji,
      remoteIdentityProvider: identity.provider,
      createdAt: existing?.createdAt ?? now,
      lastLogin: now,
    );
    if (userIndex == -1) {
      accounts.add(user);
    } else {
      accounts[userIndex] = user;
    }

    await _accountRepository.saveAccounts(accounts);
    await _accountRepository.saveCurrentAccount(user);
    final existingProfile = await _accountRepository.loadProfile(user.id);
    if (existingProfile == null) {
      final profile = UserProfile(
        id: user.id,
        name: user.username,
        avatarEmoji: user.avatarEmoji,
        createdAt: now,
      );
      await _accountRepository.saveProfile(user.id, profile.toJson());
    }
    if (existing == null) {
      await _initializeCloudFirstRunState(
        userId: user.id,
        sourceOwnerId: sourceOwnerId,
        hasExistingProfile: existingProfile != null,
      );
    }
    await _accountRepository.copyProfileToCurrent(user.id);
    await _accountRepository.saveActiveSessionUserId(user.id);

    return current.copyWith(
      currentUser: user,
      allUsers: accounts,
      error: null,
      isSessionActive: true,
      entryKind: existing == null
          ? SessionEntryKind.newLocal
          : SessionEntryKind.existing,
    );
  }

  Future<void> _markProfileSetupPending(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_completed_$userId', false);
  }

  Future<void> _initializeCloudFirstRunState({
    required String userId,
    required String? sourceOwnerId,
    required bool hasExistingProfile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (sourceOwnerId != null) {
      final sourceProfileCompleted =
          prefs.getBool('profile_setup_completed_$sourceOwnerId') ?? true;
      final sourceOnboardingCompleted =
          prefs.getBool('onboarding_completed_$sourceOwnerId') ??
              prefs.getBool('onboarding_completed') ??
              true;
      await prefs.setBool(
        'profile_setup_completed_$userId',
        sourceProfileCompleted,
      );
      await prefs.setBool(
        'onboarding_completed_$userId',
        sourceOnboardingCompleted,
      );
      return;
    }

    if (hasExistingProfile) {
      final profileKey = 'profile_setup_completed_$userId';
      final onboardingKey = 'onboarding_completed_$userId';
      if (!prefs.containsKey(profileKey)) {
        await prefs.setBool(profileKey, true);
      }
      if (!prefs.containsKey(onboardingKey)) {
        await prefs.setBool(onboardingKey, true);
      }
      return;
    }

    await _markProfileSetupPending(userId);
  }

  SessionState _requireState() {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('La sesión todavía se está inicializando.');
    }
    return current;
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _mutationQueue = _mutationQueue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _updateError(String message) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(error: message));
  }

  String _message(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }
}
