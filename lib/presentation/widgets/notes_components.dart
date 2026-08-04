import 'package:flutter/material.dart';

import '../../domain/markdown_document.dart';
import '../design_tokens.dart';
import 'note_block_editor.dart';

enum NotesLibrarySection {
  review('Para repasar', Icons.notifications_active_outlined),
  pinned('Fijadas', Icons.push_pin_outlined),
  recent('Recientes', Icons.schedule_rounded),
  archived('Archivadas', Icons.archive_outlined);

  final String label;
  final IconData icon;

  const NotesLibrarySection(this.label, this.icon);
}

enum NoteSaveVisualState {
  idle,
  saving,
  saved,
  error,
}

class NotesSectionSelector extends StatelessWidget {
  final NotesLibrarySection selected;
  final ValueChanged<NotesLibrarySection> onSelected;

  const NotesSectionSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final section in NotesLibrarySection.values)
        ChoiceChip(
          key: ValueKey('notes-section-${section.name}'),
          avatar: Icon(section.icon, size: 18),
          label: Text(section.label),
          selected: selected == section,
          onSelected: (_) => onSelected(section),
        ),
    ];

    return Semantics(
      label: 'Secciones de notas',
      child: Wrap(
        spacing: context.spacing.xs,
        runSpacing: context.spacing.xs,
        children: chips,
      ),
    );
  }
}

class NotesSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const NotesSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => TextField(
        key: const ValueKey('notes-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: constraints.maxWidth < 480
              ? 'Buscar notas'
              : 'Buscar por título, contenido o etiqueta',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class NotesCaptureCard extends StatelessWidget {
  final VoidCallback onCreate;

  const NotesCaptureCard({
    required this.onCreate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = context.zentraPalette;
    return Material(
      color: palette.calmMint.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.52 : 0.74,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.large),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        key: const ValueKey('notes-create-card'),
        onTap: onCreate,
        borderRadius: BorderRadius.circular(context.radii.large),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(context.radii.medium),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: palette.brandTeal,
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Captura una idea',
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        'Escribe primero. Organiza cuando te sirva.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Icon(
                  Icons.add_circle_rounded,
                  color: palette.brandTeal,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteLibraryCard extends StatelessWidget {
  final String title;
  final String body;
  final String? tag;
  final String updatedLabel;
  final String? reminderLabel;
  final bool isPinned;
  final bool isArchived;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;

  const NoteLibraryCard({
    required this.title,
    required this.body,
    required this.updatedLabel,
    required this.accent,
    required this.onTap,
    this.tag,
    this.reminderLabel,
    this.isPinned = false,
    this.isArchived = false,
    this.isSelected = false,
    this.onTogglePin,
    this.onToggleArchive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = isSelected
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.12),
            colorScheme.surfaceContainerLow,
          )
        : colorScheme.surfaceContainerLow;

    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        title,
        if (isPinned) 'fijada',
        if (isArchived) 'archivada',
        if (reminderLabel != null) reminderLabel!,
      ].join(', '),
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.large),
          side: BorderSide(
            color: isSelected ? accent : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 5, child: ColoredBox(color: accent)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing.md,
                      context.spacing.md,
                      context.spacing.xs,
                      context.spacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: context.spacing.xs,
                          runSpacing: context.spacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (tag != null && tag!.trim().isNotEmpty)
                              _NotePill(
                                icon: Icons.sell_outlined,
                                label: tag!,
                                color: accent,
                              ),
                            if (reminderLabel != null)
                              _NotePill(
                                icon: Icons.notifications_none_rounded,
                                label: reminderLabel!,
                                color: context.zentraPalette.warmPeach,
                              ),
                            if (isPinned)
                              _NotePill(
                                icon: Icons.push_pin_outlined,
                                label: 'Fijada',
                                color: context.zentraPalette.brandTeal,
                              ),
                          ],
                        ),
                        if ((tag != null && tag!.trim().isNotEmpty) ||
                            reminderLabel != null ||
                            isPinned)
                          SizedBox(height: context.spacing.sm),
                        Text(
                          title.trim().isEmpty ? 'Nota sin título' : title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          body.trim().isEmpty
                              ? 'Todavía no hay contenido.'
                              : body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          updatedLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NoteCardMenu(
                  isPinned: isPinned,
                  isArchived: isArchived,
                  onTogglePin: onTogglePin,
                  onToggleArchive: onToggleArchive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteDetailSurface extends StatelessWidget {
  final String title;
  final String body;
  final String? tag;
  final String updatedLabel;
  final String? reminderLabel;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onReminder;
  final VoidCallback onFocus;
  final VoidCallback onReview;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final bool isPinned;
  final bool isArchived;

  const NoteDetailSurface({
    required this.title,
    required this.body,
    required this.updatedLabel,
    required this.accent,
    required this.onEdit,
    required this.onReminder,
    required this.onFocus,
    required this.onReview,
    this.tag,
    this.reminderLabel,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.isPinned = false,
    this.isArchived = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(context.radii.extraLarge),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: context.spacing.xs,
                    runSpacing: context.spacing.xs,
                    children: [
                      if (tag != null && tag!.trim().isNotEmpty)
                        _NotePill(
                          icon: Icons.sell_outlined,
                          label: tag!,
                          color: accent,
                        ),
                      if (reminderLabel != null)
                        _NotePill(
                          icon: Icons.notifications_none_rounded,
                          label: reminderLabel!,
                          color: context.zentraPalette.warmPeach,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: reminderLabel == null
                      ? 'Agregar recordatorio'
                      : 'Editar recordatorio',
                  onPressed: onReminder,
                  icon: Icon(
                    reminderLabel == null
                        ? Icons.add_alert_outlined
                        : Icons.notifications_active_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nota',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<_NoteDetailAction>(
                  tooltip: 'Más acciones',
                  onSelected: (action) {
                    switch (action) {
                      case _NoteDetailAction.pin:
                        onTogglePin?.call();
                        break;
                      case _NoteDetailAction.archive:
                        onToggleArchive?.call();
                        break;
                      case _NoteDetailAction.delete:
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _NoteDetailAction.pin,
                      enabled: onTogglePin != null,
                      child: Text(isPinned ? 'Desfijar' : 'Fijar'),
                    ),
                    PopupMenuItem(
                      value: _NoteDetailAction.archive,
                      enabled: onToggleArchive != null,
                      child: Text(isArchived ? 'Restaurar' : 'Archivar'),
                    ),
                    PopupMenuItem(
                      value: _NoteDetailAction.delete,
                      enabled: onDelete != null,
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.spacing.md),
            Text(
              title.trim().isEmpty ? 'Nota sin título' : title,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              updatedLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing.lg),
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: body.trim().isEmpty
                      ? Text(
                          'Todavía no hay contenido.',
                          style:
                              theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                        )
                      : NoteBlockEditor(
                          document: MarkdownDocument.parse(body),
                          readOnly: true,
                          onChanged: (_) {},
                          onCaretChanged: (_) {},
                        ),
                ),
              ),
            ),
            SizedBox(height: context.spacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacks = constraints.maxWidth < 420 ||
                    MediaQuery.textScalerOf(context).scale(16) > 23;
                final review = FilledButton.icon(
                  key: const ValueKey('note-mark-reviewed'),
                  onPressed: onReview,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Marcar repasada'),
                );
                final focus = OutlinedButton.icon(
                  key: const ValueKey('note-start-focus'),
                  onPressed: onFocus,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Iniciar enfoque'),
                );
                if (stacks) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      review,
                      SizedBox(height: context.spacing.sm),
                      focus,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: review),
                    SizedBox(width: context.spacing.sm),
                    Expanded(child: focus),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotesEmptyState extends StatelessWidget {
  final NotesLibrarySection section;
  final String query;
  final VoidCallback onCreate;
  final VoidCallback? onClear;

  const NotesEmptyState({
    required this.section,
    required this.query,
    required this.onCreate,
    this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuery = query.trim().isNotEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: context.zentraPalette.calmMint.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasQuery ? Icons.search_off_rounded : section.icon,
                  size: 40,
                  color: context.zentraPalette.brandTeal,
                ),
              ),
              SizedBox(height: context.spacing.md),
              Text(
                hasQuery ? 'No encontramos esa nota' : _emptyTitleFor(section),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                hasQuery
                    ? 'Prueba otra palabra o limpia la búsqueda.'
                    : _emptyBodyFor(section),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.lg),
              if (hasQuery)
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Limpiar búsqueda'),
                )
              else
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crear una nota'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyTitleFor(NotesLibrarySection value) {
    return switch (value) {
      NotesLibrarySection.review => 'Nada pendiente por repasar',
      NotesLibrarySection.pinned => 'Todavía no hay notas fijadas',
      NotesLibrarySection.recent => 'Tu primera idea puede vivir aquí',
      NotesLibrarySection.archived => 'El archivo está vacío',
    };
  }

  String _emptyBodyFor(NotesLibrarySection value) {
    return switch (value) {
      NotesLibrarySection.review =>
        'Cuando programes un recordatorio, Zentra traerá la nota en el momento elegido.',
      NotesLibrarySection.pinned =>
        'Fija las notas a las que quieres volver con frecuencia.',
      NotesLibrarySection.recent =>
        'Tus notas son locales por defecto. Escribe primero y organiza después.',
      NotesLibrarySection.archived =>
        'Las notas que apartes quedarán aquí hasta que decidas restaurarlas.',
    };
  }
}

class NoteSaveStatus extends StatelessWidget {
  final NoteSaveVisualState state;
  final VoidCallback? onRetry;

  const NoteSaveStatus({
    required this.state,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (state) {
      NoteSaveVisualState.idle => (
          Icons.edit_outlined,
          'Sin cambios',
          colorScheme.onSurfaceVariant,
        ),
      NoteSaveVisualState.saving => (
          Icons.sync_rounded,
          'Guardando',
          colorScheme.primary,
        ),
      NoteSaveVisualState.saved => (
          Icons.cloud_done_outlined,
          'Guardado',
          context.zentraPalette.brandTeal,
        ),
      NoteSaveVisualState.error => (
          Icons.error_outline_rounded,
          'No se pudo guardar',
          colorScheme.error,
        ),
    };

    return Semantics(
      liveRegion: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: context.spacing.xxs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                  ),
            ),
          ),
          if (state == NoteSaveVisualState.error && onRetry != null) ...[
            SizedBox(width: context.spacing.xs),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NotePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: context.spacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

enum _NoteCardAction {
  pin,
  archive,
}

enum _NoteDetailAction {
  pin,
  archive,
  delete,
}

class _NoteCardMenu extends StatelessWidget {
  final bool isPinned;
  final bool isArchived;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;

  const _NoteCardMenu({
    required this.isPinned,
    required this.isArchived,
    this.onTogglePin,
    this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: PopupMenuButton<_NoteCardAction>(
        tooltip: 'Acciones de nota',
        onSelected: (action) {
          switch (action) {
            case _NoteCardAction.pin:
              onTogglePin?.call();
              break;
            case _NoteCardAction.archive:
              onToggleArchive?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _NoteCardAction.pin,
            enabled: onTogglePin != null,
            child: Text(isPinned ? 'Desfijar' : 'Fijar'),
          ),
          PopupMenuItem(
            value: _NoteCardAction.archive,
            enabled: onToggleArchive != null,
            child: Text(isArchived ? 'Restaurar' : 'Archivar'),
          ),
        ],
      ),
    );
  }
}
