// lib/presentation/widgets/note_details_panel.dart
import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Smallest touch target the panel hands out, in logical points.
const double _touchTarget = 44;

const _accentOptions = <String>[
  'mint',
  'peach',
  'water',
  'sleep',
  'focus',
];

/// Everything about a note that is not its text: reminder, focus session,
/// tags, accent and pin.
///
/// One widget for both shapes the note surface can take, a bottom sheet on a
/// phone and a side column on a wide window, so the two can never disagree
/// about what a note carries.
class NoteDetailsPanel extends StatelessWidget {
  final VoidCallback onReminder;
  final TextEditingController tagsController;
  final String accentKey;
  final ValueChanged<String> onAccentChanged;
  final VoidCallback? onFocus;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const NoteDetailsPanel({
    required this.onReminder,
    required this.tagsController,
    required this.accentKey,
    required this.onAccentChanged,
    this.onFocus,
    this.isPinned = false,
    this.onTogglePin,
    super.key,
  });

  /// A note earns an identity the first time it is written down, and both the
  /// pin and the focus timer need that identity to point at anything.
  bool get _isSaved => onTogglePin != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.large),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Volver con intención', style: theme.textTheme.titleMedium),
            SizedBox(height: context.spacing.xs),
            Text(
              'Estas herramientas enriquecen la nota sin interrumpir la '
              'escritura.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.md),
            _DetailsToolTile(
              key: const ValueKey('note-reminder-tool'),
              icon: Icons.notifications_none_rounded,
              title: 'Recordatorio',
              subtitle: _isSaved
                  ? 'Elige cuándo quieres volver'
                  : 'Guarda la nota para elegir un momento',
              onTap: onReminder,
            ),
            SizedBox(height: context.spacing.xs),
            _DetailsToolTile(
              key: const ValueKey('note-focus-tool'),
              icon: Icons.timer_outlined,
              title: 'Enfocarme en esta nota',
              subtitle: 'La duración se elige en Enfoque',
              onTap: onFocus,
            ),
            SizedBox(height: context.spacing.md),
            TextField(
              key: const ValueKey('note-tags-field'),
              controller: tagsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Etiquetas',
                hintText: 'estudio, examen',
                prefixIcon: Icon(Icons.sell_outlined),
                helperText: 'Sepáralas con comas.',
              ),
            ),
            SizedBox(height: context.spacing.md),
            Text('Acento', style: theme.textTheme.labelLarge),
            SizedBox(height: context.spacing.xs),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final accent in _accentOptions)
                  _AccentChoice(
                    key: ValueKey('note-accent-$accent'),
                    label: _accentLabel(accent),
                    color: _accentColor(context, accent),
                    selected: accentKey == accent,
                    onTap: () => onAccentChanged(accent),
                  ),
              ],
            ),
            if (_isSaved) ...[
              SizedBox(height: context.spacing.lg),
              OutlinedButton.icon(
                key: const ValueKey('note-pin-action'),
                onPressed: onTogglePin,
                icon: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                ),
                label: Text(isPinned ? 'Desfijar' : 'Fijar nota'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colour that stands for [key] in the current theme.
Color _accentColor(BuildContext context, String key) {
  final palette = context.zentraPalette;
  return switch (key) {
    'peach' => palette.warmPeach,
    'water' => palette.water,
    'sleep' => palette.sleep,
    'focus' => palette.focus,
    _ => palette.brandTeal,
  };
}

/// Name a reader sees for [key].
String _accentLabel(String key) {
  return switch (key) {
    'peach' => 'Cálido',
    'water' => 'Azul',
    'sleep' => 'Lavanda',
    'focus' => 'Enfoque',
    _ => 'Calma',
  };
}

class _AccentChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: 'Acento $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: _touchTarget),
          padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.radii.pill),
            border: Border.all(
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 14, color: color),
              SizedBox(width: context.spacing.xs),
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DetailsToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radii.medium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.sm),
            child: Row(
              children: [
                Icon(icon, color: context.zentraPalette.brandTeal),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
