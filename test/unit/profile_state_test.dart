import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/profile_state.dart';
import 'package:zentra/domain/user_profile.dart';

void main() {
  UserProfile profile({
    List<String> unlockedAchievements = const [],
    int totalHabitsCompleted = 0,
    int totalHabitsCreated = 0,
  }) {
    return UserProfile(
      id: 'profile-a',
      name: 'Uri',
      createdAt: DateTime.utc(2026, 7, 26),
      progressVersion: UserProfile.progressSchemaVersion,
      unlockedAchievements: unlockedAchievements,
      totalHabitsCompleted: totalHabitsCompleted,
      totalHabitsCreated: totalHabitsCreated,
    );
  }

  test('derives achievement views and protects pending presentation state', () {
    final pending = ['first_habit'];
    final state = ProfileState(
      ownerId: 'owner-a',
      profile: profile(
        unlockedAchievements: const ['first_habit'],
        totalHabitsCompleted: 1,
        totalHabitsCreated: 1,
      ),
      pendingAchievementIds: pending,
    );
    pending.add('habits_created_1');

    expect(state.hasProfile, isTrue);
    expect(state.hasAllAchievements, isFalse);
    expect(
      state.achievementProgress,
      closeTo(1 / Achievements.all.length, 0.000001),
    );
    expect(
      state.unlockedAchievements.map((achievement) => achievement.id),
      ['first_habit'],
    );
    expect(
      state.lockedAchievements.map((achievement) => achievement.id),
      isNot(contains('first_habit')),
    );
    expect(state.nextAchievements(limit: 2), hasLength(2));
    expect(state.pendingAchievementIds, ['first_habit']);
    expect(
      () => state.pendingAchievementIds.add('another'),
      throwsUnsupportedError,
    );
  });

  test('copyWith can clear profile and transient achievement state', () {
    final state = ProfileState(
      ownerId: 'owner-a',
      profile: profile(unlockedAchievements: const ['first_habit']),
      pendingAchievementIds: const ['first_habit'],
      allAchievementsJustUnlocked: true,
      error: 'temporary',
    );

    final cleared = state.copyWith(
      clearProfile: true,
      pendingAchievementIds: const [],
      allAchievementsJustUnlocked: false,
      clearError: true,
    );

    expect(cleared.ownerId, 'owner-a');
    expect(cleared.profile, isNull);
    expect(cleared.pendingAchievementIds, isEmpty);
    expect(cleared.allAchievementsJustUnlocked, isFalse);
    expect(cleared.error, isNull);
    expect(cleared.achievementProgress, 0);
    expect(cleared.nextAchievements(), isEmpty);
  });

  test('recognizes a profile with the complete achievement catalog', () {
    final state = ProfileState(
      ownerId: 'owner-a',
      profile: profile(
        unlockedAchievements: Achievements.all
            .map((achievement) => achievement.id)
            .toList(growable: false),
      ),
    );

    expect(state.hasAllAchievements, isTrue);
    expect(state.achievementProgress, 1);
    expect(state.lockedAchievements, isEmpty);
  });
}
