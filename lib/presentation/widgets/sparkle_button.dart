import 'dart:math';
import 'package:flutter/material.dart';

/// Botón con efecto de sparkles/brillos animados
/// Perfecto para acciones especiales como IA, logros, etc.
class SparkleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color sparkleColor;
  final bool showSparkles;
  final double size;

  const SparkleButton({
    required this.child, super.key,
    this.onPressed,
    this.sparkleColor = Colors.amber,
    this.showSparkles = true,
    this.size = 48,
  });

  @override
  State<SparkleButton> createState() => _SparkleButtonState();
}

class _SparkleButtonState extends State<SparkleButton>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _pulseController;
  final List<_Sparkle> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Generate sparkles
    for (int i = 0; i < 6; i++) {
      _sparkles.add(_Sparkle(
        angle: (i / 6) * 2 * pi,
        distance: 0.6 + _random.nextDouble() * 0.4,
        size: 3 + _random.nextDouble() * 3,
        delay: _random.nextDouble(),
      ),);
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (widget.showSparkles)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: widget.size * (0.8 + _pulseController.value * 0.2),
                    height: widget.size * (0.8 + _pulseController.value * 0.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.sparkleColor.withValues(alpha: 0.3 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  );
                },
              ),
            
            // Sparkles
            if (widget.showSparkles)
              AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SparklesPainter(
                      sparkles: _sparkles,
                      progress: _sparkleController.value,
                      color: widget.sparkleColor,
                    ),
                  );
                },
              ),
            
            // Main button content
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _Sparkle {
  final double angle;
  final double distance;
  final double size;
  final double delay;

  _Sparkle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}

class _SparklesPainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;
  final Color color;

  _SparklesPainter({
    required this.sparkles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (final sparkle in sparkles) {
      // Calculate sparkle position with rotation
      final adjustedProgress = (progress + sparkle.delay) % 1.0;
      final angle = sparkle.angle + progress * 2 * pi;
      final distance = maxRadius * sparkle.distance;
      
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;
      
      // Twinkle effect
      final twinkle = (sin(adjustedProgress * 4 * pi) + 1) / 2;
      final opacity = 0.3 + twinkle * 0.7;
      
      // Draw 4-point star
      _drawStar(canvas, Offset(x, y), sparkle.size * (0.5 + twinkle * 0.5), 
          color.withValues(alpha: opacity),);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // 4-point star
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget de celebración épica con confetti, estrellas y brillos
/// Para momentos de logro importantes
class EpicCelebration extends StatefulWidget {
  final Widget child;
  final bool celebrate;
  final Color primaryColor;
  final VoidCallback? onComplete;

  const EpicCelebration({
    required this.child, super.key,
    this.celebrate = false,
    this.primaryColor = Colors.amber,
    this.onComplete,
  });

  @override
  State<EpicCelebration> createState() => _EpicCelebrationState();
}

class _EpicCelebrationState extends State<EpicCelebration>
    with TickerProviderStateMixin {
  late AnimationController _burstController;
  late AnimationController _starsController;
  final List<_CelebrationStar> _stars = [];
  final Random _random = Random();
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _burstController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _starsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _burstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        setState(() => _isAnimating = false);
      }
    });
  }

  @override
  void didUpdateWidget(EpicCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate && !_isAnimating) {
      _triggerCelebration();
    }
  }

  void _triggerCelebration() {
    setState(() {
      _isAnimating = true;
      _stars.clear();
      
      // Generate burst stars
      for (int i = 0; i < 12; i++) {
        _stars.add(_CelebrationStar(
          angle: (i / 12) * 2 * pi + _random.nextDouble() * 0.3,
          velocity: 0.8 + _random.nextDouble() * 0.4,
          size: 8 + _random.nextDouble() * 8,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
          color: _getStarColor(),
        ),);
      }
    });

    _burstController.forward(from: 0);
    _starsController.forward(from: 0);
  }

  Color _getStarColor() {
    final colors = [
      widget.primaryColor,
      Colors.amber,
      Colors.orange,
      Colors.yellow,
      Colors.white,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _burstController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Main content with scale animation
        AnimatedBuilder(
          animation: _burstController,
          builder: (context, child) {
            final scale = _isAnimating
                ? 1.0 + sin(_burstController.value * pi) * 0.15
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: widget.child,
            );
          },
        ),
        
        // Burst ring
        if (_isAnimating)
          AnimatedBuilder(
            animation: _burstController,
            builder: (context, child) {
              final progress = _burstController.value;
              final opacity = (1 - progress).clamp(0.0, 1.0);
              final scale = 1 + progress * 2;
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: opacity * 0.8),
                      width: 3 * (1 - progress),
                    ),
                  ),
                ),
              );
            },
          ),
        
        // Stars burst
        if (_isAnimating)
          AnimatedBuilder(
            animation: _starsController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _CelebrationPainter(
                  stars: _stars,
                  progress: _starsController.value,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CelebrationStar {
  final double angle;
  final double velocity;
  final double size;
  final double rotationSpeed;
  final Color color;

  _CelebrationStar({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });
}

class _CelebrationPainter extends CustomPainter {
  final List<_CelebrationStar> stars;
  final double progress;

  _CelebrationPainter({
    required this.stars,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final star in stars) {
      // Eased progress for natural deceleration
      final easedProgress = Curves.easeOutCubic.transform(progress);
      final distance = easedProgress * 80 * star.velocity;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      final x = center.dx + cos(star.angle) * distance;
      final y = center.dy + sin(star.angle) * distance - (easedProgress * 20); // slight upward drift
      
      final rotation = progress * star.rotationSpeed * pi;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      _drawStar(canvas, Offset.zero, star.size * (1 - progress * 0.5), 
          star.color.withValues(alpha: opacity),);
      
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // 4-point star
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.25, center.dy - size * 0.25);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.25, center.dy + size * 0.25);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.25, center.dy - size * 0.25);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Shimmer effect para textos o elementos especiales
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color shimmerColor;

  const ShimmerText({
    required this.text, super.key,
    this.style,
    this.shimmerColor = Colors.white,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.style?.color ?? Colors.black,
                widget.shimmerColor,
                widget.style?.color ?? Colors.black,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }
}

/// Animated checkmark con efecto de dibujo
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 48,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _controller.forward().then((_) => widget.onComplete?.call());
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
          painter: _CheckmarkPainter(
            progress: Curves.easeOutCubic.transform(_controller.value),
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Checkmark points
    final start = Offset(size.width * 0.2, size.height * 0.5);
    final middle = Offset(size.width * 0.4, size.height * 0.7);
    final end = Offset(size.width * 0.8, size.height * 0.3);

    // Calculate how much of the path to draw
    if (progress <= 0.5) {
      // First stroke (down)
      final t = progress * 2;
      final current = Offset.lerp(start, middle, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(current.dx, current.dy);
    } else {
      // First stroke complete + second stroke (up)
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);
      
      final t = (progress - 0.5) * 2;
      final current = Offset.lerp(middle, end, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
