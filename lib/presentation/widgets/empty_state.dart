import 'package:flutter/material.dart';
import '../theme.dart';
import 'responsive_layout.dart';

/// Widget reutilizable para estados vacíos - FASE 11
/// Con animación de entrada y diseño mejorado
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final bool showAnimation;

  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.showAnimation = true,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _breatheController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Breathing animation - subtle continuous pulse
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    if (widget.showAnimation) {
      _controller.forward().then((_) {
        // Start breathing after entrance
        _breatheController.repeat(reverse: true);
      });
    } else {
      _controller.value = 1.0;
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.iconColor ?? colorScheme.primary;
    final usesExpandedLayout =
        context.zentraWindowClass != ZentraWindowClass.compact &&
            MediaQuery.textScalerOf(context).scale(16) <= 22;
    final iconExtent = usesExpandedLayout ? 164.0 : 140.0;
    final iconSize = usesExpandedLayout ? 72.0 : 64.0;
    final messageMaxWidth = usesExpandedLayout ? 440.0 : 300.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _breatheController]),
      builder: (context, child) {
        return _ScrollableCenteredContent(
          children: [
            // Icono animado con breathing
            Transform.scale(
              scale: _scaleAnimation.value * _breatheAnimation.value,
              child: Container(
                width: iconExtent,
                height: iconExtent,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      accentColor.withValues(alpha: isDark ? 0.15 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: iconSize,
                  color: accentColor,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Título con fade y slide
            Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  widget.title,
                  style: (usesExpandedLayout
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Mensaje con fade y slide
            Transform.translate(
              offset: Offset(0, _slideAnimation.value * 0.5),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: messageMaxWidth),
                  child: Text(
                    widget.message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Botón con bounce
            if (widget.buttonText != null &&
                widget.onButtonPressed != null) ...[
              const SizedBox(height: 32),
              Transform.scale(
                scale: _bounceAnimation.value,
                child: FilledButton(
                  onPressed: widget.onButtonPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Icon(Icons.add_rounded),
                      Text(
                        widget.buttonText!,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Empty state para "Todo completado" - con confeti visual
class AllDoneEmptyState extends StatefulWidget {
  final String title;
  final String message;

  const AllDoneEmptyState({
    super.key,
    this.title = '¡Todo listo!',
    this.message =
        'Has completado todos tus hábitos de hoy. ¡Excelente trabajo!',
  });

  @override
  State<AllDoneEmptyState> createState() => _AllDoneEmptyStateState();
}

class _AllDoneEmptyStateState extends State<AllDoneEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ScrollableCenteredContent(
          children: [
            // Trofeo animado
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow de fondo
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentAmber.withValues(alpha: 0.3),
                            AppTheme.accentAmber.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Círculo principal
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.accentAmber,
                            AppTheme.accentOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Título
            Opacity(
              opacity: _scaleAnimation.value.clamp(0.0, 1.0),
              child: Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            // Mensaje
            Opacity(
              opacity: _scaleAnimation.value.clamp(0.0, 1.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  widget.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Estrellas decorativas
            Opacity(
              opacity: _scaleAnimation.value.clamp(0.0, 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star_rounded,
                      size: 24,
                      color: AppTheme.accentAmber,
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollableCenteredContent extends StatelessWidget {
  final List<Widget> children;

  const _ScrollableCenteredContent({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight =
            constraints.hasBoundedHeight && constraints.maxHeight > 64
                ? constraints.maxHeight - 64
                : 0.0;
        final minWidth =
            constraints.hasBoundedWidth && constraints.maxWidth > 64
                ? constraints.maxWidth - 64
                : 0.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight,
              minWidth: minWidth,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
