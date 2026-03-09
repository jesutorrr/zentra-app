/// User profile and achievements model
class UserProfile {
  final String id;
  final String name;
  final String? avatarEmoji;
  final DateTime createdAt;
  final int totalHabitsCompleted;
  final int totalDaysActive;
  final int longestStreak;
  final int currentLevel;
  final List<String> unlockedAchievements;

  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAt, this.avatarEmoji,
    this.totalHabitsCompleted = 0,
    this.totalDaysActive = 0,
    this.longestStreak = 0,
    this.currentLevel = 1,
    this.unlockedAchievements = const [],
  });

  UserProfile copyWith({
    String? name,
    String? avatarEmoji,
    int? totalHabitsCompleted,
    int? totalDaysActive,
    int? longestStreak,
    int? currentLevel,
    List<String>? unlockedAchievements,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      longestStreak: longestStreak ?? this.longestStreak,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarEmoji': avatarEmoji,
    'createdAt': createdAt.toIso8601String(),
    'totalHabitsCompleted': totalHabitsCompleted,
    'totalDaysActive': totalDaysActive,
    'longestStreak': longestStreak,
    'currentLevel': currentLevel,
    'unlockedAchievements': unlockedAchievements,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarEmoji: json['avatarEmoji'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    totalHabitsCompleted: json['totalHabitsCompleted'] as int? ?? 0,
    totalDaysActive: json['totalDaysActive'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    currentLevel: json['currentLevel'] as int? ?? 1,
    unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
  );

  /// Calculate level based on XP (habits completed)
  static int calculateLevel(int habitsCompleted) {
    if (habitsCompleted >= 500) return 10; // Leyenda
    if (habitsCompleted >= 300) return 9;  // Maestro
    if (habitsCompleted >= 200) return 8;  // Experto
    if (habitsCompleted >= 150) return 7;  // Avanzado
    if (habitsCompleted >= 100) return 6;  // Intermedio+
    if (habitsCompleted >= 60) return 5;   // Intermedio
    if (habitsCompleted >= 35) return 4;   // Aprendiz+
    if (habitsCompleted >= 20) return 3;   // Aprendiz
    if (habitsCompleted >= 10) return 2;   // Novato+
    return 1;                              // Novato
  }

  /// Get level name
  static String getLevelName(int level) {
    switch (level) {
      case 1: return 'Novato';
      case 2: return 'Novato+';
      case 3: return 'Aprendiz';
      case 4: return 'Aprendiz+';
      case 5: return 'Intermedio';
      case 6: return 'Intermedio+';
      case 7: return 'Avanzado';
      case 8: return 'Experto';
      case 9: return 'Maestro';
      case 10: return 'Leyenda';
      default: return 'Novato';
    }
  }

  /// Get XP needed for next level
  static int getXPForNextLevel(int level) {
    switch (level) {
      case 1: return 10;
      case 2: return 20;
      case 3: return 35;
      case 4: return 60;
      case 5: return 100;
      case 6: return 150;
      case 7: return 200;
      case 8: return 300;
      case 9: return 500;
      default: return 999999;
    }
  }
}

/// Achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementType type;
  final int requirement;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.requirement,
  });
}

enum AchievementType {
  habitsCompleted,
  streakDays,
  daysActive,
  habitsCreated,
  perfectWeek,
  perfectMonth,
  // Categorías específicas
  categoryAgua,
  categoryMovimiento,
  categorySueno,
  categoryFoco,
  // Pomodoro
  pomodorosCompleted,
  // Especiales
  earlyBird,
  nightOwl,
  weekendWarrior,
  consistency,
}

