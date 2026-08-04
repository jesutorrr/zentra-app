import 'dart:math' as math;

/// Persisted identity and progress for one local Zentra owner.
class UserProfile {
  static const int progressSchemaVersion = 1;
  static const List<int> levelThresholds = [
    0,
    100,
    250,
    500,
    900,
    1400,
    2100,
    3000,
    4200,
    6000,
  ];

  final String id;
  final String name;
  final String? avatarEmoji;
  final String? talismanId;
  final DateTime createdAt;
  final int totalHabitsCompleted;
  final int totalDaysActive;
  final int longestStreak;
  final int currentLevel;
  final List<String> unlockedAchievements;
  final int progressVersion;
  final int activityXp;
  final int achievementXp;
  final int totalPomodorosCompleted;
  final int totalFocusMinutes;
  final int totalHabitsCreated;
  final Map<String, int> categoryCompletions;
  final Map<String, int> dailyHabitCompletions;
  final Map<String, int> dailyFocusSessions;
  final List<String> creditedHabitEvents;
  final List<String> creditedFocusEvents;
  final List<String> knownHabitIds;

  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.avatarEmoji,
    this.talismanId,
    this.totalHabitsCompleted = 0,
    this.totalDaysActive = 0,
    this.longestStreak = 0,
    this.currentLevel = 1,
    this.unlockedAchievements = const [],
    this.progressVersion = 0,
    this.activityXp = 0,
    this.achievementXp = 0,
    this.totalPomodorosCompleted = 0,
    this.totalFocusMinutes = 0,
    this.totalHabitsCreated = 0,
    this.categoryCompletions = const {},
    this.dailyHabitCompletions = const {},
    this.dailyFocusSessions = const {},
    this.creditedHabitEvents = const [],
    this.creditedFocusEvents = const [],
    this.knownHabitIds = const [],
  });

  int get totalXp => activityXp + achievementXp;

  int get xpForCurrentLevel => levelThresholds[currentLevel - 1];

  int get xpForNextLevel => currentLevel >= levelThresholds.length
      ? levelThresholds.last
      : levelThresholds[currentLevel];

  int get xpIntoCurrentLevel => totalXp - xpForCurrentLevel;

  int get xpNeededInCurrentLevel =>
      math.max(1, xpForNextLevel - xpForCurrentLevel);

  double get levelProgress {
    if (currentLevel >= levelThresholds.length) return 1;
    return (xpIntoCurrentLevel / xpNeededInCurrentLevel).clamp(0, 1);
  }

  int categoryCompletionCount(String categoryName) =>
      categoryCompletions[categoryName] ?? 0;

  int get categoriesExplored =>
      categoryCompletions.values.where((count) => count > 0).length;

  int get balancedCoreCategoryProgress {
    const coreCategories = ['agua', 'movimiento', 'sueno', 'foco'];
    return coreCategories
        .map(categoryCompletionCount)
        .fold<int>(1 << 30, math.min);
  }

  int daysWithAtLeastHabitCompletions(int minimum) =>
      dailyHabitCompletions.values.where((count) => count >= minimum).length;

  int get mixedFocusDays => dailyHabitCompletions.keys
      .where(
        (day) =>
            (dailyHabitCompletions[day] ?? 0) > 0 &&
            (dailyFocusSessions[day] ?? 0) > 0,
      )
      .length;

  int get weekendActiveDays {
    final activeDays = {
      ...dailyHabitCompletions.keys,
      ...dailyFocusSessions.keys,
    };
    return activeDays.where((day) {
      final date = DateTime.tryParse(day);
      return date != null &&
          (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday);
    }).length;
  }

  UserProfile copyWith({
    String? name,
    String? avatarEmoji,
    String? talismanId,
    int? totalHabitsCompleted,
    int? totalDaysActive,
    int? longestStreak,
    int? currentLevel,
    List<String>? unlockedAchievements,
    int? progressVersion,
    int? activityXp,
    int? achievementXp,
    int? totalPomodorosCompleted,
    int? totalFocusMinutes,
    int? totalHabitsCreated,
    Map<String, int>? categoryCompletions,
    Map<String, int>? dailyHabitCompletions,
    Map<String, int>? dailyFocusSessions,
    List<String>? creditedHabitEvents,
    List<String>? creditedFocusEvents,
    List<String>? knownHabitIds,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      talismanId: talismanId ?? this.talismanId,
      createdAt: createdAt,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      longestStreak: longestStreak ?? this.longestStreak,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      progressVersion: progressVersion ?? this.progressVersion,
      activityXp: activityXp ?? this.activityXp,
      achievementXp: achievementXp ?? this.achievementXp,
      totalPomodorosCompleted:
          totalPomodorosCompleted ?? this.totalPomodorosCompleted,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalHabitsCreated: totalHabitsCreated ?? this.totalHabitsCreated,
      categoryCompletions: categoryCompletions ?? this.categoryCompletions,
      dailyHabitCompletions:
          dailyHabitCompletions ?? this.dailyHabitCompletions,
      dailyFocusSessions: dailyFocusSessions ?? this.dailyFocusSessions,
      creditedHabitEvents: creditedHabitEvents ?? this.creditedHabitEvents,
      creditedFocusEvents: creditedFocusEvents ?? this.creditedFocusEvents,
      knownHabitIds: knownHabitIds ?? this.knownHabitIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
        'talismanId': talismanId,
        'createdAt': createdAt.toIso8601String(),
        'totalHabitsCompleted': totalHabitsCompleted,
        'totalDaysActive': totalDaysActive,
        'longestStreak': longestStreak,
        'currentLevel': currentLevel,
        'unlockedAchievements': unlockedAchievements,
        'progressVersion': progressVersion,
        'activityXp': activityXp,
        'achievementXp': achievementXp,
        'totalXp': totalXp,
        'totalPomodorosCompleted': totalPomodorosCompleted,
        'totalFocusMinutes': totalFocusMinutes,
        'totalHabitsCreated': totalHabitsCreated,
        'categoryCompletions': categoryCompletions,
        'dailyHabitCompletions': dailyHabitCompletions,
        'dailyFocusSessions': dailyFocusSessions,
        'creditedHabitEvents': creditedHabitEvents,
        'creditedFocusEvents': creditedFocusEvents,
        'knownHabitIds': knownHabitIds,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final habitCompletions = json['totalHabitsCompleted'] as int? ?? 0;
    final achievementXp = json['achievementXp'] as int? ?? 0;
    final legacyTotalXp = json['totalXp'] as int? ?? habitCompletions * 10;
    final activityXp = json['activityXp'] as int? ??
        math.max(0, legacyTotalXp - achievementXp);
    final totalXp = activityXp + achievementXp;

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarEmoji: json['avatarEmoji'] as String?,
      talismanId: json['talismanId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalHabitsCompleted: habitCompletions,
      totalDaysActive: json['totalDaysActive'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      currentLevel: json['progressVersion'] == null
          ? calculateLevel(totalXp)
          : json['currentLevel'] as int? ?? calculateLevel(totalXp),
      unlockedAchievements: _stringList(json['unlockedAchievements']),
      progressVersion: json['progressVersion'] as int? ?? 0,
      activityXp: activityXp,
      achievementXp: achievementXp,
      totalPomodorosCompleted: json['totalPomodorosCompleted'] as int? ?? 0,
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      totalHabitsCreated: json['totalHabitsCreated'] as int? ?? 0,
      categoryCompletions: _intMap(json['categoryCompletions']),
      dailyHabitCompletions: _intMap(json['dailyHabitCompletions']),
      dailyFocusSessions: _intMap(json['dailyFocusSessions']),
      creditedHabitEvents: _stringList(json['creditedHabitEvents']),
      creditedFocusEvents: _stringList(json['creditedFocusEvents']),
      knownHabitIds: _stringList(json['knownHabitIds']),
    );
  }

  static int calculateLevel(int xp) {
    for (var index = levelThresholds.length - 1; index >= 0; index--) {
      if (xp >= levelThresholds[index]) return index + 1;
    }
    return 1;
  }

  static String getLevelName(int level) {
    const names = [
      'Semilla',
      'Explorador',
      'Aprendiz',
      'Constante',
      'Cultivador',
      'Guía',
      'Navegante',
      'Maestro',
      'Sabio',
      'Leyenda serena',
    ];
    if (level < 1 || level > names.length) return names.first;
    return names[level - 1];
  }

  /// Cumulative XP threshold required to reach the level after [level].
  static int getXPForNextLevel(int level) {
    if (level < 1) return levelThresholds[1];
    if (level >= levelThresholds.length) return levelThresholds.last;
    return levelThresholds[level];
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is num)
        entry.key as String: (entry.value as num).toInt(),
  };
}

