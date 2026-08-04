import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'widgets/ambient_background.dart';
import 'widgets/responsive_layout.dart';

/// Honest local placeholder for the future tip jar.
///
/// Purchases are intentionally unavailable in the current release. This
/// screen must never invent products or prices while the store is not wired.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Apoyar')),
      body: ResponsiveContentFrame(
        child: ZentraAmbientBackground(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.zentraPalette.movement,
                        context.zentraPalette.sleep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: context.zentraPalette.movement
                            .withValues(alpha: 0.24),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Apoyar a Zentra',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Las compras no están disponibles en esta versión.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.zentraPalette.functionalSurface,
                  borderRadius: BorderRadius.circular(context.radii.large),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  'Zentra es gratis, sin anuncios ni suscripciones. '
                  'Si te sirve, compartirla es suficiente.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
