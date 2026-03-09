import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Full-screen Rive celebration overlay for achievements and milestones.
///
/// Plays a one-shot Rive animation over the current screen and auto-dismisses.
/// Falls back to a simple scale+fade animation when no .riv asset is present.
class RiveCelebration extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final VoidCallback? onComplete;

  const RiveCelebration({
    this.assetPath = 'assets/animations/celebration.riv',
    this.duration = const Duration(seconds: 3),
    this.onComplete,
    super.key,
  });

  /// Show celebration as an overlay on the given context.
  static void show(BuildContext context, {String? assetPath}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => RiveCelebration(
        assetPath: assetPath ?? 'assets/animations/celebration.riv',
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<RiveCelebration> createState() => _RiveCelebrationState();
}

class _RiveCelebrationState extends State<RiveCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _hasRiveAsset = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController.forward();
    _checkAssetAndScheduleDismiss();
  }

  Future<void> _checkAssetAndScheduleDismiss() async {
    try {
      await DefaultAssetBundle.of(context).load(widget.assetPath);
      if (mounted) setState(() => _hasRiveAsset = true);
    } catch (_) {
      // No Rive asset available
    }

    await Future.delayed(widget.duration);
    if (mounted) {
      await _fadeController.reverse();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: IgnorePointer(
        child: SizedBox.expand(
          child: _hasRiveAsset
              ? RiveAnimation.asset(widget.assetPath, fit: BoxFit.cover)
              : _FallbackCelebration(),
        ),
      ),
    );
  }
}

class _FallbackCelebration extends StatefulWidget {
  @override
  State<_FallbackCelebration> createState() => _FallbackCelebrationState();
}

class _FallbackCelebrationState extends State<_FallbackCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _StarBurstPainter(
            progress: _controller.value,
            color: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StarBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.6;
    const starCount = 12;

    for (int i = 0; i < starCount; i++) {
      final angle = (i / starCount) * math.pi * 2;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.fill;

      final radiusScale = i.isEven ? 1.0 : 0.6;
      final starCenter = Offset(
        center.dx + radius * 0.8 * radiusScale * math.cos(angle),
        center.dy + radius * 0.8 * radiusScale * math.sin(angle),
      );

      canvas.drawCircle(starCenter, 4 * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_StarBurstPainter old) => old.progress != progress;
}
