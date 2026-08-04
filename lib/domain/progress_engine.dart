import 'dart:math' as math;

import 'user_profile.dart';

class HabitProgressEvent {
  final String id;
  final DateTime completedOn;
  final String categoryName;

  const HabitProgressEvent({
    required this.id,
    required this.completedOn,
    required this.categoryName,
  });
}

class FocusProgressEvent {
  final String id;
  final DateTime completedOn;

  const FocusProgressEvent({
    required this.id,
    required this.completedOn,
  });
}

class ProgressSnapshot {
  final List<HabitProgressEvent> habitEvents;
  final List<FocusProgressEvent> focusEvents;
  final Set<String> knownHabitIds;
  final int longestStreak;
  final int totalPomodoros;
  final int totalFocusMinutes;

  const ProgressSnapshot({
    required this.habitEvents,
    required this.focusEvents,
    required this.knownHabitIds,
    required this.longestStreak,
    required this.totalPomodoros,
    required this.totalFocusMinutes,
  });
}

class ProgressSyncResult {
  final UserProfile profile;
  final List<Achievement> newlyUnlocked;

  const ProgressSyncResult({
    required this.profile,
    required this.newlyUnlocked,
  });
}

/// Pure, deterministic progression rules shared by providers and tests.
abstract final class ProgressEngine {
  static const int habitCompletionXp = 10;
  static const int focusSessionXp = 10;

  static ProgressSyncResult synchronize({
    required UserProfile current,
    required ProgressSnapshot snapshot,
  }) {
    final isMigration =
        current.progressVersion < UserProfile.progressSchemaVersion;
    final creditedHabitEvents = current.creditedHabitEvents.toSet();
    final creditedFocusEvents = current.creditedFocusEvents.toSet();
    final knownHabitIds = current.knownHabitIds.toSet();
    final categoryCompletions = Map<String, int>.from(
      current.categoryCompletions,
    );
    final dailyHabitCompletions = Map<String, int>.from(
      current.dailyHabitCompletions,
    );
    final dailyFocusSessions = Map<String, int>.from(
      current.dailyFocusSessions,
    );

    var totalHabitsCompleted = current.totalHabitsCompleted;
    var totalPomodorosCompleted = current.totalPomodorosCompleted;
    var totalHabitsCreated = current.totalHabitsCreated;
    var activityXp = current.activityXp;

    if (isMigration) {
      final migratedHabitEvents = <String>{};
      final migratedFocusEvents = <String>{};
      final migratedCategoryCompletions = <String, int>{};
      final migratedDailyHabits = <String, int>{};
      final migratedDailyFocus = <String, int>{};

      for (final event in snapshot.habitEvents) {
        if (!migratedHabitEvents.add(event.id)) continue;
        final day = dayKey(event.completedOn);
        migratedCategoryCompletions.update(
          event.categoryName,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        migratedDailyHabits.update(
          day,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      for (final event in snapshot.focusEvents) {
        if (!migratedFocusEvents.add(event.id)) continue;
        final day = dayKey(event.completedOn);
        migratedDailyFocus.update(
          day,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      creditedHabitEvents.addAll(migratedHabitEvents);
      creditedFocusEvents.addAll(migratedFocusEvents);
      knownHabitIds.addAll(snapshot.knownHabitIds);
      _mergeMaximums(categoryCompletions, migratedCategoryCompletions);
      _mergeMaximums(dailyHabitCompletions, migratedDailyHabits);
      _mergeMaximums(dailyFocusSessions, migratedDailyFocus);

      totalHabitsCompleted = math.max(
        totalHabitsCompleted,
        migratedHabitEvents.length,
      );
      totalPomodorosCompleted = math.max(
        totalPomodorosCompleted,
        snapshot.totalPomodoros,
      );
      totalHabitsCreated = math.max(
        totalHabitsCreated,
        knownHabitIds.length,
      );
      activityXp = math.max(
        activityXp,
        totalHabitsCompleted * habitCompletionXp +
            totalPomodorosCompleted * focusSessionXp,
      );
    } else {
      for (final event in snapshot.habitEvents) {
        if (!creditedHabitEvents.add(event.id)) continue;
        totalHabitsCompleted++;
        activityXp += habitCompletionXp;
        categoryCompletions.update(
          event.categoryName,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        dailyHabitCompletions.update(
          dayKey(event.completedOn),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      for (final event in snapshot.focusEvents) {
        if (!creditedFocusEvents.add(event.id)) continue;
        dailyFocusSessions.update(
          dayKey(event.completedOn),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final newPomodoros = math.max(
        0,
        snapshot.totalPomodoros - totalPomodorosCompleted,
      );
      totalPomodorosCompleted += newPomodoros;
      activityXp += newPomodoros * focusSessionXp;

      final unseenHabitIds = snapshot.knownHabitIds.difference(knownHabitIds);
      knownHabitIds.addAll(unseenHabitIds);
      totalHabitsCreated += unseenHabitIds.length;
    }

    final activeDays = {
      ...dailyHabitCompletions.keys,
      ...dailyFocusSessions.keys,
    };
    final normalizedUnlocked = Achievements.normalizeUnlockedIds(
      current.unlockedAchievements,
    );
    var achievementXp = math.max(
      current.achievementXp,
      Achievements.getUnlocked(
        normalizedUnlocked,
      ).fold(0, (total, achievement) => total + achievement.rewardXp),
    );

    var updated = current.copyWith(
      totalHabitsCompleted: totalHabitsCompleted,
      totalDaysActive: math.max(current.totalDaysActive, activeDays.length),
      longestStreak: math.max(current.longestStreak, snapshot.longestStreak),
      unlockedAchievements: normalizedUnlocked,
      progressVersion: UserProfile.progressSchemaVersion,
      activityXp: activityXp,
      achievementXp: achievementXp,
      totalPomodorosCompleted: totalPomodorosCompleted,
      totalFocusMinutes: math.max(
        current.totalFocusMinutes,
        snapshot.totalFocusMinutes,
      ),
      totalHabitsCreated: totalHabitsCreated,
      categoryCompletions: categoryCompletions,
      dailyHabitCompletions: dailyHabitCompletions,
      dailyFocusSessions: dailyFocusSessions,
      creditedHabitEvents: creditedHabitEvents.toList()..sort(),
      creditedFocusEvents: creditedFocusEvents.toList()..sort(),
      knownHabitIds: knownHabitIds.toList()..sort(),
    );

    final unlockedIds = normalizedUnlocked.toSet();
    final newlyUnlocked = <Achievement>[];
    for (final achievement in Achievements.all) {
      if (unlockedIds.contains(achievement.id)) continue;
      if (!achievement.isUnlockedBy(updated)) continue;
      unlockedIds.add(achievement.id);
      newlyUnlocked.add(achievement);
      achievementXp += achievement.rewardXp;
    }

    final totalXp = activityXp + achievementXp;
    updated = updated.copyWith(
      currentLevel: UserProfile.calculateLevel(totalXp),
      achievementXp: achievementXp,
      unlockedAchievements: Achievements.all
          .where((achievement) => unlockedIds.contains(achievement.id))
          .map((achievement) => achievement.id)
          .toList(growable: false),
    );

    return ProgressSyncResult(
      profile: updated,
      newlyUnlocked: newlyUnlocked,
    );
  }

  static String dayKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static void _mergeMaximums(
    Map<String, int> target,
    Map<String, int> incoming,
  ) {
    for (final entry in incoming.entries) {
      target[entry.key] = math.max(target[entry.key] ?? 0, entry.value);
    }
  }
}
