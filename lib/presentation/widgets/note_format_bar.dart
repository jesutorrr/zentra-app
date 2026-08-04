// lib/presentation/widgets/note_format_bar.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_editing.dart';
import '../design_tokens.dart';

/// Smallest touch target the bar will hand out, in logical points.
const double _touchTarget = 48;

const _commandIcons = <NoteBlockCommand, (IconData, String)>{
  NoteBlockCommand.heading: (Icons.title_rounded, 'Encabezado'),
  NoteBlockCommand.bullet: (Icons.format_list_bulleted_rounded, 'Lista'),
  NoteBlockCommand.numbered: (
    Icons.format_list_numbered_rounded,
    'Lista numerada',
  ),
  NoteBlockCommand.checklist: (Icons.checklist_rounded, 'Casilla'),
  NoteBlockCommand.quote: (Icons.format_quote_rounded, 'Cita'),
  NoteBlockCommand.code: (Icons.code_rounded, 'Código'),
  NoteBlockCommand.divider: (Icons.horizontal_rule_rounded, 'Separador'),
};

/// What the block menu wears when the caret sits on an ordinary paragraph,
/// the one block type that has no command of its own.
const (IconData, String) _paragraphGlyph = (Icons.subject_rounded, 'Párrafo');

/// Buttons the bar never collapses: the two inline styles and the two history
/// actions.
const int _fixedButtonCount = 4;

/// Formatting bar that only exists while the body has focus and sits above the
/// software keyboard.
class NoteFormatBar extends StatelessWidget {
  final bool visible;
  final ValueChanged<NoteBlockCommand> onCommand;
  final NoteBlockCommand? activeCommand;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const NoteFormatBar({
    required this.visible,
    required this.onCommand,
    this.activeCommand,
    this.onBold,
    this.onItalic,
    this.onUndo,
    this.onRedo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      // Without this the group label would swallow the buttons into a single
      // node and a screen reader would lose every command.
      explicitChildNodes: true,
      label: 'Formato de nota',
      child: Container(
        key: const ValueKey('note-format-bar'),
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.xs,
          vertical: context.spacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Flexible(child: _formatGroup(context, constraints.maxWidth)),
              _separator(context),
              // Undo is the safety net of a block editor, so it lives outside
              // the part of the bar that is allowed to give way.
              _button(
                context,
                name: 'undo',
                icon: Icons.undo_rounded,
                label: 'Deshacer',
                onPressed: onUndo,
              ),
              _button(
                context,
                name: 'redo',
                icon: Icons.redo_rounded,
                label: 'Rehacer',
                onPressed: onRedo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The seven block commands plus the two inline styles.
  ///
  /// Too narrow a window collapses the block commands into a single menu
  /// instead of letting them scroll behind no affordance at all. The scroll
  /// view stays as the last resort for a window narrower than even that.
  Widget _formatGroup(BuildContext context, double available) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (_commandsFitInline(context, available)) ...[
            for (final entry in _commandIcons.entries)
              _button(
                context,
                name: entry.key.name,
                icon: entry.value.$1,
                label: entry.value.$2,
                onPressed: () => onCommand(entry.key),
                selected: activeCommand == entry.key,
              ),
          ] else
            _blockTypeMenu(context),
          _separator(context),
          _button(
            context,
            name: 'bold',
            icon: Icons.format_bold_rounded,
            label: 'Negritas',
            onPressed: onBold,
          ),
          _button(
            context,
            name: 'italic',
            icon: Icons.format_italic_rounded,
            label: 'Cursiva',
            onPressed: onItalic,
          ),
        ],
      ),
    );
  }

  /// Whether every block command still has room next to the buttons the bar
  /// never collapses.
  ///
  /// Counted rather than read off a device breakpoint: the bar is as wide as
  /// the window, every button is the same fixed size, and neither of those
  /// changes with the reader's text size.
  bool _commandsFitInline(BuildContext context, double available) {
    if (!available.isFinite) return true;
    final buttons = _commandIcons.length + _fixedButtonCount;
    return available >= buttons * _touchTarget + 2 * context.spacing.xs;
  }

  /// One control standing in for the seven block commands.
  ///
  /// It wears the active block's icon, so the bar still answers "what is this
  /// block" at a glance the way the inline row does, and says so out loud for
  /// a screen reader.
  Widget _blockTypeMenu(BuildContext context) {
    final active = activeCommand;
    final (icon, name) =
        active == null ? _paragraphGlyph : _commandIcons[active]!;
    return PopupMenuButton<NoteBlockCommand>(
      key: const ValueKey('note-format-block-menu'),
      tooltip: 'Tipo de bloque',
      icon: Icon(icon, semanticLabel: 'Tipo de bloque: $name'),
      onSelected: onCommand,
      itemBuilder: (context) => [
        for (final entry in _commandIcons.entries)
          PopupMenuItem<NoteBlockCommand>(
            key: ValueKey('note-format-menu-${entry.key.name}'),
            value: entry.key,
            child: Semantics(
              selected: entry.key == active,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value.$1,
                    color: entry.key == active
                        ? context.zentraPalette.brandTeal
                        : null,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Flexible(child: Text(entry.value.$2)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// One toolbar button.
  ///
  /// The label rides on the icon rather than on the tooltip alone: a tooltip
  /// is a hint, and VoiceOver reads it only when the node has nothing else to
  /// say. [selected] is left null for the actions that are not toggles, so the
  /// screen reader announces a state only where one exists.
  Widget _button(
    BuildContext context, {
    required String name,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool? selected,
  }) {
    final iconWidget = Icon(icon, semanticLabel: label);
    return IconButton(
      key: ValueKey('note-format-$name'),
      tooltip: label,
      isSelected: selected,
      selectedIcon: selected == null
          ? null
          : Icon(
              icon,
              semanticLabel: label,
              color: context.zentraPalette.brandTeal,
            ),
      constraints: const BoxConstraints(
        minWidth: _touchTarget,
        minHeight: _touchTarget,
      ),
      onPressed: onPressed,
      icon: iconWidget,
    );
  }

  /// A rule needs a bounded height inside a horizontal row, and it carries no
  /// meaning for a screen reader.
  Widget _separator(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: context.spacing.lg,
          child: VerticalDivider(
            width: context.spacing.xs,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
}
