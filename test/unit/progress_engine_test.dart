import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';

void main() {
  UserProfile profile({
    int progressVersion = UserProfile.progressSchemaVersion,
    int totalHabitsCompleted = 0,
    int totalPomodorosCompleted = 0,
    int activityXp = 0,
    List<String> unlockedAchievements = const [],
  }) {
    return UserProfile(
      id: 'uri',
      name: 'Uri',
      createdAt: DateTime(2026),
      progressVersion: progressVersion,
      totalHabitsCompleted: totalHabitsCompleted,
      totalPomodorosCompleted: totalPomodorosCompleted,
      activityXp: activityXp,
      unlockedAchievements: unlockedAchievements,
    );
  }

  ProgressSnapshot snapshot({
    List<HabitProgressEvent> habits = const [],
    List<FocusProgressEvent> focus = const [],
    Set<String> knownHabitIds = const {},
    int longestStreak = 0,
    int totalPomodoros = 0,
    int totalFocusMinutes = 0,
  }) {
    return ProgressSnapshot(
      habitEvents: habits,
      focusEvents: focus,
      knownHabitIds: knownHabitIds,
      longestStreak: longestStreak,
      totalPomodoros: totalPomodoros,
      totalFocusMinutes: totalFocusMinutes,
    );
  }

  test('credits one habit event once even after unmarking and rechecking', () {
    final event = HabitProgressEvent(
      id: 'habit:water:2026-07-26',
      completedOn: DateTime(2026, 7, 26),
      categoryName: 'agua',
    );

    final first = ProgressEngine.synchronize(
      current: profile(),
      snapshot: snapshot(
        habits: [event],
        knownHabitIds: const {'water'},
      ),
    );
    expect(first.profile.totalHabitsCompleted, 1);
    expect(first.profile.activityXp, ProgressEngine.habitCompletionXp);
    expect(first.profile.categoryCompletionCount('agua'), 1);
    expect(
      first.newlyUnlocked.map((achievement) => achievement.id),
      containsAll(['first_habit', 'habits_created_1', 'agua_1']),
    );

    final unmarked = ProgressEngine.synchronize(
      current: first.profile,
      snapshot: snapshot(knownHabitIds: const {'water'}),
    );
    final rechecked = ProgressEngine.synchronize(
      current: unmarked.profile,
      snapshot: snapshot(
        habits: [event],
        knownHabitIds: const {'water'},
      ),
    );

    expect(rechecked.profile.totalHabitsCompleted, 1);
    expect(
      rechecked.profile.activityXp,
      ProgressEngine.habitCompletionXp,
    );
    expect(rechecked.newlyUnlocked, isEmpty);
  });

  test('unlocks varied achievements from independently verified signals', () {
    final day = DateTime(2026, 7, 26);
    final result = ProgressEngine.synchronize(
      current: profile(),
      snapshot: snapshot(
        habits: [
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
        focus: [
          FocusProgressEvent(id: 'focus:one:1', completedOn: day),
        ],
        knownHabitIds: const {'water', 'move', 'sleep'},
        longestStreak: 3,
        totalPomodoros: 1,
        totalFocusMinutes: 25,
      ),
    );
    final ids = result.profile.unlockedAchievements;

    expect(ids, contains('streak_3'));
    expect(ids, contains('three_habit_day_1'));
    expect(ids, contains('pomodoro_1'));
    expect(ids, contains('focus_minutes_25'));
    expect(ids, contains('mixed_focus_day_1'));
    expect(ids, contains('categories_3'));
    expect(result.profile.totalXp, greaterThan(result.profile.activityXp));
  });

  test('migrates legacy counters and achievement ids without double credit',
      () {
    final current = profile(
      progressVersion: 0,
      totalHabitsCompleted: 12,
      activityXp: 0,
      unlockedAchievements: const [
        'week_streak',
        'agua_500',
        'first_habit',
      ],
    );
    final events = [
      for (var index = 0; index < 4; index++)
        HabitProgressEvent(
          id: 'habit:water:2026-07-${index + 1}',
          completedOn: DateTime(2026, 7, index + 1),
          categoryName: 'agua',
        ),
    ];
    final result = ProgressEngine.synchronize(
      current: current,
      snapshot: snapshot(
        habits: events,
        knownHabitIds: const {'water'},
        longestStreak: 7,
      ),
    );

    expect(result.profile.totalHabitsCompleted, 12);
    expect(
      result.profile.activityXp,
      12 * ProgressEngine.habitCompletionXp,
    );
    expect(result.profile.unlockedAchievements, contains('streak_7'));
    expect(result.profile.unlockedAchievements, contains('agua_10'));
    expect(result.profile.unlockedAchievements, isNot(contains('agua_500')));
    expect(result.profile.creditedHabitEvents, hasLength(4));
  });

  test('uses the canonical Pomodoro counter when activity history is partial',
      () {
    final result = ProgressEngine.synchronize(
      current: profile(),
      snapshot: snapshot(
        totalPomodoros: 5,
        totalFocusMinutes: 125,
      ),
    );

    expect(result.profile.totalPomodorosCompleted, 5);
    expect(
      result.profile.activityXp,
      5 * ProgressEngine.focusSessionXp,
    );
    expect(result.profile.totalFocusMinutes, 125);
    expect(result.profile.unlockedAchievements, contains('pomodoro_5'));
    expect(result.profile.unlockedAchievements, contains('focus_minutes_120'));
  });

  test('legacy JSON gains XP and the new level scale safely', () {
    final restored = UserProfile.fromJson({
      'id': 'legacy',
      'name': 'Uri',
      'createdAt': DateTime(2025).toIso8601String(),
      'totalHabitsCompleted': 25,
      'currentLevel': 3,
      'unlockedAchievements': <String>[],
    });

    expect(restored.progressVersion, 0);
    expect(restored.activityXp, 250);
    expect(restored.totalXp, 250);
    expect(restored.currentLevel, 3);
  });
}
