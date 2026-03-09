import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A reusable settings tile widget with icon, title, subtitle and tap action.
///
/// Used in settings sections for navigation options. Features:
/// - Leading icon with colored background
/// - Title and subtitle text
/// - Chevron trailing icon
/// - Haptic feedback on tap
class SettingsTile extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The color for the icon and its background
  final Color iconColor;

  /// The main title text
  final String title;

  /// The subtitle/description text
  final String subtitle;

  /// Callback when the tile is tapped
  final VoidCallback onTap;

  /// Optional trailing widget (defaults to chevron icon)
  final Widget? trailing;

  /// Whether to show haptic feedback on tap (defaults to true)
  final bool enableHapticFeedback;

  const SettingsTile({
    required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap, super.key,
    this.trailing,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.opacity15,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      onTap: () {
        if (enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
        onTap();
      },
    );
  }
}
