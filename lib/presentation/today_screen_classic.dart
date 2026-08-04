import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../application/note_controller.dart';
import '../application/profile_controller.dart';
import '../application/profile_state.dart';
import '../application/session_controller.dart';
import '../core/constants.dart';
import '../domain/models.dart';
import '../domain/progress_engine.dart';
import '../domain/user_profile.dart';
import '../application/pomodoro_provider.dart';
import '../infrastructure/notification_service.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'theme.dart';
import 'habit_form_screen.dart';
import 'habits_list_screen.dart';
import 'progress_screen.dart';
import 'calendar_screen.dart';
import 'pomodoro_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'celebration_dialog.dart';
import 'widgets/habit_card.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/animated_list_item.dart';
import 'widgets/ambient_background.dart';
import 'widgets/tooltip_overlay.dart';
import 'widgets/responsive_layout.dart';
import 'utils/page_transitions.dart';
import 'utils/feedback_utils.dart';

enum _TodayDestination {
  habits,
  notes,
  focus,
  progress,
  calendar,
}

enum TodayVisualStyle {
  classic,
  salvia,
}

/// Original Today composition kept as a working fallback while Salvia evolves.
class ClassicTodayScreen extends riverpod.ConsumerStatefulWidget {
  final TodayVisualStyle visualStyle;

  const ClassicTodayScreen({
    this.visualStyle = TodayVisualStyle.classic,
    super.key,
  });

  @override
  riverpod.ConsumerState<ClassicTodayScreen> createState() =>
      _ClassicTodayScreenState();
}

