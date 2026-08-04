import 'package:flutter/material.dart';

/// Recoverable local workspace load failure.
///
/// Retry remains primary, but the user can always leave the broken workspace
/// instead of being trapped in a loop.
class SessionLoadFailureScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onExit;

  const SessionLoadFailureScreen({
    required this.message,
    required this.onRetry,
    required this.onExit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Tu espacio necesita otro intento',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('session-load-retry'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    key: const ValueKey('session-load-exit'),
                    onPressed: onExit,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver al acceso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
