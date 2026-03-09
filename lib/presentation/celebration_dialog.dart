import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'theme.dart';
import '../domain/models.dart';

/// Celebration dialog shown when all achievements are unlocked
class AllAchievementsDialog extends StatefulWidget {
  const AllAchievementsDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AllAchievementsDialog(),
    );
  }

  @override
  State<AllAchievementsDialog> createState() => _AllAchievementsDialogState();
}

class _AllAchievementsDialogState extends State<AllAchievementsDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _confettiController.play();
      _scaleController.forward();
      _glowController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Dialog
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.black, Colors.black]
                        : [
                            Colors.white,
                            colorScheme.primaryContainer.opacity30,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.amber.opacity50,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.opacity30,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy with glow
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withValues(alpha: _glowAnimation.value * 0.6),
                                Colors.amber.withValues(alpha: _glowAnimation.value * 0.2),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: _glowAnimation.value * 0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '👑',
                              style: TextStyle(fontSize: 64),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Title with shimmer effect
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.amber,
                          Colors.yellow,
                          Colors.orange,
                          Colors.amber,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        '¡LEYENDA!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      '¡Has desbloqueado todos los logros!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Eres una inspiración. Tu dedicación y constancia te han llevado a la cima. ¡Sigue brillando!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.opacity10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.opacity30,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(icon: Icons.emoji_events_rounded, label: '100%'),
                          _MiniStat(icon: Icons.star_rounded, label: 'Completo'),
                          _MiniStat(icon: Icons.local_fire_department_rounded, label: 'Épico'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '¡Soy una Leyenda!',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Confetti - Top left
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 4,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            gravity: 0.2,
            colors: const [
              Colors.amber,
              Colors.yellow,
              Colors.orange,
              Colors.red,
              Colors.purple,
              Colors.blue,
            ],
          ),
        ),

        // Confetti - Top right
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -3 * pi / 4,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            gravity: 0.2,
            colors: const [
              Colors.amber,
              Colors.yellow,
              Colors.orange,
              Colors.red,
              Colors.purple,
              Colors.blue,
            ],
          ),
        ),

        // Confetti - Top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.03,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.amber,
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.green,
              Colors.cyan,
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.amber),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

/// Achievement unlock toast/notification
class AchievementUnlockedToast extends StatefulWidget {
  final String emoji;
  final String title;
  final VoidCallback onDismiss;

  const AchievementUnlockedToast({
    required this.emoji, required this.title, required this.onDismiss, super.key,
  });

  @override
  State<AchievementUnlockedToast> createState() => _AchievementUnlockedToastState();
}

class _AchievementUnlockedToastState extends State<AchievementUnlockedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ),);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    HapticFeedback.mediumImpact();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.amber.opacity30,
                            Colors.orange.opacity20,
                          ]
                        : [
                            Colors.amber.withValues(alpha: 0.9),
                            Colors.orange.opacity80,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.opacity50,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.opacity30,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.opacity20,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Logro desbloqueado!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.amber : Colors.white,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.celebration_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo épico de día completado con borde animado de gradiente
class DayCompletedDialog extends StatefulWidget {
  final String motivationalPhrase;
  final List<Category> completedCategories;

  const DayCompletedDialog({
    required this.motivationalPhrase, required this.completedCategories, super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required String phrase,
    required List<Category> categories,
  }) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DayCompletedDialog(
        motivationalPhrase: phrase,
        completedCategories: categories,
      ),
    );
  }

  @override
  State<DayCompletedDialog> createState() => _DayCompletedDialogState();
}

class _DayCompletedDialogState extends State<DayCompletedDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _borderController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _borderController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scaleController.forward();
      _borderController.repeat();
      _pulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _borderController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<Color> get _categoryColors {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.completedCategories.isEmpty) {
      return [colorScheme.primary, colorScheme.tertiary];
    }
    
    // Get unique colors from completed categories
    final colors = widget.completedCategories
        .map((cat) => AppTheme.getCategoryColor(cat, colorScheme))
        .toSet()
        .toList();
    
    // Ensure at least 2 colors for gradient
    if (colors.length == 1) {
      colors.add(colors.first.withValues(alpha: 0.6));
    }
    
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final colors = _categoryColors;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: AnimatedBuilder(
            animation: Listenable.merge([_borderController, _pulseController]),
            builder: (context, child) {
              // Create rotating gradient with all colors
              final rotatedColors = <Color>[];
              final colorCount = colors.length;
              for (int i = 0; i < colorCount * 2; i++) {
                rotatedColors.add(colors[i % colorCount]);
              }
              
              // Subtle breathing effect
              final breathScale = 1.0 + (_pulseController.value * 0.015);
              
              return Transform.scale(
                scale: breathScale,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: SweepGradient(
                      transform: GradientRotation(_borderController.value * 2 * pi),
                      colors: rotatedColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.2 + (_pulseController.value * 0.1)),
                        blurRadius: 20 + (_pulseController.value * 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon with pulse
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.1);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors.length >= 2 
                                ? [colors[0], colors[1]]
                                : [colorScheme.primary, colorScheme.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withValues(alpha: 0.4),
                              blurRadius: 20 + (_pulseController.value * 10),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: colors.length >= 2 
                        ? colors.take(3).toList()
                        : [colorScheme.primary, colorScheme.tertiary],
                  ).createShader(bounds),
                  child: Text(
                    '¡Día completado!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Motivational phrase
                Text(
                  widget.motivationalPhrase,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Category pills
                if (widget.completedCategories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: widget.completedCategories.toSet().map((cat) {
                      final color = AppTheme.getCategoryColor(cat, colorScheme);
                      final icon = AppTheme.getCategoryIcon(cat);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 24),

                // Button with gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.length >= 2 
                          ? [colors[0], colors[1]]
                          : [colorScheme.primary, colorScheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          '¡Gracias!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
