import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../motion_policy.dart';

/// A quiet, non-interactive layer that keeps Zentra's color alive behind a
/// screen without competing with its content.
class ZentraAmbientBackground extends StatefulWidget {
  final Widget child;
  final double intensity;

  const ZentraAmbientBackground({
    required this.child,
    this.intensity = 1,
    super.key,
  });

  @override
  State<ZentraAmbientBackground> createState() =>
      _ZentraAmbientBackgroundState();
}

class _ZentraAmbientBackgroundState extends State<ZentraAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = context.motionPolicy.allowsDecorativeMotion;
    if (_shouldAnimate == shouldAnimate) return;
    _shouldAnimate = shouldAnimate;
    if (shouldAnimate) {
      // One long drift is enough to make the background feel alive without
      // keeping an endless ticker behind every screen.
      _controller.forward();
    } else {
      _controller.stop();
      _controller.value = 0.32;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.zentraPalette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      key: const ValueKey('zentra_ambient_background'),
                      painter: _AmbientColorPainter(
                        progress: _controller.value,
                        colors: [
                          palette.water,
                          palette.sleep,
                          palette.warmPeach,
                        ],
                        opacity: (dark ? 0.075 : 0.045) *
                            widget.intensity.clamp(0, 1),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientColorPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double opacity;

  const _AmbientColorPainter({
    required this.progress,
    required this.colors,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final shortest = math.min(size.width, size.height);
    final phase = progress * math.pi * 2;
    final anchors = [
      Offset(
        size.width * 0.08 + math.sin(phase) * shortest * 0.035,
        size.height * 0.12 + math.cos(phase * 0.7) * shortest * 0.025,
      ),
      Offset(
        size.width * 0.92 + math.cos(phase * 0.8) * shortest * 0.04,
        size.height * 0.48 + math.sin(phase * 0.55) * shortest * 0.035,
      ),
      Offset(
        size.width * 0.28 + math.sin(phase * 0.45) * shortest * 0.03,
        size.height * 0.94 + math.cos(phase * 0.6) * shortest * 0.03,
      ),
    ];

    for (var index = 0; index < anchors.length; index++) {
      final radius = shortest * (0.46 + index * 0.06);
      final rect = Rect.fromCircle(center: anchors[index], radius: radius);
      canvas.drawCircle(
        anchors[index],
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colors[index].withValues(alpha: opacity),
              colors[index].withValues(alpha: 0),
            ],
            stops: const [0, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientColorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.colors != colors;
  }
}
