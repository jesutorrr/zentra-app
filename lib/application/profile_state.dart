import '../domain/user_profile.dart';

class ProfileState {
  final String ownerId;
  final UserProfile? profile;
  final List<String> pendingAchievementIds;
  final bool allAchievementsJustUnlocked;
  final String? error;

  ProfileState({
    required this.ownerId,
    this.profile,
    List<String> pendingAchievementIds = const [],
    this.allAchievementsJustUnlocked = false,
    this.error,
  }) : pendingAchievementIds = List.unmodifiable(pendingAchievementIds);

  bool get hasProfile => profile != null;

  bool get hasAllAchievements {
    final value = profile;
    if (value == null) return false;
    return Achievements.getUnlocked(value.unlockedAchievements).length ==
        Achievements.all.length;
  }

  double get achievementProgress {
    final value = profile;
    if (value == null || Achievements.all.isEmpty) return 0;
    return Achievements.getUnlocked(value.unlockedAchievements).length /
        Achievements.all.length;
  }

  List<Achievement> get unlockedAchievements {
    final value = profile;
    if (value == null) return const [];
    return Achievements.getUnlocked(value.unlockedAchievements);
  }

  List<Achievement> get lockedAchievements {
    final value = profile;
    if (value == null) return Achievements.all;
    return Achievements.getLocked(value.unlockedAchievements);
  }

  List<Achievement> nextAchievements({int limit = 3}) {
    final value = profile;
    if (value == null) return const [];
    final locked = [...lockedAchievements]..sort((left, right) {
        final leftProgress = left.progress(value);
        final rightProgress = right.progress(value);
        final startedComparison =
            (rightProgress > 0 ? 1 : 0).compareTo(leftProgress > 0 ? 1 : 0);
        if (startedComparison != 0) return startedComparison;
        final fractionComparison = right
            .progressFraction(value)
            .compareTo(left.progressFraction(value));
        if (fractionComparison != 0) return fractionComparison;
        final groupComparison = left.group.index.compareTo(right.group.index);
        if (groupComparison != 0) return groupComparison;
        return left.requirement.compareTo(right.requirement);
      });
    return locked.take(limit).toList(growable: false);
  }

  ProfileState copyWith({
    UserProfile? profile,
    bool clearProfile = false,
    List<String>? pendingAchievementIds,
    bool? allAchievementsJustUnlocked,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      ownerId: ownerId,
      profile: clearProfile ? null : (profile ?? this.profile),
      pendingAchievementIds:
          pendingAchievementIds ?? this.pendingAchievementIds,
      allAchievementsJustUnlocked:
          allAchievementsJustUnlocked ?? this.allAchievementsJustUnlocked,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
