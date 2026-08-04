import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/progress_screen.dart';
import 'package:zentra/presentation/theme.dart';

class _FakeHabitReminderService implements HabitReminderService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelHabitReminder(String habitId) async {}

  @override
  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    bool isOneTime = false,
    DateTime? scheduledDate,
  }) async {
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }
}

class _ProgressHarness {
  static const ownerId = 'progress-owner';

  final ProviderContainer container;

  _ProgressHarness(SharedPreferences preferences)
      : container = ProviderContainer(
          overrides: [
            activeOwnerIdProvider.overrideWithValue(ownerId),
            habitRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return LocalStorageRepository.forOwner(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            completedTaskRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return SharedPreferencesCompletedTaskRepository(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            profileRepositoryFactoryProvider.overrideWithValue(
              (requestedOwner) {
                expect(requestedOwner, ownerId);
                return SharedPreferencesProfileRepository(
                  preferences,
                  ownerId: requestedOwner,
                );
              },
            ),
            habitReminderServiceProvider.overrideWithValue(
              _FakeHabitReminderService(),
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
    final profile = container.read(profileControllerProvider(ownerId).notifier);
    await profile.createProfile(name: 'Uri');
    await profile.syncProgress(
      announceUnlocks: false,
      snapshot: ProgressSnapshot(
        habitEvents: [
          HabitProgressEvent(
            id: 'habit:water:2026-07-26',
            completedOn: DateTime(2026, 7, 26),
            categoryName: 'agua',
          ),
        ],
        focusEvents: const [],
        knownHabitIds: const {'water'},
        longestStreak: 1,
        totalPomodoros: 0,
        totalFocusMinutes: 0,
      ),
    );
  }

  void dispose() => container.dispose();
}

void main() {
  Future<_ProgressHarness> createHarness() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final harness = _ProgressHarness(preferences);
    addTearDown(harness.dispose);
    await harness.initialize();
    return harness;
  }

  Widget buildApp(_ProgressHarness harness) {
    return UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProgressScreen(),
      ),
    );
  }

  testWidgets('shows level, next signals and the grouped collection', (
    tester,
  ) async {
    final harness = await createHarness();
    await tester.pumpWidget(buildApp(harness));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('progress-level-hero')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('progress-next-achievements')),
      findsOneWidget,
    );
    expect(find.text('Semilla'), findsOneWidget);
    expect(
      find.textContaining('${Achievements.all.length} en tu colección'),
      findsOneWidget,
    );
    expect(find.text('Siguiente logro'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('progress-achievement-collection')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('achievement-collection')),
      findsOneWidget,
    );
    expect(find.text('Primeros pasos'), findsOneWidget);
    final collectionScrollable = find.descendant(
      of: find.byKey(const ValueKey('achievement-collection')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Ritmo'),
      500,
      scrollable: collectionScrollable,
    );
    expect(find.text('Ritmo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a two-column hero layout on an expanded viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 1366);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = await createHarness();

    await tester.pumpWidget(buildApp(harness));
    await tester.pump(const Duration(milliseconds: 600));

    final hero = tester.getRect(
      find.byKey(const ValueKey('progress-level-hero')),
    );
    final next = tester.getRect(
      find.byKey(const ValueKey('progress-next-achievements')),
    );
    expect(hero.right, lessThan(next.left));
    expect(tester.takeException(), isNull);
  });
}
