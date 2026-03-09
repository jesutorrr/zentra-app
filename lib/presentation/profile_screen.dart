import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../application/user_provider.dart';
import '../application/habit_provider.dart';
import '../application/pomodoro_provider.dart';
import '../application/auth_provider.dart';
import '../domain/user_profile.dart';
import 'theme.dart';
import 'settings_screen.dart';
import 'widgets/emoji_selector.dart';
import 'widgets/stat_card.dart';
import 'widgets/skeleton_loader.dart';

/// Profile screen showing user stats and achievements
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _syncStats();
  }

  Future<void> _syncStats() async {
    final userProvider = context.read<UserProvider>();
    final habitProvider = context.read<HabitProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    
    if (!userProvider.hasProfile) return;

    // Calculate stats from habit provider
    int totalCompleted = 0;
    int longestStreak = 0;
    
    for (final habit in habitProvider.habits) {
      final streak = habitProvider.getHabitStreak(habit.id);
      if (streak > longestStreak) longestStreak = streak;
    }
    
    // Count total completions from logs
    totalCompleted = habitProvider.logs.length;
    
    // Calculate days active
    final uniqueDays = habitProvider.logs
        .map((log) => '${log.date.year}-${log.date.month}-${log.date.day}')
        .toSet()
        .length;

    // Contar completaciones por categoría
    int aguaCount = 0;
    int movimientoCount = 0;
    int suenoCount = 0;
    int focoCount = 0;

    for (final log in habitProvider.logs) {
      final habit = habitProvider.getHabitById(log.habitId);
      if (habit != null) {
        switch (habit.category.name) {
          case 'agua':
            aguaCount++;
            break;
          case 'movimiento':
            movimientoCount++;
            break;
          case 'sueno':
            suenoCount++;
            break;
          case 'foco':
            focoCount++;
            break;
        }
      }
    }

    await userProvider.recordHabitCompletion(
      totalCompleted: totalCompleted,
      longestStreak: longestStreak,
      daysActive: uniqueDays,
      categoryAguaCount: aguaCount,
      categoryMovimientoCount: movimientoCount,
      categorySuenoCount: suenoCount,
      categoryFocoCount: focoCount,
      pomodorosCount: pomodoroProvider.totalPomodoros,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi Perfil')),
            body: const ProfileSkeleton(),
          );
        }

        if (!userProvider.hasProfile) {
          return const _CreateProfileScreen();
        }

        final profile = userProvider.profile!;
        final levelProgress = _calculateLevelProgress(profile);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Perfil'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditProfileDialog(context, profile),
                tooltip: 'Editar perfil',
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                tooltip: 'Configuración',
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: RefreshIndicator(
                onRefresh: _syncStats,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile header
                    _ProfileHeader(profile: profile, isDark: isDark),
                    const SizedBox(height: 24),

                    // Level progress
                    _LevelCard(
                      profile: profile,
                      progress: levelProgress,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Stats cards
                    _StatsSection(profile: profile, isDark: isDark),
                    const SizedBox(height: 24),

                    // Achievements
                    _AchievementsSection(
                      userProvider: userProvider,
                      habitProvider: context.read<HabitProvider>(),
                      pomodoroProvider: context.read<PomodoroProvider>(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateLevelProgress(UserProfile profile) {
    final currentLevelXP = profile.currentLevel > 1
        ? UserProfile.getXPForNextLevel(profile.currentLevel - 1)
        : 0;
    final nextLevelXP = UserProfile.getXPForNextLevel(profile.currentLevel);
    final currentXP = profile.totalHabitsCompleted;

    if (profile.currentLevel >= 10) return 1.0;
    
    return ((currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP))
        .clamp(0.0, 1.0);
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    String selectedEmoji = profile.avatarEmoji ?? '😊';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Perfil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              
              // Avatar selector
              LabeledEmojiSelector(
                label: 'Avatar',
                selectedEmoji: selectedEmoji,
                onEmojiSelected: (emoji) {
                  setModalState(() => selectedEmoji = emoji);
                },
              ),
              const SizedBox(height: 24),

              // Name field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      await context.read<UserProvider>().updateProfile(
                        name: nameController.text.trim(),
                        avatarEmoji: selectedEmoji,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create profile screen for first-time users
class _CreateProfileScreen extends StatefulWidget {
  const _CreateProfileScreen();

  @override
  State<_CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<_CreateProfileScreen> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '😊';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient(colorScheme, isDark),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '¡Bienvenido!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu perfil para comenzar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Avatar selector
                  LabeledEmojiSelector(
                    label: 'Elige tu avatar',
                    selectedEmoji: _selectedEmoji,
                    onEmojiSelected: (emoji) {
                      setState(() => _selectedEmoji = emoji);
                    },
                    compact: true,
                  ),
                  const SizedBox(height: 32),

                  // Name field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '¿Cómo te llamas?',
                      hintText: 'Tu nombre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createProfile(),
                  ),
                  const SizedBox(height: 32),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('¡Comenzar!'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await context.read<UserProvider>().createProfile(
      name: name,
      avatarEmoji: _selectedEmoji,
    );
  }
}

/// Profile header with avatar and name - FASE 8: Mejorado
class _ProfileHeader extends StatefulWidget {
  final UserProfile profile;
  final bool isDark;

  const _ProfileHeader({required this.profile, required this.isDark});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Usar fecha de creación del usuario (más confiable que el perfil)
    final authProvider = context.watch<AuthProvider>();
    final userCreatedAt = authProvider.currentUser?.createdAt ?? widget.profile.createdAt;
    final daysSinceStart = DateTime.now().difference(userCreatedAt).inDays;
    final textColor = widget.isDark ? Colors.white : colorScheme.onPrimaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient(colorScheme, widget.isDark),
                borderRadius: BorderRadius.circular(28),
                border: AppTheme.cardGradientBorder(colorScheme, widget.isDark),
                boxShadow: AppTheme.cardShadow(colorScheme, widget.isDark),
              ),
              child: Column(
                children: [
                  // Avatar grande y centrado con Hero animation
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.2),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.profile.avatarEmoji ?? '😊',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  Text(
                    widget.profile.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Badge de días
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$daysSinceStart días en tu viaje',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Level progress card - FASE 8: Con animación
class _LevelCard extends StatefulWidget {
  final UserProfile profile;
  final double progress;
  final bool isDark;

  const _LevelCard({
    required this.profile,
    required this.progress,
    required this.isDark,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelName = UserProfile.getLevelName(widget.profile.currentLevel);
    final nextLevelXP = UserProfile.getXPForNextLevel(widget.profile.currentLevel);
    final isMaxLevel = widget.profile.currentLevel >= 10;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de nivel con glow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentOrange.withValues(alpha: 0.3),
                        AppTheme.accentAmber.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMaxLevel ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
                    size: 20,
                    color: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Nivel ${widget.profile.currentLevel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.accentOrange,
                        AppTheme.accentAmber,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.profile.totalHabitsCompleted} XP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar animada
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Stack(
                      children: [
                        // Fondo
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? colorScheme.surfaceContainerHighest.opacity50
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        // Progreso
                        FractionallySizedBox(
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.accentOrange,
                                  AppTheme.accentAmber,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isMaxLevel)
                          Text(
                            'Siguiente nivel: $nextLevelXP XP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 16, color: AppTheme.accentAmber),
                              const SizedBox(width: 4),
                              Text(
                                '¡Nivel máximo!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Stats section
class _StatsSection extends StatelessWidget {
  final UserProfile profile;
  final bool isDark;

  const _StatsSection({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Estadísticas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Completados',
                value: '${profile.totalHabitsCompleted}',
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.successGreen,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Mejor racha',
                value: '${profile.longestStreak}',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.accentOrange,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Días activos',
                value: '${profile.totalDaysActive}',
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Logros',
                value: '${profile.unlockedAchievements.length}/${Achievements.all.length}',
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.accentAmber,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Achievements section
class _AchievementsSection extends StatelessWidget {
  final UserProvider userProvider;
  final HabitProvider habitProvider;
  final PomodoroProvider pomodoroProvider;
  final bool isDark;

  const _AchievementsSection({
    required this.userProvider,
    required this.habitProvider,
    required this.pomodoroProvider,
    required this.isDark,
  });

  /// Obtener el progreso actual para un tipo de logro
  int _getProgressForAchievement(Achievement achievement) {
    final profile = userProvider.profile;
    if (profile == null) return 0;

    switch (achievement.type) {
      case AchievementType.habitsCompleted:
        return profile.totalHabitsCompleted;
      case AchievementType.streakDays:
        return profile.longestStreak;
      case AchievementType.daysActive:
        return profile.totalDaysActive;
      case AchievementType.categoryAgua:
        return _countCategoryLogs('agua');
      case AchievementType.categoryMovimiento:
        return _countCategoryLogs('movimiento');
      case AchievementType.categorySueno:
        return _countCategoryLogs('sueno');
      case AchievementType.categoryFoco:
        return _countCategoryLogs('foco');
      case AchievementType.pomodorosCompleted:
        return pomodoroProvider.totalPomodoros;
      default:
        return 0;
    }
  }

  int _countCategoryLogs(String categoryName) {
    int count = 0;
    for (final log in habitProvider.logs) {
      final habit = habitProvider.getHabitById(log.habitId);
      if (habit != null && habit.category.name == categoryName) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlocked = userProvider.unlockedAchievements;
    final locked = userProvider.lockedAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Logros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${unlocked.length}/${Achievements.all.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: userProvider.achievementProgress,
            minHeight: 8,
            backgroundColor: isDark
                ? colorScheme.surfaceContainerHighest.opacity50
                : colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              userProvider.hasAllAchievements
                  ? AppTheme.successGreen
                  : colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Unlocked achievements
        if (unlocked.isNotEmpty) ...[
          Text(
            'Desbloqueados',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...unlocked.map((a) => _AchievementTile(
            achievement: a,
            isUnlocked: true,
            isDark: isDark,
          ),),
          const SizedBox(height: 16),
        ],

        // Locked achievements
        if (locked.isNotEmpty) ...[
          Text(
            'Por desbloquear',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...locked.map((a) => _AchievementTile(
            achievement: a,
            isUnlocked: false,
            isDark: isDark,
            currentProgress: _getProgressForAchievement(a),
          ),),
        ],
      ],
    );
  }
}

/// Individual achievement tile with progress bar for locked achievements
class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final bool isDark;
  final int currentProgress; // Progreso actual hacia el logro

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
    required this.isDark,
    this.currentProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calcular porcentaje de progreso
    final progressPercent = (currentProgress / achievement.requirement).clamp(0.0, 1.0);
    final progressPercentText = (progressPercent * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark
                ? AppTheme.successGreen.opacity15
                : AppTheme.successGreen.opacity10)
            : (isDark
                ? colorScheme.surfaceContainerHighest.opacity30
                : colorScheme.surfaceContainerLow),
        borderRadius: BorderRadius.circular(14),
        border: isUnlocked
            ? Border.all(color: AppTheme.successGreen.opacity30)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.successGreen.opacity20
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? achievement.emoji : '🔒',
                    style: TextStyle(
                      fontSize: isUnlocked ? 22 : 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 24,
                )
              else
                // Mostrar porcentaje para logros bloqueados
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.opacity15,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$progressPercentText%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          // Barra de progreso para logros bloqueados
          if (!isUnlocked) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercent >= 0.75
                            ? AppTheme.successGreen
                            : progressPercent >= 0.5
                                ? AppTheme.accentAmber
                                : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$currentProgress/${achievement.requirement}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

