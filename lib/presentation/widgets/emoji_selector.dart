import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

/// Abre la galería completa de avatares solo cuando el usuario la necesita.
///
/// Mantener la galería fuera de los formularios evita que una preferencia
/// secundaria desplace los campos y la acción principal fuera de la pantalla.
Future<String?> showEmojiPickerSheet({
  required BuildContext context,
  required String selectedEmoji,
  String title = 'Elige tu avatar',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return FractionallySizedBox(
        heightFactor: 0.78,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige uno ahora. Podrás cambiarlo después.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: EmojiSelector(
                        selectedEmoji: selectedEmoji,
                        onEmojiSelected: (emoji) {
                          Navigator.of(sheetContext).pop(emoji);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Selector compacto para formularios.
///
/// La tarjeta muestra la elección actual y deja la galería completa detrás de
/// una acción explícita, sin esconder funcionalidad ni saturar la pantalla.
class CompactAvatarPicker extends StatelessWidget {
  final String label;
  final String selectedEmoji;
  final VoidCallback onTap;

  const CompactAvatarPicker({
    required this.label,
    required this.selectedEmoji,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        Semantics(
          button: true,
          label: 'Cambiar avatar. Avatar actual: $selectedEmoji',
          child: Material(
            key: const ValueKey('compact-avatar-picker'),
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.55),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selectedEmoji,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu avatar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Toca para cambiarlo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
    required this.selectedEmoji,
    required this.onEmojiSelected,
    super.key,
    this.compact = false,
    this.tileSize = 48,
    this.spacing = 8,
    this.customEmojis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final emojis =
        customEmojis ?? (compact ? kCompactAvatarEmojis : kAvatarEmojis);

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
            textScaler: TextScaler.noScaling,
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
    required this.label,
    required this.selectedEmoji,
    required this.onEmojiSelected,
    super.key,
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
