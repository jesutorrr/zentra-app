import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/note_repository.dart';
import 'package:zentra/domain/profile_repository.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/quick_actions_service.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/main.dart';
import 'package:zentra/presentation/auth_screen.dart';
import 'package:zentra/presentation/habit_form_screen.dart';
import 'package:zentra/presentation/onboarding_screen.dart';
import 'package:zentra/presentation/splash_screen.dart';
import 'package:zentra/presentation/today_screen.dart';
import 'package:zentra/presentation/widgets/tooltip_overlay.dart';

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

PomodoroEngine _testPomodoroEngineFactory({
  required String ownerId,
  required VoidCallback onChanged,
}) {
  return _TestPomodoroEngine(
    ownerId: ownerId,
    onChanged: onChanged,
  );
}

PomodoroEngine _hangingCleanupPomodoroEngineFactory({
  required String ownerId,
  required VoidCallback onChanged,
}) {
  return _HangingCleanupPomodoroEngine(
    ownerId: ownerId,
    onChanged: onChanged,
  );
}

class _TestPomodoroEngine extends PomodoroEngine {
  _TestPomodoroEngine({
    required String ownerId,
    required super.onChanged,
  }) : super(initialUserId: ownerId);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> retryPendingNoteReviews() async {}

  @override
  Future<void> cleanupStaleNotifications() async {}

  @override
  Future<void> shutdown() async {}
}

class _HangingCleanupPomodoroEngine extends _TestPomodoroEngine {
  _HangingCleanupPomodoroEngine({
    required super.ownerId,
    required super.onChanged,
  });

