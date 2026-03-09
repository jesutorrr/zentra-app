import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../application/habit_provider.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'utils/dialogs.dart';
import 'utils/feedback_utils.dart';
import 'widgets/animated_list_item.dart';

/// Screen showing history of completed one-time tasks and deleted recurring habits
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        centerTitle: false,
        actions: [
          Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (provider.completedTasks.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Vaciar papelera',
                onPressed: () => _showClearConfirmation(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final tasks = provider.completedTasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.history_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.opacity50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sin historial',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las tareas únicas completadas y\nlos hábitos eliminados aparecerán aquí',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group tasks by date
          final groupedTasks = <String, List<CompletedTask>>{};
          for (final task in tasks) {
            final dateKey = _formatDateGroup(task.completedAt);
            groupedTasks.putIfAbsent(dateKey, () => []);
            groupedTasks[dateKey]!.add(task);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedTasks.length,
            itemBuilder: (context, index) {
              final dateKey = groupedTasks.keys.elementAt(index);
              final tasksForDate = groupedTasks[dateKey]!;

              return AnimatedListItem(
                index: index,
                delay: const Duration(milliseconds: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 16),
                    
                    // Date header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        dateKey,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                    // Tasks for this date
                    Card(
                    elevation: 0,
                    color: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: tasksForDate.asMap().entries.map((entry) {
                        final taskIndex = entry.key;
                        final task = entry.value;
                        final isLast = taskIndex == tasksForDate.length - 1;
                        final categoryColor = AppTheme.getCategoryColor(
                          task.category,
                          colorScheme,
                        );

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: categoryColor.opacity15,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  task.wasOneTime
                                      ? Icons.task_alt_rounded
                                      : Icons.delete_outline_rounded,
                                  color: categoryColor,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: task.wasOneTime
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.wasOneTime
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: categoryColor.opacity10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.category.label,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: categoryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    task.wasOneTime ? '✓ Completada' : '✗ Eliminada',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                DateFormat.Hm('es').format(task.completedAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: 76,
                                color: colorScheme.outlineVariant.opacity50,
                              ),
                          ],
                        );
                      }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Hoy';
    } else if (taskDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(taskDate).inDays < 7) {
      return DateFormat.EEEE('es').format(date);
    } else {
      return DateFormat.yMMMd('es').format(date);
    }
  }

  void _showClearConfirmation(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '¿Vaciar historial?',
      message: 'Se eliminarán permanentemente todas las tareas del historial. Esta acción no se puede deshacer.',
      confirmText: 'Vaciar',
      cancelText: 'Cancelar',
      icon: Icons.delete_sweep_rounded,
      isDangerous: true,
    );

    if (confirmed == true && context.mounted) {
      triggerHaptic(HapticType.success);
      context.read<HabitProvider>().clearCompletedTasks();
      showSuccessSnackbar(context, 'Historial vaciado', icon: Icons.delete_sweep_rounded);
    }
  }
}
