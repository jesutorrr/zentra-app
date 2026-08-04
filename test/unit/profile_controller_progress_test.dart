import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';

import '../support/riverpod_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('queues every new achievement and restores canonical owner progress',
      () async {
    const ownerId = 'progress-owner';
    final preferences = await SharedPreferences.getInstance();
    final firstContainer = _createContainer(preferences);
    final provider = profileControllerProvider(ownerId);
    firstContainer.listen(provider, (_, __) {}, fireImmediately: true);
    await firstContainer.read(provider.future);
    final controller = firstContainer.read(provider.notifier);
    await controller.createProfile(name: 'Uri');

    final day = DateTime(2026, 7, 26);
    await controller.syncProgress(
      snapshot: ProgressSnapshot(
        habitEvents: [
          HabitProgressEvent(
            id: 'habit:water:2026-07-26',
            completedOn: day,
            categoryName: 'agua',
          ),
          HabitProgressEvent(
            id: 'habit:move:2026-07-26',
            completedOn: day,
            categoryName: 'movimiento',
          ),
          HabitProgressEvent(
            id: 'habit:sleep:2026-07-26',
            completedOn: day,
            categoryName: 'sueno',
          ),
        ],
        focusEvents: [
          FocusProgressEvent(id: 'focus:first:1', completedOn: day),
        ],
        knownHabitIds: const {'water', 'move', 'sleep'},
        longestStreak: 3,
        totalPomodoros: 1,
        totalFocusMinutes: 25,
      ),
    );

    final synchronized = firstContainer.read(provider).valueOrNull!;
    expect(synchronized.pendingAchievementIds.length, greaterThan(1));
    final firstAchievementId = synchronized.pendingAchievementIds.first;
    controller.markAchievementPresented(firstAchievementId);
    final afterPresentation = firstContainer.read(provider).valueOrNull!;
    expect(
      afterPresentation.pendingAchievementIds,
      isNot(contains(firstAchievementId)),
    );
    expect(afterPresentation.pendingAchievementIds, isNotEmpty);

    final persistedXp = afterPresentation.profile!.totalXp;

    final restoredContainer = _createContainer(preferences);
    final restoredProvider = profileControllerProvider(ownerId);
    restoredContainer.listen(
      restoredProvider,
      (_, __) {},
      fireImmediately: true,
    );
    final restored = await restoredContainer.read(restoredProvider.future);

    expect(restored.ownerId, ownerId);
    expect(restored.profile!.totalXp, persistedXp);
    expect(restored.profile!.totalHabitsCompleted, 3);
    expect(restored.pendingAchievementIds, isEmpty);
    expect(
      preferences.getString('user_profile_$ownerId'),
      isNotNull,
    );
    expect(preferences.getString('user_profile'), isNull);
  });

  test('can synchronize silently during owner restore or import', () async {
    const ownerId = 'restored-owner';
    final preferences = await SharedPreferences.getInstance();
    final container = _createContainer(preferences);
    final provider = profileControllerProvider(ownerId);
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    await controller.createProfile(name: 'Uri');

    await controller.syncProgress(
      announceUnlocks: false,
      snapshot: ProgressSnapshot(
        habitEvents: [
          HabitProgressEvent(
            id: 'habit:focus:2026-07-26',
            completedOn: DateTime(2026, 7, 26),
            categoryName: 'foco',
          ),
        ],
        focusEvents: const [],
        knownHabitIds: const {'focus'},
        longestStreak: 1,
        totalPomodoros: 0,
        totalFocusMinutes: 0,
      ),
    );

    final state = container.read(provider).valueOrNull!;
    expect(state.ownerId, ownerId);
    expect(state.unlockedAchievements, isNotEmpty);
    expect(state.pendingAchievementIds, isEmpty);
    expect(state.profile!.totalHabitsCompleted, 1);
  });
}

ProviderContainer _createContainer(SharedPreferences preferences) {
  return createTestProviderContainer(
    overrides: [
      profileRepositoryFactoryProvider.overrideWithValue(
        (ownerId) => SharedPreferencesProfileRepository(
          preferences,
          ownerId: ownerId,
        ),
      ),
      profileClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 7, 26, 18),
      ),
    ],
  );
}
