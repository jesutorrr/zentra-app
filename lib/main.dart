import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'application/habit_controller.dart';
import 'application/note_controller.dart';
import 'application/pomodoro_provider.dart';
import 'application/profile_controller.dart';
import 'application/progress_sync.dart';
import 'application/session_controller.dart';
import 'application/sync_coordinator.dart';
import 'application/theme_provider.dart';
import 'domain/notification_intent.dart';
import 'domain/sync/sync.dart';
import 'infrastructure/app_logger.dart';
import 'infrastructure/database/zentra_database.dart';
import 'infrastructure/cloud_runtime_policy.dart';
import 'infrastructure/drift_note_repository.dart';
import 'infrastructure/local_persistence_runtime.dart';
import 'infrastructure/notification_service.dart';
import 'infrastructure/quick_actions_service.dart';
import 'infrastructure/secure_supabase_storage.dart';
import 'infrastructure/supabase_bootstrap.dart';
import 'presentation/theme.dart';
import 'presentation/today_screen.dart';
import 'presentation/auth_screen.dart';
import 'presentation/splash_screen.dart';
import 'presentation/habit_form_screen.dart';
import 'presentation/pomodoro_screen.dart';
import 'presentation/progress_screen.dart';
import 'presentation/note_surface.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/profile_setup_screen.dart';
import 'presentation/session_load_failure_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Spanish locale
  await initializeDateFormatting('es', null);

  final preferences = await SharedPreferences.getInstance();
  const cloudRuntimePolicy = CloudRuntimePolicy.current;
  final supabaseBootstrap = await bootstrapSupabase(
    runtimePolicy: cloudRuntimePolicy,
  );
  final localDatabase = ZentraDatabase(driftDatabase(name: 'zentra_notes'));
  final persistence = LocalPersistenceRuntime(
    preferences: preferences,
    database: localDatabase,
    cloudSyncAllowed: cloudRuntimePolicy.enabled,
  );
  await persistence.initialize();
  if (cloudRuntimePolicy.isParked) {
    try {
      await parkSupabaseSession();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CloudParking] Could not clear cached session: $error');
      }
    }
  }
  final noteRepository = DriftNoteRepository(localDatabase);
  final syncCoordinators = <String, SyncCoordinator>{};

  SyncCoordinator coordinatorFor(String ownerId) {
    return syncCoordinators.putIfAbsent(ownerId, () {
      final transport = supabaseBootstrap.syncTransport;
      if (transport == null) {
        throw StateError('Supabase sync is not configured.');
      }
      late final SyncCoordinator coordinator;
      coordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: persistence.syncWorkspaceFor(ownerId),
        transport: transport,
        remoteChanges: transport is SyncWakeSignalSource
            ? (transport as SyncWakeSignalSource)
                .watchRemoteChanges(ownerId: ownerId)
            : null,
      );
      persistence.registerSyncCallback(ownerId, coordinator.scheduleSync);
      return coordinator;
    });
  }

  Future<void> disposeCoordinator(String ownerId) async {
    persistence.unregisterSyncCallback(ownerId);
    await syncCoordinators.remove(ownerId)?.dispose();
  }

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Resolve the persisted theme before mounting the app to avoid a theme flash.
  final initialThemeMode = await loadSavedThemeMode();

  // Initialize Quick Actions service
  final quickActionsService = QuickActionsService();
  await quickActionsService.initialize();

  runApp(
    riverpod.ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        accountRepositoryProvider.overrideWithValue(
          persistence.accountRepository,
        ),
        cloudAuthGatewayProvider.overrideWithValue(
          supabaseBootstrap.authGateway,
        ),
        cloudAuthStartupErrorProvider.overrideWithValue(
          supabaseBootstrap.error,
        ),
        cloudRuntimeEnabledProvider.overrideWithValue(
          cloudRuntimePolicy.enabled,
        ),
        cloudWorkspaceActivationProvider.overrideWithValue((
          remoteOwnerId,
          sourceOwnerId,
        ) async {
          if (sourceOwnerId != null && sourceOwnerId != remoteOwnerId) {
            persistence.prepareCloudOwner(remoteOwnerId);
            await coordinatorFor(remoteOwnerId).syncNow();
            await persistence.migrateLocalOwnerToCloud(
              sourceOwnerId: sourceOwnerId,
              remoteOwnerId: remoteOwnerId,
            );
          } else {
            await persistence.enableCloudOwner(remoteOwnerId);
          }
          await coordinatorFor(remoteOwnerId).syncNow();
          final currentTheme = await loadSavedThemeMode();
          await persistence.ensurePortableTheme(
            remoteOwnerId,
            currentTheme.name,
          );
          await coordinatorFor(remoteOwnerId).syncNow();
        }),
        cloudWorkspaceDeactivationProvider.overrideWithValue(
          disposeCoordinator,
        ),
        cloudLinkPreviewLoaderProvider.overrideWithValue(
          persistence.previewCloudLink,
        ),
        syncCoordinatorFactoryProvider.overrideWithValue(
          supabaseBootstrap.syncTransport == null ? null : coordinatorFor,
        ),
        coreOwnerStoreProvider.overrideWithValue(persistence),
        accountLocalDataCleanupProvider.overrideWithValue(
          persistence.deleteOwner,
        ),
        noteRepositoryFactoryProvider.overrideWithValue(
          persistence.noteRepositoryFor,
        ),
        portablePreferencesRepositoryFactoryProvider.overrideWithValue(
          persistence.portablePreferencesRepositoryFor,
        ),
        noteNotificationServiceProvider.overrideWithValue(
          notificationService,
        ),
        sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
        habitRepositoryFactoryProvider.overrideWithValue(
          persistence.habitRepositoryFor,
        ),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          persistence.completedTaskRepositoryFor,
        ),
        profileRepositoryFactoryProvider.overrideWithValue(
          persistence.profileRepositoryFor,
        ),
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required String ownerId,
            required VoidCallback onChanged,
          }) {
            return PomodoroEngine(
              initialUserId: ownerId,
              focusRepository: persistence.focusRepositoryFor(ownerId),
              onChanged: onChanged,
            );
          },
        ),
      ],
      child: ZentraApp(
        quickActionsService: quickActionsService,
      ),
    ),
  );
}

