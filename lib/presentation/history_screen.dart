import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/habit_controller.dart';
import '../application/profile_controller.dart';
import '../application/session_controller.dart';
import '../domain/models.dart';
import '../domain/user_profile.dart';
import 'design_tokens.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/feedback_utils.dart';
import 'widgets/responsive_layout.dart';

/// Durable activity history plus an explicitly disposable task archive.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    final habits =
        ownerId == null ? null : ref.watch(habitControllerProvider(ownerId));
    final profileWorkspace =
        ownerId == null ? null : ref.watch(profileControllerProvider(ownerId));
    final habitState = habits?.valueOrNull;
    final profileState = profileWorkspace?.valueOrNull;
    final profile = profileState?.profile;
    final archivedTasks = habitState?.completedTasks ?? const <CompletedTask>[];
    final activityDays = _activityDays(profile);
    final isLoading = ownerId == null ||
        (habits!.isLoading && habitState == null) ||
        (profileWorkspace!.isLoading && profileState == null);
    final hasError = !isLoading &&
        (habits.hasError ||
            profileWorkspace.hasError ||
            habitState?.error != null ||
            profileState?.error != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu actividad'),
        actions: [
          if (archivedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Vaciar archivo de tareas',
              onPressed: () => _showClearConfirmation(
                context,
                ref,
                ownerId!,
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveLayoutBuilder(
          builder: (context, layout) {
            if (isLoading) {
              return const _HistoryLoadingState();
            }
            if (hasError) {
              return _HistoryErrorState(
                onRetry: () => _retry(ref, ownerId),
              );
            }
            final usesTwoPane = layout.width >= 760;
            if (profile == null && archivedTasks.isEmpty) {
              return const _EmptyActivityHistory();
            }

            final overview = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActivitySummary(profile: profile),
                SizedBox(height: context.spacing.md),
                _ArchiveSection(tasks: archivedTasks),
              ],
            );
            final timeline = _ActivityTimeline(days: activityDays);

            return SingleChildScrollView(
              key: const ValueKey('activity_history_scroll'),
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPagePadding,
                layout.verticalPagePadding,
                layout.horizontalPagePadding,
                context.spacing.xxl,
              ),
              child: ResponsiveContentFrame(
                maxWidth: 1120,
                child: usesTwoPane
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: overview),
                          SizedBox(width: context.spacing.xl),
                          Expanded(flex: 6, child: timeline),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ActivitySummary(profile: profile),
                          SizedBox(height: context.spacing.lg),
                          timeline,
                          SizedBox(height: context.spacing.lg),
                          _ArchiveSection(tasks: archivedTasks),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  static List<_ActivityDay> _activityDays(UserProfile? profile) {
    if (profile == null) return const [];
    final keys = {
      ...profile.dailyHabitCompletions.keys,
      ...profile.dailyFocusSessions.keys,
    };
    final days = <_ActivityDay>[];
    for (final key in keys) {
      final date = DateTime.tryParse(key);
      final habits = profile.dailyHabitCompletions[key] ?? 0;
      final focus = profile.dailyFocusSessions[key] ?? 0;
      if (date == null || (habits == 0 && focus == 0)) continue;
      days.add(
        _ActivityDay(
          date: date,
          habitCompletions: habits,
          focusSessions: focus,
        ),
      );
    }
    days.sort((left, right) => right.date.compareTo(left.date));
    return days;
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
    WidgetRef ref,
    String ownerId,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '¿Vaciar archivo?',
      message:
          'Se eliminarán las tareas retiradas. Tu actividad, XP y logros se conservarán.',
      confirmText: 'Vaciar archivo',
      cancelText: 'Cancelar',
      icon: Icons.delete_sweep_rounded,
      isDangerous: true,
    );

    if (confirmed == true && context.mounted) {
      triggerHaptic(HapticType.success);
      await ref
          .read(habitControllerProvider(ownerId).notifier)
          .clearCompletedTasks();
      if (!context.mounted) return;
      showSuccessSnackbar(
        context,
        'Archivo vaciado. Tu progreso sigue intacto.',
        icon: Icons.inventory_2_outlined,
      );
    }
  }

  Future<void> _retry(WidgetRef ref, String ownerId) async {
    await Future.wait([
      ref.read(habitControllerProvider(ownerId).notifier).reload(),
      ref.read(profileControllerProvider(ownerId).notifier).reload(),
    ]);
  }
}

class _HistoryLoadingState extends StatelessWidget {
  const _HistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        key: ValueKey('activity-history-loading'),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _HistoryErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: scheme.error,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'No pudimos cargar tu actividad',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              'Tu progreso sigue a salvo. Intenta cargarlo otra vez.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _EmptyActivityHistory extends StatelessWidget {
  const _EmptyActivityHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.zentraPalette.calmMint,
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 48,
                  color: context.zentraPalette.brandTeal,
                ),
              ),
              SizedBox(height: context.spacing.lg),
              Text(
                'Tu historia empieza con una acción',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'Completa un hábito o una sesión de enfoque y aquí quedará guardado tu avance.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  final UserProfile? profile;

  const _ActivitySummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final value = profile;
    return Container(
      key: const ValueKey('activity-history-summary'),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: context.zentraPalette.specialSurface,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(
          color: context.zentraPalette.warmPeach.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lo que ya construiste',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Estos números son acumulados y no disminuyen si retiras una tarea.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.lg,
            children: [
              _SummaryMetric(
                value: '${value?.totalHabitsCompleted ?? 0}',
                label: 'hábitos completados',
                icon: Icons.check_circle_outline_rounded,
                color: context.zentraPalette.brandTeal,
              ),
              _SummaryMetric(
                value: _formatMinutes(value?.totalFocusMinutes ?? 0),
                label: 'de enfoque',
                icon: Icons.timer_outlined,
                color: context.zentraPalette.warmPeach,
              ),
              _SummaryMetric(
                value: '${value?.totalDaysActive ?? 0}',
                label: 'días activos',
                icon: Icons.calendar_today_outlined,
                color: context.zentraPalette.water,
              ),
              _SummaryMetric(
                value: '${value?.longestStreak ?? 0}',
                label: 'mejor racha',
                icon: Icons.local_fire_department_outlined,
                color: context.zentraPalette.movement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 126),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.radii.small),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: context.spacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ActivityTimeline extends StatelessWidget {
  final List<_ActivityDay> days;

  const _ActivityTimeline({required this.days});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('activity-history-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Día a día',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Tu avance real, incluso cuando cambian tus planes.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: context.spacing.md),
        if (days.isEmpty)
          const _NoDurableActivity()
        else
          for (var index = 0; index < days.length; index++)
            _ActivityDayTile(
              day: days[index],
              isLast: index == days.length - 1,
            ),
      ],
    );
  }
}

class _NoDurableActivity extends StatelessWidget {
  const _NoDurableActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.medium),
      ),
      child: Text(
        'Todavía no hay actividad acumulada. El archivo de tareas puede tener elementos, pero no cuenta como progreso.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ActivityDayTile extends StatelessWidget {
  final _ActivityDay day;
  final bool isLast;

  const _ActivityDayTile({
    required this.day,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.zentraPalette.brandTeal,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.spacing.md),
              child: Container(
                padding: EdgeInsets.all(context.spacing.md),
                decoration: BoxDecoration(
                  color: context.zentraPalette.functionalSurface,
                  borderRadius: BorderRadius.circular(context.radii.medium),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _formatActivityDate(day.date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: context.spacing.sm),
                    Wrap(
                      spacing: context.spacing.sm,
                      runSpacing: context.spacing.xs,
                      children: [
                        if (day.habitCompletions > 0)
                          _ActivityLabel(
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                '${day.habitCompletions} ${day.habitCompletions == 1 ? 'hábito' : 'hábitos'}',
                            color: context.zentraPalette.brandTeal,
                          ),
                        if (day.focusSessions > 0)
                          _ActivityLabel(
                            icon: Icons.timer_outlined,
                            label:
                                '${day.focusSessions} ${day.focusSessions == 1 ? 'enfoque' : 'enfoques'}',
                            color: context.zentraPalette.warmPeach,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == today) return 'Hoy';
    if (normalized == today.subtract(const Duration(days: 1))) return 'Ayer';
    return _formatSpanishDate(date, includeWeekday: true);
  }
}

class _ActivityLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActivityLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: context.spacing.xxs),
        Flexible(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveSection extends StatelessWidget {
  final List<CompletedTask> tasks;

  const _ArchiveSection({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('activity-history-archive'),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: context.zentraPalette.various,
              ),
              SizedBox(width: context.spacing.xs),
              Expanded(
                child: Text(
                  'Archivo de tareas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (tasks.isNotEmpty)
                Text(
                  '${tasks.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Aquí viven tareas únicas completadas y hábitos retirados. Vaciar este archivo no afecta tu progreso.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (tasks.isEmpty) ...[
            SizedBox(height: context.spacing.md),
            Text(
              'No hay tareas archivadas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            SizedBox(height: context.spacing.md),
            for (var index = 0; index < tasks.length; index++) ...[
              _ArchivedTaskTile(task: tasks[index]),
              if (index < tasks.length - 1)
                Divider(
                  height: context.spacing.lg,
                  color: scheme.outlineVariant,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ArchivedTaskTile extends StatelessWidget {
  final CompletedTask task;

  const _ArchivedTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categoryColor = AppTheme.getCategoryColor(task.category, scheme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.radii.small),
          ),
          child: Icon(
            task.wasOneTime
                ? Icons.task_alt_rounded
                : Icons.remove_circle_outline_rounded,
            color: categoryColor,
            size: 21,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: context.spacing.xxs),
              Text(
                [
                  task.wasOneTime ? 'Completada' : 'Retirada',
                  task.category.label,
                  _formatSpanishShortDate(task.completedAt),
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityDay {
  final DateTime date;
  final int habitCompletions;
  final int focusSessions;

  const _ActivityDay({
    required this.date,
    required this.habitCompletions,
    required this.focusSessions,
  });
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

const _spanishMonths = [
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

const _spanishShortMonths = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _spanishWeekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String _formatSpanishDate(DateTime date, {bool includeWeekday = false}) {
  final dateLabel =
      '${date.day} de ${_spanishMonths[date.month - 1]} de ${date.year}';
  if (!includeWeekday) return dateLabel;
  return _capitalize(
    '${_spanishWeekdays[date.weekday - 1]}, $dateLabel',
  );
}

String _formatSpanishShortDate(DateTime date) =>
    '${date.day} ${_spanishShortMonths[date.month - 1]} ${date.year}';
