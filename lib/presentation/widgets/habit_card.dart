import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../domain/models.dart';
import '../../application/habit_provider.dart';
import '../theme.dart';
import '../habit_form_screen.dart';
import '../utils/feedback_utils.dart';
import '../utils/dialogs.dart';
import '../utils/debounce_utils.dart';
import 'celebration_particles.dart';

/// Tarjeta de hábito con animación de tap y micro-celebraciones
/// Muestra icono de categoría, título, etiquetas y racha
class HabitCard extends StatefulWidget {
  final Habit habit;
  final HabitProvider provider;
  final bool isDark;

  const HabitCard({
    required this.habit, required this.provider, required this.isDark, super.key,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> with TickerProviderStateMixin, DebounceMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final GlobalKey _checkboxKey = GlobalKey();
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    // Pulse animation para celebración al completar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Prevent multiple rapid taps
    if (_isTapping) return;
    _isTapping = true;
    
    try {
      final wasCompleted = widget.provider.isHabitCompletedToday(widget.habit.id);
      
      // Animate card (bounce) - no await para que sea concurrente
      _controller.forward().then((_) => _controller.reverse());
      
      // Haptic feedback premium
      if (!wasCompleted) {
        // Heavy impact para completado (sensación física sólida como cerrar puerta de coche de lujo)
        HapticFeedback.heavyImpact();
        
        // Pulse celebration después del bounce
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _pulseController.forward(from: 0);
        });
        
        // Mostrar partículas de celebración
        _showCelebrationParticles();
      } else {
        // Light impact para desmarcar
        HapticFeedback.lightImpact();
      }
      
      // Toggle habit
      await widget.provider.toggleHabitToday(widget.habit.id);
    } finally {
      // Allow next tap after a short delay
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _isTapping = false;
    }
  }

  void _showCelebrationParticles() {
    // Deshabilitado para diseño minimalista OLED
    // El anillo que se llena es suficiente feedback visual
  }

  // Navegar a editar usando OpenContainer callback
  VoidCallback? _openContainerCallback;
  
  void _navigateToEdit() {
    triggerHaptic(HapticType.medium);
    // Usar OpenContainer callback si está disponible
    if (_openContainerCallback != null) {
      _openContainerCallback!();
    }
  }

  // Archivar hábito
  Future<void> _archiveHabit() async {
    triggerHaptic(HapticType.medium);
    await widget.provider.toggleArchive(widget.habit.id);
    if (mounted) {
      showSuccessSnackbar(context, 'Hábito archivado');
    }
  }

  // Eliminar hábito
  Future<void> _deleteHabit() async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Eliminar hábito?',
      message: 'Se eliminará "${widget.habit.title}" y todo su historial. Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_rounded,
      isDangerous: true,
    );
    
    if (confirm == true && mounted) {
      triggerHaptic(HapticType.warning);
      await widget.provider.deleteHabit(widget.habit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = widget.provider.isHabitCompletedToday(widget.habit.id);
    final streak = widget.provider.getHabitStreak(widget.habit.id);
    final categoryColor = AppTheme.getCategoryColor(widget.habit.category, colorScheme);
    final categoryIcon = AppTheme.getCategoryIcon(widget.habit.category);

    // Card content (reusable for context menu preview)
    final cardContent = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias, // Ensure content respects border radius
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: categoryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _CategoryIcon(
              color: categoryColor,
              icon: categoryIcon,
              heroTag: 'habit_icon_${widget.habit.id}',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HabitInfo(
                habit: widget.habit,
                isCompleted: isCompleted,
                streak: streak,
                categoryColor: categoryColor,
              ),
            ),
            KeyedSubtree(
              key: _checkboxKey,
              child: _CompletionCheckbox(
                isCompleted: isCompleted,
                accentColor: categoryColor,
              ),
            ),
          ],
        ),
      ),
    );

    // OpenContainer para transición fluida card → form
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 400),
      openBuilder: (context, closeContainer) {
        return HabitFormScreen(habitId: widget.habit.id);
      },
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      tappable: false, // Controlamos el tap manualmente
      useRootNavigator: false,
      closedBuilder: (context, openContainer) {
        // Guardar callback para usar desde context menu
        _openContainerCallback = openContainer;
        
        return AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
          builder: (context, child) {
            final combinedScale = _scaleAnimation.value * _pulseAnimation.value;
            return Transform.scale(
              scale: combinedScale,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Slidable(
              key: Key('habit_${widget.habit.id}'),
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) => _navigateToEdit(),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    icon: Icons.edit_rounded,
                    label: 'Editar',
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.5,
                children: [
                  SlidableAction(
                    onPressed: (_) => _archiveHabit(),
                    backgroundColor: categoryColor.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    icon: Icons.archive_rounded,
                    label: 'Archivar',
                  ),
                  SlidableAction(
                    onPressed: (_) => _deleteHabit(),
                    backgroundColor: colorScheme.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: 'Eliminar',
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                  ),
                ],
              ),
              child: GestureDetector(
                onLongPress: () => _showContextMenu(context, isCompleted),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: categoryColor.withValues(alpha: 0.15),
                    highlightColor: categoryColor.withValues(alpha: 0.08),
                    child: cardContent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, bool isCompleted) {
    triggerHaptic(HapticType.medium);
    
    final colorScheme = Theme.of(context).colorScheme;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleTap();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.remove_done_rounded : Icons.check_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(isCompleted ? 'Desmarcar' : 'Completar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEdit();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Editar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _archiveHabit();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Archivar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteHabit();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_rounded,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
                SizedBox(width: 8),
                Text('Eliminar'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

}

/// Icono de categoría del hábito - Con soporte para Hero animation
class _CategoryIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String? heroTag;

  const _CategoryIcon({
    required this.color,
    required this.icon,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
        size: 26,
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: iconWidget,
      );
    }
    return iconWidget;
  }
}

/// Información del hábito: título y etiquetas
class _HabitInfo extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final int streak;
  final Color categoryColor;

  const _HabitInfo({
    required this.habit,
    required this.isCompleted,
    required this.streak,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FASE 2: Título con más peso
        Text(
          habit.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isCompleted
                ? colorScheme.onSurface.opacity50
                : colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            // Category tag
            _Tag(
              text: habit.category.label,
              color: categoryColor,
              backgroundColor: categoryColor.withValues(alpha: 0.15),
            ),
            // Frequency tag
            _Tag(
              text: _getFrequencyLabel(habit),
              color: colorScheme.onSurfaceVariant,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            // Reminder indicator
            if (habit.hasReminder)
              _ReminderIndicator(
                hour: habit.reminderHour ?? 9,
                minute: habit.reminderMinute ?? 0,
              ),
            // Streak badge
            if (streak > 0)
              _StreakBadge(streak: streak),
          ],
        ),
      ],
    );
  }
}

