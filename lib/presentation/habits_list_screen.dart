import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../application/habit_provider.dart';
import 'theme.dart';
import 'habit_form_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/animated_list_item.dart';
import 'widgets/skeleton_loader.dart';
import 'utils/dialogs.dart';
import 'utils/page_transitions.dart';
import 'utils/feedback_utils.dart';

/// Screen showing all habits for management
class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        centerTitle: false,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          // Skeleton loader durante carga
          if (provider.isLoading) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const HabitListSkeleton(itemCount: 5),
              ),
            );
          }

          final activeHabits = provider.activeHabits;
          final archivedHabits = provider.archivedHabits;

          if (activeHabits.isEmpty && archivedHabits.isEmpty) {
            return _EmptyState(
              onCreateHabit: () => _navigateToForm(context),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                children: [
                  // Active habits section con animaciones
                  if (activeHabits.isNotEmpty) ...[
                    AnimatedSectionHeader(
                      delay: const Duration(milliseconds: 100),
                      child: _SectionHeader(
                        title: 'Activos',
                        count: activeHabits.length,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeHabits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habit = entry.value;
                      return AnimatedListItem(
                        index: index,
                        delay: const Duration(milliseconds: 60),
                        child: _HabitListItem(
                          habit: habit,
                          isDark: isDark,
                          onTap: () => _navigateToForm(context, habitId: habit.id),
                          onDelete: () => _confirmDelete(context, provider, habit),
                          onToggleArchive: () {
                            triggerHaptic(HapticType.medium);
                            provider.toggleArchive(habit.id);
                          },
                        ),
                      );
                    }),
                  ],

                  // Archived habits section con animaciones
                  if (archivedHabits.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    AnimatedSectionHeader(
                      delay: Duration(milliseconds: 100 + (activeHabits.length * 60)),
                      child: _SectionHeader(
                        title: 'Archivados',
                        count: archivedHabits.length,
                        isArchived: true,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...archivedHabits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habit = entry.value;
                      return AnimatedListItem(
                        index: index + activeHabits.length,
                        delay: const Duration(milliseconds: 60),
                        child: Opacity(
                          opacity: 0.7,
                          child: _HabitListItem(
                            habit: habit,
                            isDark: isDark,
                            onTap: () => _navigateToForm(context, habitId: habit.id),
                            onDelete: () => _confirmDelete(context, provider, habit),
                            onToggleArchive: () {
                              triggerHaptic(HapticType.medium);
                              provider.toggleArchive(habit.id);
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: PressableScale(
        onTap: () => _navigateToForm(context),
        hapticType: HapticType.medium,
        child: const FloatingActionButton.extended(
          onPressed: null,
          icon: Icon(Icons.add_rounded),
          label: Text('Nuevo'),
          elevation: 2,
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, {String? habitId}) {
    Navigator.of(context).push(
      PageTransitions.slideFromBottom(HabitFormScreen(habitId: habitId)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HabitProvider provider,
    Habit habit,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar hábito',
      message: '¿Eliminar "${habit.title}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_forever_rounded,
      isDangerous: true,
    );

    if (confirmed == true) {
      await provider.deleteHabit(habit.id);
    }
  }
}

/// Individual habit list item
class _HabitListItem extends StatelessWidget {
  final Habit habit;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleArchive;

  const _HabitListItem({
    required this.habit,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = AppTheme.getCategoryColor(habit.category, colorScheme);
    final categoryIcon = AppTheme.getCategoryIcon(habit.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.isArchived
                      ? colorScheme.surfaceContainerHighest
                      : categoryColor.opacity20,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: habit.isArchived
                      ? colorScheme.onSurfaceVariant
                      : categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: habit.isArchived
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: habit.isArchived
                                ? colorScheme.surfaceContainerHighest
                                : categoryColor.opacity20,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            habit.category.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: habit.isArchived
                                  ? colorScheme.onSurfaceVariant
                                  : categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _getFrequencyLabel(habit.frequency),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: Icon(
                  habit.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: colorScheme.primary,
                ),
                onPressed: onToggleArchive,
                tooltip: habit.isArchived ? 'Activar' : 'Archivar',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFrequencyLabel(Frequency frequency) {
    if (!frequency.isWeekly) {
      return 'Todos los días';
    }
    if (frequency.daysOfWeek.length == 7) {
      return 'Diario';
    }
    if (frequency.daysOfWeek.length == 5 &&
        frequency.daysOfWeek.every((d) => d >= 1 && d <= 5)) {
      return 'Entre semana';
    }
    if (frequency.daysOfWeek.length == 2 &&
        frequency.daysOfWeek.contains(6) &&
        frequency.daysOfWeek.contains(7)) {
      return 'Fines de semana';
    }
    return '${frequency.daysOfWeek.length} días/semana';
  }
}

/// Section header for habit lists
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isArchived;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.isDark, this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isArchived
                  ? (isDark 
                      ? colorScheme.surfaceContainerHighest.opacity50
                      : colorScheme.surfaceContainerHighest)
                  : (isDark
                      ? colorScheme.primary.opacity20
                      : colorScheme.primaryContainer),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isArchived ? Icons.archive_outlined : Icons.check_circle_outline,
              size: 18,
              color: isArchived
                  ? colorScheme.onSurfaceVariant
                  : (isDark ? colorScheme.primary : colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isArchived
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isArchived
                  ? (isDark 
                      ? colorScheme.surfaceContainerHighest.opacity50
                      : colorScheme.surfaceContainerHighest)
                  : (isDark
                      ? colorScheme.primary.opacity20
                      : colorScheme.primaryContainer),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isArchived
                    ? colorScheme.onSurfaceVariant
                    : (isDark ? colorScheme.primary : colorScheme.onPrimaryContainer),
              ),
            ),
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
      icon: Icons.list_alt_rounded,
      title: 'Sin hábitos aún',
      message: 'Crea tu primer hábito para comenzar a construir mejores rutinas',
      buttonText: 'Crear Hábito',
      onButtonPressed: onCreateHabit,
    );
  }
}
