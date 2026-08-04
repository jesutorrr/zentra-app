import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/habit_controller.dart';
import '../application/habit_state.dart';
import '../application/session_controller.dart';
import '../domain/models.dart';
import 'design_tokens.dart';
import 'habit_form_screen.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/feedback_utils.dart';
import 'utils/page_transitions.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/skeleton_loader.dart';

enum _HabitStatusFilter {
  active,
  archived,
}

enum _HabitCardAction {
  edit,
  toggleArchive,
  delete,
}

/// Management surface for every habit.
///
/// The screen intentionally keeps one route and adapts the composition from a
/// single readable list to list-detail according to available width.
class ClassicHabitsListScreen extends ConsumerStatefulWidget {
  const ClassicHabitsListScreen({super.key});

  @override
  ConsumerState<ClassicHabitsListScreen> createState() =>
      _ClassicHabitsListScreenState();
}

class _ClassicHabitsListScreenState
    extends ConsumerState<ClassicHabitsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _mutatingHabitIds = <String>{};
  final Set<String> _confirmingDeleteIds = <String>{};
  _HabitStatusFilter _filter = _HabitStatusFilter.active;
  String _query = '';
  String? _selectedHabitId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    final workspace = ownerId == null
        ? const AsyncValue<HabitState>.loading()
        : ref.watch(habitControllerProvider(ownerId));
    final isCompactWidth =
        MediaQuery.sizeOf(context).width < ZentraBreakpoints.medium;
    return Scaffold(
      key: const ValueKey('habits-screen'),
      appBar: AppBar(
        title: const Text('Mis hábitos'),
        centerTitle: false,
        actions: [
          if (isCompactWidth)
            IconButton(
              key: const ValueKey('habits-add'),
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              tooltip: 'Nuevo hábito',
              onPressed: () => _navigateToForm(context),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: ResponsiveLayoutBuilder(
        builder: (context, layout) {
          final usesExpandedLayout = layout.isExpanded &&
              !layout.isShort &&
              MediaQuery.textScalerOf(context).scale(16) <= 22;

          if (workspace.isLoading) {
            return _PageFrame(
              layout: layout,
              maxWidth: usesExpandedLayout ? 1180 : 720,
              child: const _HabitsLoadingState(),
            );
          }

          final state = workspace.valueOrNull;
          if (state == null ||
              ((workspace.hasError || state.error != null) &&
                  state.habits.isEmpty)) {
            return _PageFrame(
              layout: layout,
              maxWidth: 720,
              child: _ErrorState(
                onRetry: () => _retry(
                  habitControllerProvider(ownerId!),
                ),
              ),
            );
          }

          if (state.habits.isEmpty) {
            return _PageFrame(
              layout: layout,
              maxWidth: 720,
              child: _TotalEmptyState(
                isCompact: layout.isCompact,
                onCreateHabit: () => _navigateToForm(context),
              ),
            );
          }

          final visibleHabits = _visibleHabits(state);
          final selectedHabit = _selectedHabit(
            visibleHabits,
            state,
          );
          final header = _HabitsHeader(
            state: state,
            isCompact: layout.isCompact,
            onCreateHabit: () => _navigateToForm(context),
          );
          final controls = _HabitsControls(
            searchController: _searchController,
            query: _query,
            filter: _filter,
            onQueryChanged: (value) {
              setState(() {
                _query = value;
                _selectedHabitId = null;
              });
            },
            onFilterChanged: (value) {
              setState(() {
                _filter = value;
                _selectedHabitId = null;
              });
            },
          );

          if (!usesExpandedLayout) {
            return _PageFrame(
              layout: layout,
              maxWidth: 720,
              child: ListView(
                key: const ValueKey('habits-single-column-layout'),
                physics: const BouncingScrollPhysics(),
                children: [
                  header,
                  SizedBox(
                    height: layout.isCompact
                        ? context.spacing.md
                        : context.spacing.lg,
                  ),
                  controls,
                  SizedBox(
                    height: layout.isCompact
                        ? context.spacing.md
                        : context.spacing.lg,
                  ),
                  if (visibleHabits.isEmpty)
                    _EmptyResults(
                      query: _query,
                      filter: _filter,
                      onClear: _clearResults,
                    )
                  else
                    ...visibleHabits.map(
                      (habit) => Padding(
                        padding: EdgeInsets.only(
                          bottom: context.spacing.sm,
                        ),
                        child: _HabitManagementCard(
                          habit: habit,
                          state: state,
                          isBusy: _isHabitBusy(habit.id),
                          showsActionsMenu: true,
                          tapOpensDetails: false,
                          onTap: () => _navigateToForm(
                            context,
                            habitId: habit.id,
                          ),
                          onEdit: () => _navigateToForm(
                            context,
                            habitId: habit.id,
                          ),
                          onToggleCompletion: () => _toggleCompletion(
                            habitControllerProvider(ownerId!),
                            state,
                            habit,
                          ),
                          onToggleArchive: () => _toggleArchive(
                            habitControllerProvider(ownerId!),
                            habit,
                          ),
                          onDelete: () => _confirmDelete(
                            habitControllerProvider(ownerId!),
                            habit,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return _PageFrame(
            layout: layout,
            maxWidth: 1180,
            child: Column(
              key: const ValueKey('habits-expanded-layout'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: context.spacing.lg),
                controls,
                SizedBox(height: context.spacing.lg),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          key: const ValueKey('habits-list-panel'),
                          decoration: _panelDecoration(context),
                          padding: EdgeInsets.all(context.spacing.md),
                          child: visibleHabits.isEmpty
                              ? _EmptyResults(
                                  query: _query,
                                  filter: _filter,
                                  onClear: _clearResults,
                                )
                              : ListView.separated(
                                  itemCount: visibleHabits.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                    height: context.spacing.sm,
                                  ),
                                  itemBuilder: (context, index) {
                                    final habit = visibleHabits[index];
                                    return _HabitManagementCard(
                                      habit: habit,
                                      state: state,
                                      isBusy: _isHabitBusy(habit.id),
                                      showsActionsMenu: false,
                                      tapOpensDetails: true,
                                      isSelected: selectedHabit?.id == habit.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedHabitId = habit.id;
                                        });
                                      },
                                      onEdit: () => _navigateToForm(
                                        context,
                                        habitId: habit.id,
                                      ),
                                      onToggleCompletion: () =>
                                          _toggleCompletion(
                                        habitControllerProvider(
                                          ownerId!,
                                        ),
                                        state,
                                        habit,
                                      ),
                                      onToggleArchive: () => _toggleArchive(
                                        habitControllerProvider(
                                          ownerId!,
                                        ),
                                        habit,
                                      ),
                                      onDelete: () => _confirmDelete(
                                        habitControllerProvider(
                                          ownerId!,
                                        ),
                                        habit,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      SizedBox(width: context.spacing.lg),
                      Expanded(
                        flex: 2,
                        child: _HabitDetailPanel(
                          habit: selectedHabit,
                          state: state,
                          isBusy: selectedHabit != null &&
                              _isHabitBusy(selectedHabit.id),
                          onEdit: selectedHabit == null
                              ? null
                              : () => _navigateToForm(
                                    context,
                                    habitId: selectedHabit.id,
                                  ),
                          onToggleArchive: selectedHabit == null
                              ? null
                              : () => _toggleArchive(
                                    habitControllerProvider(ownerId!),
                                    selectedHabit,
                                  ),
                          onDelete: selectedHabit == null
                              ? null
                              : () => _confirmDelete(
                                    habitControllerProvider(ownerId!),
                                    selectedHabit,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Habit> _visibleHabits(HabitState state) {
    final source = _filter == _HabitStatusFilter.active
        ? state.activeHabits
        : state.archivedHabits;
    final normalizedQuery = _normalizeForSearch(_query.trim());
    if (normalizedQuery.isEmpty) return source;

    return source.where((habit) {
      return _normalizeForSearch(habit.title).contains(normalizedQuery) ||
          _normalizeForSearch(habit.category.label).contains(normalizedQuery);
    }).toList();
  }

  Habit? _selectedHabit(
    List<Habit> visibleHabits,
    HabitState state,
  ) {
    if (visibleHabits.isEmpty) return null;
    final selectedId = _selectedHabitId;
    if (selectedId != null) {
      final selected = state.getHabitById(selectedId);
      if (selected != null &&
          visibleHabits.any((habit) => habit.id == selected.id)) {
        return selected;
      }
    }
    return visibleHabits.first;
  }

  void _clearResults() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedHabitId = null;
      final ownerId = ref.read(activeOwnerIdProvider);
      final state = ownerId == null
          ? null
          : ref.read(habitControllerProvider(ownerId)).valueOrNull;
      final currentIsEmpty = _filter == _HabitStatusFilter.active
          ? state?.activeHabits.isEmpty ?? true
          : state?.archivedHabits.isEmpty ?? true;
      if (currentIsEmpty) {
        _filter = _filter == _HabitStatusFilter.active
            ? _HabitStatusFilter.archived
            : _HabitStatusFilter.active;
      }
    });
  }

  Future<void> _retry(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
  ) async {
    ref.read(provider.notifier).clearError();
    await ref.read(provider.notifier).reload();
  }

  Future<void> _navigateToForm(
    BuildContext context, {
    String? habitId,
  }) async {
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        HabitFormScreen(habitId: habitId),
      ),
    );
  }

  Future<bool> _runMutation(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
    Future<void> Function() action,
  ) async {
    if (_mutatingHabitIds.contains(habit.id)) return false;
    setState(() => _mutatingHabitIds.add(habit.id));
    try {
      ref.read(provider.notifier).clearError();
      await action();
      if (!mounted) return false;
      if (ref.read(provider).valueOrNull?.error != null) {
        showErrorSnackbar(context, 'No pudimos guardar el cambio.');
        return false;
      }
      return true;
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'No pudimos guardar el cambio.');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _mutatingHabitIds.remove(habit.id));
      }
    }
  }

  bool _isHabitBusy(String habitId) {
    return _mutatingHabitIds.contains(habitId) ||
        _confirmingDeleteIds.contains(habitId);
  }

  Future<void> _toggleCompletion(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    HabitState state,
    Habit habit,
  ) async {
    if (!habit.isScheduledFor(DateTime.now())) return;
    final wasCompleted = state.isHabitCompleted(habit.id, DateTime.now());
    final succeeded = await _runMutation(
      provider,
      habit,
      () => ref.read(provider.notifier).toggleHabitToday(habit.id),
    );
    if (!mounted || !succeeded) return;

    final isCompleted = ref
            .read(provider)
            .valueOrNull
            ?.isHabitCompleted(habit.id, DateTime.now()) ??
        false;
    if (!wasCompleted && isCompleted) {
      triggerCompletionFeedback();
      showSuccessSnackbar(context, 'Hábito completado');
    } else if (wasCompleted && !isCompleted) {
      showSuccessSnackbar(context, 'Hábito marcado como pendiente');
    }
  }

  Future<void> _toggleArchive(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
  ) async {
    final succeeded = await _runMutation(
      provider,
      habit,
      () => ref.read(provider.notifier).toggleArchive(habit.id),
    );
    if (!mounted || !succeeded) return;

    showSuccessSnackbar(
      context,
      habit.isArchived ? 'Hábito restaurado' : 'Hábito archivado',
      icon: habit.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
    );
  }

  Future<void> _confirmDelete(
    AsyncNotifierFamilyProvider<HabitController, HabitState, String> provider,
    Habit habit,
  ) async {
    if (_isHabitBusy(habit.id)) return;
    setState(() => _confirmingDeleteIds.add(habit.id));
    bool? confirmed;
    try {
      confirmed = await showConfirmDialog(
        context: context,
        title: 'Eliminar hábito',
        message:
            '¿Eliminar "${habit.title}"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        icon: Icons.delete_forever_rounded,
        isDangerous: true,
      );
    } finally {
      if (mounted) {
        setState(() => _confirmingDeleteIds.remove(habit.id));
      }
    }
    if (confirmed != true || !mounted) return;

    final succeeded = await _runMutation(
      provider,
      habit,
      () => ref.read(provider.notifier).deleteHabit(habit.id),
    );
    if (!mounted || !succeeded) return;
    showSuccessSnackbar(context, 'Hábito eliminado');
  }
}

class _PageFrame extends StatelessWidget {
  final ResponsiveLayoutData layout;
  final double maxWidth;
  final Widget child;

  const _PageFrame({
    required this.layout,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPagePadding,
        layout.verticalPagePadding,
        layout.horizontalPagePadding,
        context.spacing.lg,
      ),
      child: ResponsiveContentFrame(
        maxWidth: maxWidth,
        child: child,
      ),
    );
  }
}

class _HabitsLoadingState extends StatelessWidget {
  const _HabitsLoadingState();

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      key: const ValueKey('habits-loading-scroll'),
      physics: const ClampingScrollPhysics(),
      child: reducedMotion
          ? const _StaticHabitListPlaceholder(itemCount: 4)
          : const HabitListSkeleton(itemCount: 4),
    );
  }
}

class _StaticHabitListPlaceholder extends StatelessWidget {
  final int itemCount;

  const _StaticHabitListPlaceholder({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando hábitos',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey('habits-loading-static'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StaticPlaceholderBox(height: 96),
            SizedBox(height: context.spacing.md),
            const _StaticPlaceholderBox(height: 56),
            SizedBox(height: context.spacing.md),
            for (var index = 0; index < itemCount; index++) ...[
              const _StaticPlaceholderBox(height: 156),
              if (index < itemCount - 1) SizedBox(height: context.spacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaticPlaceholderBox extends StatelessWidget {
  final double height;

  const _StaticPlaceholderBox({required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
    );
  }
}

class _HabitsHeader extends StatelessWidget {
  final HabitState state;
  final bool isCompact;
  final VoidCallback onCreateHabit;

  const _HabitsHeader({
    required this.state,
    required this.isCompact,
    required this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = context.zentraPalette;
    final activeCount = state.activeHabits.length;
    final completedToday = state.getCompletionCount(DateTime.now());
    var bestStreak = 0;
    for (final habit in state.activeHabits) {
      final streak = state.getHabitStreak(habit.id, DateTime.now());
      if (streak > bestStreak) bestStreak = streak;
    }

    if (isCompact) {
      return Column(
        key: const ValueKey('habits-compact-header'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Constancia antes que perfección',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: context.spacing.sm),
          _CompactMetricsStrip(
            activeCount: activeCount,
            completedToday: completedToday,
            bestStreak: bestStreak,
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('habits-wide-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacks = constraints.maxWidth < 520 ||
                MediaQuery.textScalerOf(context).scale(16) > 23;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Constancia antes que perfección',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: context.spacing.xs),
                Text(
                  'Organiza lo que repites y conserva claro el siguiente paso.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
            final add = FilledButton.icon(
              key: const ValueKey('habits-add'),
              onPressed: onCreateHabit,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo hábito'),
            );

            if (stacks) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  SizedBox(height: context.spacing.md),
                  add,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: copy),
                SizedBox(width: context.spacing.md),
                add,
              ],
            );
          },
        ),
        SizedBox(height: context.spacing.lg),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                palette.specialSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(context.radii.large),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: EdgeInsets.all(context.spacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                _MetricTile(
                  icon: Icons.format_list_bulleted_rounded,
                  value: '$activeCount',
                  label: 'activos',
                ),
                _MetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$completedToday',
                  label: 'completados hoy',
                ),
                _MetricTile(
                  icon: Icons.local_fire_department_outlined,
                  value: '$bestStreak',
                  label: 'mejor racha',
                ),
              ];
              final distributesMetrics = constraints.maxWidth >= 560 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 22;
              if (distributesMetrics) {
                return Row(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      Expanded(child: metrics[index]),
                      if (index < metrics.length - 1)
                        SizedBox(width: context.spacing.sm),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: metrics,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactMetricsStrip extends StatelessWidget {
  final int activeCount;
  final int completedToday;
  final int bestStreak;

  const _CompactMetricsStrip({
    required this.activeCount,
    required this.completedToday,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = [
      (
        icon: Icons.format_list_bulleted_rounded,
        value: activeCount,
        label: 'Activos',
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        value: completedToday,
        label: 'Hoy',
      ),
      (
        icon: Icons.local_fire_department_outlined,
        value: bestStreak,
        label: 'Mejor racha',
      ),
    ];
    return Container(
      key: const ValueKey('habits-compact-metrics'),
      padding: EdgeInsets.all(context.spacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.medium),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usesVerticalMetrics =
              MediaQuery.textScalerOf(context).scale(12) > 23;
          if (usesVerticalMetrics) {
            return Column(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  _CompactMetricTile(
                    icon: metrics[index].icon,
                    value: metrics[index].value,
                    label: metrics[index].label,
                    isHorizontal: true,
                  ),
                  if (index < metrics.length - 1)
                    Divider(
                      height: context.spacing.xs,
                      color: colorScheme.outlineVariant,
                    ),
                ],
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _CompactMetricTile(
                    icon: metrics[index].icon,
                    value: metrics[index].value,
                    label: metrics[index].label,
                  ),
                ),
                if (index < metrics.length - 1)
                  SizedBox(
                    height: 44,
                    child: VerticalDivider(
                      width: context.spacing.xs,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final bool isHorizontal;

  const _CompactMetricTile({
    required this.icon,
    required this.value,
    required this.label,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: isHorizontal
              ? Row(
                  children: [
                    Icon(icon, color: colorScheme.primary, size: 20),
                    SizedBox(width: context.spacing.xs),
                    Text('$value', style: theme.textTheme.titleMedium),
                    SizedBox(width: context.spacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        style: labelStyle,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: colorScheme.primary, size: 20),
                    SizedBox(height: context.spacing.xxs),
                    Text('$value', style: theme.textTheme.titleMedium),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(context.radii.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary),
            SizedBox(width: context.spacing.xs),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$value ',
                      style: theme.textTheme.titleMedium,
                    ),
                    TextSpan(
                      text: label,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitsControls extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final _HabitStatusFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_HabitStatusFilter> onFilterChanged;

  const _HabitsControls({
    required this.searchController,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('habits-search'),
          controller: searchController,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o categoría',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      searchController.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xs,
          children: [
            ChoiceChip(
              key: const ValueKey('habits-filter-active'),
              selected: filter == _HabitStatusFilter.active,
              onSelected: (_) => onFilterChanged(_HabitStatusFilter.active),
              avatar: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Activos'),
            ),
            ChoiceChip(
              key: const ValueKey('habits-filter-archived'),
              selected: filter == _HabitStatusFilter.archived,
              onSelected: (_) => onFilterChanged(_HabitStatusFilter.archived),
              avatar: const Icon(Icons.archive_outlined),
              label: const Text('Archivados'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HabitManagementCard extends StatelessWidget {
  final Habit habit;
  final HabitState state;
  final bool isBusy;
  final bool isSelected;
  final bool showsActionsMenu;
  final bool tapOpensDetails;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onToggleCompletion;
  final Future<void> Function() onToggleArchive;
  final Future<void> Function() onDelete;

  const _HabitManagementCard({
    required this.habit,
    required this.state,
    required this.isBusy,
    required this.showsActionsMenu,
    required this.tapOpensDetails,
    required this.onTap,
    required this.onEdit,
    required this.onToggleCompletion,
    required this.onToggleArchive,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor =
        AppTheme.getCategoryColor(habit.category, colorScheme);
    final categoryIcon = AppTheme.getCategoryIcon(habit.category);
    final categoryActionBackground = _categoryControlBackground(
      context,
      categoryColor,
      emphasized: true,
    );
    final isScheduledToday = habit.isScheduledFor(DateTime.now());
    final isCompleted = state.isHabitCompleted(habit.id, DateTime.now());
    final streak = state.getHabitStreak(habit.id, DateTime.now());

    return Slidable(
      key: ValueKey('habit-row-${habit.id}'),
      enabled: !isBusy,
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            icon: Icons.edit_rounded,
            label: 'Editar',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) async => onToggleArchive(),
            backgroundColor: categoryActionBackground,
            foregroundColor: colorScheme.onSurface,
            icon: habit.isArchived
                ? Icons.unarchive_rounded
                : Icons.archive_rounded,
            label: habit.isArchived ? 'Restaurar' : 'Archivar',
          ),
          SlidableAction(
            onPressed: (_) async => onDelete(),
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: habit.isArchived
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.large),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : categoryColor.withValues(alpha: 0.34),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: tapOpensDetails
                          ? 'Ver detalles de ${habit.title}'
                          : 'Editar ${habit.title}',
                      onTap: onTap,
                      child: InkWell(
                        onTap: onTap,
                        excludeFromSemantics: true,
                        borderRadius:
                            BorderRadius.circular(context.radii.medium),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: context.spacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                    context.radii.small,
                                  ),
                                ),
                                child: Icon(
                                  categoryIcon,
                                  color: categoryColor,
                                ),
                              ),
                              SizedBox(width: context.spacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.title,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    SizedBox(height: context.spacing.xxs),
                                    Wrap(
                                      spacing: context.spacing.xs,
                                      runSpacing: context.spacing.xxs,
                                      children: [
                                        _MetadataLabel(
                                          key: ValueKey(
                                            'habit-category-label-${habit.id}',
                                          ),
                                          icon: categoryIcon,
                                          label: habit.category.label,
                                          color: categoryColor,
                                        ),
                                        if (habit.isArchived)
                                          _MetadataLabel(
                                            icon: Icons.archive_outlined,
                                            label: 'Archivado',
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showsActionsMenu) ...[
                    SizedBox(width: context.spacing.xs),
                    _HabitActionsMenu(
                      habit: habit,
                      isBusy: isBusy,
                      onSelected: _handleAction,
                    ),
                  ],
                ],
              ),
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.xs,
                children: [
                  _MetadataLabel(
                    icon: Icons.repeat_rounded,
                    label: _frequencyLabel(context, habit),
                  ),
                  _MetadataLabel(
                    icon: Icons.local_fire_department_outlined,
                    label: '$streak ${streak == 1 ? 'día' : 'días'}',
                  ),
                  _MetadataLabel(
                    icon: habit.hasReminder
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    label: _reminderLabel(context, habit),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.md),
              if (habit.isArchived)
                _RestoreControl(
                  habit: habit,
                  isBusy: isBusy,
                  onRestore: onToggleArchive,
                )
              else if (isScheduledToday)
                _CompletionControl(
                  habit: habit,
                  isCompleted: isCompleted,
                  isBusy: isBusy,
                  categoryColor: categoryColor,
                  onToggle: onToggleCompletion,
                )
              else
                Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.sm,
                    vertical: context.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(context.radii.medium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: context.spacing.xs),
                      Expanded(
                        child: Text(
                          'Hoy no toca. Se mantiene listo para su próximo día.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
  }

  Future<void> _handleAction(_HabitCardAction action) async {
    switch (action) {
      case _HabitCardAction.edit:
        onEdit();
        return;
      case _HabitCardAction.toggleArchive:
        await onToggleArchive();
        return;
      case _HabitCardAction.delete:
        await onDelete();
        return;
    }
  }
}

class _HabitActionsMenu extends StatelessWidget {
  final Habit habit;
  final bool isBusy;
  final ValueChanged<_HabitCardAction> onSelected;

  const _HabitActionsMenu({
    required this.habit,
    required this.isBusy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        final openMenu = isBusy ? null : () => _openMenu(buttonContext);
        return Semantics(
          key: ValueKey('habit-actions-${habit.id}'),
          button: true,
          enabled: !isBusy,
          label: 'Más acciones para ${habit.title}',
          onTap: openMenu,
          child: ExcludeSemantics(
            child: IconButton(
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              tooltip: 'Más acciones para ${habit.title}',
              onPressed: openMenu,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMenu(BuildContext buttonContext) async {
    final buttonBox = buttonContext.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(buttonContext).overlay!;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final topLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final selected = await showMenu<_HabitCardAction>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + buttonBox.size.height,
        overlayBox.size.width - topLeft.dx - buttonBox.size.width,
        overlayBox.size.height - topLeft.dy - buttonBox.size.height,
      ),
      items: [
        PopupMenuItem(
          key: ValueKey('habit-action-edit-${habit.id}'),
          value: _HabitCardAction.edit,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_rounded),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          key: ValueKey('habit-action-archive-${habit.id}'),
          value: _HabitCardAction.toggleArchive,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              habit.isArchived
                  ? Icons.unarchive_rounded
                  : Icons.archive_rounded,
            ),
            title: Text(
              habit.isArchived ? 'Restaurar' : 'Archivar',
            ),
          ),
        ),
        PopupMenuItem(
          key: ValueKey('habit-action-delete-${habit.id}'),
          value: _HabitCardAction.delete,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Eliminar'),
          ),
        ),
      ],
    );
    if (selected != null) {
      onSelected(selected);
    }
  }
}

class _CompletionControl extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final bool isBusy;
  final Color categoryColor;
  final Future<void> Function() onToggle;

  const _CompletionControl({
    required this.habit,
    required this.isCompleted,
    required this.isBusy,
    required this.categoryColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final action = isBusy ? null : onToggle;
    final colorScheme = Theme.of(context).colorScheme;
    final background = _categoryControlBackground(
      context,
      categoryColor,
      emphasized: isCompleted,
    );
    return Semantics(
      key: ValueKey('habit-complete-${habit.id}'),
      button: true,
      enabled: !isBusy,
      toggled: isCompleted,
      label: isCompleted
          ? 'Marcar ${habit.title} como pendiente'
          : 'Marcar ${habit.title} como completado',
      onTap: action,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FilledButton.icon(
            onPressed: action,
            style: FilledButton.styleFrom(
              backgroundColor: background,
              foregroundColor: colorScheme.onSurface,
              disabledBackgroundColor: background.withValues(alpha: 0.62),
              disabledForegroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.62),
              side: BorderSide(
                color: categoryColor.withValues(alpha: 0.72),
              ),
            ),
            icon: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
            ),
            label: Text(isCompleted ? 'Completado hoy' : 'Completar hoy'),
          ),
        ),
      ),
    );
  }
}

class _RestoreControl extends StatelessWidget {
  final Habit habit;
  final bool isBusy;
  final Future<void> Function() onRestore;

  const _RestoreControl({
    required this.habit,
    required this.isBusy,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final action = isBusy ? null : onRestore;
    return Semantics(
      key: ValueKey('habit-restore-${habit.id}'),
      button: true,
      enabled: !isBusy,
      label: 'Restaurar ${habit.title}',
      onTap: action,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.unarchive_rounded),
            label: const Text('Restaurar hábito'),
          ),
        ),
      ),
    );
  }
}

class _HabitDetailPanel extends StatelessWidget {
  final Habit? habit;
  final HabitState state;
  final bool isBusy;
  final VoidCallback? onEdit;
  final Future<void> Function()? onToggleArchive;
  final Future<void> Function()? onDelete;

  const _HabitDetailPanel({
    required this.habit,
    required this.state,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selected = habit;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey('habits-detail-panel'),
      decoration: _panelDecoration(context),
      padding: EdgeInsets.all(context.spacing.lg),
      child: selected == null
          ? Center(
              child: Text(
                'Selecciona un hábito para ver sus detalles.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHero(habit: selected),
                  SizedBox(height: context.spacing.lg),
                  _DetailLine(
                    label: 'Frecuencia',
                    value: _frequencyLabel(context, selected),
                  ),
                  _DetailLine(
                    label: 'Racha actual',
                    value:
                        '${state.getHabitStreak(selected.id, DateTime.now())} días',
                  ),
                  _DetailLine(
                    label: 'Recordatorio',
                    value: _reminderLabel(context, selected),
                  ),
                  _DetailLine(
                    label: 'Hoy',
                    value: selected.isArchived
                        ? 'Archivado'
                        : selected.isScheduledFor(DateTime.now())
                            ? state.isHabitCompleted(
                                selected.id,
                                DateTime.now(),
                              )
                                ? 'Completado'
                                : 'Pendiente'
                            : 'No programado',
                  ),
                  SizedBox(height: context.spacing.lg),
                  _DetailAction(
                    child: FilledButton.icon(
                      key: const ValueKey('habit-detail-edit'),
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  _DetailAction(
                    child: OutlinedButton.icon(
                      key: const ValueKey('habit-detail-archive'),
                      onPressed: isBusy ? null : () => onToggleArchive?.call(),
                      icon: Icon(
                        selected.isArchived
                            ? Icons.unarchive_rounded
                            : Icons.archive_rounded,
                      ),
                      label: Text(
                        selected.isArchived ? 'Restaurar' : 'Archivar',
                      ),
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  _DetailAction(
                    child: TextButton.icon(
                      key: const ValueKey('habit-detail-delete'),
                      onPressed: isBusy ? null : () => onDelete?.call(),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final Habit habit;

  const _DetailHero({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = AppTheme.getCategoryColor(habit.category, colorScheme);
    final icon = AppTheme.getCategoryIcon(habit.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(context.radii.medium),
          ),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: context.spacing.md),
        Text(habit.title, style: theme.textTheme.headlineSmall),
        SizedBox(height: context.spacing.xs),
        _MetadataLabel(
          icon: icon,
          label: habit.category.label,
          color: color,
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.xxs),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  final Widget child;

  const _DetailAction({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetadataLabel({
    required this.icon,
    required this.label,
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final identityColor = color ?? colorScheme.onSurfaceVariant;
    final background = Color.alphaBlend(
      identityColor.withValues(alpha: 0.1),
      colorScheme.surface,
    );
    final foreground = _contrastSafeMetadataForeground(
      colorScheme,
      background,
    );
    final iconForeground = _contrastRatio(identityColor, background) >= 4.5
        ? identityColor
        : foreground;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.radii.pill),
        border: Border.all(
          color: identityColor.withValues(alpha: 0.32),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: context.spacing.xxs,
        children: [
          Icon(icon, size: 16, color: iconForeground),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _contrastSafeMetadataForeground(
  ColorScheme colorScheme,
  Color background,
) {
  if (_contrastRatio(colorScheme.onSurfaceVariant, background) >= 4.5) {
    return colorScheme.onSurfaceVariant;
  }
  return colorScheme.onSurface;
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance < secondLuminance ? firstLuminance : secondLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _EmptyResults extends StatelessWidget {
  final String query;
  final _HabitStatusFilter filter;
  final VoidCallback onClear;

  const _EmptyResults({
    required this.query,
    required this.filter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          key: const ValueKey('habits-empty-results'),
          padding: EdgeInsets.all(context.spacing.xl),
          decoration: _panelDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                color: colorScheme.primary,
                size: 44,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                hasQuery
                    ? 'No encontramos coincidencias'
                    : filter == _HabitStatusFilter.active
                        ? 'No hay hábitos activos'
                        : 'No hay hábitos archivados',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                hasQuery
                    ? 'Prueba con otro nombre o con la categoría.'
                    : 'Cambia de vista para seguir organizando tus hábitos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.md),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: Text(
                  hasQuery ? 'Limpiar búsqueda' : 'Cambiar de vista',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalEmptyState extends StatelessWidget {
  final bool isCompact;
  final VoidCallback onCreateHabit;

  const _TotalEmptyState({
    required this.isCompact,
    required this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              SizedBox(height: context.spacing.lg),
              Text(
                'Tu espacio está listo',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'Crea un hábito pequeño y deja que la constancia haga el resto.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton.icon(
                key: ValueKey(
                  isCompact ? 'habits-empty-add' : 'habits-add',
                ),
                onPressed: onCreateHabit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo hábito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: colorScheme.error,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'No pudimos cargar tus hábitos',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              'Tus datos siguen a salvo. Intenta cargar la lista otra vez.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(context.radii.large),
    border: Border.all(color: colorScheme.outlineVariant),
  );
}

Color _categoryControlBackground(
  BuildContext context,
  Color categoryColor, {
  required bool emphasized,
}) {
  final theme = Theme.of(context);
  final opacity = switch (theme.brightness) {
    Brightness.light => emphasized ? 0.2 : 0.1,
    Brightness.dark => emphasized ? 0.34 : 0.18,
  };
  return Color.alphaBlend(
    categoryColor.withValues(alpha: opacity),
    theme.colorScheme.surface,
  );
}

String _frequencyLabel(BuildContext context, Habit habit) {
  if (habit.isOneTime) {
    final scheduledDate = habit.scheduledDate;
    if (scheduledDate == null) return 'Una vez';
    final formattedDate =
        MaterialLocalizations.of(context).formatMediumDate(scheduledDate);
    return 'Una vez · $formattedDate';
  }

  final frequency = habit.frequency;
  if (!frequency.isWeekly) return 'Cuando lo necesites';
  final days = frequency.daysOfWeek;
  if (days.length == 7) return 'Todos los días';
  if (days.length == 5 && days.every((day) => day >= 1 && day <= 5)) {
    return 'Entre semana';
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return 'Fines de semana';
  }
  return days.map((day) => Weekday.fromValue(day).label).join(', ');
}

String _reminderLabel(BuildContext context, Habit habit) {
  if (!habit.hasReminder ||
      habit.reminderHour == null ||
      habit.reminderMinute == null) {
    return 'Sin recordatorio';
  }
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(
      hour: habit.reminderHour!,
      minute: habit.reminderMinute!,
    ),
  );
}

String _normalizeForSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');
}
