import 'dart:math';
import 'package:flutter/material.dart';

/// Widget de partículas para micro-celebraciones - FASE 4 UX
/// Muestra una explosión de partículas cuando se completa una acción

class CelebrationParticles extends StatefulWidget {
  final Color color;
  final int particleCount;
  final double size;
  final VoidCallback? onComplete;

  const CelebrationParticles({
    required this.color, super.key,
    this.particleCount = 12,
    this.size = 60,
    this.onComplete,
  });

  @override
  State<CelebrationParticles> createState() => _CelebrationParticlesState();
}

class _CelebrationParticlesState extends State<CelebrationParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      final angle = (index / widget.particleCount) * 2 * pi + _random.nextDouble() * 0.5;
      final velocity = 0.5 + _random.nextDouble() * 0.5;
      final size = 4.0 + _random.nextDouble() * 4.0;
      return _Particle(
        angle: angle,
        velocity: velocity,
        size: size,
        color: _getParticleColor(index),
      );
    });

    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  Color _getParticleColor(int index) {
    // Variaciones del color base
    final hsl = HSLColor.fromColor(widget.color);
    final variation = (_random.nextDouble() - 0.5) * 0.2;
    return hsl
        .withLightness((hsl.lightness + variation).clamp(0.3, 0.8))
        .withSaturation((hsl.saturation + variation).clamp(0.5, 1.0))
        .toColor();
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
          size: Size(widget.size, widget.size),
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            maxRadius: widget.size / 2,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double maxRadius;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      // Calcular posición con curva de desaceleración
      final easedProgress = Curves.easeOutCubic.transform(progress);
      final distance = easedProgress * maxRadius * particle.velocity;
      
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      // Fade out
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      // Escala que disminuye
      final scale = 1 - (progress * 0.5);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Overlay para mostrar partículas en cualquier posición
class ParticleOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required Offset position,
    required Color color,
    int particleCount = 12,
    double size = 80,
  }) {
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - size / 2,
        top: position.dy - size / 2,
        child: IgnorePointer(
          child: CelebrationParticles(
            color: color,
            particleCount: particleCount,
            size: size,
            onComplete: () {
              _currentOverlay?.remove();
              _currentOverlay = null;
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }
}

/// Widget de estrellas para rachas especiales
class StarBurst extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const StarBurst({
    super.key,
    this.color = Colors.amber,
    this.size = 100,
    this.onComplete,
  });

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Icon(
                Icons.star_rounded,
                size: widget.size,
                color: widget.color,
                shadows: [
                  Shadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Número animado que "salta" cuando cambia
class BouncingNumber extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const BouncingNumber({
    required this.value, super.key,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<BouncingNumber> createState() => _BouncingNumberState();
}

class _BouncingNumberState extends State<BouncingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(BouncingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _previousValue && widget.value > _previousValue) {
      _controller.forward(from: 0);
    }
    _previousValue = widget.value;
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
          scale: _scaleAnimation.value,
          child: Text(
            '${widget.prefix ?? ''}${widget.value}${widget.suffix ?? ''}',
            style: widget.style,
          ),
        );
      },
    );
  }
}

/// Efecto de brillo/shimmer para elementos completados
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color shimmerColor;

  const ShimmerEffect({
    required this.child, super.key,
    this.isActive = true,
    this.shimmerColor = Colors.white,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
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
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.shimmerColor.withValues(alpha: 0),
                widget.shimmerColor.withValues(alpha: 0.3),
                widget.shimmerColor.withValues(alpha: 0),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              transform: const GradientRotation(0.5),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
