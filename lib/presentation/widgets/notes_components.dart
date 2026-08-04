import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/markdown_document.dart';
import '../design_tokens.dart';
import '../motion_policy.dart';
import 'note_block_editor.dart';
import 'note_block_view.dart';

/// Width below which the four section chips stop fitting on one line.
///
/// Measured against the longest set of labels rather than a device class: the
/// chips are as wide as their text, and the same threshold already decides how
/// much the search field spells out.
const double _sectionsFitOneLine = 480;

enum NotesLibrarySection {
  review('Para repasar', Icons.notifications_active_outlined),
  pinned('Fijadas', Icons.push_pin_outlined),
  recent('Recientes', Icons.schedule_outlined),
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

class NotesSectionSelector extends StatefulWidget {
  final NotesLibrarySection selected;
  final ValueChanged<NotesLibrarySection> onSelected;

  const NotesSectionSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  @override
  State<NotesSectionSelector> createState() => _NotesSectionSelectorState();
}

class _NotesSectionSelectorState extends State<NotesSectionSelector> {
  /// One key per section so the strip can scroll the live filter into view.
  final _chipKeys = {
    for (final section in NotesLibrarySection.values)
      section: GlobalKey(debugLabel: 'notes-section-${section.name}'),
  };

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(NotesSectionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelected();
  }

  /// Brings the live filter on screen once the strip has been laid out.
  ///
  /// A narrow window scrolls the sections, and the one doing the filtering is
  /// the one the reader most needs to see: without this, opening the library
  /// on a phone hides the active section past the right edge and the list
  /// looks filtered by whichever chip happens to be visible.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipContext = _chipKeys[widget.selected]?.currentContext;
      if (chipContext == null || !mounted) return;
      // Only the horizontal strip. A wide window lays the chips out in a Wrap,
      // where the nearest scrollable is the library itself, and asking that to
      // reveal a chip would scroll the notes out from under the reader.
      final position = Scrollable.maybeOf(chipContext)?.position;
      if (position == null || position.axis != Axis.horizontal) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: context.motionPolicy.duration(
          const Duration(milliseconds: 200),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final chips = [
      for (final section in NotesLibrarySection.values)
        // The global key rides on a wrapper so the chip keeps the value key
        // callers already reach for.
        KeyedSubtree(
          key: _chipKeys[section],
          child: ChoiceChip(
            key: ValueKey('notes-section-${section.name}'),
            avatar: Icon(section.icon, size: 18),
            label: Text(section.label),
            selected: selected == section,
            onSelected: (_) => widget.onSelected(section),
          ),
        ),
    ];

    return Semantics(
      label: 'Secciones de notas',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On a phone the four sections wrap onto a second line and push the
          // first note further down than the notes themselves get to sit. One
          // scrolling line costs a swipe to reach the last section, which is
          // the same bargain the tag strip right below already makes.
          if (constraints.maxWidth < _sectionsFitOneLine) {
            return SingleChildScrollView(
              key: const ValueKey('notes-section-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final chip in chips) ...[
                    chip,
                    if (chip != chips.last) SizedBox(width: context.spacing.xs),
                  ],
                ],
              ),
            );
          }
          return Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: chips,
          );
        },
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

class NoteLibraryCard extends StatelessWidget {
  final String title;

  /// Already readable preview text, never raw Markdown: the caller strips the
  /// markers so the card never has to guess which characters are syntax.
  final String body;
  final String? tag;
  final String updatedLabel;
  final String? reminderLabel;
  final int checkedCount;
  final int checkItemCount;

