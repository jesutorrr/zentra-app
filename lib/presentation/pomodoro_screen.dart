import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../application/pomodoro_provider.dart';
import 'theme.dart';
import 'pomodoro_history_screen.dart';
import 'utils/feedback_utils.dart';
import 'widgets/sparkle_button.dart';

/// Ejemplos de actividades para el placeholder del Pomodoro
const List<String> _activityExamples = [
  // Estudio/Aprendizaje
  'Estudiar Flutter',
  'Leer un libro',
  'Estudiar matemáticas',
  'Aprender Python',
  'Estudiar historia',
  'Tomar curso online',
  'Aprender idiomas',
  'Repasar apuntes',
  'Hacer flashcards',
  'Ver tutorial',
  'Practicar examen',
  'Investigar tema',
  // Trabajo/Productividad
  'Escribir código',
  'Preparar presentación',
  'Revisar emails',
  'Planificar semana',
  'Resolver problemas',
  'Organizar archivos',
  'Reunión de trabajo',
  'Llamadas pendientes',
  'Documentar proyecto',
  'Revisar reportes',
  'Hacer presupuesto',
  // Creatividad
  'Diseñar UI',
  'Escribir artículo',
  'Dibujar',
  'Editar video',
  'Grabar podcast',
  'Crear contenido',
  'Escribir diario',
  'Brainstorming',
  'Diseñar logo',
  'Editar fotos',
  // Música/Arte
  'Practicar piano',
  'Practicar guitarra',
  'Componer música',
  'Pintar',
  // Bienestar
  'Hacer ejercicio',
  'Meditar',
  'Yoga',
  'Estiramientos',
  'Respiración profunda',
  // Personal/Hogar
  'Limpiar escritorio',
  'Ordenar habitación',
  'Cocinar',
  'Hacer lista de compras',
];