enum AchievementGroup {
  beginnings(
    'Primeros pasos',
    'Señales pequeñas de que tu espacio ya está vivo.',
  ),
  rhythm('Ritmo', 'Constancia que crece sin castigar los días difíciles.'),
  balance('Balance', 'Cuidar distintas partes de tu día con intención.'),
  focus('Enfoque', 'Tiempo protegido para avanzar en lo importante.'),
  exploration('Exploración', 'Formas nuevas de hacer Zentra realmente tuyo.');

  final String label;
  final String description;

  const AchievementGroup(this.label, this.description);
}

enum AchievementMetric {
  habitsCompleted,
  streakDays,
  activeDays,
  habitsCreated,
  categoryCompletions,
  pomodoroSessions,
  focusMinutes,
  categoriesExplored,
  balancedCoreCategories,
  threeHabitDays,
  mixedFocusDays,
  weekendActiveDays,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String symbol;
  final AchievementGroup group;
  final AchievementMetric metric;
  final int requirement;
  final int rewardXp;
  final String? categoryName;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.symbol,
    required this.group,
    required this.metric,
    required this.requirement,
    required this.rewardXp,
    this.categoryName,
  });

  int progress(UserProfile profile) {
    return switch (metric) {
      AchievementMetric.habitsCompleted => profile.totalHabitsCompleted,
      AchievementMetric.streakDays => profile.longestStreak,
      AchievementMetric.activeDays => profile.totalDaysActive,
      AchievementMetric.habitsCreated => profile.totalHabitsCreated,
      AchievementMetric.categoryCompletions =>
        profile.categoryCompletionCount(categoryName ?? ''),
      AchievementMetric.pomodoroSessions => profile.totalPomodorosCompleted,
      AchievementMetric.focusMinutes => profile.totalFocusMinutes,
      AchievementMetric.categoriesExplored => profile.categoriesExplored,
      AchievementMetric.balancedCoreCategories =>
        profile.balancedCoreCategoryProgress,
      AchievementMetric.threeHabitDays =>
        profile.daysWithAtLeastHabitCompletions(3),
      AchievementMetric.mixedFocusDays => profile.mixedFocusDays,
      AchievementMetric.weekendActiveDays => profile.weekendActiveDays,
    };
  }

  bool isUnlockedBy(UserProfile profile) => progress(profile) >= requirement;

  double progressFraction(UserProfile profile) =>
      (progress(profile) / requirement).clamp(0, 1);
}