class ZentraApp extends riverpod.ConsumerWidget {
  final QuickActionsService quickActionsService;
  final SessionWorkspacePreparation? sessionWorkspacePreparation;

  const ZentraApp({
    required this.quickActionsService,
    this.sessionWorkspacePreparation,
    super.key,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Zentra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.flutterThemeMode,
      home: AuthWrapper(
        quickActionsService: quickActionsService,
        sessionWorkspacePreparation: sessionWorkspacePreparation,
      ),
    );
  }
}

typedef SessionWorkspacePreparation = Future<void> Function(
  String userId, {
  required bool isImporting,
});

class _UserSessionReadiness {
  final bool profileSetupCompleted;
  final bool onboardingCompleted;

  const _UserSessionReadiness({
    required this.profileSetupCompleted,
    required this.onboardingCompleted,
  });
}

/// Wrapper that shows auth screen or main app based on auth state
class AuthWrapper extends riverpod.ConsumerStatefulWidget {
  final QuickActionsService quickActionsService;
  final SessionWorkspacePreparation? sessionWorkspacePreparation;

  const AuthWrapper({
    required this.quickActionsService,
    this.sessionWorkspacePreparation,
    super.key,
  });

  @override
  riverpod.ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends riverpod.ConsumerState<AuthWrapper>
    with WidgetsBindingObserver {
  String? _lastUserId;
  String? _loadingUserId;
  String? _pendingHabitId;
  String? _pendingNoteId;
  String? _deferredQuickAction;
  bool _pendingPomodoroNavigation = false;
  String? _sessionLoadError;
  String? _sessionLoadErrorUserId;
  bool? _profileSetupCompleted;
  bool? _onboardingCompleted;
  Future<void> _sessionPreparationQueue = Future<void>.value();
  int _sessionPreparationGeneration = 0;
  int? _lastProgressFingerprint;
  bool _progressSyncScheduled = false;
  DateTime? _lastAppliedSuccessfulSyncAt;
  Future<void> _remoteRefreshQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    // Setup Quick Actions callback
    widget.quickActionsService.onActionSelected = _handleQuickAction;
    // Setup notification tap callback
    NotificationService.onNotificationTap = _handleNotificationTap;
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Check if app was launched from a notification
    _checkPendingNotification();
  }