/// Pomodoro Timer Screen - Uses global provider from main.dart
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  PomodoroProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<PomodoroProvider>();
      _provider!.addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final completed = _provider?.justCompletedActivity;
    if (completed != null && mounted) {
      _showActivityCompletedCelebration(completed);
      _provider?.clearJustCompletedActivity();
    }
  }

  void _showActivityCompletedCelebration(dynamic activity) {
    triggerHaptic(HapticType.success);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ActivityCompletedDialog(
        activityName: activity.name,
        cyclesCompleted: activity.cyclesCompleted,
        totalMinutes: activity.totalMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        centerTitle: false,
        actions: [
          Consumer<PomodoroProvider>(
            builder: (context, provider, _) {
              final isRunning = provider.state == PomodoroState.running;
              return AnimatedOpacity(
                opacity: isRunning ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: isRunning,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // History button
                      IconButton(
                        icon: const Icon(Icons.history_rounded),
                        tooltip: 'Historial',
                        onPressed: () {
                          triggerHaptic(HapticType.light);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PomodoroHistoryScreen()),
                          );
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.primary.opacity20
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.todayPomodoros}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Configuración',
                        onPressed: () => _showSettings(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, _) {
          final isRunning = provider.state == PomodoroState.running;
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Current activity card (if any)
                    if (provider.hasActiveActivity) ...[
                      _ActiveActivityCard(provider: provider, isDark: isDark),
                      const SizedBox(height: 16),
                    ],
                    
                    // Zen Mode: Hide Session Type selector when running
                    AnimatedSize(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      child: isRunning
                          ? const SizedBox.shrink()
                          : Column(
                              children: [
                                _SessionTypeCard(provider: provider, isDark: isDark),
                                const SizedBox(height: 24),
                              ],
                            ),
                    ),

                    _TimerCard(provider: provider, isDark: isDark),
                    
                    // Zen Mode: Hide Stats and Tips when running
                    AnimatedSize(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      child: isRunning
                          ? const SizedBox.shrink()
                          : Column(
                              children: [
                                const SizedBox(height: 24),
                                _StatsCard(provider: provider, isDark: isDark),
                                const SizedBox(height: 24),
                                _TipsCard(isDark: isDark),
                                const SizedBox(height: 80), // Space for FAB
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<PomodoroProvider>(
        builder: (context, provider, _) {
          // Don't show FAB if there's an active activity
          if (provider.hasActiveActivity) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _showAddActivityDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva actividad'),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          );
        },
      ),
    );
  }

  static void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  }

  static void _showAddActivityDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Nueva actividad'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿En qué vas a enfocarte?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej: ${_activityExamples[Random().nextInt(_activityExamples.length)]}',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<PomodoroProvider>().startActivity(value.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.opacity30,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La sesión durará 4 ciclos de pomodoro (aprox. 2 horas)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<PomodoroProvider>().startActivity(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }
}

/// Card showing the current active activity
class _ActiveActivityCard extends StatelessWidget {
  final PomodoroProvider provider;
  final bool isDark;

  const _ActiveActivityCard({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activity = provider.currentActivity!;
    // Use actual activity cycles completed
    final cyclesCompleted = provider.activityCyclesCompleted;
    final isFinalBreak = provider.isActivityFinalBreak;
    // Show 4/4 when in final break (cycle will be counted when break ends)
    final displayCycles = isFinalBreak ? 4 : cyclesCompleted;

    return Card(
      elevation: 0,
      color: isFinalBreak 
          ? colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.4 : 0.6)
          : colorScheme.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFinalBreak ? colorScheme.tertiary.opacity50 : colorScheme.primary.opacity30,
          width: isFinalBreak ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFinalBreak 
                        ? colorScheme.tertiary.opacity20 
                        : colorScheme.primary.opacity20,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFinalBreak ? Icons.celebration_rounded : Icons.timer_rounded,
                    color: isFinalBreak ? colorScheme.tertiary : colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFinalBreak ? '¡Ciclo completado!' : 'Actividad en curso',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isFinalBreak ? colorScheme.tertiary : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        activity.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isFinalBreak)
                  IconButton(
                    onPressed: () => _showCancelDialog(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Cancelar actividad',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress indicator
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: displayCycles / 4,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: isFinalBreak ? colorScheme.tertiary : colorScheme.primary,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$displayCycles/4',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFinalBreak ? colorScheme.tertiary : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFinalBreak 
                  ? 'Disfruta tu descanso largo' 
                  : 'Iniciado a las ${activity.formattedStartTime}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar actividad?'),
        content: const Text(
          'El progreso de esta actividad no se guardará en el historial.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, continuar'),
          ),
          FilledButton(
            onPressed: () {
              context.read<PomodoroProvider>().cancelActivity();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}

class _SessionTypeCard extends StatelessWidget {
  final PomodoroProvider provider;
  final bool isDark;

  const _SessionTypeCard({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _SessionTab(
              label: 'Enfoque',
              icon: Icons.center_focus_strong_rounded,
              isSelected: provider.sessionType == SessionType.work,
              onTap: provider.state == PomodoroState.idle
                  ? () => provider.selectSessionType(SessionType.work)
                  : null,
              color: colorScheme.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _SessionTab(
              label: 'Descanso',
              icon: Icons.coffee_rounded,
              isSelected: provider.sessionType == SessionType.shortBreak,
              onTap: provider.state == PomodoroState.idle
                  ? () => provider.selectSessionType(SessionType.shortBreak)
                  : null,
              color: AppTheme.successGreen,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _SessionTab(
              label: 'Largo',
              icon: Icons.self_improvement_rounded,
              isSelected: provider.sessionType == SessionType.longBreak,
              onTap: provider.state == PomodoroState.idle
                  ? () => provider.selectSessionType(SessionType.longBreak)
                  : null,
              color: const Color(0xFF42A5F5),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color color;
  final bool isDark;

  const _SessionTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = onTap == null && !isSelected;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.3 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: color.opacity50, width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? color : (isDisabled ? Colors.grey : colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : isDisabled
                          ? colorScheme.onSurfaceVariant.opacity50
                          : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final PomodoroProvider provider;
  final bool isDark;

  const _TimerCard({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBreak = provider.isBreak;
    final primaryColor = isBreak
        ? (provider.sessionType == SessionType.longBreak
            ? const Color(0xFF42A5F5)
            : AppTheme.successGreen)
        : colorScheme.primary;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _CircularTimer(
              provider: provider,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            _TimerControls(provider: provider, primaryColor: primaryColor),
            if (!isBreak) ...[
              const SizedBox(height: 24),
              _SessionDots(provider: provider, color: primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// Timer circular mejorado - FASE 8 UX: Con ondas y partículas
class _CircularTimer extends StatefulWidget {
  final PomodoroProvider provider;
  final Color primaryColor;
  final bool isDark;

  const _CircularTimer({
    required this.provider,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<_CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<_CircularTimer> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _breathController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isRunning = widget.provider.state == PomodoroState.running;
    final isBreak = widget.provider.isBreak;
    
    if (isRunning) {
      if (isBreak) {
        // Durante descanso: respiración suave
        _pulseController.stop();
        _waveController.stop();
        if (!_breathController.isAnimating) {
          _breathController.repeat(reverse: true);
        }
      } else {
        // Durante trabajo: pulso y ondas
        _breathController.stop();
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        if (!_waveController.isAnimating) {
          _waveController.repeat();
        }
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
      _breathController.stop();
      _breathController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFinished = widget.provider.state == PomodoroState.finished;
    final isRunning = widget.provider.state == PomodoroState.running;
    final isBreak = widget.provider.isBreak;

    return GestureDetector(
      onTap: isFinished
          ? () {
              triggerHaptic(HapticType.medium);
              widget.provider.skip();
            }
          : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _waveController, _breathAnimation]),
        builder: (context, child) {
          final scale = isRunning 
              ? (isBreak ? _breathAnimation.value : _pulseAnimation.value) 
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ondas concéntricas durante trabajo
                  if (isRunning && !isBreak) ...[
                    _PulseWave(
                      controller: _waveController,
                      color: widget.primaryColor,
                      delay: 0.0,
                    ),
                    _PulseWave(
                      controller: _waveController,
                      color: widget.primaryColor,
                      delay: 0.33,
                    ),
                    _PulseWave(
                      controller: _waveController,
                      color: widget.primaryColor,
                      delay: 0.66,
                    ),
                  ],
                  
                  // Partículas flotantes durante descanso
                  if (isRunning && isBreak)
                    _FloatingParticles(color: widget.primaryColor),
                  
                  // Glow exterior
                  if (isRunning)
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: isBreak ? 0.2 : 0.35),
                            blurRadius: isBreak ? 30 : 50,
                            spreadRadius: isBreak ? 3 : 8,
                          ),
                        ],
                      ),
                    ),
                  
                  // Arco de progreso
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: _ProgressArcPainter(
                        progress: widget.provider.progress,
                        color: widget.primaryColor,
                        backgroundColor: widget.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : colorScheme.surfaceContainerHighest,
                        strokeWidth: 14,
                      ),
                    ),
                  ),
                  
                  // Círculo interior
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isFinished
                          ? LinearGradient(
                              colors: [
                                widget.primaryColor,
                                widget.primaryColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFinished
                          ? null
                          : AppTheme.getContainerColor(colorScheme, widget.isDark),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: isFinished ? 0.5 : 0.15),
                          blurRadius: isFinished ? 40 : 15,
                          spreadRadius: isFinished ? 10 : 0,
                        ),
                      ],
                    ),
                    child: isFinished
                        ? _FinishedContent(provider: widget.provider)
                        : _TimerContent(provider: widget.provider, primaryColor: widget.primaryColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Onda de pulso que se expande - FASE 8 UX
class _PulseWave extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double delay;

  const _PulseWave({
    required this.controller,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = ((controller.value + delay) % 1.0);
        final size = 280 + (progress * 60);
        final opacity = (1 - progress) * 0.3;
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

/// Partículas flotantes para el modo descanso - FASE 8 UX
class _FloatingParticles extends StatefulWidget {
  final Color color;

  const _FloatingParticles({required this.color});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _particles = List.generate(8, (index) {
      return _Particle(
        angle: _random.nextDouble() * 2 * math.pi,
        radius: 100 + _random.nextDouble() * 40,
        speed: 0.5 + _random.nextDouble() * 0.5,
        size: 4 + _random.nextDouble() * 4,
        offset: _random.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double radius;
  final double speed;
  final double size;
  final double offset;

  _Particle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.offset,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final angle = particle.angle + (progress * particle.speed * 2 * math.pi);
      final floatOffset = math.sin((progress + particle.offset) * 2 * math.pi) * 10;
      final radius = particle.radius + floatOffset;
      
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      // Fade basado en posición
      final opacity = 0.3 + (math.sin((progress + particle.offset) * 4 * math.pi) * 0.2);
      paint.color = color.withValues(alpha: opacity.clamp(0.1, 0.5));
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}

/// Contenido del timer - FASE 6: Más grande y dramático
class _TimerContent extends StatelessWidget {
  final PomodoroProvider provider;
  final Color primaryColor;

  const _TimerContent({required this.provider, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRunning = provider.state == PomodoroState.running;
    final isPaused = provider.state == PomodoroState.paused;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Etiqueta de sesión
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            provider.sessionLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tiempo - más grande
        Text(
          provider.formattedTime,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: 2,
            fontSize: 64,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        // Estado
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isRunning
              ? Row(
                  key: const ValueKey('running'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PulsingDot(color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'En progreso',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : isPaused
                  ? Row(
                      key: const ValueKey('paused'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Pausado',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      key: const ValueKey('idle'),
                      'Toca iniciar para comenzar',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
        ),
      ],
    );
  }
}

/// Punto pulsante para indicar que está corriendo
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _controller.value * 0.6),
                blurRadius: 8,
                spreadRadius: _controller.value * 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FinishedContent extends StatelessWidget {
  final PomodoroProvider provider;

  const _FinishedContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBreak = provider.isBreak;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isBreak ? Icons.coffee_rounded : Icons.celebration_rounded,
          size: 48,
          color: Colors.white,
        ),
        const SizedBox(height: 12),
        Text(
          isBreak ? '¡Descanso\nterminado!' : '¡Pomodoro\ncompletado!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca para continuar',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.opacity80,
          ),
        ),
      ],
    );
  }
}

class _TimerControls extends StatefulWidget {
  final PomodoroProvider provider;
  final Color primaryColor;

  const _TimerControls({required this.provider, required this.primaryColor});

  @override
  State<_TimerControls> createState() => _TimerControlsState();
}

class _TimerControlsState extends State<_TimerControls> {
  bool _isProcessing = false;

  void _handlePlayPause() {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    HapticFeedback.mediumImpact();
    final isRunning = widget.provider.state == PomodoroState.running;
    final isFinished = widget.provider.state == PomodoroState.finished;
    
    if (isRunning) {
      widget.provider.pause();
    } else if (isFinished) {
      widget.provider.skip();
      widget.provider.start();
    } else {
      widget.provider.start();
    }
    
    // Debounce: prevent rapid taps for 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = widget.provider.state == PomodoroState.running;
    final isIdle = widget.provider.state == PomodoroState.idle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.refresh_rounded,
          label: 'Reiniciar',
          onPressed: widget.provider.state != PomodoroState.idle
              ? () {
                  HapticFeedback.lightImpact();
                  widget.provider.reset();
                }
              : null,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _handlePlayPause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.opacity40,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 24),
        _ControlButton(
          icon: widget.provider.isActivityFinalBreak 
              ? Icons.check_circle_rounded 
              : Icons.skip_next_rounded,
          label: widget.provider.isActivityFinalBreak ? 'Finalizar' : 'Saltar',
          onPressed: isIdle
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.provider.skip();
                },
          color: widget.provider.isActivityFinalBreak 
              ? colorScheme.primary 
              : colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, size: 28, color: isEnabled ? color : color.opacity30),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEnabled ? color : color.opacity30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDots extends StatelessWidget {
  final PomodoroProvider provider;
  final Color color;

  const _SessionDots({required this.provider, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completed = provider.completedPomodoros % 4;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isCompleted = index < completed;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? color : colorScheme.outline.opacity30,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${4 - completed} más para descanso largo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final PomodoroProvider provider;
  final bool isDark;

  const _StatsCard({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.accentOrange, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Tus estadísticas',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Main stats row: Pomodoros | Activities
            Row(
              children: [
                // Pomodoros column
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pomodoros',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hoy: ${provider.todayPomodoros}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${provider.todayMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Activities column
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Actividades',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hoy: ${provider.todayActivities}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        Text(
                          'Total: ${provider.totalActivities}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.successGreen.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Total pomodoros bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${provider.totalPomodoros} pomodoros (${provider.totalHoursFormatted})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.firstPomodoroDate != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 16, color: colorScheme.onSurfaceVariant,),
                    const SizedBox(width: 8),
                    Text(
                      'Desde ${_formatDate(provider.firstPomodoroDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TipsCard extends StatelessWidget {
  final bool isDark;

  const _TipsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppTheme.accentOrange, size: 22,),
                const SizedBox(width: 8),
                Text(
                  '¿Cómo funciona?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _TipItem(icon: Icons.timer_rounded, text: '1 pomodoro = 25 min de enfoque'),
            const SizedBox(height: 8),
            const _TipItem(icon: Icons.coffee_rounded, text: 'Después de cada pomodoro, 5 min de descanso'),
            const SizedBox(height: 8),
            const _TipItem(icon: Icons.emoji_events_rounded, text: '4 pomodoros = 1 actividad completa (~2 hrs)'),
            const SizedBox(height: 8),
            const _TipItem(icon: Icons.self_improvement_rounded, text: 'Al completar una actividad, descanso largo de 15 min'),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int _workMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PomodoroProvider>();
    _workMinutes = provider.workDuration;
    _shortBreakMinutes = provider.shortBreakDuration;
    _longBreakMinutes = provider.longBreakDuration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<PomodoroProvider>();

    return Container(
      decoration: AppTheme.getContainerDecoration(
        colorScheme, 
        isDark, 
        borderRadius: 24,
      ).copyWith(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.opacity30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.settings_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DurationSetting(
                label: 'Tiempo de enfoque',
                icon: Icons.center_focus_strong_rounded,
                value: _workMinutes,
                min: 5,
                max: 60,
                color: colorScheme.primary,
                onChanged: (value) {
                  setState(() => _workMinutes = value);
                  provider.setWorkDuration(value);
                },
              ),
              const SizedBox(height: 20),
              _DurationSetting(
                label: 'Descanso corto',
                icon: Icons.coffee_rounded,
                value: _shortBreakMinutes,
                min: 1,
                max: 15,
                color: AppTheme.successGreen,
                onChanged: (value) {
                  setState(() => _shortBreakMinutes = value);
                  provider.setShortBreakDuration(value);
                },
              ),
              const SizedBox(height: 20),
              _DurationSetting(
                label: 'Descanso largo',
                icon: Icons.self_improvement_rounded,
                value: _longBreakMinutes,
                min: 5,
                max: 30,
                color: const Color(0xFF42A5F5),
                onChanged: (value) {
                  setState(() => _longBreakMinutes = value);
                  provider.setLongBreakDuration(value);
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los cambios se aplicarán en la próxima sesión.',
                        style: theme.textTheme.bodySmall?.copyWith(
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
}

class _DurationSetting extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _DurationSetting({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.opacity15,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$value min',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            overlayColor: color.opacity10,
            trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Celebration dialog when activity is completed
class _ActivityCompletedDialog extends StatefulWidget {
  final String activityName;
  final int cyclesCompleted;
  final int totalMinutes;

  const _ActivityCompletedDialog({
    required this.activityName,
    required this.cyclesCompleted,
    required this.totalMinutes,
  });

  @override
  State<_ActivityCompletedDialog> createState() => _ActivityCompletedDialogState();
}

class _ActivityCompletedDialogState extends State<_ActivityCompletedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
    
    // Start confetti after dialog appears
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Format time from totalMinutes
    final hours = widget.totalMinutes ~/ 60;
    final minutes = widget.totalMinutes % 60;
    final timeText = hours > 0 
        ? '$hours h ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.2,
          shouldLoop: false,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
            Colors.amber,
            Colors.orange,
            Colors.pink,
            Colors.purple,
          ],
        ),
        
        // Dialog
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Celebration icon with sparkles
                      EpicCelebration(
                        celebrate: true,
                        primaryColor: colorScheme.primary,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.celebration_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¡Increíble!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completaste tu sesión de',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.activityName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.cyclesCompleted} ciclos · $timeText',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Sigue así! 💪',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('¡Genial!'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