/// A broad catalog built from progress that Zentra can verify locally.
abstract final class Achievements {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_habit',
      title: 'Primer paso',
      description: 'Completa tu primer hábito.',
      symbol: 'spark',
      group: AchievementGroup.beginnings,
      metric: AchievementMetric.habitsCompleted,
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'habits_created_1',
      title: 'Intención escrita',
      description: 'Crea tu primer hábito.',
      symbol: 'seed',
      group: AchievementGroup.beginnings,
      metric: AchievementMetric.habitsCreated,
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'pomodoro_1',
      title: 'Espacio protegido',
      description: 'Completa tu primera sesión de enfoque.',
      symbol: 'focus',
      group: AchievementGroup.beginnings,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 1,
      rewardXp: 15,
    ),
    Achievement(
      id: 'days_3',
      title: 'Ya tiene ritmo',
      description: 'Vuelve y avanza durante 3 días distintos.',
      symbol: 'path',
      group: AchievementGroup.beginnings,
      metric: AchievementMetric.activeDays,
      requirement: 3,
      rewardXp: 15,
    ),
    Achievement(
      id: 'habits_10',
      title: 'Diez decisiones',
      description: 'Completa 10 hábitos.',
      symbol: 'check',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.habitsCompleted,
      requirement: 10,
      rewardXp: 20,
    ),
    Achievement(
      id: 'habits_50',
      title: 'Constancia visible',
      description: 'Completa 50 hábitos.',
      symbol: 'steps',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.habitsCompleted,
      requirement: 50,
      rewardXp: 40,
    ),
    Achievement(
      id: 'habits_100',
      title: 'Cien veces contigo',
      description: 'Completa 100 hábitos.',
      symbol: 'milestone',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.habitsCompleted,
      requirement: 100,
      rewardXp: 60,
    ),
    Achievement(
      id: 'habits_500',
      title: 'Ritmo profundo',
      description: 'Completa 500 hábitos.',
      symbol: 'mountain',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.habitsCompleted,
      requirement: 500,
      rewardXp: 120,
    ),
    Achievement(
      id: 'habits_1000',
      title: 'Huella duradera',
      description: 'Completa 1000 hábitos.',
      symbol: 'summit',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.habitsCompleted,
      requirement: 1000,
      rewardXp: 200,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Tres días en calma',
      description: 'Mantén una racha de 3 días.',
      symbol: 'flame',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 3,
      rewardXp: 15,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Semana presente',
      description: 'Mantén una racha de 7 días.',
      symbol: 'calendar',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 7,
      rewardXp: 25,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Ritmo que permanece',
      description: 'Mantén una racha de 14 días.',
      symbol: 'waves',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 14,
      rewardXp: 35,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Un mes de intención',
      description: 'Mantén una racha de 30 días.',
      symbol: 'moon',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 30,
      rewardXp: 60,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Ritual propio',
      description: 'Mantén una racha de 100 días.',
      symbol: 'ritual',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 100,
      rewardXp: 120,
    ),
    Achievement(
      id: 'streak_365',
      title: 'Una vuelta al sol',
      description: 'Mantén una racha de 365 días.',
      symbol: 'sun',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.streakDays,
      requirement: 365,
      rewardXp: 250,
    ),
    Achievement(
      id: 'days_7',
      title: 'Primera semana',
      description: 'Avanza durante 7 días distintos.',
      symbol: 'calendar',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.activeDays,
      requirement: 7,
      rewardXp: 20,
    ),
    Achievement(
      id: 'days_30',
      title: 'Un mes contigo',
      description: 'Avanza durante 30 días distintos.',
      symbol: 'orbit',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.activeDays,
      requirement: 30,
      rewardXp: 45,
    ),
    Achievement(
      id: 'days_90',
      title: 'Estación completa',
      description: 'Avanza durante 90 días distintos.',
      symbol: 'season',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.activeDays,
      requirement: 90,
      rewardXp: 80,
    ),
    Achievement(
      id: 'days_365',
      title: 'Año consciente',
      description: 'Avanza durante 365 días distintos.',
      symbol: 'year',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.activeDays,
      requirement: 365,
      rewardXp: 180,
    ),
    Achievement(
      id: 'three_habit_day_1',
      title: 'Día redondo',
      description: 'Completa al menos 3 hábitos en un mismo día.',
      symbol: 'three',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.threeHabitDays,
      requirement: 1,
      rewardXp: 20,
    ),
    Achievement(
      id: 'three_habit_day_7',
      title: 'Semana con espacio',
      description: 'Logra 7 días con al menos 3 hábitos completados.',
      symbol: 'constellation',
      group: AchievementGroup.rhythm,
      metric: AchievementMetric.threeHabitDays,
      requirement: 7,
      rewardXp: 60,
    ),
    Achievement(
      id: 'pomodoro_5',
      title: 'Cinco pausas al ruido',
      description: 'Completa 5 sesiones de enfoque.',
      symbol: 'focus',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 5,
      rewardXp: 20,
    ),
    Achievement(
      id: 'pomodoro_10',
      title: 'Enfoque naciente',
      description: 'Completa 10 sesiones de enfoque.',
      symbol: 'lens',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 10,
      rewardXp: 30,
    ),
    Achievement(
      id: 'pomodoro_25',
      title: 'Tiempo protegido',
      description: 'Completa 25 sesiones de enfoque.',
      symbol: 'shield',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 25,
      rewardXp: 45,
    ),
    Achievement(
      id: 'pomodoro_50',
      title: 'Atención entrenada',
      description: 'Completa 50 sesiones de enfoque.',
      symbol: 'target',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 50,
      rewardXp: 65,
    ),
    Achievement(
      id: 'pomodoro_100',
      title: 'Mente despejada',
      description: 'Completa 100 sesiones de enfoque.',
      symbol: 'clarity',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 100,
      rewardXp: 100,
    ),
    Achievement(
      id: 'pomodoro_500',
      title: 'Presencia profunda',
      description: 'Completa 500 sesiones de enfoque.',
      symbol: 'deep_focus',
      group: AchievementGroup.focus,
      metric: AchievementMetric.pomodoroSessions,
      requirement: 500,
      rewardXp: 220,
    ),
    Achievement(
      id: 'focus_minutes_25',
      title: 'Veinticinco presentes',
      description: 'Acumula 25 minutos reales de enfoque.',
      symbol: 'minute',
      group: AchievementGroup.focus,
      metric: AchievementMetric.focusMinutes,
      requirement: 25,
      rewardXp: 15,
    ),
    Achievement(
      id: 'focus_minutes_120',
      title: 'Dos horas tuyas',
      description: 'Acumula 120 minutos reales de enfoque.',
      symbol: 'hourglass',
      group: AchievementGroup.focus,
      metric: AchievementMetric.focusMinutes,
      requirement: 120,
      rewardXp: 35,
    ),
    Achievement(
      id: 'focus_minutes_300',
      title: 'Bloque de claridad',
      description: 'Acumula 300 minutos reales de enfoque.',
      symbol: 'clarity',
      group: AchievementGroup.focus,
      metric: AchievementMetric.focusMinutes,
      requirement: 300,
      rewardXp: 55,
    ),
    Achievement(
      id: 'focus_minutes_1000',
      title: 'Atención cultivada',
      description: 'Acumula 1000 minutos reales de enfoque.',
      symbol: 'garden',
      group: AchievementGroup.focus,
      metric: AchievementMetric.focusMinutes,
      requirement: 1000,
      rewardXp: 120,
    ),
    Achievement(
      id: 'mixed_focus_day_1',
      title: 'Acción y atención',
      description: 'Completa un hábito y una sesión de enfoque el mismo día.',
      symbol: 'link',
      group: AchievementGroup.focus,
      metric: AchievementMetric.mixedFocusDays,
      requirement: 1,
      rewardXp: 25,
    ),
    Achievement(
      id: 'mixed_focus_day_7',
      title: 'Ritmo integrado',
      description: 'Combina hábitos y enfoque durante 7 días.',
      symbol: 'bridge',
      group: AchievementGroup.focus,
      metric: AchievementMetric.mixedFocusDays,
      requirement: 7,
      rewardXp: 70,
    ),
    ..._categoryAchievements,
    Achievement(
      id: 'categories_3',
      title: 'Horizonte amplio',
      description: 'Completa hábitos de 3 categorías distintas.',
      symbol: 'prism',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoriesExplored,
      requirement: 3,
      rewardXp: 25,
    ),
    Achievement(
      id: 'categories_5',
      title: 'Todo tu espacio',
      description: 'Completa hábitos de las 5 categorías.',
      symbol: 'spectrum',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoriesExplored,
      requirement: 5,
      rewardXp: 50,
    ),
    Achievement(
      id: 'balanced_core_3',
      title: 'Balance inicial',
      description: 'Completa 3 hábitos en cada categoría esencial.',
      symbol: 'balance',
      group: AchievementGroup.balance,
      metric: AchievementMetric.balancedCoreCategories,
      requirement: 3,
      rewardXp: 45,
    ),
    Achievement(
      id: 'balanced_core_10',
      title: 'Cuidado completo',
      description: 'Completa 10 hábitos en cada categoría esencial.',
      symbol: 'mandala',
      group: AchievementGroup.balance,
      metric: AchievementMetric.balancedCoreCategories,
      requirement: 10,
      rewardXp: 90,
    ),
    Achievement(
      id: 'habits_created_3',
      title: 'Mapa personal',
      description: 'Crea 3 hábitos distintos.',
      symbol: 'map',
      group: AchievementGroup.exploration,
      metric: AchievementMetric.habitsCreated,
      requirement: 3,
      rewardXp: 15,
    ),
    Achievement(
      id: 'habits_created_7',
      title: 'Semana diseñada',
      description: 'Crea 7 hábitos distintos.',
      symbol: 'compass',
      group: AchievementGroup.exploration,
      metric: AchievementMetric.habitsCreated,
      requirement: 7,
      rewardXp: 30,
    ),
    Achievement(
      id: 'habits_created_15',
      title: 'Sistema propio',
      description: 'Crea 15 hábitos distintos.',
      symbol: 'blueprint',
      group: AchievementGroup.exploration,
      metric: AchievementMetric.habitsCreated,
      requirement: 15,
      rewardXp: 55,
    ),
    Achievement(
      id: 'weekend_days_4',
      title: 'Fin de semana presente',
      description: 'Avanza en 4 días de fin de semana.',
      symbol: 'weekend',
      group: AchievementGroup.exploration,
      metric: AchievementMetric.weekendActiveDays,
      requirement: 4,
      rewardXp: 30,
    ),
  ];

  static const List<Achievement> _categoryAchievements = [
    Achievement(
      id: 'agua_1',
      title: 'Primera gota',
      description: 'Completa tu primer hábito de agua.',
      symbol: 'water',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'agua',
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'agua_10',
      title: 'Corriente constante',
      description: 'Completa 10 hábitos de agua.',
      symbol: 'water',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'agua',
      requirement: 10,
      rewardXp: 25,
    ),
    Achievement(
      id: 'movimiento_1',
      title: 'Cuerpo despierto',
      description: 'Completa tu primer hábito de movimiento.',
      symbol: 'movement',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'movimiento',
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'movimiento_10',
      title: 'Impulso propio',
      description: 'Completa 10 hábitos de movimiento.',
      symbol: 'movement',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'movimiento',
      requirement: 10,
      rewardXp: 25,
    ),
    Achievement(
      id: 'sueno_1',
      title: 'Descanso elegido',
      description: 'Completa tu primer hábito de sueño.',
      symbol: 'moon',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'sueno',
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'sueno_10',
      title: 'Noche cuidada',
      description: 'Completa 10 hábitos de sueño.',
      symbol: 'moon',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'sueno',
      requirement: 10,
      rewardXp: 25,
    ),
    Achievement(
      id: 'foco_1',
      title: 'Mente clara',
      description: 'Completa tu primer hábito de enfoque.',
      symbol: 'focus',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'foco',
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'foco_10',
      title: 'Dirección serena',
      description: 'Completa 10 hábitos de enfoque.',
      symbol: 'focus',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'foco',
      requirement: 10,
      rewardXp: 25,
    ),
    Achievement(
      id: 'varios_1',
      title: 'Algo sólo tuyo',
      description: 'Completa tu primer hábito personal.',
      symbol: 'spark',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'varios',
      requirement: 1,
      rewardXp: 10,
    ),
    Achievement(
      id: 'varios_10',
      title: 'Tu propia categoría',
      description: 'Completa 10 hábitos personales.',
      symbol: 'spark',
      group: AchievementGroup.balance,
      metric: AchievementMetric.categoryCompletions,
      categoryName: 'varios',
      requirement: 10,
      rewardXp: 25,
    ),
  ];

  static const Map<String, String> legacyAliases = {
    'habits_250': 'habits_100',
    'habits_2000': 'habits_1000',
    'streak_21': 'streak_14',
    'streak_60': 'streak_30',
    'days_180': 'days_90',
    'days_730': 'days_365',
    'agua_50': 'agua_10',
    'agua_100': 'agua_10',
    'agua_250': 'agua_10',
    'agua_500': 'agua_10',
    'agua_1000': 'agua_10',
    'movimiento_50': 'movimiento_10',
    'movimiento_100': 'movimiento_10',
    'movimiento_250': 'movimiento_10',
    'movimiento_500': 'movimiento_10',
    'movimiento_1000': 'movimiento_10',
    'sueno_50': 'sueno_10',
    'sueno_100': 'sueno_10',
    'sueno_250': 'sueno_10',
    'sueno_500': 'sueno_10',
    'sueno_1000': 'sueno_10',
    'foco_50': 'foco_10',
    'foco_100': 'foco_10',
    'foco_250': 'foco_10',
    'foco_500': 'foco_10',
    'foco_1000': 'foco_10',
    'week_streak': 'streak_7',
    'two_week_streak': 'streak_14',
    'month_streak': 'streak_30',
  };

  static Achievement? getById(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  static List<String> normalizeUnlockedIds(Iterable<String> ids) {
    final knownIds = all.map((achievement) => achievement.id).toSet();
    return {
      for (final id in ids)
        if (knownIds.contains(legacyAliases[id] ?? id)) legacyAliases[id] ?? id,
    }.toList(growable: false);
  }

  static List<Achievement> getByGroup(AchievementGroup group) =>
      all.where((achievement) => achievement.group == group).toList();

  static List<Achievement> getUnlocked(List<String> unlockedIds) {
    final ids = normalizeUnlockedIds(unlockedIds).toSet();
    return all.where((achievement) => ids.contains(achievement.id)).toList();
  }

  static List<Achievement> getLocked(List<String> unlockedIds) {
    final ids = normalizeUnlockedIds(unlockedIds).toSet();
    return all.where((achievement) => !ids.contains(achievement.id)).toList();
  }
}