  @override
  Future<void> cleanupStaleNotifications() => Completer<void>().future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const foregroundChannel = MethodChannel('flutter_foreground_task/methods');
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TooltipKeys.fabNewHabit: true,
      TooltipKeys.pomodoroButton: true,
      TooltipKeys.habitCard: true,
    });
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      foregroundChannel,
      (call) async => call.method == 'isRunningService' ? false : null,
    );
    messenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async => null,
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(foregroundChannel, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
  });

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 30,
  }) async {
    for (var attempt = 0; attempt < maxPumps; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .where((text) => text.isNotEmpty)
        .toSet()
        .toList(growable: false);
    fail(
      'Widget not found after ${maxPumps * 100} ms: $finder. '
      'Visible texts: $visibleTexts',
    );
  }

  testWidgets(
    'fresh local entry completes profile before onboarding and Today',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final noteDatabase = ZentraDatabase(NativeDatabase.memory());
      final noteRepository = DriftNoteRepository(noteDatabase);
      final quickActionsService = QuickActionsService();
      addTearDown(noteDatabase.close);

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            habitRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => LocalStorageRepository.forOwner(
                prefs,
                ownerId: ownerId,
              ),
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesCompletedTaskRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesProfileRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            noteRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => DriftNoteRepository.forOwner(
                noteDatabase,
                ownerId: ownerId,
              ),
            ),
            sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
            pomodoroEngineFactoryProvider.overrideWithValue(
              _testPomodoroEngineFactory,
            ),
          ],
          child: ZentraApp(
            quickActionsService: quickActionsService,
          ),
        ),
      );

      final localEntry = find.text('Usar en este dispositivo');
      await pumpUntilFound(tester, localEntry);
      await tester.ensureVisible(localEntry);
      await tester.pump();
      await tester.tap(localEntry);
      final continueEntry = find.byKey(const ValueKey('auth-continue'));
      await tester.ensureVisible(continueEntry);
      await tester.tap(continueEntry);

      await pumpUntilFound(tester, find.text('Tu perfil'));
      expect(find.text('Tu primer hábito'), findsNothing);
      expect(find.byType(TodayScreen), findsNothing);
      final sessionAtProfile = riverpod.ProviderScope.containerOf(
        tester.element(find.text('Tu perfil')),
      ).read(sessionControllerProvider).valueOrNull;
      expect(
        prefs.getBool(
          'profile_setup_completed_${sessionAtProfile!.currentUser!.id}',
        ),
        isFalse,
      );
      quickActionsService.onActionSelected!(
        QuickActionsService.newHabitAction,
      );
      await tester.pumpAndSettle();
      expect(find.byType(HabitFormScreen), findsNothing);
      expect(find.text('Tu perfil'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('profile-setup-name')),
        'Uri',
      );
      await tester.tap(
        find.byKey(const ValueKey('profile-setup-continue')),
      );

      await pumpUntilFound(tester, find.byType(OnboardingScreen));
      expect(find.text('Hazlo tuyo'), findsNothing);
      expect(find.text('Tu primer hábito'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byType(TodayScreen), findsNothing);

      await tester.tap(find.text('Saltar'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('onboarding-morning-reminder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding-evening-reminder')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding-primary-action')),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-primary-action')));
      await pumpUntilFound(tester, find.byType(TodayScreen));

      final container = riverpod.ProviderScope.containerOf(
        tester.element(find.byType(TodayScreen)),
      );
      final currentUser =
          container.read(sessionControllerProvider).valueOrNull?.currentUser;
      expect(
        prefs.getBool(
          'profile_setup_completed_${currentUser!.id}',
        ),
        isTrue,
      );
      expect(
        prefs.getBool(
          'onboarding_completed_${currentUser.id}',
        ),
        isTrue,
      );

      await container.read(sessionControllerProvider.notifier).logout();
      await pumpUntilFound(tester, find.byType(AuthScreen));
      await tester.tap(find.text('Usar en este dispositivo'));
      await tester.tap(find.byKey(const ValueKey('auth-continue')));
      await pumpUntilFound(
        tester,
        find.byType(TodayScreen),
        maxPumps: 60,
      );
      final reopenedSession =
          container.read(sessionControllerProvider).valueOrNull;
      expect(reopenedSession?.currentUser?.id, currentUser.id);
      expect(reopenedSession?.allUsers, hasLength(1));
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'initial repository failure offers retry and a safe exit',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final noteDatabase = ZentraDatabase(NativeDatabase.memory());
      final noteRepository = DriftNoteRepository(noteDatabase);
      addTearDown(noteDatabase.close);

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            habitRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => LocalStorageRepository.forOwner(
                prefs,
                ownerId: ownerId,
              ),
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesCompletedTaskRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              _FailingProfileRepository.new,
            ),
            noteRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => DriftNoteRepository.forOwner(
                noteDatabase,
                ownerId: ownerId,
              ),
            ),
            sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
            pomodoroEngineFactoryProvider.overrideWithValue(
              _testPomodoroEngineFactory,
            ),
          ],
          child: ZentraApp(
            quickActionsService: QuickActionsService(),
          ),
        ),
      );

      final localEntry = find.text('Usar en este dispositivo');
      await pumpUntilFound(tester, localEntry);
      await tester.ensureVisible(localEntry);
      await tester.pump();
      await tester.tap(localEntry);
      final continueEntry = find.byKey(const ValueKey('auth-continue'));
      await tester.ensureVisible(continueEntry);
      await tester.tap(continueEntry);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('session-load-retry')),
      );

      expect(find.text('Tu espacio necesita otro intento'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-load-exit')),
        findsOneWidget,
      );
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(TodayScreen), findsNothing);
      await tester.tap(find.byKey(const ValueKey('session-load-exit')));
      await pumpUntilFound(tester, find.byType(AuthScreen));
      expect(find.text('Usar en este dispositivo'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    },
  );

  testWidgets(
    'retry recovers after a first-load error and a stuck platform cleanup',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final noteDatabase = ZentraDatabase(NativeDatabase.memory());
      final noteRepository = DriftNoteRepository(noteDatabase);
      final profiles = <String, _FailOnceProfileRepository>{};
      addTearDown(noteDatabase.close);

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            habitRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => LocalStorageRepository.forOwner(
                prefs,
                ownerId: ownerId,
              ),
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesCompletedTaskRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => profiles.putIfAbsent(
                ownerId,
                () => _FailOnceProfileRepository(ownerId),
              ),
            ),
            noteRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => DriftNoteRepository.forOwner(
                noteDatabase,
                ownerId: ownerId,
              ),
            ),
            sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
            pomodoroEngineFactoryProvider.overrideWithValue(
              _hangingCleanupPomodoroEngineFactory,
            ),
          ],
          child: ZentraApp(
            quickActionsService: QuickActionsService(),
          ),
        ),
      );

      final localEntry = find.text('Usar en este dispositivo');
      await pumpUntilFound(tester, localEntry);
      await tester.tap(localEntry);
      await tester.tap(find.byKey(const ValueKey('auth-continue')));
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('session-load-retry')),
      );

      await tester.tap(find.byKey(const ValueKey('session-load-retry')));
      await pumpUntilFound(
        tester,
        find.text('Tu perfil'),
        maxPumps: 60,
      );

      expect(profiles.values.single.loadCalls, 2);
      expect(find.text('Tu espacio necesita otro intento'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 600));
    },
  );

  testWidgets(
    'a stuck workspace preparation reaches the recoverable error screen',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final noteDatabase = ZentraDatabase(NativeDatabase.memory());
      final noteRepository = DriftNoteRepository(noteDatabase);
      addTearDown(noteDatabase.close);

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            habitRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => LocalStorageRepository.forOwner(
                prefs,
                ownerId: ownerId,
              ),
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesCompletedTaskRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesProfileRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            noteRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => DriftNoteRepository.forOwner(
                noteDatabase,
                ownerId: ownerId,
              ),
            ),
            sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
            pomodoroEngineFactoryProvider.overrideWithValue(
              _testPomodoroEngineFactory,
            ),
          ],
          child: ZentraApp(
            quickActionsService: QuickActionsService(),
            sessionWorkspacePreparation: (
              _, {
              required isImporting,
            }) =>
                Completer<void>().future,
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('Usar en este dispositivo'));
      await tester.tap(find.text('Usar en este dispositivo'));
      await tester.tap(find.byKey(const ValueKey('auth-continue')));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      await tester.pump();

      expect(find.text('Tu espacio necesita otro intento'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-load-retry')),
        findsOneWidget,
      );
      expect(find.byType(SplashScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
    },
  );

  testWidgets(
    'restored session stays on Splash and enters Today without auth or onboarding',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final prefs = await SharedPreferences.getInstance();
      final noteRepository = _MemoryNoteRepository('restored-owner');
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();

      await tester.pumpWidget(
        riverpod.ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(
              _RestoredSessionController.new,
            ),
            habitRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => LocalStorageRepository.forOwner(
                prefs,
                ownerId: ownerId,
              ),
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesCompletedTaskRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (ownerId) => SharedPreferencesProfileRepository(
                prefs,
                ownerId: ownerId,
              ),
            ),
            noteRepositoryFactoryProvider.overrideWithValue(
              (ownerId) {
                expect(ownerId, noteRepository.currentUserId);
                return noteRepository;
              },
            ),
            sessionNoteRepositoryProvider.overrideWithValue(noteRepository),
            pomodoroEngineFactoryProvider.overrideWithValue(
              _testPomodoroEngineFactory,
            ),
          ],
          child: ZentraApp(
            quickActionsService: QuickActionsService(),
            sessionWorkspacePreparation: (
              ownerId, {
              required isImporting,
            }) async {
              expect(ownerId, 'restored-owner');
              expect(isImporting, isTrue);
              if (!preparationStarted.isCompleted) {
                preparationStarted.complete();
              }
              await releasePreparation.future;
            },
          ),
        ),
      );

      for (var attempt = 0;
          attempt < 30 && !preparationStarted.isCompleted;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(preparationStarted.isCompleted, isTrue);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(TodayScreen), findsNothing);

      final container = riverpod.ProviderScope.containerOf(
        tester.element(find.byType(SplashScreen)),
      );
      final sessionController =
          container.read(sessionControllerProvider.notifier)
              as _RestoredSessionController;
      releasePreparation.complete();
      await tester.runAsync(() async {
        await sessionController.entryConsumed.future.timeout(
          const Duration(seconds: 10),
        );
      });
      await pumpUntilFound(tester, find.byType(TodayScreen), maxPumps: 60);

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(
        prefs.getBool('onboarding_completed_restored-owner'),
        isTrue,
      );
      expect(
        prefs.getBool('profile_setup_completed_restored-owner'),
        isTrue,
      );

      final session = container.read(sessionControllerProvider).valueOrNull;
      expect(session?.entryKind, SessionEntryKind.existing);
      expect(session?.needsDataReload, isFalse);
      await tester.pump(const Duration(seconds: 2));
    },
  );
}

