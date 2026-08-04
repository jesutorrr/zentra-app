import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/pomodoro_provider.dart';
import '../application/session_controller.dart';
import '../domain/pomodoro_activity.dart';
import 'design_tokens.dart';
import 'motion_policy.dart';
import 'widgets/responsive_layout.dart';

class PomodoroHistoryScreen extends ConsumerWidget {
  const PomodoroHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    if (ownerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final provider = ref.watch(pomodoroControllerProvider(ownerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de enfoque'),
      ),
      body: SafeArea(
        top: false,
        child: provider.activityHistory.isEmpty
            ? const _EmptyFocusHistory()
            : ResponsiveLayoutBuilder(
                builder: (context, layout) {
                  final overview = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FocusSummary(activities: provider.activityHistory),
                      SizedBox(height: context.spacing.md),
                      _FocusWeekChart(data: provider.weeklyChartData),
                    ],
                  );
                  final timeline = _FocusTimeline(
                    summaries: provider.dailySummaries,
                  );

                  return SingleChildScrollView(
                    key: const ValueKey('focus_history_scroll'),
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPagePadding,
                      layout.verticalPagePadding,
                      layout.horizontalPagePadding,
                      context.spacing.xxl,
                    ),
                    child: ResponsiveContentFrame(
                      maxWidth: 1120,
                      child: layout.isExpanded
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
                                overview,
                                SizedBox(height: context.spacing.lg),
                                timeline,
                              ],
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyFocusHistory extends StatelessWidget {
  const _EmptyFocusHistory();

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
                  Icons.timer_outlined,
                  size: 48,
                  color: context.zentraPalette.focus,
                ),
              ),
              SizedBox(height: context.spacing.lg),
              Text(
                'Aún no hay sesiones completadas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'Cuando termines tu primer enfoque, aquí verás el tiempo que te has regalado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton.icon(
                onPressed: Navigator.of(context).pop,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar un enfoque'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusSummary extends StatelessWidget {
  final List<PomodoroActivity> activities;

  const _FocusSummary({required this.activities});

  @override
  Widget build(BuildContext context) {
    final minutes = activities.fold<int>(
      0,
      (total, activity) => total + activity.totalMinutes,
    );
    final focusedDays =
        activities.map((activity) => activity.dateOnly).toSet().length;
    final streak = _calculateStreak(activities);

    return Container(
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
            'Tu tiempo presente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              _SummaryMetric(
                value: _formatMinutes(minutes),
                label: 'enfocado',
                icon: Icons.timer_outlined,
              ),
              _SummaryMetric(
                value: '${activities.length}',
                label: 'sesiones',
                icon: Icons.check_circle_outline_rounded,
              ),
              _SummaryMetric(
                value: '$focusedDays',
                label: focusedDays == 1 ? 'día activo' : 'días activos',
                icon: Icons.calendar_today_outlined,
              ),
              _SummaryMetric(
                value: '$streak',
                label: streak == 1 ? 'día en ritmo' : 'días en ritmo',
                icon: Icons.local_fire_department_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  int _calculateStreak(List<PomodoroActivity> activities) {
    final days = activities.map((activity) => activity.dateOnly).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var cursor =
        days.contains(today) ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.zentraPalette.warmPeach),
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
                        color: scheme.onSurfaceVariant,
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

class _FocusWeekChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _FocusWeekChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMinutes = data.fold<int>(
      1,
      (current, entry) => math.max(current, entry['minutes'] as int),
    );

    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: context.zentraPalette.functionalSurface,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Últimos 7 días',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: context.spacing.lg),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.6,
            child: Builder(
              builder: (context) {
                final chartTextScale =
                    MediaQuery.textScalerOf(context).scale(1);
                return SizedBox(
                  height: 168 + (chartTextScale - 1) * 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry in data)
                        Expanded(
                          child: _FocusBar(
                            day: entry['day'] as String,
                            minutes: entry['minutes'] as int,
                            maximum: maxMinutes,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBar extends StatelessWidget {
  final String day;
  final int minutes;
  final int maximum;

  const _FocusBar({
    required this.day,
    required this.minutes,
    required this.maximum,
  });

  @override
  Widget build(BuildContext context) {
    final height =
        minutes == 0 ? 5.0 : math.max(12, 112 * minutes / maximum).toDouble();
    final focus = context.zentraPalette.focus;
    return Semantics(
      label: '$day, $minutes minutos de enfoque',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (minutes > 0)
            Text(
              '$minutes',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: focus,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          SizedBox(height: context.spacing.xxs),
          AnimatedContainer(
            duration: context.motionPolicy
                .duration(const Duration(milliseconds: 260)),
            curve: Curves.easeOutCubic,
            width: 22,
            height: height,
            decoration: BoxDecoration(
              color: minutes == 0
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : focus.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(day, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _FocusTimeline extends StatelessWidget {
  final List<DailyPomodoroSummary> summaries;

  const _FocusTimeline({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sesiones',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: context.spacing.md),
        for (final summary in summaries) ...[
          _DayHeader(summary: summary),
          SizedBox(height: context.spacing.xs),
          for (final activity in summary.activities) ...[
            _FocusActivityTile(activity: activity),
            SizedBox(height: context.spacing.xs),
          ],
          SizedBox(height: context.spacing.md),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DailyPomodoroSummary summary;

  const _DayHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            summary.formattedDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          '${summary.totalMinutes} min',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _FocusActivityTile extends StatelessWidget {
  final PomodoroActivity activity;

  const _FocusActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCycle = activity.cyclesCompleted > 1;
    final useStackedLayout = MediaQuery.textScalerOf(context).scale(1) > 1.6;
    final timeRange = activity.endTime == null
        ? activity.formattedStartTime
        : '${activity.formattedStartTime}–${activity.formattedEndTime}';
    final leading = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (isCycle
                ? context.zentraPalette.warmPeach
                : context.zentraPalette.focus)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(context.radii.small),
      ),
      child: Icon(
        isCycle ? Icons.sync_rounded : Icons.center_focus_strong_rounded,
        color: isCycle
            ? context.zentraPalette.warmPeach
            : context.zentraPalette.focus,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.name.isEmpty ? 'Sesión de enfoque' : activity.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: context.spacing.xxs),
        Wrap(
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              timeRange,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Text(
              isCycle
                  ? '${activity.cyclesCompleted} enfoques'
                  : 'Enfoque rápido',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (activity.noteId != null)
              Icon(
                Icons.description_outlined,
                size: 16,
                color: context.zentraPalette.focus,
                semanticLabel: 'Nota vinculada',
              ),
          ],
        ),
      ],
    );
    final duration = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.zentraPalette.calmMint,
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Text(
        activity.durationString,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.zentraPalette.focus,
              fontWeight: FontWeight.w800,
            ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: context.zentraPalette.functionalSurface,
        borderRadius: BorderRadius.circular(context.radii.medium),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: useStackedLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    SizedBox(width: context.spacing.sm),
                    Expanded(child: details),
                  ],
                ),
                SizedBox(height: context.spacing.sm),
                duration,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                SizedBox(width: context.spacing.sm),
                Expanded(child: details),
                SizedBox(width: context.spacing.sm),
                duration,
              ],
            ),
    );
  }
}