  void _navigateToPomodoro() {
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider).valueOrNull;
    if (session?.isAuthenticated != true || !_canOpenAppDestinations) {
      _pendingPomodoroNavigation = true;
      return;
    }
    _pendingPomodoroNavigation = false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PomodoroScreen()),
      (route) => route.isFirst,
    );
  }

  void _openPendingPomodoro() {
    if (!_pendingPomodoroNavigation) return;
    _navigateToPomodoro();
  }

  void _checkPendingNotification() {
    // Check after a short delay to ensure navigation is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final payload = NotificationService.consumePendingNotificationPayload();
        if (payload != null) {
          _handleNotificationTap(payload);
        }
      });
    });
  }

  void _handleNotificationTap(String? payload) {
    final intent = ZentraNotificationIntent.tryDecode(payload);
    if (intent == null) return;

    if (intent.type == ZentraNotificationType.pomodoro) {
      _pendingPomodoroNavigation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openPendingPomodoro();
      });
    } else if (intent.type == ZentraNotificationType.habitReminder) {
      _pendingHabitId = intent.entityId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPendingHabit();
      });
    } else if (intent.type == ZentraNotificationType.noteReminder) {
      _pendingNoteId = intent.entityId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPendingNote();
      });
    }
  }

  void _openPendingHabit() {
    final habitId = _pendingHabitId;
    if (!mounted || habitId == null || !_canOpenAppDestinations) return;

    final session = ref.read(sessionControllerProvider).valueOrNull;
    final ownerId = ref.read(activeOwnerIdProvider);
    final habitState = ownerId == null
        ? null
        : ref.read(habitControllerProvider(ownerId)).valueOrNull;
    if (session?.isAuthenticated != true ||
        habitState?.getHabitById(habitId) == null) {
      return;
    }

    _pendingHabitId = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habitId: habitId),
      ),
      (route) => route.isFirst,
    );
  }

  void _openPendingNote() {
    final noteId = _pendingNoteId;
    if (!mounted || noteId == null || !_canOpenAppDestinations) return;

    final session = ref.read(sessionControllerProvider).valueOrNull;
    final ownerId = ref.read(activeOwnerIdProvider);
    if (session?.isAuthenticated != true || ownerId == null) return;

    final note =
        ref.read(noteControllerProvider(ownerId)).valueOrNull?.getNote(noteId);
    _pendingNoteId = null;
    if (note == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Esa nota ya no está disponible.'),
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => NoteSurface(noteId: noteId),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final ownerId = ref.read(activeOwnerIdProvider);
    if (ownerId == null) return;
    final pomodoroController =
        ref.read(pomodoroControllerProvider(ownerId).notifier);
    final habitController = ref.read(habitControllerProvider(ownerId).notifier);
    final noteController = ref.read(noteControllerProvider(ownerId).notifier);

    if (state == AppLifecycleState.resumed) {
      // App came to foreground - recalculate timer and clean up notifications
      await pomodoroController.setAppInForeground(true);
      await pomodoroController.onAppResumed();
      await pomodoroController.cleanupStaleNotifications();

      final notificationService = NotificationService();
      final timezoneChanged = await notificationService.refreshTimezone();
      if (await notificationService.isSystemNotificationPermissionGranted()) {
        final habitState =
            ref.read(habitControllerProvider(ownerId)).valueOrNull;
        if (habitState != null) {
          await notificationService.scheduleDailyReminders(
            snapshot: habitState.buildDailyReminderSnapshot(
              capturedAt: DateTime.now(),
            ),
          );
        }
        if (timezoneChanged) {
          await habitController.rescheduleHabitReminders();
          await noteController.rescheduleReminders();
        }
      }
      ref.read(syncCoordinatorFactoryProvider)?.call(ownerId).scheduleSync(
            debounce: Duration.zero,
          );
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background
      await pomodoroController.setAppInForeground(false);
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated - cancel notifications if timer not running
      if (ref.read(pomodoroControllerProvider(ownerId)).state !=
          PomodoroState.running) {
        unawaited(pomodoroController.cleanupStaleNotifications());
      }
    }
  }

  void _handleQuickAction(String action) {
    // Wait for context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_canOpenAppDestinations) {
        _deferredQuickAction = action;
        return;
      }

      switch (action) {
        case QuickActionsService.newHabitAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HabitFormScreen()),
          );
          break;
        case QuickActionsService.newNoteAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NoteSurface()),
          );
          break;
        case QuickActionsService.pomodoroAction:
          _pendingPomodoroNavigation = true;
          _openPendingPomodoro();
          break;
        case QuickActionsService.progressAction:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cloudIdentityChangesProvider, (_, next) {
      next.whenData((identity) {
        unawaited(
          ref
              .read(sessionControllerProvider.notifier)
              .applyCloudIdentity(identity),
        );
      });
    });
    final sessionAsync = ref.watch(sessionControllerProvider);
    final session = sessionAsync.valueOrNull;

    // Show splash screen while checking auth state.
    if (session == null) {
      return const SplashScreen();
    }

    // Show main app if authenticated.
    if (session.isAuthenticated) {
      final currentUserId = session.currentUser?.id;
      final needsReload = session.needsDataReload;
      if (currentUserId != null) {
        ref.listen(syncMachineStateProvider(currentUserId), (_, next) {
          next.whenData((syncState) {
            final successfulAt = syncState.lastSuccessfulSyncAt;
            if (successfulAt == null ||
                _lastAppliedSuccessfulSyncAt == successfulAt) {
              return;
            }
            _lastAppliedSuccessfulSyncAt = successfulAt;
            _scheduleRemoteWorkspaceRefresh(currentUserId);
          });
        });
        ref.listen(
          habitControllerProvider(currentUserId),
          (_, __) => _onProgressSourceChanged(currentUserId),
        );
        ref.listen(
          pomodoroControllerProvider(currentUserId),
          (_, __) => _onProgressSourceChanged(currentUserId),
        );
        ref.listen(
          noteControllerProvider(currentUserId),
          (_, __) {},
        );
      }
      if (_sessionLoadErrorUserId != null &&
          _sessionLoadErrorUserId != currentUserId) {
        _sessionLoadError = null;
        _sessionLoadErrorUserId = null;
      }

      // Load every provider for the active owner before exposing onboarding
      // or Today. This prevents a restored/new user from briefly seeing the
      // previous owner's data.
      if ((_lastUserId != currentUserId || needsReload) &&
          _loadingUserId != currentUserId &&
          _sessionLoadError == null &&
          currentUserId != null) {
        _scheduleUserSessionPreparation(
          currentUserId,
          entryKind: session.entryKind,
          isImporting: needsReload,
        );
      }

      if (_sessionLoadError != null && currentUserId != null) {
        return _buildSessionLoadFailure(session, currentUserId);
      }

      if (_lastUserId != currentUserId ||
          _profileSetupCompleted == null ||
          _onboardingCompleted == null) {
        return const SplashScreen();
      }

      if (_profileSetupCompleted == false) {
        final profile = ref
            .watch(profileControllerProvider(currentUserId!))
            .valueOrNull
            ?.profile;
        return ProfileSetupScreen(
          ownerId: currentUserId,
          initialProfile: profile,
          onBack: () => ref.read(sessionControllerProvider.notifier).logout(),
          onComplete: () => _completeProfileSetup(currentUserId),
        );
      }

      if (_onboardingCompleted == false) {
        return OnboardingScreen(
          userId: currentUserId!,
          onBack: () => ref.read(sessionControllerProvider.notifier).logout(),
          onComplete: () {
            setState(() => _onboardingCompleted = true);
            _schedulePendingDestinations();
          },
        );
      }

      return const TodayScreen();
    }

    // Reset last user on logout.
    if (_lastUserId != null ||
        _loadingUserId != null ||
        _sessionLoadError != null) {
      final previousOwnerId = _lastUserId ?? _loadingUserId;
      _sessionPreparationGeneration += 1;
      _lastUserId = null;
      _loadingUserId = null;
      _sessionLoadError = null;
      _sessionLoadErrorUserId = null;
      _profileSetupCompleted = null;
      _onboardingCompleted = null;
      _lastProgressFingerprint = null;
      _progressSyncScheduled = false;
      _lastAppliedSuccessfulSyncAt = null;
      if (previousOwnerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              ref.read(activeOwnerIdProvider) == previousOwnerId ||
              _lastUserId == previousOwnerId ||
              _loadingUserId == previousOwnerId) {
            return;
          }
          _disposeOwnerWorkspace(previousOwnerId);
        });
      }
    }
    return const AuthScreen();
  }

  void _scheduleUserSessionPreparation(
    String userId, {
    required SessionEntryKind entryKind,
    required bool isImporting,
    bool forceReload = false,
  }) {
    final generation = ++_sessionPreparationGeneration;
    _loadingUserId = userId;
    _profileSetupCompleted = null;
    _onboardingCompleted = null;

    _sessionPreparationQueue =
        _sessionPreparationQueue.catchError((_) {}).then((_) async {
      if (!mounted ||
          generation != _sessionPreparationGeneration ||
          ref.read(activeOwnerIdProvider) != userId) {
        return;
      }

      try {
        final previousOwnerId = _lastUserId;
        if (previousOwnerId != null && previousOwnerId != userId) {
          _disposeOwnerWorkspace(previousOwnerId);
          _lastProgressFingerprint = null;
          _lastAppliedSuccessfulSyncAt = null;
        }
        final prepared = await _prepareUserSession(
          userId,
          entryKind: entryKind,
          isImporting: isImporting,
          forceReload: forceReload,
        );
        if (!mounted ||
            generation != _sessionPreparationGeneration ||
            ref.read(activeOwnerIdProvider) != userId) {
          return;
        }

        ref.read(sessionControllerProvider.notifier).consumeEntryKind();
        if (isImporting) {
          ref.read(sessionControllerProvider.notifier).clearNeedsDataReload();
        }
        setState(() {
          _lastUserId = userId;
          _loadingUserId = null;
          _sessionLoadError = null;
          _sessionLoadErrorUserId = null;
          _profileSetupCompleted = prepared.profileSetupCompleted;
          _onboardingCompleted = prepared.onboardingCompleted;
        });
        _checkPendingQuickAction();
        _schedulePendingDestinations();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[SessionPreparation] Failed: $error\n$stackTrace',
          );
        }
        if (!mounted ||
            generation != _sessionPreparationGeneration ||
            ref.read(activeOwnerIdProvider) != userId) {
          return;
        }
        setState(() {
          _loadingUserId = null;
          _sessionLoadError =
              'No pudimos preparar tu espacio. Tus datos siguen seguros.';
          _sessionLoadErrorUserId = userId;
          _profileSetupCompleted = null;
          _onboardingCompleted = null;
        });
      }
    });
  }

  Future<_UserSessionReadiness> _prepareUserSession(
    String userId, {
    required SessionEntryKind entryKind,
    required bool isImporting,
    bool forceReload = false,
  }) async {
    final sessionWorkspacePreparation = widget.sessionWorkspacePreparation;
    late final Future<void> preparation;
    if (sessionWorkspacePreparation == null) {
      preparation = _loadUserData(
        userId,
        isImporting: isImporting,
        forceReload: forceReload,
      );
    } else {
      preparation = sessionWorkspacePreparation(
        userId,
        isImporting: isImporting,
      );
    }
    await preparation.timeout(const Duration(seconds: 12));

    final prefs = await SharedPreferences.getInstance();
    final profileSetupKey = 'profile_setup_completed_$userId';
    final userOnboardingKey = 'onboarding_completed_$userId';
    bool profileSetupCompleted;
    bool onboardingCompleted;

    switch (entryKind) {
      case SessionEntryKind.restored:
        profileSetupCompleted = true;
        onboardingCompleted = true;
        await prefs.setBool(profileSetupKey, true);
        await prefs.setBool(userOnboardingKey, true);
        break;
      case SessionEntryKind.newLocal:
        profileSetupCompleted = prefs.getBool(profileSetupKey) ?? false;
        onboardingCompleted = prefs.getBool(userOnboardingKey) ?? false;
        break;
      case SessionEntryKind.existing:
        profileSetupCompleted = prefs.getBool(profileSetupKey) ?? true;
        if (!prefs.containsKey(profileSetupKey)) {
          await prefs.setBool(profileSetupKey, true);
        }
        final storedForUser = prefs.getBool(userOnboardingKey);
        final legacyCompleted = prefs.getBool('onboarding_completed') ?? false;
        onboardingCompleted = storedForUser ?? legacyCompleted;
        if (storedForUser == null && legacyCompleted) {
          await prefs.setBool(userOnboardingKey, true);
        }
        break;
    }

    return _UserSessionReadiness(
      profileSetupCompleted: profileSetupCompleted,
      onboardingCompleted: onboardingCompleted,
    );
  }

  Future<void> _completeProfileSetup(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_completed_$userId', true);
    if (!mounted || ref.read(activeOwnerIdProvider) != userId) return;
    setState(() => _profileSetupCompleted = true);
    _schedulePendingDestinations();
  }

  Widget _buildSessionLoadFailure(
    SessionState session,
    String userId,
  ) {
    return SessionLoadFailureScreen(
      message: _sessionLoadError!,
      onRetry: () {
        _lastProgressFingerprint = null;
        _lastAppliedSuccessfulSyncAt = null;
        setState(() {
          _sessionLoadError = null;
          _sessionLoadErrorUserId = null;
        });
        _scheduleUserSessionPreparation(
          userId,
          entryKind: session.entryKind,
          isImporting: session.needsDataReload,
          forceReload: true,
        );
      },
      onExit: () async {
        await ref.read(sessionControllerProvider.notifier).logout();
        if (!mounted) return;
        setState(() {
          _sessionLoadError = null;
          _sessionLoadErrorUserId = null;
          _loadingUserId = null;
        });
      },
    );
  }

  void _checkPendingQuickAction() {
    final pending = widget.quickActionsService.pendingAction;
    if (pending != null) {
      widget.quickActionsService.clearPendingAction();
      _handleQuickAction(pending);
    }
  }

  bool get _canOpenAppDestinations =>
      _lastUserId != null &&
      _profileSetupCompleted == true &&
      _onboardingCompleted == true;

  void _schedulePendingDestinations() {
    if (!_canOpenAppDestinations) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canOpenAppDestinations) return;
      _openPendingHabit();
      _openPendingNote();
      _openPendingPomodoro();
      final quickAction = _deferredQuickAction;
      if (quickAction != null) {
        _deferredQuickAction = null;
        _handleQuickAction(quickAction);
      }
    });
  }

  /// Load all user-specific data
  Future<void> _loadUserData(
    String userId, {
    bool isImporting = false,
    bool forceReload = false,
  }) async {
    final habitController = ref.read(habitControllerProvider(userId).notifier);
    final profileController =
        ref.read(profileControllerProvider(userId).notifier);
    final noteController = ref.read(noteControllerProvider(userId).notifier);
    final pomodoroController =
        ref.read(pomodoroControllerProvider(userId).notifier);
    final notificationService = NotificationService();

    if (isImporting) {
      await notificationService.cancelAllNotifications();
      await Future.wait([
        habitController.reload(isImporting: true),
        profileController.reload(),
        noteController.reload(),
      ]);
    } else if (forceReload) {
      await Future.wait([
        habitController.reload(),
        profileController.reload(),
        noteController.reload(),
      ]);
    } else {
      await Future.wait([
        ref.read(habitControllerProvider(userId).future),
        ref.read(profileControllerProvider(userId).future),
        ref.read(noteControllerProvider(userId).future),
      ]);
    }

    final habitState = ref.read(habitControllerProvider(userId)).valueOrNull;
    final profileState =
        ref.read(profileControllerProvider(userId)).valueOrNull;
    final noteState = ref.read(noteControllerProvider(userId)).valueOrNull;
    if (habitState == null ||
        habitState.error != null ||
        profileState == null ||
        profileState.error != null ||
        noteState == null ||
        noteState.errorMessage != null) {
      throw StateError('One or more user data sources failed to load.');
    }

    pomodoroController.onLinkedNoteFocused = noteController.markFocusCompleted;
    await pomodoroController.initialize();
    if (await notificationService.isSystemNotificationPermissionGranted()) {
      if (isImporting) {
        await Future.wait([
          habitController.rescheduleHabitReminders(),
          noteController.rescheduleReminders(),
          notificationService.scheduleDailyReminders(
            snapshot: habitState.buildDailyReminderSnapshot(
              capturedAt: DateTime.now(),
            ),
          ),
        ]);
      } else {
        await noteController.rescheduleReminders();
      }
    }
    await pomodoroController.retryPendingNoteReviews();
    await _syncCurrentProgress(
      userId,
      announceUnlocks: false,
    );
    _lastProgressFingerprint = _progressFingerprint(userId);

    // Stale platform UI is non-critical. A wedged Live Activity or foreground
    // service must never keep the owner workspace behind Splash forever.
    try {
      await pomodoroController.cleanupStaleNotifications().timeout(
            const Duration(seconds: 2),
          );
    } catch (error, stackTrace) {
      AppLogger().error(
        'SessionPreparation',
        'Could not finish stale Pomodoro cleanup',
        error,
        stackTrace,
      );
    }
    _openPendingHabit();
    _openPendingNote();
    _openPendingPomodoro();
  }

  int? _progressFingerprint(String ownerId) {
    final habitState = ref.read(habitControllerProvider(ownerId)).valueOrNull;
    if (habitState == null) return null;
    final pomodoroState = ref.read(pomodoroControllerProvider(ownerId));
    return progressSourceFingerprintFromState(
      habitState: habitState,
      activityHistory: pomodoroState.activityHistory,
      totalPomodoros: pomodoroState.totalPomodoros,
      totalFocusMinutes: pomodoroState.totalMinutes,
    );
  }

  void _onProgressSourceChanged(String ownerId) {
    if (!mounted || ref.read(activeOwnerIdProvider) != ownerId) return;
    final fingerprint = _progressFingerprint(ownerId);
    if (fingerprint == null) return;
    if (_lastProgressFingerprint == fingerprint) return;
    _lastProgressFingerprint = fingerprint;
    if (_progressSyncScheduled) return;
    _progressSyncScheduled = true;
    scheduleMicrotask(() {
      _progressSyncScheduled = false;
      if (!mounted || ref.read(activeOwnerIdProvider) != ownerId) return;
      final habitState = ref.read(habitControllerProvider(ownerId)).valueOrNull;
      unawaited(
        _syncCurrentProgress(
          ownerId,
          announceUnlocks: habitState?.isImporting != true,
        ),
      );
    });
  }

  void _scheduleRemoteWorkspaceRefresh(String ownerId) {
    _remoteRefreshQueue =
        _remoteRefreshQueue.catchError((_) {}).then((_) async {
      // A cloud session can finish its first sync while the owner workspace is
      // still preparing. Let that initial load settle before refreshing the
      // already visible controllers.
      await Future<void>.delayed(Duration.zero);
      await _sessionPreparationQueue.catchError((_) {});
      if (!mounted ||
          ref.read(activeOwnerIdProvider) != ownerId ||
          _lastUserId != ownerId) {
        return;
      }

      final habitController =
          ref.read(habitControllerProvider(ownerId).notifier);
      final profileController =
          ref.read(profileControllerProvider(ownerId).notifier);
      final noteController = ref.read(noteControllerProvider(ownerId).notifier);
      final pomodoroController =
          ref.read(pomodoroControllerProvider(ownerId).notifier);

      await Future.wait([
        habitController.refreshAfterSync(),
        profileController.refreshAfterSync(),
        noteController.refreshAfterSync(),
        pomodoroController.refreshAfterSync(),
        ref.read(themeControllerProvider.notifier).refreshAfterSync(ownerId),
      ]);
      if (!mounted || ref.read(activeOwnerIdProvider) != ownerId) return;
      await noteController.rescheduleReminders();
      _onProgressSourceChanged(ownerId);
    });
  }

  Future<void> _syncCurrentProgress(
    String ownerId, {
    required bool announceUnlocks,
  }) async {
    final habitState = ref.read(habitControllerProvider(ownerId)).valueOrNull;
    final profileState =
        ref.read(profileControllerProvider(ownerId)).valueOrNull;
    if (habitState == null || profileState?.profile == null) return;
    final pomodoroState = ref.read(pomodoroControllerProvider(ownerId));
    await ref.read(profileControllerProvider(ownerId).notifier).syncProgress(
          snapshot: buildProgressSnapshotFromState(
            habitState: habitState,
            activityHistory: pomodoroState.activityHistory,
            totalPomodoros: pomodoroState.totalPomodoros,
            totalFocusMinutes: pomodoroState.totalMinutes,
            now: DateTime.now(),
          ),
          announceUnlocks: announceUnlocks,
        );
  }

  void _disposeOwnerWorkspace(String ownerId) {
    ref.invalidate(habitControllerProvider(ownerId));
    ref.invalidate(profileControllerProvider(ownerId));
    ref.invalidate(noteControllerProvider(ownerId));
    ref.invalidate(pomodoroControllerProvider(ownerId));
  }
}
