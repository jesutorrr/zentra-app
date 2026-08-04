import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/profile_repository.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/history_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _HistoryHarness {
  static const ownerId = 'history-owner';

  final ProviderContainer container;

  _HistoryHarness(
    SharedPreferences preferences, {
    HabitRepository? habitRepository,
    ProfileRepository? profileRepository,
  }) : container = ProviderContainer(
          overrides: [
            activeOwnerIdProvider.overrideWithValue(ownerId),
            habitRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return habitRepository ??
                    LocalStorageRepository.forOwner(
                      preferences,
                      ownerId: requestedOwner,
                    );
              },
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) => SharedPreferencesCompletedTaskRepository(
                preferences,
                ownerId: requestedOwner,
              ),
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return profileRepository ??
                    SharedPreferencesProfileRepository(
                      preferences,
                      ownerId: requestedOwner,
                    );
              },
            ),
          ],
        );

  Future<void> initialize() async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      profileControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(ownerId).future),
      container.read(profileControllerProvider(ownerId).future),
    ]);
  }

  List<CompletedTask> get completedTasks {
    return container
            .read(habitControllerProvider(ownerId))
            .valueOrNull
            ?.completedTasks ??
        const [];
  }

  UserProfile? get profile {
    return container
        .read(profileControllerProvider(ownerId))
        .valueOrNull
        ?.profile;
  }

  void dispose() => container.dispose();
}

class _BlockingHabitRepository implements HabitRepository {
  final String ownerId;
  final Completer<List<Habit>> habits = Completer<List<Habit>>();

  _BlockingHabitRepository(this.ownerId);

  @override
  void setCurrentUser(String? userId) {
    if (userId != ownerId) {
      throw StateError('Unexpected owner $userId');
    }
  }

  @override
  Future<List<Habit>> getHabits() => habits.future;

  @override
  Future<List<HabitLog>> getAllLogs() async => const [];

  @override
  Future<List<HabitLog>> getLogsForDate(DateTime date) async => const [];

  @override
  Future<void> saveHabit(Habit habit) async {}

  @override
  Future<void> updateHabit(Habit habit) async {}

  @override
  Future<void> deleteHabit(String habitId) async {}

  @override
  Future<void> toggleLog(String habitId, DateTime date) async {}
}

class _RetryProfileRepository implements ProfileRepository {
  @override
  final String ownerId;
  final UserProfile profile;
  int attempts = 0;

  _RetryProfileRepository({
    required this.ownerId,
    required this.profile,
  });

  @override
  Future<UserProfile?> loadProfile() async {
    attempts += 1;
    if (attempts == 1) throw StateError('temporary profile failure');
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> deleteProfile() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_HistoryHarness> seededProviders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final profile = UserProfile(
      id: 'profile-history',
      name: 'Uri',
      createdAt: today.subtract(const Duration(days: 90)),
      totalHabitsCompleted: 7,
      totalDaysActive: 2,
      longestStreak: 3,
      totalFocusMinutes: 45,
      dailyHabitCompletions: {
        ProgressEngine.dayKey(today): 2,
        ProgressEngine.dayKey(yesterday): 1,
      },
      dailyFocusSessions: {
        ProgressEngine.dayKey(today): 1,
      },
    );
    final archived = CompletedTask(
      id: 'task-water',
      title: 'Comprar botella',
      category: Category.agua,
      completedAt: today.add(const Duration(hours: 10)),
      wasOneTime: true,
    );

    SharedPreferences.setMockInitialValues({
      'user_profile_${_HistoryHarness.ownerId}': jsonEncode(profile.toJson()),
      'completed_tasks_${_HistoryHarness.ownerId}':
          jsonEncode([archived.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();
    final harness = _HistoryHarness(prefs);
    addTearDown(harness.dispose);
    await harness.initialize();
    return harness;
  }

  Future<_HistoryHarness> pumpHistory(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    final providers = await seededProviders();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providers.container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return providers;
  }

  testWidgets('separates durable activity from the disposable task archive',
      (tester) async {
    await pumpHistory(tester, size: const Size(390, 844));

    expect(find.text('Tu actividad'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('2 hábitos'), findsOneWidget);
    expect(find.text('1 enfoque'), findsOneWidget);
    expect(find.text('Archivo de tareas'), findsOneWidget);
    expect(find.text('Comprar botella'), findsOneWidget);
    expect(
      find.textContaining('Vaciar este archivo no afecta tu progreso'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing the archive keeps durable progress intact',
      (tester) async {
    final providers = await pumpHistory(
      tester,
      size: const Size(390, 844),
    );

    await tester.tap(
      find.byTooltip('Vaciar archivo de tareas'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Vaciar archivo'));
    await tester.pumpAndSettle();

    expect(providers.completedTasks, isEmpty);
    expect(
      providers.profile!.dailyHabitCompletions.values,
      containsAll([2, 1]),
    );
    expect(find.text('Comprar botella'), findsNothing);
    expect(find.text('2 hábitos'), findsOneWidget);
    expect(find.text('No hay tareas archivadas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses overview and timeline columns at expanded width',
      (tester) async {
    await pumpHistory(tester, size: const Size(834, 1194));

    final summary = find.byKey(const ValueKey('activity-history-summary'));
    final timeline = find.byKey(const ValueKey('activity-history-timeline'));
    expect(
      tester.getTopLeft(summary).dx,
      lessThan(tester.getTopLeft(timeline).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated activity supports 320 percent text on a 320px phone',
      (tester) async {
    await pumpHistory(
      tester,
      size: const Size(320, 568),
      textScale: 3.2,
    );

    expect(
      find.byKey(const ValueKey('activity_history_scroll')),
      findsOneWidget,
    );
    expect(find.text('Comprar botella'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows loading until the owner habit workspace is ready',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _BlockingHabitRepository(_HistoryHarness.ownerId);
    final harness = _HistoryHarness(
      preferences,
      habitRepository: repository,
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('activity-history-loading')),
      findsOneWidget,
    );
    expect(find.text('Tu historia empieza con una acción'), findsNothing);

    repository.habits.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('Tu historia empieza con una acción'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile error retries without discarding the task archive',
      (tester) async {
    final profile = UserProfile(
      id: 'profile-retry',
      name: 'Uri',
      createdAt: DateTime(2026, 7, 1),
      totalHabitsCompleted: 4,
    );
    final archived = CompletedTask(
      id: 'retry-task',
      title: 'Tarea conservada',
      category: Category.foco,
      completedAt: DateTime(2026, 7, 26),
      wasOneTime: true,
    );
    SharedPreferences.setMockInitialValues({
      'completed_tasks_${_HistoryHarness.ownerId}':
          jsonEncode([archived.toJson()]),
    });
    final preferences = await SharedPreferences.getInstance();
    final profileRepository = _RetryProfileRepository(
      ownerId: _HistoryHarness.ownerId,
      profile: profile,
    );
    final harness = _HistoryHarness(
      preferences,
      profileRepository: profileRepository,
    );
    addTearDown(harness.dispose);
    await harness.initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tu actividad'), findsOneWidget);
    final retry = find.text('Reintentar');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(profileRepository.attempts, 2);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Tarea conservada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