/// All available achievements - 50 logros creativos
class Achievements {
  static const List<Achievement> all = [
    // ═══════════════════════════════════════════════════════════════════════
    // 🎯 HÁBITOS COMPLETADOS (8 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'first_habit',
      title: 'Primer Paso',
      description: 'Completa tu primer hábito',
      emoji: '🎯',
      type: AchievementType.habitsCompleted,
      requirement: 1,
    ),
    Achievement(
      id: 'habits_10',
      title: 'En Marcha',
      description: 'Completa 10 hábitos',
      emoji: '🚀',
      type: AchievementType.habitsCompleted,
      requirement: 10,
    ),
    Achievement(
      id: 'habits_50',
      title: 'Constante',
      description: 'Completa 50 hábitos',
      emoji: '💪',
      type: AchievementType.habitsCompleted,
      requirement: 50,
    ),
    Achievement(
      id: 'habits_100',
      title: 'Centenario',
      description: 'Completa 100 hábitos',
      emoji: '💯',
      type: AchievementType.habitsCompleted,
      requirement: 100,
    ),
    Achievement(
      id: 'habits_250',
      title: 'Dedicado',
      description: 'Completa 250 hábitos',
      emoji: '🌟',
      type: AchievementType.habitsCompleted,
      requirement: 250,
    ),
    Achievement(
      id: 'habits_500',
      title: 'Imparable',
      description: 'Completa 500 hábitos',
      emoji: '⚡',
      type: AchievementType.habitsCompleted,
      requirement: 500,
    ),
    Achievement(
      id: 'habits_1000',
      title: 'Milésimo',
      description: 'Completa 1000 hábitos',
      emoji: '🏅',
      type: AchievementType.habitsCompleted,
      requirement: 1000,
    ),
    Achievement(
      id: 'habits_2000',
      title: 'Leyenda Viviente',
      description: 'Completa 2000 hábitos',
      emoji: '🦸',
      type: AchievementType.habitsCompleted,
      requirement: 2000,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 🔥 RACHAS (8 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'streak_3',
      title: 'Mini Racha',
      description: 'Mantén una racha de 3 días',
      emoji: '🔥',
      type: AchievementType.streakDays,
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Semana Perfecta',
      description: 'Mantén una racha de 7 días',
      emoji: '🌟',
      type: AchievementType.streakDays,
      requirement: 7,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Dos Semanas',
      description: 'Mantén una racha de 14 días',
      emoji: '✨',
      type: AchievementType.streakDays,
      requirement: 14,
    ),
    Achievement(
      id: 'streak_21',
      title: 'Hábito Formado',
      description: 'Mantén una racha de 21 días',
      emoji: '🧠',
      type: AchievementType.streakDays,
      requirement: 21,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Mes Completo',
      description: 'Mantén una racha de 30 días',
      emoji: '🏆',
      type: AchievementType.streakDays,
      requirement: 30,
    ),
    Achievement(
      id: 'streak_60',
      title: 'Dos Meses',
      description: 'Mantén una racha de 60 días',
      emoji: '💎',
      type: AchievementType.streakDays,
      requirement: 60,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Centurión',
      description: 'Mantén una racha de 100 días',
      emoji: '👑',
      type: AchievementType.streakDays,
      requirement: 100,
    ),
    Achievement(
      id: 'streak_365',
      title: 'Año Invicto',
      description: 'Mantén una racha de 365 días',
      emoji: '🏰',
      type: AchievementType.streakDays,
      requirement: 365,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 📅 DÍAS ACTIVOS (6 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'days_7',
      title: 'Primera Semana',
      description: 'Usa la app durante 7 días',
      emoji: '📅',
      type: AchievementType.daysActive,
      requirement: 7,
    ),
    Achievement(
      id: 'days_30',
      title: 'Un Mes Contigo',
      description: 'Usa la app durante 30 días',
      emoji: '🗓️',
      type: AchievementType.daysActive,
      requirement: 30,
    ),
    Achievement(
      id: 'days_90',
      title: 'Trimestre',
      description: 'Usa la app durante 90 días',
      emoji: '📊',
      type: AchievementType.daysActive,
      requirement: 90,
    ),
    Achievement(
      id: 'days_180',
      title: 'Medio Año',
      description: 'Usa la app durante 180 días',
      emoji: '🎖️',
      type: AchievementType.daysActive,
      requirement: 180,
    ),
    Achievement(
      id: 'days_365',
      title: 'Un Año Transformador',
      description: 'Usa la app durante 365 días',
      emoji: '🌈',
      type: AchievementType.daysActive,
      requirement: 365,
    ),
    Achievement(
      id: 'days_730',
      title: 'Dos Años de Evolución',
      description: 'Usa la app durante 730 días',
      emoji: '🎊',
      type: AchievementType.daysActive,
      requirement: 730,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 💧 CATEGORÍA: AGUA (6 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'agua_10',
      title: 'Gota a Gota',
      description: 'Completa 10 hábitos de hidratación',
      emoji: '💧',
      type: AchievementType.categoryAgua,
      requirement: 10,
    ),
    Achievement(
      id: 'agua_50',
      title: 'Río Interior',
      description: 'Completa 50 hábitos de hidratación',
      emoji: '🌊',
      type: AchievementType.categoryAgua,
      requirement: 50,
    ),
    Achievement(
      id: 'agua_100',
      title: 'Océano de Salud',
      description: 'Completa 100 hábitos de hidratación',
      emoji: '🐋',
      type: AchievementType.categoryAgua,
      requirement: 100,
    ),
    Achievement(
      id: 'agua_250',
      title: 'Cascada Vital',
      description: 'Completa 250 hábitos de hidratación',
      emoji: '🏞️',
      type: AchievementType.categoryAgua,
      requirement: 250,
    ),
    Achievement(
      id: 'agua_500',
      title: 'Maestro del Agua',
      description: 'Completa 500 hábitos de hidratación',
      emoji: '🧜',
      type: AchievementType.categoryAgua,
      requirement: 500,
    ),
    Achievement(
      id: 'agua_1000',
      title: 'Leyenda Acuática',
      description: 'Completa 1000 hábitos de hidratación',
      emoji: '🔱',
      type: AchievementType.categoryAgua,
      requirement: 1000,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 🏃 CATEGORÍA: MOVIMIENTO (6 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'movimiento_10',
      title: 'Primeros Pasos',
      description: 'Completa 10 hábitos de movimiento',
      emoji: '👟',
      type: AchievementType.categoryMovimiento,
      requirement: 10,
    ),
    Achievement(
      id: 'movimiento_50',
      title: 'Cuerpo en Acción',
      description: 'Completa 50 hábitos de movimiento',
      emoji: '🏃',
      type: AchievementType.categoryMovimiento,
      requirement: 50,
    ),
    Achievement(
      id: 'movimiento_100',
      title: 'Atleta Interior',
      description: 'Completa 100 hábitos de movimiento',
      emoji: '🏋️',
      type: AchievementType.categoryMovimiento,
      requirement: 100,
    ),
    Achievement(
      id: 'movimiento_250',
      title: 'Máquina de Energía',
      description: 'Completa 250 hábitos de movimiento',
      emoji: '⚡',
      type: AchievementType.categoryMovimiento,
      requirement: 250,
    ),
    Achievement(
      id: 'movimiento_500',
      title: 'Guerrero Fitness',
      description: 'Completa 500 hábitos de movimiento',
      emoji: '🥇',
      type: AchievementType.categoryMovimiento,
      requirement: 500,
    ),
    Achievement(
      id: 'movimiento_1000',
      title: 'Titán del Movimiento',
      description: 'Completa 1000 hábitos de movimiento',
      emoji: '🦾',
      type: AchievementType.categoryMovimiento,
      requirement: 1000,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 😴 CATEGORÍA: SUEÑO (6 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'sueno_10',
      title: 'Dulces Sueños',
      description: 'Completa 10 hábitos de sueño',
      emoji: '😴',
      type: AchievementType.categorySueno,
      requirement: 10,
    ),
    Achievement(
      id: 'sueno_50',
      title: 'Descanso Reparador',
      description: 'Completa 50 hábitos de sueño',
      emoji: '🌙',
      type: AchievementType.categorySueno,
      requirement: 50,
    ),
    Achievement(
      id: 'sueno_100',
      title: 'Guardián del Sueño',
      description: 'Completa 100 hábitos de sueño',
      emoji: '🌜',
      type: AchievementType.categorySueno,
      requirement: 100,
    ),
    Achievement(
      id: 'sueno_250',
      title: 'Arquitecto de Sueños',
      description: 'Completa 250 hábitos de sueño',
      emoji: '✨',
      type: AchievementType.categorySueno,
      requirement: 250,
    ),
    Achievement(
      id: 'sueno_500',
      title: 'Señor de la Noche',
      description: 'Completa 500 hábitos de sueño',
      emoji: '🌌',
      type: AchievementType.categorySueno,
      requirement: 500,
    ),
    Achievement(
      id: 'sueno_1000',
      title: 'Leyenda Nocturna',
      description: 'Completa 1000 hábitos de sueño',
      emoji: '🦉',
      type: AchievementType.categorySueno,
      requirement: 1000,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 🎯 CATEGORÍA: FOCO (6 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'foco_10',
      title: 'Mente Clara',
      description: 'Completa 10 hábitos de concentración',
      emoji: '🎯',
      type: AchievementType.categoryFoco,
      requirement: 10,
    ),
    Achievement(
      id: 'foco_50',
      title: 'Enfoque Láser',
      description: 'Completa 50 hábitos de concentración',
      emoji: '🔍',
      type: AchievementType.categoryFoco,
      requirement: 50,
    ),
    Achievement(
      id: 'foco_100',
      title: 'Mente de Acero',
      description: 'Completa 100 hábitos de concentración',
      emoji: '🧘',
      type: AchievementType.categoryFoco,
      requirement: 100,
    ),
    Achievement(
      id: 'foco_250',
      title: 'Maestro Zen',
      description: 'Completa 250 hábitos de concentración',
      emoji: '🪷',
      type: AchievementType.categoryFoco,
      requirement: 250,
    ),
    Achievement(
      id: 'foco_500',
      title: 'Iluminado',
      description: 'Completa 500 hábitos de concentración',
      emoji: '💡',
      type: AchievementType.categoryFoco,
      requirement: 500,
    ),
    Achievement(
      id: 'foco_1000',
      title: 'Sabio Interior',
      description: 'Completa 1000 hábitos de concentración',
      emoji: '🧙',
      type: AchievementType.categoryFoco,
      requirement: 1000,
    ),

    // ═══════════════════════════════════════════════════════════════════════
    // 🍅 POMODORO (4 logros)
    // ═══════════════════════════════════════════════════════════════════════
    Achievement(
      id: 'pomodoro_10',
      title: 'Tomate Novato',
      description: 'Completa 10 sesiones Pomodoro',
      emoji: '🍅',
      type: AchievementType.pomodorosCompleted,
      requirement: 10,
    ),
    Achievement(
      id: 'pomodoro_50',
      title: 'Productivo',
      description: 'Completa 50 sesiones Pomodoro',
      emoji: '⏱️',
      type: AchievementType.pomodorosCompleted,
      requirement: 50,
    ),
    Achievement(
      id: 'pomodoro_100',
      title: 'Maestro del Tiempo',
      description: 'Completa 100 sesiones Pomodoro',
      emoji: '⌛',
      type: AchievementType.pomodorosCompleted,
      requirement: 100,
    ),
    Achievement(
      id: 'pomodoro_500',
      title: 'Señor del Pomodoro',
      description: 'Completa 500 sesiones Pomodoro',
      emoji: '🎩',
      type: AchievementType.pomodorosCompleted,
      requirement: 500,
    ),
  ];

  /// Obtener logro por ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtener logros por categoría
  static List<Achievement> getByType(AchievementType type) {
    return all.where((a) => a.type == type).toList();
  }

  /// Obtener logros desbloqueados
  static List<Achievement> getUnlocked(List<String> unlockedIds) {
    return all.where((a) => unlockedIds.contains(a.id)).toList();
  }

  /// Obtener logros bloqueados
  static List<Achievement> getLocked(List<String> unlockedIds) {
    return all.where((a) => !unlockedIds.contains(a.id)).toList();
  }
}
