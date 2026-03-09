import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;

/// Transiciones de página personalizadas - FASE 9 UX: Avanzadas
/// En iOS usa CupertinoPageRoute para soportar swipe back gesture
class PageTransitions {
  /// Transición de slide desde la derecha con fade
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> slideFromRight<T>(Widget page) {
    // Use CupertinoPageRoute on iOS for swipe back gesture support
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Transición de slide desde abajo (para modales/formularios)
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> slideFromBottom<T>(Widget page) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Transición de fade simple
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> fade<T>(Widget page) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Transición de scale con fade (para diálogos/celebraciones)
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> scaleUp<T>(Widget page) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// FASE 9: Shared Axis X - Material Design 3 style
  /// Ideal para navegación horizontal entre pantallas del mismo nivel
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> sharedAxisX<T>(Widget page, {bool forward = true}) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        final direction = forward ? 1.0 : -1.0;
        
        // Fade through effect
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );
        
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.3 * direction, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// FASE 9: Shared Axis Y - Para navegación vertical
  /// Ideal para drill-down o detalles
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> sharedAxisY<T>(Widget page, {bool forward = true}) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        final direction = forward ? 1.0 : -1.0;
        
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );
        
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 0.15 * direction),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// FASE 9: Container Transform - Expande desde un punto
  /// Ideal para abrir detalles desde una tarjeta
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> containerTransform<T>(
    Widget page, {
    Offset? originOffset,
    Color? containerColor,
  }) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );
        
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            alignment: originOffset != null 
                ? Alignment(
                    (originOffset.dx / MediaQuery.of(context).size.width) * 2 - 1,
                    (originOffset.dy / MediaQuery.of(context).size.height) * 2 - 1,
                  )
                : Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

  /// FASE 9: Circular Reveal - Revela desde un punto con círculo
  /// Ideal para FAB o acciones flotantes
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> circularReveal<T>(
    Widget page, {
    Offset? center,
  }) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final screenSize = MediaQuery.of(context).size;
        final revealCenter = center ?? 
            Offset(screenSize.width - 56, screenSize.height - 56);
        
        return _CircularRevealTransition(
          animation: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          center: revealCenter,
          screenSize: screenSize,
          child: child,
        );
      },
    );
  }

  /// FASE 9: Fade Through - Transición suave con fade
  /// Ideal para cambios de contenido en el mismo contenedor
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> fadeThrough<T>(Widget page) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Outgoing fade
        final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
          ),
        );
        
        // Incoming fade with scale
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );
        
        final scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );
        
        return FadeTransition(
          opacity: fadeOut,
          child: FadeTransition(
            opacity: fadeIn,
            child: ScaleTransition(
              scale: scaleIn,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// FASE 9: Slide and Fade con parallax
  /// Efecto de profundidad con la pantalla anterior
  /// En iOS usa CupertinoPageRoute para swipe back gesture
  static Route<T> parallaxSlide<T>(Widget page) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        // Nueva pantalla entra desde la derecha
        final slideIn = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
        
        // Pantalla anterior se mueve ligeramente a la izquierda (parallax)
        final slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(curvedAnimation);
        
        final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );
        
        return Stack(
          children: [
            SlideTransition(
              position: slideOut,
              child: Container(), // Placeholder para la pantalla anterior
            ),
            SlideTransition(
              position: slideIn,
              child: FadeTransition(
                opacity: fadeIn,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget animado para el reveal circular - FASE 9
class _CircularRevealTransition extends AnimatedWidget {
  final Offset center;
  final Size screenSize;
  final Widget child;

  const _CircularRevealTransition({
    required Animation<double> animation,
    required this.center,
    required this.screenSize,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return ClipPath(
      clipper: _CircularRevealClipper(
        fraction: animation.value,
        center: center,
        screenSize: screenSize,
      ),
      child: child,
    );
  }
}

/// Clipper para el efecto de reveal circular - FASE 9
class _CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;
  final Size screenSize;

  _CircularRevealClipper({
    required this.fraction,
    required this.center,
    required this.screenSize,
  });

  @override
  Path getClip(Size size) {
    // Calcular el radio máximo necesario para cubrir toda la pantalla
    final maxRadius = math.sqrt(
      math.pow(math.max(center.dx, screenSize.width - center.dx), 2) +
      math.pow(math.max(center.dy, screenSize.height - center.dy), 2),
    ) * 1.2;
    
    final currentRadius = maxRadius * fraction;
    
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: currentRadius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return fraction != oldClipper.fraction;
  }
}
