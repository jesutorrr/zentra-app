import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader widgets para estados de carga - FASE 12
/// Proporciona feedback visual mientras se cargan los datos
/// Actualizado con librería shimmer para efecto más profesional

/// Widget base de skeleton con animación shimmer premium
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    required this.width, required this.height, super.key,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFF8F8F8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer wrapper para cualquier widget
class ShimmerWrapper extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerWrapper({
    required this.child, super.key,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFF8F8F8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Skeleton para una tarjeta de hábito
class HabitCardSkeleton extends StatelessWidget {
  const HabitCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: const Row(
        children: [
          // Icono de categoría
          SkeletonBox(width: 48, height: 48, borderRadius: 14),
          SizedBox(width: 14),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonBox(width: 70, height: 12, borderRadius: 4),
                    SizedBox(width: 8),
                    SkeletonBox(width: 50, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          // Checkbox
          SkeletonBox(width: 28, height: 28, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Skeleton para la sección de progreso
class ProgressSectionSkeleton extends StatelessWidget {
  const ProgressSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          // Fecha
          SkeletonBox(width: 160, height: 32, borderRadius: 16),
          SizedBox(height: 24),
          // Círculo de progreso
          SkeletonBox(width: 160, height: 160, borderRadius: 80),
          SizedBox(height: 20),
          // Saludo
          SkeletonBox(width: 200, height: 24, borderRadius: 6),
          SizedBox(height: 8),
          // Frase
          SkeletonBox(width: 250, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton para lista de hábitos
class HabitListSkeleton extends StatelessWidget {
  final int itemCount;

  const HabitListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 120, height: 20, borderRadius: 4),
              SkeletonBox(width: 80, height: 16, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          ...List.generate(itemCount, (index) => const HabitCardSkeleton()),
        ],
      ),
    );
  }
}

/// Skeleton para tarjeta de estadísticas
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: 10),
              SizedBox(width: 12),
              SkeletonBox(width: 120, height: 18, borderRadius: 4),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 14, borderRadius: 7),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 60, height: 12, borderRadius: 4),
              SkeletonBox(width: 80, height: 12, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton para pantalla de perfil
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              children: [
                SkeletonBox(width: 100, height: 100, borderRadius: 50),
                SizedBox(height: 16),
                SkeletonBox(width: 150, height: 28, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 180, height: 32, borderRadius: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Level card
          const StatCardSkeleton(),
          const SizedBox(height: 24),
          // Stats
          const Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 100, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 100, borderRadius: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pantalla completa de carga con logo
class FullScreenLoader extends StatefulWidget {
  final String? message;

  const FullScreenLoader({super.key, this.message});

  @override
  State<FullScreenLoader> createState() => _FullScreenLoaderState();
}

class _FullScreenLoaderState extends State<FullScreenLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 24),
              Text(
                widget.message!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
