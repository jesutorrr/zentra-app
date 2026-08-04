import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistema de Feedback Visual y Auditivo Unificado
/// Proporciona feedback consistente en toda la aplicación

// =============================================================================
// HAPTIC FEEDBACK - Patrones ricos estilo iOS
// =============================================================================

/// Tipos de feedback háptico según la acción
enum HapticType {
  light, // Selección, hover
  medium, // Tap, toggle
  heavy, // Acción importante, confirmación
  success, // Completar tarea - patrón celebración
  warning, // Advertencia
  error, // Error - patrón de alerta
  selection, // Cambio de selección (picker)
  impact, // Impacto fuerte único
}

/// Ejecuta feedback háptico según el tipo con patrones ricos
void triggerHaptic(HapticType type) {
  switch (type) {
    case HapticType.light:
      HapticFeedback.selectionClick();
    case HapticType.medium:
      HapticFeedback.lightImpact();
    case HapticType.heavy:
      HapticFeedback.mediumImpact();
    case HapticType.success:
      HapticFeedback.selectionClick();
      Future.delayed(const Duration(milliseconds: 60), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 130), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        HapticFeedback.heavyImpact();
      });
    case HapticType.warning:
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.selectionClick();
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        HapticFeedback.mediumImpact();
      });
    case HapticType.error:
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 80), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 240), () {
        HapticFeedback.heavyImpact();
      });
    case HapticType.selection:
      HapticFeedback.selectionClick();
    case HapticType.impact:
      HapticFeedback.heavyImpact();
  }
}

// =============================================================================
// SOUND FEEDBACK - Sonidos opcionales
// =============================================================================

/// Servicio para manejar sonidos de la app
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const String _keySoundsEnabled = 'sounds_enabled';
  bool _soundsEnabled = false;
  bool _initialized = false;
  Future<void>? _initializing;
  Future<void>? _preparingPlayer;
  AudioPlayer? _completionPlayer;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundsEnabled = prefs.getBool(_keySoundsEnabled) ?? false;
      if (_soundsEnabled) {
        await _prepareCompletionPlayer();
      }
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _prepareCompletionPlayer() async {
    if (_completionPlayer != null) return;
    final pending = _preparingPlayer;
    if (pending != null) {
      await pending;
      return;
    }

    final preparation = _createCompletionPlayer();
    _preparingPlayer = preparation;
    try {
      await preparation;
    } finally {
      _preparingPlayer = null;
    }
  }

  Future<void> _createCompletionPlayer() async {
    final player = AudioPlayer();
    try {
      await player.setSource(AssetSource('sounds/completion.mp3'));
      await player.setVolume(0.3);
      await player.setReleaseMode(ReleaseMode.stop);
      _completionPlayer = player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  bool get soundsEnabled => _soundsEnabled;

  Future<void> setSoundsEnabled(bool enabled) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundsEnabled, enabled);
    _soundsEnabled = enabled;

    if (enabled) {
      await _prepareCompletionPlayer();
      return;
    }

    final player = _completionPlayer;
    _completionPlayer = null;
    await player?.dispose();
  }

  void playSuccess() {
    if (!_soundsEnabled || _completionPlayer == null) return;
    _completionPlayer!.stop();
    _completionPlayer!.resume();
  }

  void playAlert() {
    if (!_soundsEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }
}

/// Trigger haptic y sonido combinados para completar hábito
void triggerCompletionFeedback() {
  HapticFeedback.mediumImpact();
  SoundService().playSuccess();
}

// =============================================================================
// ANIMATED PRESS EFFECT
// =============================================================================

/// Widget que agrega efecto de presión animado a cualquier hijo
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final HapticType? hapticType;

  const PressableScale({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.hapticType,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        if (widget.hapticType != null) {
          triggerHaptic(widget.hapticType!);
        }
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// SHAKE ANIMATION (Para errores)
// =============================================================================

/// Widget que hace "shake" para indicar error
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onShakeComplete;

  const ShakeWidget({
    required this.child,
    super.key,
    this.shake = false,
    this.onShakeComplete,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onShakeComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      shake();
    }
  }

  void shake() {
    triggerHaptic(HapticType.error);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
