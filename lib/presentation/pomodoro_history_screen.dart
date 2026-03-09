import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/pomodoro_provider.dart';
import '../domain/pomodoro_activity.dart';

class PomodoroHistoryScreen extends StatelessWidget {
  const PomodoroHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pomodoros'),
        centerTitle: true,
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, child) {
          final weeklyData = provider.weeklyChartData;
          final dailySummaries = provider.dailySummaries;
          
          if (provider.activityHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin actividades completadas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa tu primer Pomodoro para\nver tu historial aquí',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Gráfica de actividades
              SliverToBoxAdapter(
                child: _ActivityChart(weeklyData: weeklyData),
              ),
              
              // Resumen
              SliverToBoxAdapter(
                child: _SummaryCard(activities: provider.activityHistory),
              ),
              
              // Lista de actividades por día - usando SliverList simple
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Flatten the dailySummaries into a single list with headers
                    int currentIndex = 0;
                    for (final summary in dailySummaries) {
                      // Header for this date
                      if (index == currentIndex) {
                        return _DateHeader(
                          date: summary.date,
                          count: summary.activities.length,
                        );
                      }
                      currentIndex++;
                      
                      // Activities for this date
                      for (final activity in summary.activities) {
                        if (index == currentIndex) {
                          return _ActivityTile(activity: activity);
                        }
                        currentIndex++;
                      }
                    }
                    return null;
                  },
                  childCount: dailySummaries.fold<int>(
                    0, 
                    (sum, s) => sum + 1 + s.activities.length, // 1 header + activities
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const _ActivityChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final maxValue = weeklyData.fold(0, (max, item) {
      final count = item['count'] as int;
      return count > max ? count : max;
    });
    final chartMax = maxValue > 0 ? maxValue : 1;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Actividad (últimos 7 días)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = (constraints.maxWidth - 32) / 7 - 8;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyData.map((data) {
                      final count = data['count'] as int;
                      final day = data['day'] as String;
                      final date = data['date'] as DateTime;
                      final heightPercent = count / chartMax;
                      final isToday = _isToday(date);
                      
                      return Tooltip(
                        message: '${_formatShortDate(date)}: $count actividades',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (count > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$count',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: barWidth.clamp(20.0, 40.0),
                              height: count > 0 ? (100 * heightPercent).clamp(8.0, 100.0) : 4,
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? (isToday ? colorScheme.primary : colorScheme.primaryContainer)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: isToday
                                    ? Border.all(color: colorScheme.primary, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isToday ? colorScheme.primary : colorScheme.outline,
                                fontWeight: isToday ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _SummaryCard extends StatelessWidget {
  final List<PomodoroActivity> activities;

  const _SummaryCard({required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final totalActivities = activities.length;
    final totalCycles = activities.fold(0, (sum, a) => sum + a.cyclesCompleted);
    final totalMinutes = totalCycles * 25;
    
    // Calcular racha actual
    final streak = _calculateStreak(activities);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.check_circle,
              value: '$totalActivities',
              label: 'Completadas',
              color: colorScheme.primary,
            ),
            _StatItem(
              icon: Icons.timer,
              value: '${totalMinutes}m',
              label: 'Enfocado',
              color: colorScheme.secondary,
            ),
            _StatItem(
              icon: Icons.local_fire_department,
              value: '$streak',
              label: 'Racha días',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<PomodoroActivity> activities) {
    if (activities.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Obtener días únicos con actividades
    final daysWithActivities = <DateTime>{};
    for (final activity in activities) {
      final date = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      daysWithActivities.add(date);
    }
    
    // Contar racha desde hoy o ayer
    int streak = 0;
    var checkDate = today;
    
    // Si hoy no hay actividades, empezar desde ayer
    if (!daysWithActivities.contains(today)) {
      checkDate = today.subtract(const Duration(days: 1));
    }
    
    while (daysWithActivities.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int count;

  const _DateHeader({required this.date, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            _formatDateHeader(date),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';
    
    final weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 
                    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',];
    
    return '${weekdays[date.weekday - 1]} ${date.day} de ${months[date.month - 1]}';
  }
}

class _ActivityTile extends StatelessWidget {
  final PomodoroActivity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.timer,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          activity.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime!)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.loop,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '${activity.cyclesCompleted}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