class _ClassicTodayScreenState
    extends riverpod.ConsumerState<ClassicTodayScreen> {
  static const double _wideNavigationMinWidth = 960;

  OverlayEntry? _achievementOverlay;
  bool _dayCompletedShown =
      false; // Track if we've shown the day complete message
  double _lastProgress = 0.0;

  String? _trackedHabitOwnerId;
  String? _trackedProfileOwnerId;
  HabitState? _latestHabitState;
  Timer? _dailyReminderRefreshDebounce;
  bool _showNotificationPermissionNotice = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotificationPermissionNotice());
  }

  Future<void> _loadNotificationPermissionNotice() async {
    final preferences = await SharedPreferences.getInstance();
    final pending =
        preferences.getBool(kNotificationPermissionNoticePendingKey) ?? false;
    if (!mounted) return;
    setState(() => _showNotificationPermissionNotice = pending);
  }

  Future<void> _dismissNotificationPermissionNotice() async {
    if (mounted) {
      setState(() => _showNotificationPermissionNotice = false);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      kNotificationPermissionNoticePendingKey,
      false,
    );
  }

  Future<void> _openNotificationSettings() async {
    final opened = await launchUrl(
      Uri.parse('app-settings:'),
      mode: LaunchMode.externalApplication,
    );
    if (opened) {
      await _dismissNotificationPermissionNotice();
    }
  }

  void _onHabitStateChange(String ownerId, HabitState habitState) {
    if (!mounted) return;
    final now = DateTime.now();
    final currentProgress = habitState.getDailyProgress(now);
    final totalHabits = habitState.getTodayHabits(now).length;
    _latestHabitState = habitState;

    if (_trackedHabitOwnerId != ownerId) {
      _trackedHabitOwnerId = ownerId;
      _lastProgress = currentProgress;
      _dayCompletedShown = currentProgress == 1;
      _scheduleDailyReminderRefresh();
      return;
    }

    // Don't show celebration if importing backup
    if (habitState.isImporting) {
      _lastProgress = currentProgress;
      _dayCompletedShown =
          currentProgress == 1.0; // Mark as shown if already complete
      return;
    }

    // Check if day just completed (progress went to 100% and there are habits)
    if (currentProgress == 1.0 &&
        _lastProgress < 1.0 &&
        totalHabits > 0 &&
        !_dayCompletedShown) {
      _dayCompletedShown = true;
      _showDayCompletedCelebration(habitState);
    }

    // Reset flag if progress drops (user unchecked something)
    if (currentProgress < 1.0) {
      _dayCompletedShown = false;
    }

    _lastProgress = currentProgress;
    _scheduleDailyReminderRefresh();
  }

  void _primeHabitState(String ownerId, HabitState habitState) {
    final now = DateTime.now();
    _trackedHabitOwnerId = ownerId;
    _latestHabitState = habitState;
    _lastProgress = habitState.getDailyProgress(now);
    _dayCompletedShown = _lastProgress == 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDailyReminderRefresh();
    });
  }

  void _scheduleDailyReminderRefresh() {
    _dailyReminderRefreshDebounce?.cancel();
    _dailyReminderRefreshDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_refreshDailyReminders()),
    );
  }

  Future<void> _refreshDailyReminders() async {
    final habitState = _latestHabitState;
    if (!mounted || habitState == null) return;
    final service = NotificationService();
    final settings = await service.getDailyReminderSettings();
    if (!settings.hasEnabledReminder ||
        !await service.isSystemNotificationPermissionGranted()) {
      return;
    }
    await service.scheduleDailyReminders(
      snapshot: habitState.buildDailyReminderSnapshot(
        capturedAt: DateTime.now(),
      ),
    );
  }

  void _showDayCompletedCelebration(HabitState habitState) {
    // Get a random motivational phrase
    final random = Random();
    final phrase =
        kMotivationalPhrases[random.nextInt(kMotivationalPhrases.length)];

    // Get categories of completed habits
    final now = DateTime.now();
    final completedCategories = habitState.habits
        .where((habit) => habitState.isHabitCompleted(habit.id, now))
        .map((h) => h.category)
        .toList();

    // Show epic celebration dialog
    DayCompletedDialog.show(
      context,
      phrase: phrase,
      categories: completedCategories,
    );
  }

  void _onProfileStateChange(String ownerId, ProfileState profileState) {
    if (!mounted) return;
    if (_achievementOverlay != null) return;

    if (profileState.pendingAchievementIds.isEmpty &&
        profileState.allAchievementsJustUnlocked) {
      AllAchievementsDialog.show(context);
      ref
          .read(profileControllerProvider(ownerId).notifier)
          .clearNewlyUnlocked();
      return;
    }

    // Show toast for individual achievements
    if (profileState.pendingAchievementIds.isNotEmpty) {
      final achievementId = profileState.pendingAchievementIds.first;
      final achievement = Achievements.getById(achievementId);
      if (achievement != null) {
        _showAchievementToast(ownerId, achievement);
      } else {
        ref
            .read(profileControllerProvider(ownerId).notifier)
            .markAchievementPresented(achievementId);
      }
    }
  }

  void _showAchievementToast(String ownerId, Achievement achievement) {
    _achievementOverlay?.remove();
    _achievementOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AchievementUnlockedToast(
          symbol: achievement.symbol,
          title: achievement.title,
          rewardXp: achievement.rewardXp,
          onDismiss: () {
            _achievementOverlay?.remove();
            _achievementOverlay = null;
            if (!mounted) return;
            ref
                .read(profileControllerProvider(ownerId).notifier)
                .markAchievementPresented(achievement.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final profileState =
                  ref.read(profileControllerProvider(ownerId)).valueOrNull;
              if (mounted && profileState != null) {
                _onProfileStateChange(ownerId, profileState);
              }
            });
          },
        ),
      ),
    );
    Overlay.of(context).insert(_achievementOverlay!);
  }

  @override
  void dispose() {
    _dailyReminderRefreshDebounce?.cancel();
    _achievementOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final usesSalvia = widget.visualStyle == TodayVisualStyle.salvia;
    final usesCompactNavigation =
        !context.zentraWindowClass.isAtLeastExpanded ||
            MediaQuery.sizeOf(context).width < _wideNavigationMinWidth ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
    final ownerId = ref.watch(activeOwnerIdProvider);
    final habitProvider =
        ownerId == null ? null : habitControllerProvider(ownerId);
    final profileProvider =
        ownerId == null ? null : profileControllerProvider(ownerId);
    final pomodoroState =
        ownerId == null ? null : ref.watch(pomodoroControllerProvider(ownerId));
    final habitAsync = habitProvider == null ? null : ref.watch(habitProvider);
    final profileAsync =
        profileProvider == null ? null : ref.watch(profileProvider);
    final noteState = ownerId == null
        ? null
        : ref.watch(noteControllerProvider(ownerId)).valueOrNull;
    if (ownerId != null && habitProvider != null && profileProvider != null) {
      ref.listen(
        habitProvider,
        (previous, next) {
          final state = next.valueOrNull;
          if (state != null) _onHabitStateChange(ownerId, state);
        },
      );
      ref.listen(
        profileProvider,
        (previous, next) {
          final state = next.valueOrNull;
          if (state != null) _onProfileStateChange(ownerId, state);
        },
      );
    }
    final habitState = habitAsync?.valueOrNull;
    final profileState = profileAsync?.valueOrNull;
    final profile = profileState?.profile;
    if (ownerId != null &&
        habitState != null &&
        _trackedHabitOwnerId != ownerId) {
      _primeHabitState(ownerId, habitState);
    }
    if (ownerId != null &&
        profileState != null &&
        _trackedProfileOwnerId != ownerId) {
      _trackedProfileOwnerId = ownerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onProfileStateChange(ownerId, profileState);
      });
    }

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
            if (kDebugMode) {
              debugPrint('Could not move to background: $e');
            }
          }
        }
      },
      child: Scaffold(
        key: const ValueKey('today-screen'),
        backgroundColor: usesSalvia ? Colors.transparent : null,
        appBar: usesSalvia && usesCompactNavigation
            ? null
            : _buildAppBar(
                context,
                isDark,
                colorScheme,
                usesCompactNavigation,
                profile,
                pomodoroState,
              ),
        bottomNavigationBar:
            usesSalvia && usesCompactNavigation && habitState != null
                ? _TodayActionBar(
                    pomodoroState: pomodoroState,
                    onOpenFocus: () => _openTodayDestination(
                      context,
                      _TodayDestination.focus,
                    ),
                    onCreateHabit: () => _navigateToForm(context),
                  )
                : null,
        body: _TodayVisualBackground(
          visualStyle: widget.visualStyle,
          useTopSafeArea: usesSalvia && usesCompactNavigation,
          child: ResponsiveLayoutBuilder(
            builder: (context, layout) {
              if (habitState == null || ownerId == null) {
                return ResponsiveContentFrame(
                  maxWidth: layout.isExpanded ? 1180 : 720,
                  child: const SingleChildScrollView(
                    child: Column(
                      children: [
                        ProgressSectionSkeleton(),
                        HabitListSkeleton(itemCount: 4),
                      ],
                    ),
                  ),
                );
              }
              final habitController =
                  ref.read(habitControllerProvider(ownerId).notifier);

              final now = DateTime.now();
              final todayHabits = habitState.getTodayHabits(now);
              final pendingHabits = todayHabits
                  .where((habit) => !habitState.isHabitCompleted(habit.id, now))
                  .toList();
              final completedHabits = todayHabits
                  .where((habit) => habitState.isHabitCompleted(habit.id, now))
                  .toList();
              final habits = _TodayHabitsPanel(
                state: habitState,
                controller: habitController,
                pendingHabits: pendingHabits,
                completedHabits: completedHabits,
                isDark: isDark,
                usesSalvia: usesSalvia,
                onCreateHabit: () => _navigateToForm(context),
              );
              final progress = _ProgressSection(
                state: habitState,
                profile: profile,
                isDark: isDark,
                usesSalvia: usesSalvia,
                onOpenProfile: () => _openProfile(context),
              );
              final focus = _TodayFocusCard(
                pomodoroState: pomodoroState,
                onTap: () => _openTodayDestination(
                  context,
                  _TodayDestination.focus,
                ),
              );
              final notesToReview =
                  noteState?.dueForReviewAt(DateTime.now()) ?? const [];
              final notes = notesToReview.isEmpty
                  ? null
                  : _TodayNoteReviewCard(
                      count: notesToReview.length,
                      title: notesToReview.first.title,
                      scheduledAt: noteState
                          ?.getReminder(notesToReview.first.id)
                          ?.scheduledAtUtc
                          .toLocal(),
                      usesSalvia: usesSalvia,
                      onTap: () => _openTodayDestination(
                        context,
                        _TodayDestination.notes,
                      ),
                    );
              final permissionNotice =
                  usesSalvia && _showNotificationPermissionNotice
                      ? _NotificationPermissionNoticeCard(
                          onOpenSettings: _openNotificationSettings,
                          onDismiss: _dismissNotificationPermissionNotice,
                        )
                      : null;

              final content = layout.isExpanded && !usesCompactNavigation
                  ? Row(
                      key: const ValueKey('today-expanded-layout'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: habits,
                        ),
                        SizedBox(width: context.spacing.lg),
                        Flexible(
                          flex: 2,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              children: [
                                progress,
                                if (permissionNotice != null) ...[
                                  SizedBox(height: context.spacing.md),
                                  permissionNotice,
                                ],
                                if (notes != null) ...[
                                  SizedBox(height: context.spacing.md),
                                  notes,
                                ],
                                SizedBox(height: context.spacing.md),
                                focus,
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('today-single-column-layout'),
                      children: [
                        progress,
                        if (permissionNotice != null) ...[
                          SizedBox(height: context.spacing.md),
                          permissionNotice,
                        ],
                        if (usesSalvia) ...[
                          SizedBox(height: context.spacing.md),
                          _PrimaryNavigationStrip(
                            pomodoroState: pomodoroState,
                            usesSalvia: true,
                            onSelected: (destination) =>
                                _openTodayDestination(context, destination),
                          ),
                        ],
                        if (notes != null) ...[
                          SizedBox(height: context.spacing.md),
                          notes,
                        ],
                        SizedBox(height: context.spacing.md),
                        habits,
                        if (!usesSalvia) ...[
                          SizedBox(height: context.spacing.md),
                          focus,
                        ],
                      ],
                    );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      triggerHaptic(HapticType.light);
                      await habitController.reload();
                    },
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      usesSalvia
                          ? context.spacing.lg
                          : layout.horizontalPagePadding,
                      usesSalvia
                          ? context.spacing.md
                          : layout.verticalPagePadding,
                      usesSalvia
                          ? context.spacing.lg
                          : layout.horizontalPagePadding,
                      usesSalvia ? context.spacing.lg : context.spacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ResponsiveContentFrame(
                        maxWidth: layout.isExpanded ? 1180 : 720,
                        child: content,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    Navigator.of(context).push(
      PageTransitions.slideFromRight(const HabitFormScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageTransitions.sharedAxisX(
        const ProfileScreen(),
        forward: false,
      ),
    );
  }

  /// Builds standard AppBar
  AppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    bool usesCompactNavigation,
    UserProfile? profile,
    PomodoroViewState? pomodoroState,
  ) {
    final emoji = profile?.avatarEmoji ?? '😊';
    void openProfile() => _openProfile(context);

    return AppBar(
      title: const Text('Hoy'),
      centerTitle: false,
      leading: Semantics(
        key: const ValueKey('today-profile-action'),
        button: true,
        label: 'Abrir perfil',
        onTap: openProfile,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: openProfile,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
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
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottom: usesCompactNavigation
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                MediaQuery.textScalerOf(context).scale(12) > 18 ? 64 : 58,
              ),
              child: _PrimaryNavigationStrip(
                pomodoroState: pomodoroState,
                onSelected: (destination) =>
                    _openTodayDestination(context, destination),
              ),
            )
          : null,
      actions: [
        if (!usesCompactNavigation) ...[
          _NavButton(
            icon: Icons.list_alt_rounded,
            label: 'Mis hábitos',
            onTap: () => Navigator.of(context).push(
              PageTransitions.slideFromRight(const HabitsListScreen()),
            ),
          ),
          ContextualTooltip(
            tooltipKey: TooltipKeys.pomodoroButton,
            message: 'Timer de enfoque para trabajar concentrado ',
            position: TooltipPosition.below,
            enabled: (pomodoroState?.totalPomodoros ?? 0) == 0,
            child: _PomodoroNavButton(
              key: const ValueKey('today-focus-action'),
              pomodoroState: pomodoroState,
              compact: false,
              onTap: () => Navigator.of(context).push(
                PageTransitions.slideFromRight(const PomodoroScreen()),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.note_alt_outlined,
            label: 'Notas',
            onTap: () => Navigator.of(context).push(
              PageTransitions.slideFromRight(const NotesScreen()),
            ),
          ),
          _NavButton(
            icon: Icons.bar_chart_rounded,
            label: 'Progreso',
            onTap: () => Navigator.of(context).push(
              PageTransitions.slideFromRight(const ProgressScreen()),
            ),
          ),
          _NavButton(
            key: const ValueKey('today-calendar-action'),
            icon: Icons.calendar_month_rounded,
            label: 'Calendario',
            onTap: () => Navigator.of(context).push(
              PageTransitions.slideFromRight(const CalendarScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  void _openTodayDestination(
    BuildContext context,
    _TodayDestination destination,
  ) {
    final Widget screen = switch (destination) {
      _TodayDestination.habits => const HabitsListScreen(),
      _TodayDestination.notes => const NotesScreen(),
      _TodayDestination.focus => const PomodoroScreen(),
      _TodayDestination.progress => const ProgressScreen(),
      _TodayDestination.calendar => const CalendarScreen(),
    };

    Navigator.of(context).push(PageTransitions.slideFromRight(screen));
  }
}

class _TodayVisualBackground extends StatelessWidget {
  final TodayVisualStyle visualStyle;
  final bool useTopSafeArea;
  final Widget child;

  const _TodayVisualBackground({
    required this.visualStyle,
    required this.useTopSafeArea,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (visualStyle == TodayVisualStyle.classic) {
      return ZentraAmbientBackground(intensity: 0.8, child: child);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.zentraPalette;
    return DecoratedBox(
      key: const ValueKey('today-salvia-background'),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : null,
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [
                  palette.backgroundTop,
                  Theme.of(context).colorScheme.surface,
                ],
                stops: const [0, 0.42],
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
              ),
      ),
      child: SafeArea(
        top: useTopSafeArea,
        bottom: false,
        child: child,
      ),
    );
  }
}

class _TodayActionBar extends StatelessWidget {
  final PomodoroViewState? pomodoroState;
  final VoidCallback onOpenFocus;
  final VoidCallback onCreateHabit;

  const _TodayActionBar({
    required this.pomodoroState,
    required this.onOpenFocus,
    required this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.zentraPalette;
    final focusLabel = pomodoroState?.state == PomodoroState.running ||
            pomodoroState?.state == PomodoroState.paused
        ? pomodoroState!.formattedTime
        : 'Enfoque';

    return Material(
      color: isDark ? Colors.black : Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          key: const ValueKey('today-salvia-actions'),
          children: [
            Expanded(
              child: _TodayActionButton(
                key: const ValueKey('today-focus-launcher'),
                semanticsLabel: 'Abrir enfoque',
                label: focusLabel,
                icon: pomodoroState?.state == PomodoroState.running
                    ? Icons.timer_rounded
                    : Icons.play_arrow_rounded,
                backgroundColor: palette.brandTeal,
                foregroundColor:
                    isDark ? const Color(0xFF00201B) : Colors.white,
                onTap: onOpenFocus,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TodayActionButton(
                key: const ValueKey('today-add-habit'),
                semanticsLabel: 'Nuevo hábito',
                label: 'Hábito',
                icon: Icons.add_rounded,
                backgroundColor: isDark ? palette.surfaceCard : palette.ink,
                foregroundColor: isDark ? palette.brandTeal : palette.tealSoft,
                labelColor: const Color(0xFFF8F6F0),
                onTap: onCreateHabit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayActionButton extends StatelessWidget {
  final String semanticsLabel;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _TodayActionButton({
    required this.semanticsLabel,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.labelColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: () {
              triggerHaptic(HapticType.light);
              onTap();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: labelColor ?? foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
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

class _TodayHabitsPanel extends StatelessWidget {
  final HabitState state;
  final HabitController controller;
  final List<Habit> pendingHabits;
  final List<Habit> completedHabits;
  final bool isDark;
  final bool usesSalvia;
  final VoidCallback onCreateHabit;

  const _TodayHabitsPanel({
    required this.state,
    required this.controller,
    required this.pendingHabits,
    required this.completedHabits,
    required this.isDark,
    required this.usesSalvia,
    required this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    if (usesSalvia) {
      return Column(
        key: const ValueKey('today-habits-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingHabits.isNotEmpty || completedHabits.isNotEmpty) ...[
            _TodayHabitsHeader(
              onCreateHabit: onCreateHabit,
              usesSalvia: true,
            ),
            SizedBox(height: spacing.sm),
          ],
          if (pendingHabits.isEmpty && completedHabits.isEmpty)
            _EmptyState(
              onCreateHabit: onCreateHabit,
              usesSalvia: true,
            )
          else ...[
            for (var index = 0; index < pendingHabits.length; index++)
              _HabitListEntry(
                key: ValueKey('today-pending-${pendingHabits[index].id}'),
                habit: pendingHabits[index],
                state: state,
                controller: controller,
                isDark: isDark,
                usesSalvia: true,
                index: index,
                showTooltip: index == 0,
              ),
            for (var index = 0; index < completedHabits.length; index++)
              _HabitListEntry(
                key: ValueKey('today-completed-${completedHabits[index].id}'),
                habit: completedHabits[index],
                state: state,
                controller: controller,
                isDark: isDark,
                usesSalvia: true,
                index: index + pendingHabits.length,
              ),
          ],
        ],
      );
    }

    return Column(
      key: const ValueKey('today-habits-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingHabits.isNotEmpty || completedHabits.isNotEmpty) ...[
          _TodayHabitsHeader(
            onCreateHabit: onCreateHabit,
            usesSalvia: false,
          ),
          SizedBox(height: spacing.md),
        ],
        if (pendingHabits.isEmpty && completedHabits.isEmpty)
          _EmptyState(
            onCreateHabit: onCreateHabit,
            usesSalvia: false,
          )
        else ...[
          if (pendingHabits.isEmpty && completedHabits.isNotEmpty) ...[
            const _AllHabitsCompleteBanner(),
            SizedBox(height: spacing.md),
          ],
          if (pendingHabits.isNotEmpty) ...[
            _HabitSectionHeader(
              label: 'Pendientes',
              count: pendingHabits.length,
              icon: Icons.pending_actions_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: spacing.sm),
            for (var index = 0; index < pendingHabits.length; index++)
              _HabitListEntry(
                key: ValueKey('today-pending-${pendingHabits[index].id}'),
                habit: pendingHabits[index],
                state: state,
                controller: controller,
                isDark: isDark,
                index: index,
                showTooltip: index == 0,
              ),
          ],
          if (completedHabits.isNotEmpty) ...[
            if (pendingHabits.isNotEmpty) SizedBox(height: spacing.sm),
            _HabitSectionHeader(
              label: 'Completados',
              count: completedHabits.length,
              icon: Icons.check_circle_rounded,
              color: AppTheme.successGreen,
            ),
            SizedBox(height: spacing.sm),
            for (var index = 0; index < completedHabits.length; index++)
              _HabitListEntry(
                key: ValueKey('today-completed-${completedHabits[index].id}'),
                habit: completedHabits[index],
                state: state,
                controller: controller,
                isDark: isDark,
                index: index + pendingHabits.length,
              ),
          ],
        ],
      ],
    );
  }
}

class _TodayHabitsHeader extends StatelessWidget {
  final VoidCallback onCreateHabit;
  final bool usesSalvia;

  const _TodayHabitsHeader({
    required this.onCreateHabit,
    required this.usesSalvia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (usesSalvia) {
      return Text(
        'HÁBITOS',
        style: theme.textTheme.labelSmall?.copyWith(
          color: context.zentraPalette.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.5,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(16) > 24;
        final title = Text(
          'Hábitos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        );
        final action = TextButton.icon(
          key: const ValueKey('today-add-habit'),
          onPressed: onCreateHabit,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo hábito'),
        );
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            action,
          ],
        );
      },
    );
  }
}

class _HabitSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _HabitSectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSectionHeader(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(context.radii.small),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitListEntry extends StatelessWidget {
  final Habit habit;
  final HabitState state;
  final HabitController controller;
  final bool isDark;
  final bool usesSalvia;
  final int index;
  final bool showTooltip;

  const _HabitListEntry({
    required this.habit,
    required this.state,
    required this.controller,
    required this.isDark,
    required this.index,
    this.usesSalvia = false,
    this.showTooltip = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final card = HabitCard(
      habit: habit,
      isCompleted: state.isHabitCompleted(habit.id, now),
      streak: state.getHabitStreak(habit.id, now),
      onToggle: () => controller.toggleHabitToday(habit.id),
      onArchive: () => controller.toggleArchive(habit.id),
      onDelete: () => controller.deleteHabit(habit.id),
      isDark: isDark,
      salviaCompact: usesSalvia,
    );
    return AnimatedListItem(
      index: index,
      delay: const Duration(milliseconds: 60),
      child: showTooltip
          ? ContextualTooltip(
              tooltipKey: TooltipKeys.habitCard,
              message: 'Toca para marcar como completado',
              position: TooltipPosition.below,
              child: card,
            )
          : card,
    );
  }
}

class _AllHabitsCompleteBanner extends StatelessWidget {
  const _AllHabitsCompleteBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.opacity10,
        borderRadius: BorderRadius.circular(context.radii.medium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successGreen,
          ),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              'Listo por hoy.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionNoticeCard extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const _NotificationPermissionNoticeCard({
    required this.onOpenSettings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    return Semantics(
      key: const ValueKey('today-notification-permission-notice'),
      container: true,
      label:
          'Los avisos están apagados. Tus hábitos siguen funcionando. Puedes activarlos en Ajustes cuando quieras.',
      child: Container(
        padding: EdgeInsets.all(context.spacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(context.radii.large),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.warmPeach.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(context.radii.medium),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: palette.warmPeach,
              ),
            ),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Los avisos están apagados',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey(
                          'today-notification-permission-dismiss',
                        ),
                        onPressed: onDismiss,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Descartar aviso',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Tus hábitos siguen funcionando. Actívalos en Ajustes cuando quieras.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: context.spacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18;
                      final primary = FilledButton(
                        key: const ValueKey(
                          'today-notification-permission-settings',
                        ),
                        onPressed: onOpenSettings,
                        child: const Text('Abrir Ajustes'),
                      );
                      final later = TextButton(
                        key: const ValueKey(
                          'today-notification-permission-later',
                        ),
                        onPressed: onDismiss,
                        child: const Text('Más tarde'),
                      );
                      if (stack) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            primary,
                            SizedBox(height: context.spacing.xs),
                            later,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: primary),
                          SizedBox(width: context.spacing.sm),
                          Expanded(child: later),
                        ],
                      );
                    },
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

class _ProgressSection extends StatelessWidget {
  final HabitState state;
  final UserProfile? profile;
  final bool isDark;
  final bool usesSalvia;
  final VoidCallback onOpenProfile;

  const _ProgressSection({
    required this.state,
    required this.profile,
    required this.isDark,
    required this.usesSalvia,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final stats = state.getTodayStats(now);
    final completed = stats['completed'] ?? 0;
    final total = stats['total'] ?? 0;
    final progress = state.getDailyProgress(now);
    final liveHabitXp = state.logs.length * ProgressEngine.habitCompletionXp;
    final level = UserProfile.calculateLevel(
      max(profile?.totalXp ?? 0, liveHabitXp),
    );
    final levelName = UserProfile.getLevelName(level);
    final capitalizedDate = _formatSpanishDate(DateTime.now());
    final semanticValue = '$completed de $total hábitos completados';

    if (usesSalvia) {
      final palette = context.zentraPalette;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  capitalizedDate.toUpperCase().replaceFirst(',', ' ·'),
                  maxLines: 2,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.inkTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                key: const ValueKey('today-gamification-summary'),
                label: 'Nivel $level, $levelName',
                child: Container(
                  key: const ValueKey('today-level-chip'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.tealTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'lvl $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.brandTeal,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TodayIdentityMark(
                profile: profile,
                usesSalvia: true,
                onTap: onOpenProfile,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            key: const ValueKey('today-progress-summary'),
            container: true,
            excludeSemantics: true,
            label: 'Progreso de hoy',
            value: semanticValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _greeting(profile?.name),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: palette.ink,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        key: const ValueKey('today-progress-track'),
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: palette.brandTeal,
                          backgroundColor: palette.progressTrack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$completed/$total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.inkSecondary,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Semantics(
      key: const ValueKey('today-progress-summary'),
      container: true,
      excludeSemantics: true,
      label: 'Progreso de hoy',
      value: semanticValue,
      child: Container(
        padding: EdgeInsets.all(context.spacing.md),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient(colorScheme, isDark),
          borderRadius: BorderRadius.circular(context.radii.large),
          border: AppTheme.cardGradientBorder(colorScheme, isDark),
          boxShadow: AppTheme.cardShadow(colorScheme, isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(profile?.name),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        capitalizedDate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                _TodayIdentityMark(profile: profile),
              ],
            ),
            SizedBox(height: context.spacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.radii.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: context.spacing.xs,
              spacing: context.spacing.md,
              children: [
                Text(
                  '$completed de $total completados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Semantics(
                  key: const ValueKey('today-gamification-summary'),
                  label: 'Nivel $level, $levelName',
                  child: Text(
                    'Nivel $level · $levelName',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting(String? fullName) {
    final name = fullName?.trim().split(' ').first;
    final suffix = name == null || name.isEmpty ? '' : ', $name';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días$suffix';
    if (hour < 19) return 'Buenas tardes$suffix';
    return 'Buenas noches$suffix';
  }

  static String _formatSpanishDate(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} '
        'de ${months[date.month - 1]}';
  }
}

class _TodayIdentityMark extends StatelessWidget {
  final UserProfile? profile;
  final bool usesSalvia;
  final VoidCallback? onTap;

  const _TodayIdentityMark({
    required this.profile,
    this.usesSalvia = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (usesSalvia) {
      return Semantics(
        key: const ValueKey('today-profile-action'),
        button: true,
        label: 'Abrir perfil',
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Material(
              color: context.zentraPalette.tealTint,
              shape: const CircleBorder(),
              child: InkWell(
                excludeFromSemantics: true,
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: Text(
                      profile?.avatarEmoji ?? '😊',
                      style: const TextStyle(fontSize: 18),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: profile?.talismanId == null
          ? 'Avatar de perfil'
          : 'Avatar y talismán de perfil',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              profile?.avatarEmoji ?? '😊',
              style: Theme.of(context).textTheme.headlineSmall,
              textScaler: TextScaler.noScaling,
            ),
          ),
          if (profile?.talismanId != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(context.spacing.xxs),
                decoration: BoxDecoration(
                  color: context.zentraPalette.specialSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: context.zentraPalette.warmPeach,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayNoteReviewCard extends StatelessWidget {
  final int count;
  final String title;
  final DateTime? scheduledAt;
  final bool usesSalvia;
  final VoidCallback onTap;

  const _TodayNoteReviewCard({
    required this.count,
    required this.title,
    required this.scheduledAt,
    required this.usesSalvia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    if (usesSalvia) {
      final noteColor = AppTheme.getSalviaNoteColor(theme.brightness);
      final timeLabel = scheduledAt == null
          ? 'lista para revisar'
          : MaterialLocalizations.of(context).formatTimeOfDay(
              TimeOfDay.fromDateTime(scheduledAt!),
              alwaysUse24HourFormat:
                  MediaQuery.alwaysUse24HourFormatOf(context),
            );
      final meta =
          count == 1 ? 'Nota · hoy $timeLabel' : '$count notas para revisar';
      return DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0D1B2523),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('today-note-review-card'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2B1412)
                          : const Color(0xFFFDECEA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.push_pin_outlined,
                      size: 21,
                      color: noteColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trim().isEmpty ? 'Nota sin título' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: palette.inkDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: palette.specialSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.large),
        side: BorderSide(
          color: palette.warmPeach.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        key: const ValueKey('today-note-review-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.large),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.warmPeach.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(context.radii.medium),
                ),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: palette.warmPeach,
                ),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? 'Revisar nota' : 'Revisar $count notas',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.warmPeach,
                      ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      title.trim().isEmpty ? 'Nota sin título' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.spacing.sm),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  final PomodoroViewState? pomodoroState;
  final VoidCallback onTap;

  const _TodayFocusCard({
    required this.pomodoroState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = pomodoroState;
    final active = provider?.state == PomodoroState.running ||
        provider?.state == PomodoroState.paused;
    final title = active
        ? '${provider!.formattedTime} · ${provider.sessionLabel}'
        : '${provider?.workDuration ?? 25} min de enfoque';

    return Semantics(
      key: const ValueKey('today-focus-launcher'),
      button: true,
      label: 'Abrir enfoque',
      value: title,
      onTap: onTap,
      child: Material(
        color: context.zentraPalette.warmPeach.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.12,
        ),
        borderRadius: BorderRadius.circular(context.radii.large),
        child: InkWell(
          excludeFromSemantics: true,
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radii.large),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(context.radii.medium),
                  ),
                  child: Icon(
                    active ? Icons.timer_rounded : Icons.play_arrow_rounded,
                    color: colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active ? 'ENFOQUE ACTIVO' : 'ENFOQUE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.accentOrange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateHabit;
  final bool usesSalvia;

  const _EmptyState({
    required this.onCreateHabit,
    required this.usesSalvia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (usesSalvia) {
      final palette = context.zentraPalette;
      return Container(
        key: const ValueKey('today-empty-state'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: palette.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0D1B2523),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_task_rounded,
              color: palette.brandTeal,
              size: 30,
            ),
            const SizedBox(height: 16),
            Text(
              'Crea tu primer hábito',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige qué quieres repetir y cuándo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey('today-empty-state'),
      padding: EdgeInsets.all(context.spacing.xl),
      decoration: BoxDecoration(
        color: context.zentraPalette.specialSurface,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.zentraPalette.calmMint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_task_rounded,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            'Crea tu primer hábito',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Elige qué quieres repetir y cuándo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: FilledButton.icon(
              key: const ValueKey('today-empty-create-habit'),
              onPressed: onCreateHabit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear hábito'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryNavigationStrip extends StatelessWidget {
  final PomodoroViewState? pomodoroState;
  final ValueChanged<_TodayDestination> onSelected;
  final bool usesSalvia;

  const _PrimaryNavigationStrip({
    required this.pomodoroState,
    required this.onSelected,
    this.usesSalvia = false,
  });

  @override
  Widget build(BuildContext context) {
    final usesScrollableLayout =
        MediaQuery.textScalerOf(context).scale(12) > 18;

    if (usesSalvia && !usesScrollableLayout) {
      final destinations = _buildDestinations(context, vertical: true);
      return SizedBox(
        height: 68,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              Expanded(child: destinations[index]),
            ],
          ],
        ),
      );
    }

    if (!usesScrollableLayout) {
      final destinations = _buildDestinations(context, vertical: true);
      return SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(child: destinations[index]),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: _withSpacing(_buildDestinations(context)),
        ),
      ),
    );
  }

  List<Widget> _buildDestinations(
    BuildContext context, {
    bool vertical = false,
  }) {
    final palette = context.zentraPalette;
    final brightness = Theme.of(context).brightness;
    return [
      _PrimaryDestinationChip(
        icon: Icons.list_alt_rounded,
        label: usesSalvia ? 'Hábitos' : 'Mis hábitos',
        accent: usesSalvia
            ? AppTheme.getSalviaCategoryColor(Category.foco, brightness)
            : AppTheme.successGreen,
        selectedBackground: usesSalvia
            ? AppTheme.getCategoryTint(
                Category.foco,
                Theme.of(context).brightness,
              )
            : null,
        selected: usesSalvia,
        usesSalvia: usesSalvia,
        vertical: vertical,
        onTap: () => onSelected(_TodayDestination.habits),
      ),
      _PrimaryDestinationChip(
        key: const ValueKey('today-notes-action'),
        icon: Icons.note_alt_outlined,
        label: 'Notas',
        accent: usesSalvia
            ? AppTheme.getSalviaNoteColor(brightness)
            : palette.warmPeach,
        usesSalvia: usesSalvia,
        vertical: vertical,
        onTap: () => onSelected(_TodayDestination.notes),
      ),
      _PrimaryDestinationChip(
        key: const ValueKey('today-focus-action'),
        icon: Icons.timer_rounded,
        label: !usesSalvia &&
                (pomodoroState?.state == PomodoroState.running ||
                    pomodoroState?.state == PomodoroState.paused)
            ? pomodoroState!.formattedTime
            : 'Enfoque',
        accent: usesSalvia
            ? AppTheme.getSalviaCategoryColor(Category.movimiento, brightness)
            : AppTheme.accentOrange,
        selected: !usesSalvia &&
            (pomodoroState?.state == PomodoroState.running ||
                pomodoroState?.state == PomodoroState.paused),
        usesSalvia: usesSalvia,
        vertical: vertical,
        onTap: () => onSelected(_TodayDestination.focus),
      ),
      _PrimaryDestinationChip(
        icon: Icons.bar_chart_rounded,
        label: 'Progreso',
        accent: Theme.of(context).colorScheme.primary,
        usesSalvia: usesSalvia,
        vertical: vertical,
        onTap: () => onSelected(_TodayDestination.progress),
      ),
      _PrimaryDestinationChip(
        key: const ValueKey('today-calendar-action'),
        icon: Icons.calendar_month_rounded,
        label: usesSalvia ? 'Mes' : 'Calendario',
        semanticsLabel: 'Calendario',
        accent: usesSalvia
            ? AppTheme.getSalviaCategoryColor(Category.sueno, brightness)
            : palette.sleep,
        usesSalvia: usesSalvia,
        vertical: vertical,
        onTap: () => onSelected(_TodayDestination.calendar),
      ),
    ];
  }

  List<Widget> _withSpacing(List<Widget> destinations) {
    return [
      for (var index = 0; index < destinations.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        destinations[index],
      ],
    ];
  }
}

class _PrimaryDestinationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? semanticsLabel;
  final VoidCallback onTap;
  final bool selected;
  final bool vertical;
  final bool usesSalvia;
  final Color accent;
  final Color? selectedBackground;

  const _PrimaryDestinationChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    this.selected = false,
    this.vertical = false,
    this.usesSalvia = false,
    this.selectedBackground,
    this.semanticsLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;
    final foreground = usesSalvia
        ? (selected ? accent : palette.inkTertiary)
        : (selected ? colorScheme.onPrimaryContainer : accent);
    final iconColor = usesSalvia ? accent : foreground;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      onTap: onTap,
      child: Opacity(
        opacity: usesSalvia && !selected ? 0.55 : 1,
        child: Material(
          color: selected
              ? selectedBackground ?? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: InkWell(
              excludeFromSemantics: true,
              onTap: () {
                triggerHaptic(HapticType.light);
                onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: vertical ? 2 : 12,
                  vertical: vertical ? 5 : 8,
                ),
                child: Flex(
                  direction: vertical ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: vertical ? 21 : 20, color: iconColor),
                    SizedBox(
                      width: vertical ? 0 : 7,
                      height: vertical ? 4 : 0,
                    ),
                    Flexible(
                      child: Text(
                        key: ValueKey('today-destination-label-$label'),
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: (vertical
                                ? Theme.of(context).textTheme.labelSmall
                                : Theme.of(context).textTheme.labelLarge)
                            ?.copyWith(
                          color: foreground,
                          fontSize: usesSalvia && vertical ? 10 : null,
                          fontWeight:
                              usesSalvia ? FontWeight.w500 : FontWeight.w700,
                          letterSpacing: usesSalvia ? 0.3 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pomodoro navigation button - Muestra timer y color según tipo de sesión
class _PomodoroNavButton extends StatelessWidget {
  final PomodoroViewState? pomodoroState;
  final VoidCallback onTap;
  final bool compact;

  const _PomodoroNavButton({
    required this.pomodoroState,
    required this.onTap,
    required this.compact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Obtener info del Pomodoro
    final isRunning = pomodoroState?.state == PomodoroState.running;
    final isPaused = pomodoroState?.state == PomodoroState.paused;
    final sessionType = pomodoroState?.sessionType ?? SessionType.work;
    final formattedTime = pomodoroState?.formattedTime ?? '25:00';

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
      sessionLabel = 'Enfoque';
    }

    return Semantics(
      button: true,
      label: sessionLabel,
      onTap: onTap,
      child: Tooltip(
        message: sessionLabel,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: buttonColor.withValues(alpha: isDark ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              excludeFromSemantics: true,
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : (isRunning || isPaused ? 12 : 14),
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono con animación de pulso si está corriendo
                    _AnimatedPomodoroIcon(
                      isRunning: isRunning,
                      color: buttonColor,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      // Timer o texto
                      if (isRunning || isPaused)
                        Text(
                          sessionLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: buttonColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      else
                        Text(
                          sessionLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: buttonColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedPomodoroIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.isRunning && context.motionPolicy.allowsDecorativeMotion;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate) {
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
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: Tooltip(
        message: label,
        preferBelow: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              excludeFromSemantics: true,
              onTap: () {
                triggerHaptic(HapticType.light);
                onTap();
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