class _RestoredSessionController extends SessionController {
  final Completer<void> entryConsumed = Completer<void>();

  @override
  Future<SessionState> build() async {
    final now = DateTime(2026, 8, 3, 9);
    final user = LocalUser(
      id: 'restored-owner',
      username: 'Uri',
      createdAt: now,
      lastLogin: now,
    );
    return SessionState(
      currentUser: user,
      allUsers: [user],
      isSessionActive: true,
      needsDataReload: true,
      entryKind: SessionEntryKind.restored,
    );
  }

  @override
  SessionEntryKind consumeEntryKind() {
    final result = super.consumeEntryKind();
    if (!entryConsumed.isCompleted) entryConsumed.complete();
    return result;
  }
}

class _MemoryNoteRepository implements NoteRepository {
  final String ownerId;
  final List<Note> _notes = [];
  final Map<String, NoteReminder> _reminders = {};
  final List<NoteReview> _reviews = [];

  _MemoryNoteRepository(this.ownerId);

  @override
  String get currentUserId => ownerId;

  @override
  void setCurrentUser(String? userId) {
    if (userId != ownerId) throw StateError('Unexpected owner: $userId');
  }

  @override
  Future<List<Note>> getNotes({bool includeArchived = false}) async => _notes;

  @override
  Future<Note?> getNote(String noteId) async =>
      _notes.where((note) => note.id == noteId).firstOrNull;

