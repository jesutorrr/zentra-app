import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

/// A reusable emoji selector widget for avatar/profile selection.
/// 
/// Displays a grid of emoji options that the user can select from.
/// Provides haptic feedback on selection and visual indication of 
/// the currently selected emoji.
class EmojiSelector extends StatelessWidget {
  /// The currently selected emoji
  final String selectedEmoji;
  
  /// Callback when an emoji is selected
  final ValueChanged<String> onEmojiSelected;
  
  /// Whether to use the compact emoji list (15 items) or full list (30 items)
  final bool compact;
  
  /// Size of each emoji tile
  final double tileSize;
  
  /// Spacing between emoji tiles
  final double spacing;
  
  /// Custom list of emojis to display (overrides compact setting)
  final List<String>? customEmojis;

  const EmojiSelector({
    required this.selectedEmoji, required this.onEmojiSelected, super.key,
    this.compact = false,
    this.tileSize = 48,
    this.spacing = 8,
    this.customEmojis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final emojis = customEmojis ?? (compact ? kCompactAvatarEmojis : kAvatarEmojis);
    
    // Use GridView for consistent alignment across platforms
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = emoji == selectedEmoji;
        return _EmojiTile(
          emoji: emoji,
          isSelected: isSelected,
          size: tileSize,
          colorScheme: colorScheme,
          onTap: () {
            onEmojiSelected(emoji);
            HapticFeedback.selectionClick();
          },
        );
      },
    );
  }
}

/// Individual emoji tile widget
class _EmojiTile extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final double size;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _EmojiTile({
    required this.emoji,
    required this.isSelected,
    required this.size,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size * 0.25),
          border: isSelected
              ? Border.all(
                  color: colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// A labeled emoji selector with a title
class LabeledEmojiSelector extends StatelessWidget {
  /// The title label shown above the emoji grid
  final String label;
  
  /// The currently selected emoji
  final String selectedEmoji;
  
  /// Callback when an emoji is selected
  final ValueChanged<String> onEmojiSelected;
  
  /// Whether to use the compact emoji list
  final bool compact;

  const LabeledEmojiSelector({
    required this.label, required this.selectedEmoji, required this.onEmojiSelected, super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        EmojiSelector(
          selectedEmoji: selectedEmoji,
          onEmojiSelected: onEmojiSelected,
          compact: compact,
        ),
      ],
    );
  }
}
