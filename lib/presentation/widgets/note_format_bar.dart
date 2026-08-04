// lib/presentation/widgets/note_format_bar.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_editing.dart';
import '../design_tokens.dart';

/// Smallest touch target the bar will hand out, in logical points.
const double _touchTarget = 48;

/// What a screen reader hears on a command the active block refuses.
///
/// A dimmed button already reads as unavailable, but not as to why, and the
/// reason is the whole point: the same button works one block away.
const String _unavailableOnBlock = 'No disponible en este bloque';

/// The way out of a block no command can change. Named after the action in the
/// app bar, so the sentence is a place the reader can actually go.
const String _plainTextNotice =
    'Este bloque solo se puede editar en «Editar como texto».';

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

  /// The commands that would actually change the block under the caret.
  ///
  /// Everything outside it is drawn disabled. Several commands refuse to act
  /// rather than lose text, and a button that looks live and does nothing is
  /// worse than one that admits it cannot help.
  final Set<NoteBlockCommand> availableCommands;

  /// Whether nothing on the bar can change the block under the caret, which
  /// earns the reader a line pointing at the way out.
  ///
  /// The separator does not count: it inserts a rule below the block instead
  /// of touching it, so it is available even where everything else refuses.
  final bool blockAcceptsNoCommand;

  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const NoteFormatBar({
    required this.visible,
    required this.onCommand,
    required this.availableCommands,
    this.activeCommand,
    this.blockAcceptsNoCommand = false,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (blockAcceptsNoCommand) _plainTextHint(context),
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Flexible(child: _formatGroup(context, constraints.maxWidth)),
                  _separator(context),
                  // Undo is the safety net of a block editor, so it lives
                  // outside the part of the bar that is allowed to give way.
                  _button(
                    context,
                    name: 'undo',
                    icon: Icons.undo_rounded,
                    label: 'Deshacer',
                    unavailableHint: 'No hay nada que deshacer',
                    onPressed: onUndo,
                  ),
                  _button(
                    context,
                    name: 'redo',
                    icon: Icons.redo_rounded,
                    label: 'Rehacer',
                    unavailableHint: 'No hay nada que rehacer',
                    onPressed: onRedo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The one line the bar says out loud, for the block it cannot touch at all.
  ///
  /// Deliberately not a warning: nothing is wrong and nothing was lost, there
  /// is simply another door. It is read as ordinary text rather than announced
  /// as a live region, so it never interrupts the reader mid block.
  Widget _plainTextHint(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('note-format-plain-text-hint'),
      padding: EdgeInsets.only(
        left: context.spacing.xxs,
        right: context.spacing.xxs,
        bottom: context.spacing.xxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: context.spacing.xxs),
          // Expanded rather than a bare text: at a large text scale the line
          // has to wrap instead of running off the edge of a narrow phone.
          Expanded(
            child: Text(
              _plainTextNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
                unavailableHint: _unavailableOnBlock,
                onPressed: availableCommands.contains(entry.key)
                    ? () => onCommand(entry.key)
                    : null,
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
            unavailableHint: _unavailableOnBlock,
            onPressed: onBold,
          ),
          _button(
            context,
            name: 'italic',
            icon: Icons.format_italic_rounded,
            label: 'Cursiva',
            unavailableHint: _unavailableOnBlock,
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
          _menuItem(context, entry.key, entry.value, active),
      ],
    );
  }

  PopupMenuItem<NoteBlockCommand> _menuItem(
    BuildContext context,
    NoteBlockCommand command,
    (IconData, String) glyph,
    NoteBlockCommand? active,
  ) {
    final enabled = availableCommands.contains(command);
    return PopupMenuItem<NoteBlockCommand>(
      key: ValueKey('note-format-menu-${command.name}'),
      value: command,
      enabled: enabled,
      child: Semantics(
        selected: command == active,
        // The row the menu offers is dimmed already; this is what tells a
        // reader who cannot see the dimming why the row will not answer.
        hint: enabled ? null : _unavailableOnBlock,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              glyph.$1,
              color: command == active ? context.zentraPalette.brandTeal : null,
            ),
            SizedBox(width: context.spacing.sm),
            Flexible(child: Text(glyph.$2)),
          ],
        ),
      ),
    );
  }

  /// One toolbar button.
  ///
  /// The label rides on the icon rather than on the tooltip alone: a tooltip
  /// is a hint, and VoiceOver reads it only when the node has nothing else to
  /// say. [selected] is left null for the actions that are not toggles, so the
  /// screen reader announces a state only where one exists.
  ///
  /// A null [onPressed] both dims the button and drops its tap action, which
  /// is what makes a screen reader call it unavailable. [unavailableHint] adds
  /// the part the platform cannot know: why this one is out right now.
  Widget _button(
    BuildContext context, {
    required String name,
    required IconData icon,
    required String label,
    required String unavailableHint,
    required VoidCallback? onPressed,
    bool? selected,
  }) {
    final iconWidget = Icon(icon, semanticLabel: label);
    final button = IconButton(
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
    if (onPressed != null) return button;
    // Merged rather than annotated in place: the button builds its own
    // semantics container, so a hint left outside it would become a second
    // node the reader has to find on its own.
    return MergeSemantics(
      child: Semantics(hint: unavailableHint, child: button),
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
