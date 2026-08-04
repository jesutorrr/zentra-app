import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';
import 'motion_policy.dart';
import 'widgets/responsive_layout.dart';

/// Calm brand moment shown while [AuthWrapper] resolves the initial route.
class ClassicSplashScreen extends StatefulWidget {
  const ClassicSplashScreen({super.key});

  @override
  State<ClassicSplashScreen> createState() => _ClassicSplashScreenState();
}

class _ClassicSplashScreenState extends State<ClassicSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _orbitController;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;
  late final Animation<Offset> _copyOffset;

  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _orbitController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _copyOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = context.motionPolicy.reduceMotion;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _entranceController.value = 1;
      _orbitController
        ..stop()
        ..value = 0.5;
      return;
    }

    _entranceController.forward(from: 0);
    _orbitController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overlayStyle = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colorScheme.surface,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _CalmBackground(),
            SafeArea(
              child: ResponsiveLayoutBuilder(
                builder: (context, layout) {
                  final spacing = context.spacing;
                  final isWide = layout.windowClass.isAtLeastExpanded;
                  final contentHeight = layout.height -
                      (layout.verticalPagePadding * 2).clamp(0, layout.height);

                  return SingleChildScrollView(
                    key: const ValueKey('splash-scroll-view'),
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.horizontalPagePadding,
                      vertical: layout.verticalPagePadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: contentHeight),
                      child: ResponsiveContentFrame(
                        maxWidth: isWide ? 680 : 520,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: _entranceOpacity,
                              child: ScaleTransition(
                                scale: _entranceScale,
                                child: _BrandOrbit(
                                  animation: _orbitController,
                                  isWide: isWide,
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? spacing.xl : spacing.lg),
                            FadeTransition(
                              opacity: _entranceOpacity,
                              child: SlideTransition(
                                position: _copyOffset,
                                child: const _BrandCopy(),
                              ),
                            ),
                            SizedBox(height: isWide ? spacing.xxl : spacing.xl),
                            const _LoadingStatus(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalmBackground extends StatelessWidget {
  const _CalmBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            palette.calmMint.withValues(alpha: 0.36),
            palette.specialSurface,
          ],
          stops: const [0, 0.58, 1],
        ),
      ),
      child: CustomPaint(
        painter: _CalmBackgroundPainter(
          teal: palette.brandTeal,
          peach: palette.warmPeach,
        ),
      ),
    );
  }
}

class _BrandOrbit extends StatelessWidget {
  final Animation<double> animation;
  final bool isWide;

  const _BrandOrbit({
    required this.animation,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.zentraPalette;
    final orbitSize = isWide ? 304.0 : 244.0;
    final logoSize = isWide ? 148.0 : 116.0;

    return Semantics(
      image: true,
      label: 'Logotipo de Zentra',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final pulse = 0.985 + (animation.value * 0.025);
            return Transform.scale(
              scale: pulse,
              child: SizedBox.square(
                dimension: orbitSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _OrbitRing(
                      size: orbitSize,
                      color: colorScheme.outlineVariant,
                    ),
                    _OrbitRing(
                      size: orbitSize * 0.76,
                      color: palette.brandTeal.withValues(alpha: 0.26),
                    ),
                    _OrbitRing(
                      size: orbitSize * 0.5,
                      color: palette.warmPeach.withValues(alpha: 0.32),
                    ),
                    SizedBox.square(
                      key: const ValueKey('zentra-splash-logo'),
                      dimension: logoSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: 5,
                              sigmaY: 5,
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                palette.brandTeal.withValues(alpha: 0.58),
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/zentra_logo_mark.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/zentra_logo_mark.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
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

class _OrbitRing extends StatelessWidget {
  final double size;
  final Color color;

  const _OrbitRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
      ),
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = context.spacing;

    return Column(
      children: [
        Text(
          'ZENTRA',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 3.2,
          ),
        ),
        SizedBox(height: spacing.xs),
        Text(
          'Una acción clara a la vez.',
          key: const ValueKey('zentra-splash-message'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        SizedBox(height: spacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'Hábitos, notas y enfoque en un espacio hecho para darte claridad.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = context.spacing;
    final reduceMotion = context.motionPolicy.reduceMotion;

    return Semantics(
      label: 'Preparando tu espacio',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.radii.pill),
                child: reduceMotion
                    ? Container(
                        key: const ValueKey('zentra-static-loading-indicator'),
                        width: 56,
                        height: 3,
                        color: colorScheme.primary,
                      )
                    : const LinearProgressIndicator(
                        key: ValueKey('zentra-animated-loading-indicator'),
                        minHeight: 3,
                      ),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Preparando tu espacio',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmBackgroundPainter extends CustomPainter {
  final Color teal;
  final Color peach;

  const _CalmBackgroundPainter({
    required this.teal,
    required this.peach,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = size.shortestSide;
    final tealPaint = Paint()
      ..color = teal.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final peachPaint = Paint()
      ..color = peach.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.18),
      shortestSide * 0.2,
      tealPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.82),
      shortestSide * 0.24,
      peachPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalmBackgroundPainter oldDelegate) {
    return oldDelegate.teal != teal || oldDelegate.peach != peach;
  }
}
