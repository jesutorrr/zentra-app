import 'package:flutter/material.dart';

@immutable
class ZentraMotionPolicy {
  final bool reduceMotion;

  const ZentraMotionPolicy({required this.reduceMotion});

  factory ZentraMotionPolicy.of(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return ZentraMotionPolicy(
      reduceMotion: mediaQuery?.disableAnimations == true ||
          mediaQuery?.accessibleNavigation == true,
    );
  }

  bool get allowsDecorativeMotion => !reduceMotion;

  Duration duration(Duration preferred) {
    return reduceMotion ? Duration.zero : preferred;
  }
}

extension ZentraMotionContext on BuildContext {
  ZentraMotionPolicy get motionPolicy => ZentraMotionPolicy.of(this);
}
