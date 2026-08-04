import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';
import 'motion_policy.dart';

export 'splash_screen_classic.dart' show ClassicSplashScreen;

/// Quiet Salvia brand moment while the initial route is resolved.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _progress;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 620),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _progress = Tween<double>(begin: 0.18, end: 0.72).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
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
      _progressController
        ..stop()
        ..value = 0.48;
      return;
    }
    _entranceController.forward(from: 0);
    _progressController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;
    final overlay =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    final background = isDark ? Colors.black : palette.functionalSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: background,
        systemNavigationBarDividerColor: background,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Semantics(
          label: 'Zentra. Preparando tu espacio.',
          liveRegion: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!isDark)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF0F7F3),
                        Color(0xFFF8F6F0),
                      ],
                      stops: [0, 0.48],
                    ),
                  ),
                ),
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(16) / 16;
                    final needsScroll =
                        textScale > 1.35 || constraints.maxHeight < 620;
                    final content = ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: needsScroll ? 560 : constraints.maxHeight,
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: const Alignment(0, -0.04),
                            child: FadeTransition(
                              opacity: _opacity,
                              child: ScaleTransition(
                                scale: _scale,
                                child: const _SalviaSplashMessage(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 30,
                            child: FadeTransition(
                              opacity: _opacity,
                              child: Text(
                                'ZENTRA',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: palette.brandTeal,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 4.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (!needsScroll) return content;
                    return SingleChildScrollView(
                      key: const ValueKey('splash-scroll-view'),
                      child: content,
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    return LinearProgressIndicator(
                      key: ValueKey(
                        context.motionPolicy.reduceMotion
                            ? 'zentra-static-loading-indicator'
                            : 'zentra-animated-loading-indicator',
                      ),
                      value: context.motionPolicy.reduceMotion
                          ? 0.44
                          : _progress.value,
                      minHeight: 3,
                      color: palette.brandTeal,
                      backgroundColor: palette.progressTrack,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalviaSplashMessage extends StatelessWidget {
  const _SalviaSplashMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.zentraPalette;
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final markSize = width >= 700 ? 84.0 : 76.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            image: true,
            label: 'Logotipo de Zentra',
            child: ExcludeSemantics(
              child: Container(
                key: const ValueKey('zentra-splash-logo'),
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  color: palette.brandTeal,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isDark
                      ? const []
                      : [
                          BoxShadow(
                            color: palette.ink.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                padding: EdgeInsets.all(markSize * 0.16),
                child: Image.asset(
                  'assets/images/zentra_logo_mark.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.spa_outlined,
                    size: markSize * 0.46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width >= 700 ? 440 : 310),
            child: Text(
              'Una acción clara a la vez.',
              key: const ValueKey('zentra-splash-message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                color: palette.ink,
                fontSize: width >= 700 ? 52 : 40,
                fontWeight: FontWeight.w400,
                height: 1.08,
                letterSpacing: -1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
