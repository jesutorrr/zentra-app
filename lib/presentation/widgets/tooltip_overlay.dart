import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for tracking which tooltips have been shown
class TooltipKeys {
  static const String fabNewHabit = 'tooltip_fab_new_habit';
  static const String pomodoroButton = 'tooltip_pomodoro_button';
  static const String habitCard = 'tooltip_habit_card';
}

/// Service to manage tooltip state
class TooltipService {
  static Future<bool> shouldShowTooltip(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(key) ?? false);
  }

  static Future<void> markTooltipShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  static Future<void> resetAllTooltips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TooltipKeys.fabNewHabit);
    await prefs.remove(TooltipKeys.pomodoroButton);
    await prefs.remove(TooltipKeys.habitCard);
  }
}

/// A contextual tooltip that appears once for new users
class ContextualTooltip extends StatefulWidget {
  final Widget child;
  final String tooltipKey;
  final String message;
  final TooltipPosition position;
  final bool enabled;
  final VoidCallback? onDismiss;

  const ContextualTooltip({
    required this.child,
    required this.tooltipKey,
    required this.message,
    super.key,
    this.position = TooltipPosition.above,
    this.enabled = true,
    this.onDismiss,
  });

  @override
  State<ContextualTooltip> createState() => _ContextualTooltipState();
}

class _ContextualTooltipState extends State<ContextualTooltip>
    with SingleTickerProviderStateMixin {
  bool _showTooltip = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.enabled) {
      _checkAndShowTooltip();
    }
  }

  Future<void> _checkAndShowTooltip() async {
    final shouldShow = await TooltipService.shouldShowTooltip(widget.tooltipKey);
    if (shouldShow && mounted) {
      // Delay to let the UI settle
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _showTooltip = true);
        _showOverlay();
      }
    }
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        targetKey: _targetKey,
        message: widget.message,
        position: widget.position,
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
        onDismiss: _dismissTooltip,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_showTooltip && mounted) {
        _dismissTooltip();
      }
    });
  }

  void _dismissTooltip() async {
    if (!_showTooltip) return;
    
    await _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    if (mounted) {
      setState(() => _showTooltip = false);
    }
    
    await TooltipService.markTooltipShown(widget.tooltipKey);
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _targetKey,
      child: widget.child,
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String message;
  final TooltipPosition position;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final VoidCallback onDismiss;

  const _TooltipOverlay({
    required this.targetKey,
    required this.message,
    required this.position,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final RenderBox? targetBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (targetBox == null) return const SizedBox.shrink();

    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position
    double top;
    double left;
    final tooltipWidth = screenSize.width * 0.7;
    
    // Center horizontally relative to target
    left = targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
    // Keep within screen bounds
    left = left.clamp(16.0, screenSize.width - tooltipWidth - 16);

    if (position == TooltipPosition.above) {
      top = targetPosition.dy - 80;
    } else {
      top = targetPosition.dy + targetSize.height + 16;
    }

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        child: Stack(
          children: [
            // Highlight the target element
            Positioned(
              left: targetPosition.dx - 8,
              top: targetPosition.dy - 8,
              child: Container(
                width: targetSize.width + 16,
                height: targetSize.height + 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            // Tooltip bubble
            Positioned(
              left: left,
              top: top,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toca para continuar',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TooltipPosition { above, below }
