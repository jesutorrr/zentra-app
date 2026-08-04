import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../application/habit_controller.dart';
import '../application/pomodoro_provider.dart';
import '../application/profile_controller.dart';
import '../application/profile_state.dart';
import '../application/progress_sync.dart';
import '../application/session_controller.dart';
import '../domain/user_profile.dart';
import 'motion_policy.dart';
import 'profile_setup_screen.dart';
import 'theme.dart';
import 'settings_screen.dart';
import 'widgets/achievement_components.dart';
import 'widgets/ambient_background.dart';
import 'widgets/emoji_selector.dart';
import 'widgets/skeleton_loader.dart';

/// Profile screen showing user stats and achievements
class ProfileScreen extends riverpod.ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  riverpod.ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends riverpod.ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStats());
  }

  Future<void> _syncStats() async {
    final ownerId = ref.read(activeOwnerIdProvider);
    if (ownerId == null) return;
    final profileState =
        ref.read(profileControllerProvider(ownerId)).valueOrNull;
    final habitState = ref.read(habitControllerProvider(ownerId)).valueOrNull;
    if (profileState?.profile == null || habitState == null) return;
    final pomodoroState = ref.read(pomodoroControllerProvider(ownerId));
    await ref.read(profileControllerProvider(ownerId).notifier).syncProgress(
          snapshot: buildProgressSnapshotFromState(
            habitState: habitState,
            activityHistory: pomodoroState.activityHistory,
            totalPomodoros: pomodoroState.totalPomodoros,
            totalFocusMinutes: pomodoroState.totalMinutes,
            now: DateTime.now(),
          ),
          announceUnlocks: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ownerId = ref.watch(activeOwnerIdProvider);
    if (ownerId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profileAsync = ref.watch(profileControllerProvider(ownerId));
    final profileState = profileAsync.valueOrNull;

    if (profileState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: profileAsync.hasError
            ? const Center(child: Text('No pudimos cargar tu perfil.'))
            : const ProfileSkeleton(),
      );
    }

    if (!profileState.hasProfile) {
      return ProfileSetupScreen(ownerId: ownerId);
    }

    final profile = profileState.profile!;
    final levelProgress = _calculateLevelProgress(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(
              context,
              profile,
              ownerId,
            ),
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
      body: ZentraAmbientBackground(
        intensity: 0.85,
        child: Center(
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
                    profileState: profileState,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateLevelProgress(UserProfile profile) {
    return profile.levelProgress;
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserProfile profile,
    String ownerId,
  ) {
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
                'Editar perfil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),

              // Avatar selector
              CompactAvatarPicker(
                label: 'Avatar',
                selectedEmoji: selectedEmoji,
                onTap: () async {
                  final emoji = await showEmojiPickerSheet(
                    context: context,
                    selectedEmoji: selectedEmoji,
                  );
                  if (emoji != null && context.mounted) {
                    setModalState(() => selectedEmoji = emoji);
                  }
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
                      await ref
                          .read(profileControllerProvider(ownerId).notifier)
                          .updateProfile(
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

/// Profile header with avatar and name - FASE 8: Mejorado
class _ProfileHeader extends riverpod.ConsumerStatefulWidget {
  final UserProfile profile;
  final bool isDark;

  const _ProfileHeader({required this.profile, required this.isDark});

  @override
  riverpod.ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends riverpod.ConsumerState<_ProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _motionConfigured = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (context.motionPolicy.allowsDecorativeMotion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
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
    final userCreatedAt = ref.watch(
          sessionControllerProvider.select(
            (session) => session.valueOrNull?.currentUser?.createdAt,
          ),
        ) ??
        widget.profile.createdAt;
    final daysSinceStart = DateTime.now().difference(userCreatedAt).inDays;
    final textColor =
        widget.isDark ? Colors.white : colorScheme.onPrimaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient(colorScheme, widget.isDark),
                borderRadius: BorderRadius.circular(28),
                border: AppTheme.cardGradientBorder(colorScheme, widget.isDark),
                boxShadow: AppTheme.cardShadow(colorScheme, widget.isDark),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(16) > 24;
                  final avatarSize = stacked ? 82.0 : 72.0;
                  final avatar = Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.16),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.profile.avatarEmoji ?? '😊',
                        style: TextStyle(fontSize: stacked ? 40 : 34),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  );
                  final identity = Column(
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: stacked ? TextAlign.center : TextAlign.start,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysSinceStart días con Zentra',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: stacked ? TextAlign.center : TextAlign.start,
                      ),
                    ],
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        avatar,
                        const SizedBox(height: 12),
                        identity,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      avatar,
                      const SizedBox(width: 18),
                      Expanded(child: identity),
                    ],
                  );
                },
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
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (context.motionPolicy.allowsDecorativeMotion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
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
    final nextLevelXP = widget.profile.xpForNextLevel;
    final isMaxLevel =
        widget.profile.currentLevel >= UserProfile.levelThresholds.length;
    final remainingXp =
        (nextLevelXP - widget.profile.totalXp).clamp(0, nextLevelXP);

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
                    isMaxLevel
                        ? Icons.workspace_premium_rounded
                        : Icons.bolt_rounded,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    '${widget.profile.totalXp} XP',
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
                                  color: AppTheme.accentOrange
                                      .withValues(alpha: 0.4),
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
                            '$remainingXp XP para nivel '
                            '${widget.profile.currentLevel + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                size: 16,
                                color: AppTheme.accentAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Nivel máximo',
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
    final metrics = [
      (
        title: 'Completados',
        value: '${profile.totalHabitsCompleted}',
        icon: Icons.check_circle_rounded,
        color: AppTheme.successGreen,
      ),
      (
        title: 'Mejor racha',
        value: '${profile.longestStreak}',
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.accentOrange,
      ),
      (
        title: 'Días activos',
        value: '${profile.totalDaysActive}',
        icon: Icons.calendar_today_rounded,
        color: colorScheme.primary,
      ),
      (
        title: 'Logros',
        value:
            '${profile.unlockedAchievements.length}/${Achievements.all.length}',
        icon: Icons.emoji_events_rounded,
        color: AppTheme.accentAmber,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn =
                MediaQuery.textScalerOf(context).scale(16) > 26 ||
                    constraints.maxWidth < 300;
            const spacing = 12.0;
            final width = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: width,
                    child: _ProfileMetricCard(
                      title: metric.title,
                      value: metric.value,
                      icon: metric.icon,
                      color: metric.color,
                      isDark: isDark,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ProfileMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      container: true,
      label: '$title, $value',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? colors.surfaceContainerHighest.withValues(alpha: 0.42)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.28 : 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievements section
class _AchievementsSection extends StatelessWidget {
  final ProfileState profileState;
  final bool isDark;

  const _AchievementsSection({
    required this.profileState,
    required this.isDark,
  });

  int _getProgressForAchievement(Achievement achievement) {
    final profile = profileState.profile;
    if (profile == null) return 0;
    return achievement.progress(profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = profileState.profile!;
    final unlocked = profileState.unlockedAchievements;
    final next = profileState.nextAchievements(limit: 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tu colección',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
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
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: profileState.achievementProgress,
            minHeight: 8,
            backgroundColor: isDark
                ? colorScheme.surfaceContainerHighest.opacity50
                : colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              profileState.hasAllAchievements
                  ? AppTheme.successGreen
                  : colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (unlocked.isNotEmpty) ...[
          Text(
            'Último logro',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _AchievementTile(
            achievement: unlocked.last,
            isUnlocked: true,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
        if (next.isNotEmpty) ...[
          Text(
            'Siguiente',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...next.map(
            (a) => _AchievementTile(
              achievement: a,
              isUnlocked: false,
              isDark: isDark,
              currentProgress: _getProgressForAchievement(a),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('profile-achievement-collection'),
            onPressed: () => showAchievementCollection(
              context,
              profile: profile,
            ),
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            label: const Text('Ver colección completa'),
          ),
        ),
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
    final progressPercent =
        (currentProgress / achievement.requirement).clamp(0.0, 1.0);
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
                  child: Icon(
                    isUnlocked
                        ? achievementIcon(achievement.symbol)
                        : Icons.lock_outline_rounded,
                    size: isUnlocked ? 22 : 18,
                    color: isUnlocked
                        ? AppTheme.successGreen
                        : colorScheme.onSurfaceVariant,
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
                    const SizedBox(height: 2),
                    Text(
                      '+${achievement.rewardXp} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: achievementColor(
                          achievement.group,
                          colorScheme,
                        ),
                        fontWeight: FontWeight.w700,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