/// Etiqueta pequeña (categoría, frecuencia)
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _Tag({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Indicador de recordatorio configurado
class _ReminderIndicator extends StatelessWidget {
  final int hour;
  final int minute;

  const _ReminderIndicator({
    required this.hour,
    required this.minute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 12,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de racha con icono de fuego animado y número que salta - FASE 4 UX
class _StreakBadge extends StatefulWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge> 
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fireController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fireAnimation;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _previousStreak = widget.streak;
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_scaleController);

    _fireController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fireAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar cuando la racha aumenta
    if (widget.streak > _previousStreak) {
      _scaleController.forward(from: 0);
      _fireController.forward(from: 0).then((_) {
        if (mounted) _fireController.reverse();
      });
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBigStreak = widget.streak >= 7;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fireAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: isBigStreak
                  ? LinearGradient(
                      colors: [
                        AppTheme.accentOrange.withValues(alpha: 0.2),
                        AppTheme.accentAmber.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              color: isBigStreak ? null : AppTheme.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              boxShadow: _fireAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: AppTheme.accentOrange.withValues(alpha: 0.3 * _fireAnimation.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de fuego con efecto de brillo
                Stack(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppTheme.accentOrange,
                    ),
                    if (_fireAnimation.value > 0)
                      Positioned.fill(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5 * _fireAnimation.value),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                // Número con animación de salto
                BouncingNumber(
                  value: widget.streak,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Anillo de progreso que se llena - Diseño OLED minimalista
/// Pendiente: anillo vacío con borde sutil
/// Completado: anillo lleno con glow del color de categoría
class _CompletionCheckbox extends StatefulWidget {
  final bool isCompleted;
  final Color accentColor;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.accentColor,
  });

  @override
  State<_CompletionCheckbox> createState() => _CompletionCheckboxState();
}

class _CompletionCheckboxState extends State<_CompletionCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  bool _wasCompleted = false;

  @override
  void initState() {
    super.initState();
    _wasCompleted = widget.isCompleted;
    
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    if (widget.isCompleted) {
      _fillController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CompletionCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !_wasCompleted) {
      _fillController.forward(from: 0);
      triggerCompletionFeedback();
    } else if (!widget.isCompleted && _wasCompleted) {
      _fillController.reverse();
    }
    _wasCompleted = widget.isCompleted;
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fillController,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_fillController.value);
        
        return SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              accentColor: widget.accentColor,
              backgroundColor: isDark
                  ? widget.accentColor.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.3),
              strokeWidth: 3.0,
              glowIntensity: progress,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter para el anillo de progreso
class _RingPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double glowIntensity;

  _RingPainter({
    required this.progress,
    required this.accentColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Cuando está pendiente (progress == 0): solo borde gris sutil
    // Cuando está completado: anillo iluminado con glow
    if (progress < 0.01) {
      // Solo borde gris sutil para pendientes
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      
      canvas.drawCircle(center, radius, bgPaint);
    } else {
      // Anillo iluminado para completados
      
      // Glow effect
      if (glowIntensity > 0.2) {
        final glowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.4 * glowIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity);
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -1.5708, // Empieza arriba (-90 grados en radianes)
          progress * 6.2832, // 2*PI para círculo completo
          false,
          glowPaint,
        );
      }
      
      // Anillo principal iluminado
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708, // Empieza arriba
        progress * 6.2832, // Progreso del círculo
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.accentColor != accentColor ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}

// ============================================================================
// HELPERS
// ============================================================================

/// Obtiene la etiqueta de frecuencia para un hábito
String _getFrequencyLabel(Habit habit) {
  if (habit.isOneTime) return 'Única';
  
  final days = habit.frequency.daysOfWeek;
  if (days.length == 7) return 'Diariamente';
  if (days.length == 5 && 
      days.contains(1) && days.contains(2) && days.contains(3) && 
      days.contains(4) && days.contains(5) &&
      !days.contains(6) && !days.contains(7)) {
    return 'Semanal';
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return 'Fin de Semana';
  }
  return 'Personalizado';
}