  /// Search term to emphasize inside [body], when the card is showing a result.
  final String? highlightQuery;
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
    this.checkedCount = 0,
    this.checkItemCount = 0,
    this.highlightQuery,
    this.isPinned = false,
    this.isArchived = false,
    this.isSelected = false,
    this.onTogglePin,
    this.onToggleArchive,
    super.key,
  });

  String get _progressLabel => '$checkedCount de $checkItemCount';

  /// Clamped so a caller that passes counts from two different reads cannot
  /// paint a bar longer than its own track.
  double get _progressValue {
    if (checkItemCount <= 0) return 0;
    return (checkedCount / checkItemCount).clamp(0, 1);
  }

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
        // The bar alone carries no meaning for a reader who cannot see it.
        if (checkItemCount > 0) '$_progressLabel completadas',
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
                        Text.rich(
                          TextSpan(
                            children: _highlightSpans(
                              context,
                              body.trim().isEmpty
                                  ? 'Todavía no hay contenido.'
                                  : body,
                            ),
                          ),
                          key: const ValueKey('note-card-preview'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (checkItemCount > 0) ...[
                          SizedBox(height: context.spacing.xs),
                          _buildProgress(context, theme),
                        ],
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

  /// The checklist track plus its count, always paired: the bar is colour
  /// only, so the count is what a reader who cannot see it gets.
  Widget _buildProgress(BuildContext context, ThemeData theme) {
    const progress = ValueKey('note-card-progress');
    final label = Text(
      _progressLabel,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final track = ClipRRect(
      borderRadius: BorderRadius.circular(context.radii.pill),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: _progressValue,
        backgroundColor: context.zentraPalette.progressTrack,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
    // Side by side the count stops fitting long before the largest text
    // sizes, and squeezing the track to zero would leave the bar meaningless.
    if (MediaQuery.textScalerOf(context).scale(16) > 23) {
      return Column(
        key: progress,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          track,
          SizedBox(height: context.spacing.xxs),
          label,
        ],
      );
    }
    return Row(
      key: progress,
      children: [
        Expanded(child: track),
        SizedBox(width: context.spacing.xs),
        label,
      ],
    );
  }

  /// Splits [value] so the searched term reads as the reason this card is on
  /// screen.
  ///
  /// Matching is done with [String.indexOf] rather than a pattern, so a query
  /// full of regular expression characters is treated as the literal text the
  /// reader typed.
  List<TextSpan> _highlightSpans(BuildContext context, String value) {
    final theme = Theme.of(context);
    final base = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final query = highlightQuery?.trim() ?? '';
    if (query.isEmpty) return [TextSpan(text: value, style: base)];
    // Case folding can change a string's length, so the offset it yields is
    // clamped before it indexes back into the original text.
    final at = value.toLowerCase().indexOf(query.toLowerCase());
    if (at < 0 || at >= value.length) {
      return [TextSpan(text: value, style: base)];
    }
    final end =
        at + query.length > value.length ? value.length : at + query.length;
    return [
      if (at > 0) TextSpan(text: value.substring(0, at), style: base),
      TextSpan(
        text: value.substring(at, end),
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      if (end < value.length) TextSpan(text: value.substring(end), style: base),
    ];
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
              style: noteTitleTextStyle(context),
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

  /// Size of the leading glyph, in logical points.
  static const double _glyphSize = 18;

  /// Narrowest a Material button gets, whatever it holds.
  static const double _minButtonWidth = 64;

  static const String _retryLabel = 'Reintentar';

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
    final retries = state == NoteSaveVisualState.error && onRetry != null;

    return Semantics(
      liveRegion: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_fits(context, label, constraints.maxWidth, retries)) {
            return _glyphOnly(context, icon, label, color, retries);
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: _glyphSize, color: color),
              SizedBox(width: context.spacing.xxs),
              Text(
                label,
                key: const ValueKey('note-save-label'),
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                    ),
              ),
              if (retries) ...[
                SizedBox(width: context.spacing.xs),
                TextButton(
                  key: const ValueKey('note-save-retry'),
                  onPressed: onRetry,
                  child: const Text(_retryLabel),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// What is left when the app bar has no room for the word: the glyph alone,
  /// still tappable while there is something to retry.
  ///
  /// The word is dropped whole rather than clipped, because a state ellipsized
  /// to `Sin …` says less than the glyph it sits next to, and the reader who
  /// cannot see either still gets the full label from the live region above.
  Widget _glyphOnly(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool retries,
  ) {
    if (!retries) return Icon(icon, size: _glyphSize, color: color);
    return IconButton(
      key: const ValueKey('note-save-retry'),
      tooltip: _retryLabel,
      onPressed: onRetry,
      icon: Icon(icon, color: color, semanticLabel: '$label. $_retryLabel.'),
    );
  }

  /// Whether the word next to the glyph still has room.
  ///
  /// Measured rather than guessed at a breakpoint: the app bar hands the title
  /// whatever its actions leave over, and that changes with the writing mode,
  /// the window and the reader's text size all at once.
  bool _fits(
    BuildContext context,
    String label,
    double available,
    bool retries,
  ) {
    if (!available.isFinite) return true;
    final theme = Theme.of(context);
    var needed = _glyphSize +
        context.spacing.xxs +
        _textWidth(context, label, theme.textTheme.labelLarge);
    if (retries) {
      final button = theme.textButtonTheme.style;
      final padding =
          button?.padding?.resolve(const <WidgetState>{})?.horizontal ?? 0;
      final text = _textWidth(
        context,
        _retryLabel,
        button?.textStyle?.resolve(const <WidgetState>{}) ??
            theme.textTheme.labelLarge,
      );
      needed += context.spacing.xs + math.max(_minButtonWidth, text + padding);
    }
    // A little slack, so a rounding difference between this measurement and
    // the real layout can never become an overflow.
    return needed + context.spacing.xxs <= available;
  }

  double _textWidth(BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
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
          // A long tag at a large text size is wider than the card that holds
          // it, so the pill grows a second line instead of running over.
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                  ),
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
