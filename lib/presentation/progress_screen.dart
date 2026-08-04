import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../application/profile_controller.dart';
import '../application/session_controller.dart';
import '../core/constants.dart';
import '../domain/models.dart';
import '../domain/user_profile.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'theme.dart';
import 'widgets/achievement_components.dart';
import 'widgets/ambient_background.dart';
import 'widgets/empty_state.dart';
import 'widgets/charts.dart';
import 'widgets/responsive_layout.dart';
import 'utils/feedback_utils.dart';
import 'utils/page_transitions.dart';
import 'history_screen.dart';

/// Screen showing weekly progress history
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Obtener categorías ordenadas por cantidad de hábitos
  List<_CategoryData> _getSortedCategories(HabitState provider) {
    final categoryCount = <Category, int>{};

    // Contar hábitos por categoría
    for (final habit in provider.habits) {
      categoryCount[habit.category] = (categoryCount[habit.category] ?? 0) + 1;
    }

    // Filtrar categorías con al menos 1 hábito
    final categories = categoryCount.entries
        .where((e) => e.value > 0)
        .map((e) => _CategoryData(category: e.key, habitCount: e.value))
        .toList();

    // Ordenar: primero por cantidad (desc), luego alfabéticamente
    categories.sort((a, b) {
      final countCompare = b.habitCount.compareTo(a.habitCount);
      if (countCompare != 0) return countCompare;
      return a.category.label.compareTo(b.category.label);
    });

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ownerId = ref.watch(activeOwnerIdProvider);
    if (ownerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final habitAsync = ref.watch(habitControllerProvider(ownerId));
    final profileAsync = ref.watch(profileControllerProvider(ownerId));
    final provider = habitAsync.valueOrNull;
    final profileState = profileAsync.valueOrNull;
    if (provider == null || profileState == null) {
      final error = habitAsync.error ?? profileAsync.error;
      return Scaffold(
        appBar: AppBar(title: const Text('Progreso')),
        body: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Text('No pudimos cargar tu progreso: $error'),
        ),
      );
    }
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Tu actividad',
            onPressed: () {
              triggerHaptic(HapticType.light);
              Navigator.of(context).push(
                PageTransitions.slideFromRight(const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: ZentraAmbientBackground(
        intensity: 0.9,
        child: profile == null
            ? const _EmptyState()
            : Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final history = provider.getProgressHistory(
                    kWeeklyProgressDays,
                    now: now,
                  );
                  final hasData = history.any((d) => d['total'] > 0);
                  final sortedCategories = _getSortedCategories(provider);
                  final weeklyAverage = provider.getWeeklyAverageProgress(now);

                  return ResponsiveLayoutBuilder(
                    builder: (context, layout) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            layout.horizontalPagePadding,
                            layout.verticalPagePadding,
                            layout.horizontalPagePadding,
                            context.spacing.xxl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (layout.isExpanded)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _ProgressHero(profile: profile),
                                    ),
                                    SizedBox(width: context.spacing.lg),
                                    Expanded(
                                      flex: 2,
                                      child: _NextAchievementsCard(
                                        profile: profile,
                                        achievements: profileState
                                            .nextAchievements(limit: 1),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _ProgressHero(profile: profile),
                                SizedBox(height: context.spacing.lg),
                                _NextAchievementsCard(
                                  profile: profile,
                                  achievements:
                                      profileState.nextAchievements(limit: 1),
                                ),
                              ],
                              SizedBox(height: context.spacing.lg),
                              _ProgressMetrics(profile: profile),
                              SizedBox(height: context.spacing.xl),
                              const _SectionHeading(title: 'Últimos 7 días'),
                              SizedBox(height: context.spacing.md),
                              if (hasData)
                                _buildHabitRhythm(
                                  context: context,
                                  history: history,
                                  weeklyAverage: weeklyAverage,
                                  sortedCategories: sortedCategories,
                                  isDark: isDark,
                                  expanded: layout.isExpanded,
                                  habitState: provider,
                                  now: now,
                                )
                              else
                                const _EmptyState(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHabitRhythm({
    required BuildContext context,
    required List<Map<String, dynamic>> history,
    required double weeklyAverage,
    required List<_CategoryData> sortedCategories,
    required bool isDark,
    required bool expanded,
    required HabitState habitState,
    required DateTime now,
  }) {
    final totalPages = 1 + sortedCategories.length;
    final carousel = Column(
      children: [
        SizedBox(
          height: 400,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                triggerHaptic(HapticType.light);
              },
              itemCount: totalPages,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _WeeklySummaryCard(
                      averageProgress: weeklyAverage,
                      history: history,
                      isDark: isDark,
                    ),
                  );
                }
                final categoryData = sortedCategories[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CategoryCard(
                    category: categoryData.category,
                    isDark: isDark,
                    habitState: habitState,
                    now: now,
                  ),
                );
              },
            ),
          ),
        ),
        if (totalPages > 1) ...[
          SizedBox(height: context.spacing.md),
          _PageIndicator(
            currentPage: _currentPage,
            totalPages: totalPages,
            isDark: isDark,
          ),
        ],
      ],
    );
    final chart = Column(
      children: [
        WeeklyProgressChart(history: history, isDark: isDark),
        SizedBox(height: context.spacing.lg),
        _DailyDetailsSection(
          history: history,
          isDark: isDark,
          habitState: habitState,
        ),
      ],
    );

    if (!expanded) {
      return Column(
        children: [
          carousel,
          SizedBox(height: context.spacing.xl),
          chart,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: carousel),
        SizedBox(width: context.spacing.xl),
        Expanded(child: chart),
      ],
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final UserProfile profile;

  const _ProgressHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isMaxLevel =
        profile.currentLevel >= UserProfile.levelThresholds.length;
    final remainingXp =
        isMaxLevel ? 0 : profile.xpForNextLevel - profile.totalXp;
    final levelName = UserProfile.getLevelName(profile.currentLevel);

    return Semantics(
      key: const ValueKey('progress-level-hero'),
      container: true,
      label: 'Nivel ${profile.currentLevel}, $levelName',
      value: '${profile.totalXp} XP. '
          '${isMaxLevel ? 'Nivel máximo' : 'Faltan $remainingXp XP'}',
      child: Container(
        padding: EdgeInsets.all(context.spacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.tertiaryContainer.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.radii.extraLarge),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: AppTheme.cardShadow(
            colors,
            theme.brightness == Brightness.dark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(context.radii.medium),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colors.onPrimary,
                    size: 28,
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIVEL ${profile.currentLevel}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        levelName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.md,
                    vertical: context.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(context.radii.pill),
                  ),
                  child: Text(
                    '${profile.totalXp} XP',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.pill),
              child: LinearProgressIndicator(
                value: profile.levelProgress,
                minHeight: 12,
                color: colors.primary,
                backgroundColor: colors.surface.withValues(alpha: 0.66),
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              isMaxLevel
                  ? 'Nivel máximo'
                  : '$remainingXp XP para nivel ${profile.currentLevel + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.spacing.lg),
            FilledButton.tonalIcon(
              key: const ValueKey('progress-achievement-collection'),
              onPressed: () => showAchievementCollection(
                context,
                profile: profile,
              ),
              icon: const Icon(Icons.auto_awesome_mosaic_outlined),
              label: Text(
                '${Achievements.getUnlocked(profile.unlockedAchievements).length}'
                '/${Achievements.all.length} en tu colección',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAchievementsCard extends StatelessWidget {
  final UserProfile profile;
  final List<Achievement> achievements;

  const _NextAchievementsCard({
    required this.profile,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('progress-next-achievements'),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.extraLarge),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Siguiente logro',
          ),
          SizedBox(height: context.spacing.md),
          if (achievements.isEmpty)
            Text(
              'Colección completa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < achievements.length; index++) ...[
              AchievementProgressTile(
                achievement: achievements[index],
                profile: profile,
                compact: true,
              ),
              if (index < achievements.length - 1)
                SizedBox(height: context.spacing.sm),
            ],
        ],
      ),
    );
  }
}

class _ProgressMetrics extends StatelessWidget {
  final UserProfile profile;

  const _ProgressMetrics({required this.profile});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: 'Hábitos',
        value: '${profile.totalHabitsCompleted}',
        detail: 'completados',
        icon: Icons.check_circle_outline_rounded,
      ),
      (
        label: 'Mejor racha',
        value: '${profile.longestStreak}',
        detail: 'días',
        icon: Icons.local_fire_department_outlined,
      ),
      (
        label: 'Días activos',
        value: '${profile.totalDaysActive}',
        detail: 'con avance',
        icon: Icons.calendar_today_outlined,
      ),
      (
        label: 'Enfoque',
        value: '${profile.totalFocusMinutes}',
        detail: 'minutos reales',
        icon: Icons.center_focus_strong_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final spacing = context.spacing.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _ProgressMetricCard(
                  label: metric.label,
                  value: metric.value,
                  detail: metric.detail,
                  icon: metric.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;

  const _ProgressMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      container: true,
      label: '$label, $value $detail',
      child: Container(
        padding: EdgeInsets.all(context.spacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(context.radii.medium),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 24),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/// Datos de categoría para ordenamiento
class _CategoryData {
  final Category category;
  final int habitCount;

  const _CategoryData({required this.category, required this.habitCount});
}

/// Indicador de página con puntos
class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;

  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Tarjeta de categoría con estadísticas específicas
class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isDark;
  final HabitState habitState;
  final DateTime now;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.habitState,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryInfo = _getCategoryInfo(category);

    final categoryHabits =
        habitState.habits.where((habit) => habit.category == category).toList();
    final history = habitState.getProgressHistory(
      kWeeklyProgressDays,
      now: now,
    );
    final stats = _calculateCategoryStats(
      categoryHabits,
      habitState,
      history,
      category,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  categoryInfo.color.withValues(alpha: 0.3),
                  categoryInfo.color.withValues(alpha: 0.1),
                ]
              : [
                  categoryInfo.color.withValues(alpha: 0.15),
                  categoryInfo.color.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: categoryInfo.color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: categoryInfo.color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y nombre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: categoryInfo.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryInfo.icon,
                  size: 28,
                  color: categoryInfo.color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${categoryHabits.length} hábitos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (isDark ? Colors.white : colorScheme.onSurface)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Porcentaje de cumplimiento
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryInfo.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats.completionRate}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: categoryInfo.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: categoryInfo.color.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _CategoryStatItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Esta semana',
                  value:
                      '${stats.completed}/${stats.total} (${stats.completionRate}%)',
                  color: categoryInfo.color,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _CategoryStatItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Racha actual',
                  value: '${stats.currentStreak} días',
                  color: categoryInfo.color,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CategoryStatItem(
                  icon: Icons.star_rounded,
                  label: 'Más constante',
                  value: stats.mostConsistentHabit,
                  color: categoryInfo.color,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _CategoryStatItem(
                  icon: stats.trendIcon,
                  label: 'Tendencia',
                  value: stats.trend,
                  color: stats.trendColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _CategoryStats _calculateCategoryStats(
    List<dynamic> habits,
    HabitState provider,
    List<Map<String, dynamic>> history,
    Category cat,
  ) {
    if (habits.isEmpty) {
      return const _CategoryStats(
        completed: 0,
        total: 0,
        completionRate: 0,
        currentStreak: 0,
        mostConsistentHabit: 'N/A',
        trend: 'Sin datos',
        trendIcon: Icons.remove_rounded,
        trendColor: Colors.grey,
      );
    }

    int totalCompleted = 0;
    int totalExpected = 0;
    int currentStreak = 0;
    String mostConsistent = habits.first.title;
    int mostConsistentStreak = 0;

    // Para calcular tendencia: primera mitad vs segunda mitad
    int firstHalfCompleted = 0;
    int firstHalfExpected = 0;
    int secondHalfCompleted = 0;
    int secondHalfExpected = 0;

    final today = DateTime(now.year, now.month, now.day);

    for (final habit in habits) {
      final Habit h = habit as Habit;

      // Contar completados últimos 7 días
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        if (h.frequency.appliesTo(date)) {
          totalExpected++;
          final isCompleted = provider.isHabitCompleted(h.id, date);
          if (isCompleted) {
            totalCompleted++;
          }

          // Dividir en mitades para tendencia (0-2 = reciente, 3-6 = anterior)
          if (i < 3) {
            secondHalfExpected++;
            if (isCompleted) secondHalfCompleted++;
          } else {
            firstHalfExpected++;
            if (isCompleted) firstHalfCompleted++;
          }
        }
      }

      // Calcular racha actual
      final streak = provider.getHabitStreak(h.id, now);
      currentStreak +=
          streak; // Sumar rachas de todos los hábitos de la categoría
      if (streak > mostConsistentStreak) {
        mostConsistentStreak = streak;
        mostConsistent = h.title;
      }
    }

    // Racha promedio de la categoría
    final avgStreak =
        habits.isNotEmpty ? (currentStreak / habits.length).round() : 0;

    final rate = totalExpected > 0
        ? ((totalCompleted / totalExpected) * 100).round()
        : 0;

    // Calcular tendencia inteligente
    final firstHalfRate =
        firstHalfExpected > 0 ? firstHalfCompleted / firstHalfExpected : 0.0;
    final secondHalfRate =
        secondHalfExpected > 0 ? secondHalfCompleted / secondHalfExpected : 0.0;

    String trend;
    IconData trendIcon;
    Color trendColor;

    // Lógica de tendencia que reconoce mantener nivel alto
    if (rate >= 80 && secondHalfRate >= 0.8) {
      // Mantiene nivel excelente
      trend = 'Alto';
      trendIcon = Icons.star_rounded;
      trendColor = AppTheme.accentAmber;
    } else if (secondHalfRate > firstHalfRate + 0.1) {
      // Mejorando significativamente
      trend = 'Mejorando';
      trendIcon = Icons.trending_up_rounded;
      trendColor = AppTheme.successGreen;
    } else if (secondHalfRate < firstHalfRate - 0.1) {
      // Bajando
      trend = 'Bajando';
      trendIcon = Icons.trending_down_rounded;
      trendColor = AppTheme.accentOrange;
    } else if (rate >= 60) {
      // Estable en buen nivel
      trend = 'Estable';
      trendIcon = Icons.trending_flat_rounded;
      trendColor = AppTheme.successGreen;
    } else {
      // Estable pero bajo
      trend = 'Estable';
      trendIcon = Icons.trending_flat_rounded;
      trendColor = Colors.grey;
    }

    return _CategoryStats(
      completed: totalCompleted,
      total: totalExpected,
      completionRate: rate,
      currentStreak: avgStreak,
      mostConsistentHabit: mostConsistent.length > 12
          ? '${mostConsistent.substring(0, 10)}...'
          : mostConsistent,
      trend: trend,
      trendIcon: trendIcon,
      trendColor: trendColor,
    );
  }

  _CategoryInfo _getCategoryInfo(Category category) {
    switch (category) {
      case Category.agua:
        return const _CategoryInfo(
          icon: Icons.water_drop_rounded,
          color: Color(0xFF2196F3),
        );
      case Category.movimiento:
        return const _CategoryInfo(
          icon: Icons.directions_run_rounded,
          color: Color(0xFFFF7043),
        );
      case Category.sueno:
        return const _CategoryInfo(
          icon: Icons.nightlight_round,
          color: Color(0xFF9C27B0),
        );
      case Category.foco:
        return const _CategoryInfo(
          icon: Icons.psychology_rounded,
          color: Color(0xFF4CAF50),
        );
      case Category.varios:
        return const _CategoryInfo(
          icon: Icons.category_rounded,
          color: Color(0xFF607D8B),
        );
    }
  }
}

class _CategoryStats {
  final int completed;
  final int total;
  final int completionRate;
  final int currentStreak; // Racha actual (no mejor histórica)
  final String mostConsistentHabit;
  final String trend; // "Excelente", "Mejorando", "Estable", "Bajando"
  final IconData trendIcon;
  final Color trendColor;

  const _CategoryStats({
    required this.completed,
    required this.total,
    required this.completionRate,
    required this.currentStreak,
    required this.mostConsistentHabit,
    required this.trend,
    required this.trendIcon,
    required this.trendColor,
  });
}

class _CategoryInfo {
  final IconData icon;
  final Color color;

  const _CategoryInfo({required this.icon, required this.color});
}

class _CategoryStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _CategoryStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Weekly summary card - FASE 7: Con animación y flip para estadísticas
class _WeeklySummaryCard extends StatefulWidget {
  final double averageProgress;
  final List<Map<String, dynamic>> history;
  final bool isDark;

  const _WeeklySummaryCard({
    required this.averageProgress,
    required this.history,
    required this.isDark,
  });

  @override
  State<_WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<_WeeklySummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _percentAnimation;
  late Animation<double> _scaleAnimation;

  // Flip animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _percentAnimation =
        Tween<double>(begin: 0.0, end: widget.averageProgress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Flip controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motionPolicy;
    _flipController.duration = motion.duration(
      const Duration(milliseconds: 600),
    );
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (motion.allowsDecorativeMotion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    triggerHaptic(HapticType.light);
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _flipController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _toggleCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.14159;
                final isBack = _flipAnimation.value >= 0.5;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(3.14159),
                          child: _buildBackCard(),
                        )
                      : _buildFrontCard(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate stats
    final totalCompleted = widget.history.fold<int>(
      0,
      (sum, day) => sum + (day['completed'] as int),
    );
    final totalHabits = widget.history.fold<int>(
      0,
      (sum, day) => sum + (day['total'] as int),
    );
    final perfectDays = widget.history
        .where(
          (d) => d['total'] > 0 && d['completed'] == d['total'],
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(colorScheme, widget.isDark),
        borderRadius: BorderRadius.circular(24),
        border: AppTheme.cardGradientBorder(colorScheme, widget.isDark),
        boxShadow: AppTheme.cardShadow(colorScheme, widget.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.isDark
                          ? Colors.white
                          : colorScheme.onPrimaryContainer)
                      .opacity15,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: widget.isDark
                      ? Colors.white
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Resumen Semanal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              // Hint to tap
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: (widget.isDark
                        ? Colors.white
                        : colorScheme.onPrimaryContainer)
                    .withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main percentage - ANIMADO - Más grande e impactante
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(_percentAnimation.value * 100).toInt()}',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: widget.isDark
                                ? Colors.white
                                : colorScheme.onPrimaryContainer,
                            height: 1,
                            letterSpacing: -2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: (widget.isDark
                                      ? Colors.white
                                      : colorScheme.onPrimaryContainer)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'promedio de cumplimiento',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (widget.isDark
                                ? Colors.white
                                : colorScheme.onPrimaryContainer)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _getMotivationalIcon(context, widget.averageProgress),
            ],
          ),

          const SizedBox(height: 20),
          Divider(
            height: 1,
            color:
                (widget.isDark ? Colors.white : colorScheme.onPrimaryContainer)
                    .opacity20,
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Completados',
                value: '$totalCompleted/$totalHabits',
                icon: Icons.check_circle_outline,
                isDark: widget.isDark,
              ),
              _StatItem(
                label: 'Días perfectos',
                value: '$perfectDays',
                icon: Icons.star_outline_rounded,
                isDark: widget.isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor =
        widget.isDark ? Colors.white : colorScheme.onPrimaryContainer;

    // Calcular estadísticas detalladas
    final bestDay = _getBestDay();
    final trend = _getTrend();
    final currentStreak = _getCurrentStreak();
    final avgPerDay = _getAverageHabitsPerDay();
    final bestPercent = _getBestDayPercent();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(colorScheme, widget.isDark),
        borderRadius: BorderRadius.circular(24),
        border: AppTheme.cardGradientBorder(colorScheme, widget.isDark),
        boxShadow: AppTheme.cardShadow(colorScheme, widget.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.opacity15,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Estadísticas Detalladas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.flip_rounded,
                size: 14,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Resumen destacado
          _buildHighlightSection(textColor, bestPercent),
          const SizedBox(height: 12),

          Divider(height: 1, color: textColor.opacity20),
          const SizedBox(height: 12),

          // Stats grid - 3 filas de 2
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppTheme.accentAmber,
                  label: 'Mejor día',
                  value: bestDay,
                  isDark: widget.isDark,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: trend.$1,
                  iconColor: trend.$2,
                  label: 'Tendencia',
                  value: trend.$3,
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.accentOrange,
                  label: 'Racha (≥80%)',
                  value: '$currentStreak días',
                  isDark: widget.isDark,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: Icons.speed_rounded,
                  iconColor: colorScheme.primary,
                  label: 'Consistencia',
                  value: _getConsistency(),
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.task_alt_rounded,
                  iconColor: AppTheme.successGreen,
                  label: 'Promedio/día',
                  value: avgPerDay,
                  isDark: widget.isDark,
                ),
              ),
              Expanded(
                child: _DetailStat(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF7C4DFF),
                  label: 'Días activos',
                  value: '${_getDaysWithActivity()}/7',
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightSection(Color textColor, int bestPercent) {
    final theme = Theme.of(context);

    final hasActivity = bestPercent > 0;
    final icon = hasActivity ? Icons.insights_rounded : Icons.remove_rounded;
    final iconColor =
        hasActivity ? AppTheme.accentAmber : textColor.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActivity ? 'Mejor día: ${_getBestDay()}' : 'Sin actividad',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$bestPercent% de cumplimiento',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getBestDayPercent() {
    int bestPercent = 0;
    for (final day in widget.history) {
      final total = day['total'] as int;
      final completed = day['completed'] as int;
      if (total > 0) {
        final percent = ((completed / total) * 100).toInt();
        if (percent > bestPercent) bestPercent = percent;
      }
    }
    return bestPercent;
  }

  String _getAverageHabitsPerDay() {
    if (widget.history.isEmpty) return '0';

    int totalCompleted = 0;
    int daysWithHabits = 0;

    for (final day in widget.history) {
      final total = day['total'] as int;
      final completed = day['completed'] as int;
      if (total > 0) {
        totalCompleted += completed;
        daysWithHabits++;
      }
    }

    if (daysWithHabits == 0) return '0';
    final avg = totalCompleted / daysWithHabits;
    return avg.toStringAsFixed(1);
  }

  int _getDaysWithActivity() {
    int count = 0;
    for (final day in widget.history) {
      final completed = day['completed'] as int;
      if (completed > 0) count++;
    }
    return count;
  }

  String _getBestDay() {
    // weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    final days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    double bestProgress = 0;
    DateTime? bestDate;

    for (final day in widget.history) {
      final total = day['total'] as int;
      final completed = day['completed'] as int;
      final progress = total > 0 ? completed / total : 0.0;

      if (progress > bestProgress) {
        bestProgress = progress;
        bestDate = day['date'] as DateTime;
      }
    }

    if (bestDate == null || bestProgress == 0) return 'N/A';
    return days[bestDate.weekday];
  }

  (IconData, Color, String) _getTrend() {
    if (widget.history.length < 2) {
      return (Icons.remove_rounded, Colors.grey, 'Sin datos');
    }

    // Comparar primera mitad con segunda mitad
    final midpoint = widget.history.length ~/ 2;
    double firstHalf = 0;
    double secondHalf = 0;

    for (int i = 0; i < midpoint; i++) {
      final total = widget.history[i]['total'] as int;
      final completed = widget.history[i]['completed'] as int;
      firstHalf += total > 0 ? completed / total : 0;
    }

    for (int i = midpoint; i < widget.history.length; i++) {
      final total = widget.history[i]['total'] as int;
      final completed = widget.history[i]['completed'] as int;
      secondHalf += total > 0 ? completed / total : 0;
    }

    firstHalf /= midpoint;
    secondHalf /= (widget.history.length - midpoint);

    if (secondHalf > firstHalf + 0.1) {
      return (Icons.trending_up_rounded, AppTheme.successGreen, 'Subiendo');
    } else if (secondHalf < firstHalf - 0.1) {
      return (Icons.trending_down_rounded, AppTheme.accentOrange, 'Bajando');
    } else {
      return (Icons.trending_flat_rounded, AppTheme.accentAmber, 'Estable');
    }
  }

  int _getCurrentStreak() {
    int streak = 0;
    // Iterar desde el día más reciente hacia atrás
    for (int i = widget.history.length - 1; i >= 0; i--) {
      final day = widget.history[i];
      final total = day['total'] as int;
      final completed = day['completed'] as int;
      // Umbral del 80% para contar como día exitoso
      final progress = total > 0 ? completed / total : 0.0;
      if (total > 0 && progress >= 0.8) {
        streak++;
      } else if (total > 0) {
        break; // Racha rota
      }
      // Si total == 0, ignorar ese día (sin hábitos programados)
    }
    return streak;
  }

  String _getConsistency() {
    int daysWithActivity = 0;
    for (final day in widget.history) {
      final completed = day['completed'] as int;
      if (completed > 0) daysWithActivity++;
    }

    final percent = widget.history.isNotEmpty
        ? ((daysWithActivity / widget.history.length) * 100).toInt()
        : 0;
    return '$percent%';
  }

  Widget _getMotivationalIcon(BuildContext context, double progress) {
    IconData icon;
    Color color;
    String label;

    if (progress >= 0.9) {
      icon = Icons.local_fire_department_rounded;
      color = AppTheme.accentOrange;
      label = '90% o más';
    } else if (progress >= 0.7) {
      icon = Icons.emoji_events_rounded;
      color = AppTheme.accentAmber;
      label = '70% o más';
    } else if (progress >= 0.5) {
      icon = Icons.trending_up_rounded;
      color = AppTheme.successGreen;
      label = '50% o más';
    } else if (progress >= 0.3) {
      icon = Icons.eco_rounded;
      color = const Color(0xFF66BB6A);
      label = '30% o más';
    } else {
      icon = Icons.horizontal_rule_rounded;
      color = widget.isDark ? Colors.white70 : Colors.grey;
      label = '${(progress * 100).round()}%';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Detail stat for back of card
class _DetailStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _DetailStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isDark ? Colors.white : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat item widget - Números más grandes
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isDark ? Colors.white : colorScheme.onPrimaryContainer;

    return Column(
      children: [
        // Icono en círculo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: textColor.withValues(alpha: 0.8),
            size: 22,
          ),
        ),
        const SizedBox(height: 10),
        // Valor grande
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Daily details section
class _DailyDetailsSection extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final bool isDark;
  final HabitState habitState;

  const _DailyDetailsSection({
    required this.history,
    required this.isDark,
    required this.habitState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalle por día',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...history.reversed.map(
              (day) => _DayDetailItem(
                date: day['date'] as DateTime,
                completed: day['completed'] as int,
                total: day['total'] as int,
                progress: day['progress'] as double,
                isDark: isDark,
                habitState: habitState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual day detail item - clickeable para ver detalle
class _DayDetailItem extends StatelessWidget {
  final DateTime date;
  final int completed;
  final int total;
  final double progress;
  final bool isDark;
  final HabitState habitState;

  const _DayDetailItem({
    required this.date,
    required this.completed,
    required this.total,
    required this.progress,
    required this.isDark,
    required this.habitState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Hoy';
    } else {
      dateLabel = DateFormat('EEEE d', 'es').format(date);
      dateLabel = dateLabel[0].toUpperCase() + dateLabel.substring(1);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: total > 0 ? () => _showDayDetail(context, dateLabel) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isToday
                ? (isDark
                    ? colorScheme.primary.opacity15
                    : colorScheme.primaryContainer.opacity50)
                : (isDark
                    ? colorScheme.surfaceContainerHighest.opacity50
                    : colorScheme.surfaceContainerLow),
            borderRadius: BorderRadius.circular(14),
            border: isToday
                ? Border.all(
                    color: colorScheme.primary
                        .withValues(alpha: isDark ? 0.5 : 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        dateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isToday ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (total > 0)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.opacity50,
                      ),
                  ],
                ),
              ),

              // Progress bar
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? colorScheme.surfaceContainerHighest.opacity50
                        : colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? AppTheme.successGreen
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Stats
              SizedBox(
                width: 50,
                child: Text(
                  total > 0 ? '$completed/$total' : '-',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Check icon for perfect days
              SizedBox(
                width: 32,
                child: progress == 1.0 && total > 0
                    ? const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context, String dateLabel) {
    final habits = habitState.getHabitsDetailForDate(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayDetailSheet(
        dateLabel: dateLabel,
        date: date,
        habits: habits,
      ),
    );
  }
}

/// Bottom sheet showing habits for a specific day
class _DayDetailSheet extends StatelessWidget {
  final String dateLabel;
  final DateTime date;
  final List<Map<String, dynamic>> habits;

  const _DayDetailSheet({
    required this.dateLabel,
    required this.date,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final completedHabits =
        habits.where((h) => h['completed'] == true).toList();
    final pendingHabits = habits.where((h) => h['completed'] == false).toList();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.opacity15,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${completedHabits.length} de ${habits.length} completados',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.opacity50),

          // Habits list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completed habits
                  if (completedHabits.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.check_circle_rounded,
                      title: 'Completados',
                      color: AppTheme.successGreen,
                      count: completedHabits.length,
                    ),
                    const SizedBox(height: 12),
                    ...completedHabits.map(
                      (h) => _HabitItem(
                        habit: h['habit'],
                        completed: true,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Pending habits
                  if (pendingHabits.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.radio_button_unchecked_rounded,
                      title: 'No completados',
                      color: colorScheme.onSurfaceVariant,
                      count: pendingHabits.length,
                    ),
                    const SizedBox(height: 12),
                    ...pendingHabits.map(
                      (h) => _HabitItem(
                        habit: h['habit'],
                        completed: false,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header for habits list
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual habit item in the detail sheet
class _HabitItem extends StatelessWidget {
  final dynamic habit;
  final bool completed;
  final bool isDark;

  const _HabitItem({
    required this.habit,
    required this.completed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor =
        AppTheme.getCategoryColor(habit.category, colorScheme);
    final categoryIcon = AppTheme.getCategoryIcon(habit.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.opacity50
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: completed
            ? Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Habit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed
                        ? colorScheme.onSurface.opacity50
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  habit.category.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),

          // Status icon
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color:
                completed ? AppTheme.successGreen : colorScheme.outlineVariant,
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// Empty state when no data - FASE 11: Usa el widget reutilizable
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.bar_chart_rounded,
      title: 'Sin actividad',
      message: 'Completa un hábito para ver tu tendencia.',
    );
  }
}
