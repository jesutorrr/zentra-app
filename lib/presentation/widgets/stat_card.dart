import 'package:flutter/material.dart';

/// A reusable card widget for displaying statistics with an icon.
///
/// Used in profile screens, stats sections, and anywhere statistics
/// need to be displayed in a card format.
class StatCard extends StatelessWidget {
  /// The title/label for the statistic
  final String title;

  /// The value to display (typically a number as string)
  final String value;

  /// An icon to display (preferred over emoji)
  final IconData? icon;

  /// Icon color (defaults to primary)
  final Color? iconColor;

  /// An emoji to display as fallback (deprecated, use icon instead)
  final String? emoji;

  /// Whether the app is in dark mode (for styling)
  final bool isDark;

  /// Optional custom color for the value text
  final Color? valueColor;

  /// Optional icon/emoji size (defaults to 20)
  final double iconSize;

  const StatCard({
    required this.title, required this.value, required this.isDark, super.key,
    this.icon,
    this.iconColor,
    this.emoji,
    this.valueColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: iconColor ?? colorScheme.primary,
                    ),
                  )
                else if (emoji != null)
                  Text(emoji!, style: TextStyle(fontSize: iconSize)),
                const Spacer(),
                // FASE 2: Números más grandes y prominentes
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
