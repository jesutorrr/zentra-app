import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget para mostrar celebraciones con Lottie
/// Usa animaciones de red (LottieFiles) para máxima calidad
class LottieCelebration extends StatefulWidget {
  final LottieCelebrationType type;
  final double size;
  final bool repeat;
  final VoidCallback? onComplete;

  const LottieCelebration({
    required this.type, super.key,
    this.size = 200,
    this.repeat = false,
    this.onComplete,
  });

  @override
  State<LottieCelebration> createState() => _LottieCelebrationState();
}

class _LottieCelebrationState extends State<LottieCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.repeat) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.network(
        widget.type.url,
        controller: _controller,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          if (widget.repeat) {
            _controller.repeat();
          } else {
            _controller.forward();
          }
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback si no carga
          return _FallbackCelebration(type: widget.type, size: widget.size);
        },
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return _FallbackCelebration(type: widget.type, size: widget.size);
          }
          return child;
        },
      ),
    );
  }
}

/// Tipos de celebración disponibles
enum LottieCelebrationType {
  // Celebraciones
  confetti('https://lottie.host/e8e9f5a8-f5c5-4a0e-b5c5-8f5e5a5e5a5e/confetti.json'),
  fireworks('https://lottie.host/d5a5e5a5-5a5e-5a5e-5a5e-5a5e5a5e5a5e/fireworks.json'),
  trophy('https://assets2.lottiefiles.com/packages/lf20_touohxv0.json'),
  star('https://assets10.lottiefiles.com/packages/lf20_obhph3sh.json'),
  checkmark('https://assets4.lottiefiles.com/packages/lf20_jbrw3hcz.json'),
  
  // Rachas
  fire('https://assets9.lottiefiles.com/packages/lf20_5ngs2ksb.json'),
  streak('https://assets2.lottiefiles.com/packages/lf20_xlmz9xwm.json'),
  
  // Completar día
  celebration('https://assets5.lottiefiles.com/packages/lf20_u4yrau.json'),
  success('https://assets1.lottiefiles.com/packages/lf20_s2lryxtd.json'),
  
  // Pomodoro
  timer('https://assets8.lottiefiles.com/packages/lf20_p8bfn5to.json'),
  focus('https://assets3.lottiefiles.com/packages/lf20_ydo1amjm.json');

  final String url;
  const LottieCelebrationType(this.url);
}

/// Fallback cuando Lottie no carga
class _FallbackCelebration extends StatefulWidget {
  final LottieCelebrationType type;
  final double size;

  const _FallbackCelebration({
    required this.type,
    required this.size,
  });

  @override
  State<_FallbackCelebration> createState() => _FallbackCelebrationState();
}

class _FallbackCelebrationState extends State<_FallbackCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case LottieCelebrationType.confetti:
      case LottieCelebrationType.celebration:
        return Icons.celebration_rounded;
      case LottieCelebrationType.fireworks:
        return Icons.auto_awesome_rounded;
      case LottieCelebrationType.trophy:
        return Icons.emoji_events_rounded;
      case LottieCelebrationType.star:
        return Icons.star_rounded;
      case LottieCelebrationType.checkmark:
      case LottieCelebrationType.success:
        return Icons.check_circle_rounded;
      case LottieCelebrationType.fire:
      case LottieCelebrationType.streak:
        return Icons.local_fire_department_rounded;
      case LottieCelebrationType.timer:
      case LottieCelebrationType.focus:
        return Icons.timer_rounded;
    }
  }

  Color get _color {
    switch (widget.type) {
      case LottieCelebrationType.confetti:
      case LottieCelebrationType.celebration:
      case LottieCelebrationType.fireworks:
        return Colors.purple;
      case LottieCelebrationType.trophy:
        return Colors.amber;
      case LottieCelebrationType.star:
        return Colors.yellow.shade700;
      case LottieCelebrationType.checkmark:
      case LottieCelebrationType.success:
        return Colors.green;
      case LottieCelebrationType.fire:
      case LottieCelebrationType.streak:
        return Colors.orange;
      case LottieCelebrationType.timer:
      case LottieCelebrationType.focus:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(
              _icon,
              size: widget.size * 0.6,
              color: _color,
            ),
          ),
        );
      },
    );
  }
}

/// Overlay de celebración que cubre toda la pantalla
class CelebrationOverlay extends StatefulWidget {
  final LottieCelebrationType type;
  final VoidCallback? onComplete;
  final Duration duration;

  const CelebrationOverlay({
    super.key,
    this.type = LottieCelebrationType.celebration,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  /// Muestra el overlay de celebración
  static void show(
    BuildContext context, {
    LottieCelebrationType type = LottieCelebrationType.celebration,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        type: type,
        onComplete: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );
    
    overlay.insert(entry);
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
    
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
      animation: _fadeAnimation,
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: LottieCelebration(
                  type: widget.type,
                  size: 300,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
