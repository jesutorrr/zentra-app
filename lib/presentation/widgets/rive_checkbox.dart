import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Premium animated checkbox powered by Rive state machines.
///
/// Falls back to a Material animated checkbox when no .riv asset is available.
/// To enable Rive animations, place a .riv file at [assetPath] with a state
/// machine named [stateMachineName] containing a boolean input [inputName].
class RiveCheckbox extends StatefulWidget {
  final bool isChecked;
  final Color accentColor;
  final double size;
  final String assetPath;
  final String stateMachineName;
  final String inputName;

  const RiveCheckbox({
    required this.isChecked,
    required this.accentColor,
    this.size = 32,
    this.assetPath = 'assets/animations/checkbox.riv',
    this.stateMachineName = 'State Machine 1',
    this.inputName = 'isChecked',
    super.key,
  });

  @override
  State<RiveCheckbox> createState() => _RiveCheckboxState();
}

class _RiveCheckboxState extends State<RiveCheckbox> {
  SMIBool? _checkedInput;
  StateMachineController? _controller;
  bool _riveLoaded = false;
  Future<bool>? _assetFuture;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      widget.stateMachineName,
    );
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      final input = controller.findInput<bool>(widget.inputName);
      if (input is SMIBool) {
        _checkedInput = input;
        _checkedInput!.value = widget.isChecked;
        setState(() => _riveLoaded = true);
      }
    }
  }

  @override
  void didUpdateWidget(RiveCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked && _checkedInput != null) {
      _checkedInput!.value = widget.isChecked;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _buildRiveOrFallback(),
    );
  }

  Widget _buildRiveOrFallback() {
    if (_riveLoaded) {
      return RiveAnimation.asset(
        widget.assetPath,
        onInit: _onRiveInit,
        fit: BoxFit.contain,
      );
    }
    _assetFuture ??= _checkAssetExists();
    return FutureBuilder<bool>(
      future: _assetFuture,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return RiveAnimation.asset(
            widget.assetPath,
            onInit: _onRiveInit,
            fit: BoxFit.contain,
          );
        }
        return _FallbackCheckbox(
          isChecked: widget.isChecked,
          accentColor: widget.accentColor,
          size: widget.size,
        );
      },
    );
  }

  Future<bool> _checkAssetExists() async {
    try {
      await DefaultAssetBundle.of(context).load(widget.assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Animated fallback checkbox when no Rive asset is available.
/// Uses a smooth scale + check animation.
class _FallbackCheckbox extends StatefulWidget {
  final bool isChecked;
  final Color accentColor;
  final double size;

  const _FallbackCheckbox({
    required this.isChecked,
    required this.accentColor,
    required this.size,
  });

  @override
  State<_FallbackCheckbox> createState() => _FallbackCheckboxState();
}

class _FallbackCheckboxState extends State<_FallbackCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    if (widget.isChecked) _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(_FallbackCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked && !oldWidget.isChecked) {
      _animController.forward(from: 0);
    } else if (!widget.isChecked && oldWidget.isChecked) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                Colors.transparent,
                widget.accentColor,
                _checkAnim.value,
              ),
              border: Border.all(
                color: Color.lerp(
                  widget.accentColor.withValues(alpha: 0.3),
                  widget.accentColor,
                  _checkAnim.value,
                )!,
                width: 2.5,
              ),
              boxShadow: _checkAnim.value > 0.5
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.4 * _checkAnim.value),
                        blurRadius: 12 * _checkAnim.value,
                        spreadRadius: 2 * _checkAnim.value,
                      ),
                    ]
                  : null,
            ),
            child: _checkAnim.value > 0.3
                ? Icon(
                    Icons.check_rounded,
                    size: widget.size * 0.55,
                    color: Colors.white.withValues(alpha: _checkAnim.value),
                  )
                : null,
          ),
        );
      },
    );
  }
}
