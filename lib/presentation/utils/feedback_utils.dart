import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistema de Feedback Visual y Auditivo Unificado
/// Proporciona feedback consistente en toda la aplicación

// =============================================================================
// HAPTIC FEEDBACK - Patrones ricos estilo iOS
// =============================================================================

/// Tipos de feedback háptico según la acción
enum HapticType {
  light,       // Selección, hover
  medium,      // Tap, toggle
  heavy,       // Acción importante, confirmación
  success,     // Completar tarea - patrón celebración
  warning,     // Advertencia
  error,       // Error - patrón de alerta
  selection,   // Cambio de selección (picker)
  impact,      // Impacto fuerte único
}

/// Ejecuta feedback háptico según el tipo con patrones ricos
void triggerHaptic(HapticType type) {
  switch (type) {
    case HapticType.light:
      HapticFeedback.selectionClick();
    case HapticType.medium:
      HapticFeedback.lightImpact();
    case HapticType.heavy:
      HapticFeedback.mediumImpact();
    case HapticType.success:
      // Patrón de celebración: tap-tap-tap ascendente
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 80), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        HapticFeedback.heavyImpact();
      });
    case HapticType.warning:
      // Patrón de advertencia: dos golpes
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.mediumImpact();
      });
    case HapticType.error:
      // Patrón de error: tres golpes rápidos
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
    case HapticType.selection:
      HapticFeedback.selectionClick();
    case HapticType.impact:
      HapticFeedback.heavyImpact();
  }
}

// =============================================================================
// SOUND FEEDBACK - Sonidos opcionales
// =============================================================================

/// Servicio para manejar sonidos de la app
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const String _keySoundsEnabled = 'sounds_enabled';
  bool _soundsEnabled = false;
  bool _initialized = false;

  /// Inicializa el servicio cargando preferencias
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _soundsEnabled = prefs.getBool(_keySoundsEnabled) ?? false;
    _initialized = true;
  }

  /// Verifica si los sonidos están habilitados
  bool get soundsEnabled => _soundsEnabled;

  /// Habilita o deshabilita los sonidos
  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundsEnabled, enabled);
  }

  /// Reproduce sonido de éxito (completar hábito)
  void playSuccess() {
    if (!_soundsEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Reproduce sonido de alerta
  void playAlert() {
    if (!_soundsEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }
}

/// Trigger haptic y sonido combinados para completar hábito
void triggerCompletionFeedback() {
  triggerHaptic(HapticType.success);
  SoundService().playSuccess();
}

// =============================================================================
// ANIMATED PRESS EFFECT
// =============================================================================

/// Widget que agrega efecto de presión animado a cualquier hijo
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final HapticType? hapticType;

  const PressableScale({
    required this.child, super.key,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.hapticType,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        if (widget.hapticType != null) {
          triggerHaptic(widget.hapticType!);
        }
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// SHAKE ANIMATION (Para errores)
// =============================================================================

/// Widget que hace "shake" para indicar error
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onShakeComplete;

  const ShakeWidget({
    required this.child, super.key,
    this.shake = false,
    this.onShakeComplete,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onShakeComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      shake();
    }
  }

  void shake() {
    triggerHaptic(HapticType.error);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// PULSE ANIMATION (Para llamar atención)
// =============================================================================

/// Widget con animación de pulso para llamar la atención
class PulseWidget extends StatefulWidget {
  final Widget child;
  final bool pulse;
  final Duration duration;
  final double maxScale;

  const PulseWidget({
    required this.child, super.key,
    this.pulse = true,
    this.duration = const Duration(milliseconds: 1000),
    this.maxScale = 1.05,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return widget.child;

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

// =============================================================================
// GLOW EFFECT
// =============================================================================

/// Widget con efecto de glow animado
class GlowingWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool glow;
  final double blurRadius;
  final double spreadRadius;

  const GlowingWidget({
    required this.child, required this.glowColor, super.key,
    this.glow = true,
    this.blurRadius = 20,
    this.spreadRadius = 2,
  });

  @override
  State<GlowingWidget> createState() => _GlowingWidgetState();
}

class _GlowingWidgetState extends State<GlowingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.glow) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glow && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.glow && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.glow) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _animation.value),
                blurRadius: widget.blurRadius,
                spreadRadius: widget.spreadRadius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// SUCCESS CHECKMARK ANIMATION
// =============================================================================

/// Animación de checkmark para éxito
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 60,
    this.color = Colors.green,
    this.duration = const Duration(milliseconds: 500),
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: Colors.white,
                strokeWidth: widget.size * 0.1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final checkSize = size.width * 0.35;

    // Puntos del checkmark
    final start = Offset(center.dx - checkSize * 0.5, center.dy);
    final middle = Offset(center.dx - checkSize * 0.1, center.dy + checkSize * 0.4);
    final end = Offset(center.dx + checkSize * 0.5, center.dy - checkSize * 0.3);

    final path = Path();

    if (progress <= 0.5) {
      // Primera línea (de start a middle)
      final t = progress * 2;
      final currentPoint = Offset.lerp(start, middle, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Primera línea completa
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);

      // Segunda línea (de middle a end)
      final t = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(middle, end, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// THEME TRANSITION
// =============================================================================

/// Transición suave entre temas claro/oscuro
class ThemeTransitionOverlay extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const ThemeTransitionOverlay({
    required this.child, required this.isDark, super.key,
  });

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool? _previousIsDark;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _previousIsDark = widget.isDark;
  }

  @override
  void didUpdateWidget(ThemeTransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDark != _previousIsDark) {
      _controller.forward(from: 0).then((_) {
        if (mounted) _previousIsDark = widget.isDark;
      });
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
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            if (_controller.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: (_previousIsDark ?? false ? Colors.white : Colors.black)
                        .withValues(alpha: (1 - _controller.value) * 0.3),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