  @override
  Future<void> upsertNote(Note note) async {
    final index = _notes.indexWhere((current) => current.id == note.id);
    if (index < 0) {
      _notes.add(note);
    } else {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    _reminders.remove(noteId);
    _reviews.removeWhere((review) => review.noteId == noteId);
  }

  @override
  Future<List<Note>> searchNotes(
    String query, {
    bool includeArchived = false,
  }) async =>
      _notes;

  @override
  Future<NoteReminder?> getReminderForNote(String noteId) async =>
      _reminders[noteId];

  @override
  Future<List<NoteReminder>> getScheduledReminders({
    DateTime? throughUtc,
  }) async =>
      _reminders.values.toList();

  @override
  Future<void> upsertReminder(NoteReminder reminder) async {
    _reminders[reminder.noteId] = reminder;
  }

  @override
  Future<void> deleteReminderForNote(String noteId) async {
    _reminders.remove(noteId);
  }

  @override
  Future<List<NoteReview>> getReviewsForNote(String noteId) async =>
      _reviews.where((review) => review.noteId == noteId).toList();

  @override
  Future<void> addReview(NoteReview review) async {
    _reviews.add(review);
  }

  @override
  Future<NoteOwnerSnapshot> exportOwner() async => NoteOwnerSnapshot(
        ownerId: ownerId,
        exportedAt: DateTime(2026, 8, 3),
        notes: _notes,
        reminders: _reminders.values.toList(),
        reviews: _reviews,
      );

  @override
  Future<void> importOwner(
    NoteOwnerSnapshot snapshot, {
    bool replaceExisting = true,
  }) async {}

  @override
  Future<void> deleteOwner() async {
    _notes.clear();
    _reminders.clear();
    _reviews.clear();
  }
}

class _FailingProfileRepository implements ProfileRepository {
  @override
  final String ownerId;

  _FailingProfileRepository(this.ownerId);

  @override
  Future<void> deleteProfile() async {}

  @override
  Future<UserProfile?> loadProfile() {
    throw StateError('profile unavailable');
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {}
}

class _FailOnceProfileRepository implements ProfileRepository {
  @override
  final String ownerId;

  int loadCalls = 0;

  _FailOnceProfileRepository(this.ownerId);

  @override
  Future<void> deleteProfile() async {}

  @override
  Future<UserProfile?> loadProfile() async {
    loadCalls += 1;
    if (loadCalls == 1) {
      throw StateError('profile temporarily unavailable');
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {}
}
