import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../core/constants.dart';
import '../domain/user_profile.dart';
import '../application/habit_provider.dart';
import '../application/user_provider.dart';
import '../application/pomodoro_provider.dart';
import 'theme.dart';
import 'habit_form_screen.dart';
import 'habits_list_screen.dart';
import 'progress_screen.dart';
import 'calendar_screen.dart';
import 'pomodoro_screen.dart';
import 'profile_screen.dart';
import 'celebration_dialog.dart';
import 'history_screen.dart';
import 'widgets/habit_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/animated_list_item.dart';
import 'widgets/tooltip_overlay.dart';
import 'utils/page_transitions.dart';
import 'utils/feedback_utils.dart';

/// Main screen showing today's habits and progress
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  OverlayEntry? _achievementOverlay;
  bool _dayCompletedShown = false; // Track if we've shown the day complete message
  double _lastProgress = 0.0;
  
  // Store provider references for safe disposal
  HabitProvider? _habitProvider;
  UserProvider? _userProvider;

  @override
  void initState() {
    super.initState();
    // Listen for achievement unlocks and day completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAchievements();
      _listenForDayCompletion();
    });
  }

  void _listenForDayCompletion() {
    _habitProvider = context.read<HabitProvider>();
    _lastProgress = _habitProvider!.getTodayProgress();
    _habitProvider!.addListener(_onHabitProviderChange);
  }

  void _onHabitProviderChange() {
    if (!mounted) return;
    final habitProvider = context.read<HabitProvider>();
    final currentProgress = habitProvider.getTodayProgress();
    final totalHabits = habitProvider.getTodayHabits().length;
    
    // Don't show celebration if importing backup
    if (habitProvider.isImporting) {
      _lastProgress = currentProgress;
      _dayCompletedShown = currentProgress == 1.0; // Mark as shown if already complete
      return;
    }
    
    // Check if day just completed (progress went to 100% and there are habits)
    if (currentProgress == 1.0 && _lastProgress < 1.0 && totalHabits > 0 && !_dayCompletedShown) {
      _dayCompletedShown = true;
      _showDayCompletedCelebration();
    }
    
    // Reset flag if progress drops (user unchecked something)
    if (currentProgress < 1.0) {
      _dayCompletedShown = false;
    }
    
    _lastProgress = currentProgress;
  }

  void _showDayCompletedCelebration() {
    triggerHaptic(HapticType.heavy);
    
    // Get a random motivational phrase
    final random = Random();
    final phrase = kMotivationalPhrases[random.nextInt(kMotivationalPhrases.length)];
    
    // Get categories of completed habits
    final habitProvider = context.read<HabitProvider>();
    final completedCategories = habitProvider.habits
        .where((h) => habitProvider.isHabitCompletedToday(h.id))
        .map((h) => h.category)
        .toList();
    
    // Show epic celebration dialog
    DayCompletedDialog.show(
      context,
      phrase: phrase,
      categories: completedCategories,
    );
  }

  void _checkForAchievements() {
    _userProvider = context.read<UserProvider>();
    _userProvider!.addListener(_onUserProviderChange);
  }

  void _onUserProviderChange() {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    
    // Check for all achievements unlocked
    if (userProvider.allAchievementsJustUnlocked) {
      AllAchievementsDialog.show(context);
      userProvider.clearNewlyUnlocked();
      return;
    }

    // Show toast for individual achievements
    if (userProvider.newlyUnlockedAchievements.isNotEmpty) {
      final achievementId = userProvider.newlyUnlockedAchievements.first;
      final achievement = Achievements.getById(achievementId);
      if (achievement != null) {
        _showAchievementToast(achievement);
      }
      userProvider.clearNewlyUnlocked();
    }
  }

  void _showAchievementToast(Achievement achievement) {
    _achievementOverlay?.remove();
    _achievementOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AchievementUnlockedToast(
          emoji: achievement.emoji,
          title: achievement.title,
          onDismiss: () {
            _achievementOverlay?.remove();
            _achievementOverlay = null;
          },
        ),
      ),
    );
    Overlay.of(context).insert(_achievementOverlay!);
  }

  @override
  void dispose() {
    // Remove listeners using stored references (safe for dispose)
    _habitProvider?.removeListener(_onHabitProviderChange);
    _userProvider?.removeListener(_onUserProviderChange);
    _achievementOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use PopScope to move app to background instead of closing when back is pressed
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Move app to background instead of closing (keeps Pomodoro running)
          // This simulates pressing the home button
          const platform = MethodChannel('com.zentra.app/app_lifecycle');
          try {
            await platform.invokeMethod('moveToBackground');
          } catch (e) {
            // Fallback: just do nothing (don't close the app)
            debugPrint('Could not move to background: $e');
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, isDark, colorScheme),
        body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Skeleton loading state
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const SingleChildScrollView(
                  child: Column(
                    children: [
                      ProgressSectionSkeleton(),
                      HabitListSkeleton(itemCount: 4),
                    ],
                  ),
                ),
              ),
            );
          }

          final todayHabits = provider.getTodayHabits();
          
          // Separar hábitos pendientes y completados
          final pendingHabits = todayHabits
              .where((h) => !provider.isHabitCompletedToday(h.id))
              .toList();
          final completedHabits = todayHabits
              .where((h) => provider.isHabitCompletedToday(h.id))
              .toList();

          return todayHabits.isEmpty
              ? _EmptyState(onCreateHabit: () => _navigateToForm(context))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        // iOS-style Pull to Refresh
                        CupertinoSliverRefreshControl(
                          onRefresh: () async {
                            triggerHaptic(HapticType.light);
                            await provider.loadHabits();
                            await provider.loadLogs();
                          },
                        ),
                        SliverToBoxAdapter(
                          child: _ProgressSection(provider: provider, isDark: isDark),
                        ),
                        if (pendingHabits.isEmpty && completedHabits.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.opacity10,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.celebration_rounded,
                                      size: 20,
                                      color: AppTheme.successGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '¡Día completado! Ya hiciste todos tus hábitos de hoy.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // === SECCIÓN: PENDIENTES ===
                          if (pendingHabits.isNotEmpty) ...[
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              sliver: SliverToBoxAdapter(
                                child: AnimatedSectionHeader(
                                  delay: const Duration(milliseconds: 300),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.pending_actions_rounded,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Pendientes',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${pendingHabits.length}',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final habit = pendingHabits[index];
                                    final habitCard = HabitCard(
                                      habit: habit,
                                      provider: provider,
                                      isDark: isDark,
                                    );
                                    // Show tooltip only on first habit card
                                    final isFirstHabit = index == 0;
                                    return AnimatedListItem(
                                      index: index,
                                      delay: const Duration(milliseconds: 60),
                                      child: isFirstHabit
                                          ? ContextualTooltip(
                                              tooltipKey: TooltipKeys.habitCard,
                                              message: 'Toca para marcar como completado ✓',
                                              position: TooltipPosition.below,
                                              child: habitCard,
                                            )
                                          : habitCard,
                                    );
                                  },
                                  childCount: pendingHabits.length,
                                ),
                              ),
                            ),
                          ],
                          
                          // === SECCIÓN: COMPLETADOS ===
                          if (completedHabits.isNotEmpty) ...[
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(24, pendingHabits.isEmpty ? 0 : 16, 24, 0),
                              sliver: SliverToBoxAdapter(
                                child: AnimatedSectionHeader(
                                  delay: Duration(milliseconds: pendingHabits.isEmpty ? 300 : 500),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Completados',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${completedHabits.length}',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: AppTheme.successGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final habit = completedHabits[index];
                                    return AnimatedListItem(
                                      index: index + pendingHabits.length,
                                      delay: const Duration(milliseconds: 60),
                                      child: Opacity(
                                        opacity: 0.7,
                                        child: HabitCard(
                                          habit: habit,
                                          provider: provider,
                                          isDark: isDark,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: completedHabits.length,
                                ),
                              ),
                            ),
                          ],
                          
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 80),
                        ),
                      ],
                    ),
                  ),
                );
          },
        ),
        floatingActionButton: Consumer<HabitProvider>(
          builder: (context, habitProvider, _) {
            final hasNoHabits = habitProvider.habits.isEmpty;
            return ContextualTooltip(
              tooltipKey: TooltipKeys.fabNewHabit,
              message: '¡Toca aquí para crear tu primer hábito!',
              position: TooltipPosition.above,
              enabled: hasNoHabits, // Solo mostrar si no tiene hábitos
              child: PressableScale(
                onTap: () => _navigateToForm(context),
                hapticType: HapticType.medium,
                scaleDown: 0.92,
                child: const FloatingActionButton.extended(
                  onPressed: null, // Manejado por PressableScale
                  icon: Icon(Icons.add_rounded),
                  label: Text('Nuevo'),
                  elevation: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
            );
          },
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    // FASE 9: Circular reveal desde el FAB
    final screenSize = MediaQuery.of(context).size;
    Navigator.of(context).push(
      PageTransitions.circularReveal(
        const HabitFormScreen(),
        center: Offset(screenSize.width - 80, screenSize.height - 80),
      ),
    );
  }

  /// Builds standard AppBar
  AppBar _buildAppBar(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Hoy'),
      centerTitle: false,
      leading: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final emoji = userProvider.profile?.avatarEmoji ?? '😊';
          return Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                PageTransitions.sharedAxisX(const ProfileScreen(), forward: false),
              ),
              child: Center(
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? colorScheme.primary.opacity20
                          : colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        Consumer<PomodoroProvider>(
          builder: (context, pomodoroProvider, _) {
            final hasUsedPomodoro = pomodoroProvider.totalPomodoros > 0;
            return ContextualTooltip(
              tooltipKey: TooltipKeys.pomodoroButton,
              message: 'Timer de enfoque para trabajar concentrado ',
              position: TooltipPosition.below,
              enabled: !hasUsedPomodoro, // Solo si nunca ha usado Pomodoro
              child: _PomodoroNavButton(
                onTap: () => Navigator.of(context).push(
                  PageTransitions.slideFromRight(const PomodoroScreen()),
                ),
              ),
            );
          },
        ),
        _NavButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Progreso',
          onTap: () => Navigator.of(context).push(
            PageTransitions.slideFromRight(const ProgressScreen()),
          ),
        ),
        _NavButton(
          icon: Icons.calendar_month_rounded,
          tooltip: 'Calendario',
          onTap: () => Navigator.of(context).push(
            PageTransitions.slideFromRight(const CalendarScreen()),
          ),
        ),
        _NavButton(
          icon: Icons.list_alt_rounded,
          tooltip: 'Mis Hábitos',
          onTap: () => Navigator.of(context).push(
            PageTransitions.slideFromRight(const HabitsListScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Pomodoro navigation button - Muestra timer y color según tipo de sesión
class _PomodoroNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PomodoroNavButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Obtener info del Pomodoro
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final isRunning = pomodoroProvider.state == PomodoroState.running;
    final isPaused = pomodoroProvider.state == PomodoroState.paused;
    final sessionType = pomodoroProvider.sessionType;
    final formattedTime = pomodoroProvider.formattedTime;
    
    // Color según tipo de sesión
    Color buttonColor;
    String sessionLabel;
    
    if (isRunning || isPaused) {
      sessionLabel = formattedTime;
      switch (sessionType) {
        case SessionType.work:
          buttonColor = colorScheme.primary; // Verde/Teal para enfoque
          break;
        case SessionType.shortBreak:
          buttonColor = AppTheme.accentAmber; // Ámbar para descanso corto
          break;
        case SessionType.longBreak:
          buttonColor = AppTheme.accentOrange; // Naranja para descanso largo
          break;
      }
    } else {
      buttonColor = colorScheme.primary;
      sessionLabel = 'Pomodoro';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: buttonColor.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isRunning || isPaused ? 12 : 14, 
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono con animación de pulso si está corriendo
                _AnimatedPomodoroIcon(isRunning: isRunning, color: buttonColor),
                const SizedBox(width: 6),
                // Timer o texto
                if (isRunning || isPaused) ...[
                  Text(
                    sessionLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: buttonColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ] else
                  Text(
                    sessionLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: buttonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono de Pomodoro con animación de pulso
class _AnimatedPomodoroIcon extends StatefulWidget {
  final bool isRunning;
  final Color color;

  const _AnimatedPomodoroIcon({
    required this.isRunning,
    required this.color,
  });

  @override
  State<_AnimatedPomodoroIcon> createState() => _AnimatedPomodoroIconState();
}

class _AnimatedPomodoroIconState extends State<_AnimatedPomodoroIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isRunning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedPomodoroIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRunning && oldWidget.isRunning) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRunning ? _scaleAnimation.value : 1.0,
          child: Icon(
            Icons.timer_rounded,
            size: 20,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Navigation button in app bar - Con tooltip y mejor feedback
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isDark ? const Color(0xFF2C2C2E) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              triggerHaptic(HapticType.light);
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(icon, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress section showing daily completion stats - Con versión compacta/expandida
class _ProgressSection extends StatefulWidget {
  final HabitProvider provider;
  final bool isDark;

  const _ProgressSection({required this.provider, required this.isDark});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String? _cachedPhrase; // Cache the motivational phrase
  double? _lastProgress; // Track progress to update phrase only when needed
  bool _isExpanded = false; // Estado compacto/expandido

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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

  void _toggleExpanded() {
    triggerHaptic(HapticType.light);
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = context.watch<UserProvider>();
    final userName = userProvider.profile?.name.split(' ').first;
    final stats = widget.provider.getTodayStats();
    final completed = stats['completed']!;
    final total = stats['total']!;
    final progress = widget.provider.getTodayProgress();
    final today = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
    final capitalizedToday = today[0].toUpperCase() + today.substring(1);
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : colorScheme.onPrimaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                padding: EdgeInsets.all(_isExpanded ? 24 : 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient(colorScheme, isDark),
                  borderRadius: BorderRadius.circular(_isExpanded ? 28 : 20),
                  border: AppTheme.cardGradientBorder(colorScheme, isDark),
                  boxShadow: AppTheme.cardShadow(colorScheme, isDark),
                ),
                child: _isExpanded 
                    ? _buildExpandedContent(theme, colorScheme, textColor, capitalizedToday, progress, completed, total, userName, isDark)
                    : _buildCompactContent(theme, colorScheme, textColor, capitalizedToday, progress, completed, total, userName),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Versión compacta - una sola fila con toda la info
  Widget _buildCompactContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Color textColor,
    String date,
    double progress,
    int completed,
    int total,
    String? userName,
  ) {
    return Row(
      children: [
        // Mini progreso circular
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor.withValues(alpha: 0.15),
                ),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
              Text(
                '$completed/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Info central
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getGreeting(userName),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Icono expandir
        Icon(
          Icons.keyboard_arrow_down_rounded,
          color: textColor.withValues(alpha: 0.5),
          size: 24,
        ),
      ],
    );
  }

  /// Versión expandida - diseño original completo
  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Color textColor,
    String date,
    double progress,
    int completed,
    int total,
    String? userName,
    bool isDark,
  ) {
    return Column(
      children: [
        // Icono colapsar arriba
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: textColor.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Fecha
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: textColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: textColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 10),
              Text(
                date,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Progreso circular grande
        _CircularProgress(
          progress: progress,
          isDark: isDark,
          colorScheme: colorScheme,
          completed: completed,
          total: total,
        ),
        
        const SizedBox(height: 20),
        
        // Saludo
        Text(
          _getGreeting(userName),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Frase motivacional
        Text(
          _getCachedMotivationalPhrase(progress),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Returns cached phrase, only regenerating when progress bracket changes
  String _getCachedMotivationalPhrase(double progress) {
    // Determine progress bracket (0-29%, 30-49%, 50-69%, 70-99%, 100%)
    int bracket;
    if (progress >= 1.0) {
      bracket = 4;
    } else if (progress >= 0.7) {
      bracket = 3;
    } else if (progress >= 0.5) {
      bracket = 2;
    } else if (progress >= 0.3) {
      bracket = 1;
    } else {
      bracket = 0;
    }
    
    // Calculate last bracket
    int lastBracket = -1;
    if (_lastProgress != null) {
      if (_lastProgress! >= 1.0) {
        lastBracket = 4;
      } else if (_lastProgress! >= 0.7) {
        lastBracket = 3;
      } else if (_lastProgress! >= 0.5) {
        lastBracket = 2;
      } else if (_lastProgress! >= 0.3) {
        lastBracket = 1;
      } else {
        lastBracket = 0;
      }
    }
    
    // Only regenerate phrase if bracket changed or no cached phrase
    if (_cachedPhrase == null || bracket != lastBracket) {
      _cachedPhrase = _getMotivationalPhrase(progress);
      _lastProgress = progress;
    }
    
    return _cachedPhrase!;
  }

  String _getGreeting(String? userName) {
    final hour = DateTime.now().hour;
    final name = userName != null && userName.isNotEmpty ? ', $userName' : '';
    if (hour < 12) return '¡Buenos días$name!';
    if (hour < 19) return '¡Buenas tardes$name!';
    return '¡Buenas noches$name!';
  }
  
  String _getMotivationalPhrase(double progress) {
    final random = Random();
    
    if (progress >= 1.0) {
      // 100% completado - 12 variantes neutras
      final phrases = [
        '¡Día completado! Increíble trabajo.',
        '¡Lo lograste! Imparable.',
        '¡Perfecto! Hoy fue un gran día.',
        '¡Misión cumplida! Excelente.',
        '¡Épico! Nada te detiene.',
        '¡100%! La constancia da resultados.',
        '¡Hecho! Otro día de victoria.',
        '¡Completado! Tu esfuerzo vale la pena.',
        '¡Genial! Día redondo.',
        '¡Wow! Todo listo, a descansar.',
        '¡Bravo! La disciplina triunfa.',
        '¡Logrado! Mañana será igual de bueno.',
      ];
      return phrases[random.nextInt(phrases.length)];
    } else if (progress >= 0.7) {
      // 70-99% - 12 variantes neutras
      final phrases = [
        '¡Casi! Un último esfuerzo.',
        '¡Ya casi! La meta está cerca.',
        '¡Increíble avance! Solo un poco más.',
        '¡Vas volando! No pares ahora.',
        '¡Impresionante! El final está cerca.',
        '¡Falta poco! Tú puedes.',
        '¡Gran avance! Ya casi está.',
        '¡Muy bien! Solo quedan algunos.',
        '¡Excelente! La recta final.',
        '¡Vamos! Un empujón más.',
        '¡Casi listo! No aflojes.',
        '¡Tremendo progreso! Ya mero.',
      ];
      return phrases[random.nextInt(phrases.length)];
    } else if (progress >= 0.5) {
      // 50-69% - 12 variantes neutras
      final phrases = [
        'Vas por buen camino, ¡sigue así!',
        '¡Mitad del camino! Tú puedes.',
        'Buen ritmo, mantén el impulso.',
        '¡Excelente progreso! No aflojes.',
        'La constancia es clave.',
        '¡Bien! Más de la mitad listo.',
        'Buen paso, sigue adelante.',
        '¡Genial! El progreso es visible.',
        'Vas muy bien, no te detengas.',
        '¡Mitad lograda! A por el resto.',
        'El esfuerzo se nota, ¡sigue!',
        '¡Buen trabajo! Mantén el ritmo.',
      ];
      return phrases[random.nextInt(phrases.length)];
    } else if (progress > 0) {
      // 1-49% - 12 variantes neutras
      final phrases = [
        'Cada pequeño paso cuenta.',
        '¡Buen comienzo! Sigue adelante.',
        'Los grandes logros empiezan así.',
        'Un paso a la vez, vas bien.',
        '¡Ya empezaste! Eso es lo importante.',
        'El progreso es progreso, sin importar el tamaño.',
        '¡Arrancaste! Eso ya es un logro.',
        'Poco a poco se llega lejos.',
        '¡Bien! Ya hay avance.',
        'Cada hábito completado suma.',
        'El camino de mil pasos empieza con uno.',
        '¡Vas! No importa la velocidad.',
      ];
      return phrases[random.nextInt(phrases.length)];
    } else {
      // 0% - 12 variantes neutras
      final phrases = [
        '¡Hoy es un gran día para empezar!',
        '¡El momento perfecto es ahora!',
        'Tu mejor versión te espera.',
        '¡Vamos! El primer paso es el más importante.',
        'Hoy es tu día, ¡a por ello!',
        '¿Listo para empezar? ¡Tú puedes!',
        'Un nuevo día, nuevas oportunidades.',
        'El mejor momento para empezar es ahora.',
        '¡Ánimo! Hoy puede ser un gran día.',
        'Cada día es una nueva oportunidad.',
        '¡Adelante! El primer check te espera.',
        'Hoy es perfecto para avanzar.',
      ];
      return phrases[random.nextInt(phrases.length)];
    }
  }
}

/// Circular progress indicator - FASE 4: Más grande y con contador
class _CircularProgress extends StatelessWidget {
  final double progress;
  final bool isDark;
  final ColorScheme colorScheme;
  final int completed;
  final int total;

  const _CircularProgress({
    required this.progress,
    required this.isDark,
    required this.colorScheme,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : colorScheme.onPrimaryContainer;
    
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo del círculo
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Progreso
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          // Texto central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completed/$total',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'completados',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty state widget - FASE 11: Usa el widget reutilizable
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateHabit;

  const _EmptyState({required this.onCreateHabit});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.self_improvement_rounded,
      title: '¡Comienza tu viaje!',
      message: 'Crea tu primer hábito y comienza a construir una mejor versión de ti mismo.',
      buttonText: 'Crear Primer Hábito',
      onButtonPressed: onCreateHabit,
    );
  }
}
