import 'dart:async';

import 'package:flutter/material.dart';

import '../motion_policy.dart';

/// Widget que anima la entrada de items en una lista - FASE 14
/// Proporciona animación escalonada (staggered) para cada item
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const AnimatedListItem({
    required this.index,
    required this.child,
    super.key,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _delayTimer;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = context.motionPolicy.reduceMotion;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    _delayTimer?.cancel();
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _scheduleEntrance();
    }
  }

  @override
  void didUpdateWidget(AnimatedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index != widget.index ||
        oldWidget.delay != widget.delay ||
        oldWidget.duration != widget.duration) {
      _scheduleEntrance();
    }
  }

  void _scheduleEntrance() {
    _delayTimer?.cancel();
    if (_reduceMotion == true || _controller.isCompleted) {
      _controller.value = 1;
      return;
    }

    final entranceDelay = widget.delay * widget.index;
    if (entranceDelay == Duration.zero) {
      _controller.forward();
      return;
    }

    _delayTimer = Timer(entranceDelay, () {
      if (!mounted || _reduceMotion == true) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Widget para animar la entrada del header de una sección
class AnimatedSectionHeader extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedSectionHeader({
    required this.child,
    super.key,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedSectionHeader> createState() => _AnimatedSectionHeaderState();
}

class _AnimatedSectionHeaderState extends State<AnimatedSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _delayTimer;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = context.motionPolicy.reduceMotion;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    _delayTimer?.cancel();
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _scheduleEntrance();
    }
  }

  @override
  void didUpdateWidget(AnimatedSectionHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay) {
      _scheduleEntrance();
    }
  }

  void _scheduleEntrance() {
    _delayTimer?.cancel();
    if (_reduceMotion == true || _controller.isCompleted) {
      _controller.value = 1;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }

    _delayTimer = Timer(widget.delay, () {
      if (!mounted || _reduceMotion == true) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
