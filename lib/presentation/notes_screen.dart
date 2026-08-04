import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/note_controller.dart';
import '../application/note_state.dart';
import '../application/session_controller.dart';
import '../domain/note_models.dart';
import 'design_tokens.dart';
import 'note_reminder_screen.dart';
import 'note_surface.dart';
import 'pomodoro_screen.dart';
import 'utils/dialogs.dart';
import 'utils/page_transitions.dart';
import 'widgets/notes_components.dart';
import 'widgets/responsive_layout.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  static const double _listDetailMinWidth = 800;

  final TextEditingController _searchController = TextEditingController();
  NotesLibrarySection _section = NotesLibrarySection.recent;
  String _query = '';
  String? _selectedNoteId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = ref.watch(activeOwnerIdProvider);
    final notes =
        ownerId == null ? null : ref.watch(noteControllerProvider(ownerId));

    return Scaffold(
      key: const ValueKey('notes-screen'),
      appBar: AppBar(
        title: const Text('Notas'),
        centerTitle: false,
      ),
      body: ownerId == null || notes == null
          ? const _NotesLoadingState()
          : notes.when(
              loading: () => ResponsiveLayoutBuilder(
                builder: (context, layout) => _NotesPageFrame(
                  layout: layout,
                  maxWidth: 720,
                  child: const _NotesLoadingState(),
                ),
              ),
              error: (error, stackTrace) => ResponsiveLayoutBuilder(
                builder: (context, layout) => _NotesPageFrame(
                  layout: layout,
                  maxWidth: 720,
                  child: _NotesErrorState(
                    message: 'No pudimos cargar tus notas. Intenta de nuevo.',
                    onRetry: () => ref
                        .read(noteControllerProvider(ownerId).notifier)
                        .reload(),
                  ),
                ),
              ),
              data: (noteState) {
                final controller =
                    ref.read(noteControllerProvider(ownerId).notifier);
                return ResponsiveLayoutBuilder(
                  builder: (context, layout) {
                    final usesListDetail = MediaQuery.sizeOf(context).width >=
                            _listDetailMinWidth &&
                        !layout.isShort &&
                        MediaQuery.textScalerOf(context).scale(16) <= 23;
                    final visibleNotes = _visibleNotes(noteState);
                    final selected = _selectedNote(visibleNotes);

                    if (noteState.isLoading && noteState.notes.isEmpty) {
                      return _NotesPageFrame(
                        layout: layout,
                        maxWidth: usesListDetail ? 1240 : 720,
                        child: const _NotesLoadingState(),
                      );
                    }

                    if (noteState.errorMessage != null &&
                        noteState.notes.isEmpty) {
                      return _NotesPageFrame(
                        layout: layout,
                        maxWidth: 720,
                        child: _NotesErrorState(
                          message: noteState.errorMessage!,
                          onRetry: controller.reload,
                        ),
                      );
                    }

                    final header = _NotesHeader(
                      isCompact: layout.isCompact,
                      onCreate: _createNote,
                    );
                    final controls = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NotesSearchField(
                          controller: _searchController,
                          onChanged: (value) => _search(controller, value),
                          onClear: () => _clearSearch(controller),
                        ),
                        SizedBox(height: context.spacing.sm),
                        NotesSectionSelector(
                          selected: _section,
                          onSelected: (value) {
                            setState(() {
                              _section = value;
                              _selectedNoteId = null;
                            });
                          },
                        ),
                      ],
                    );

                    if (!usesListDetail) {
                      return _NotesPageFrame(
                        layout: layout,
                        maxWidth: 720,
                        child: ListView(
                          key: const ValueKey('notes-compact-layout'),
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            header,
                            SizedBox(height: context.spacing.md),
                            if (layout.isCompact) ...[
                              NotesCaptureCard(onCreate: _createNote),
                              SizedBox(height: context.spacing.md),
                            ],
                            controls,
                            SizedBox(height: context.spacing.lg),
                            if (visibleNotes.isEmpty)
                              NotesEmptyState(
                                section: _section,
                                query: _query,
                                onCreate: _createNote,
                                onClear: () => _clearSearch(controller),
                              )
                            else
                              for (final note in visibleNotes)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: context.spacing.sm,
                                  ),
                                  child: _buildNoteCard(
                                    noteState,
                                    controller,
                                    note,
                                    selected: false,
                                    opensEditor: true,
                                  ),
                                ),
                          ],
                        ),
                      );
                    }

                    return _NotesPageFrame(
                      layout: layout,
                      maxWidth: 1240,
                      child: Column(
                        key: const ValueKey('notes-expanded-layout'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          SizedBox(height: context.spacing.lg),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DecoratedBox(
                                    decoration: _panelDecoration(context),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(context.spacing.md),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          controls,
                                          SizedBox(height: context.spacing.md),
                                          Expanded(
                                            child: visibleNotes.isEmpty
                                                ? NotesEmptyState(
                                                    section: _section,
                                                    query: _query,
                                                    onCreate: _createNote,
                                                    onClear: () => _clearSearch(
                                                      controller,
                                                    ),
                                                  )
                                                : ListView.separated(
                                                    key: const ValueKey(
                                                      'notes-library-panel',
                                                    ),
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    itemCount:
                                                        visibleNotes.length,
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            SizedBox(
                                                      height:
                                                          context.spacing.sm,
                                                    ),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final note =
                                                          visibleNotes[index];
                                                      return _buildNoteCard(
                                                        noteState,
                                                        controller,
                                                        note,
                                                        selected:
                                                            selected?.id ==
                                                                note.id,
                                                        opensEditor: false,
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.spacing.lg),
                                Expanded(
                                  flex: 6,
                                  child: selected == null
                                      ? _NoNoteSelected(onCreate: _createNote)
                                      : _buildDetail(
                                          noteState,
                                          controller,
                                          selected,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  List<Note> _visibleNotes(NoteState state) {
    final source = state.filteredNotes;
    final normalized = _normalize(_query.trim());
    final filtered = source.where((note) {
      if (!_belongsToSection(state, note)) return false;
      if (normalized.isEmpty) return true;
      return _normalize(note.title).contains(normalized) ||
          _normalize(note.body).contains(normalized) ||
          note.tags.any((tag) => _normalize(tag).contains(normalized));
    }).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  bool _belongsToSection(NoteState state, Note note) {
    switch (_section) {
      case NotesLibrarySection.review:
        if (note.isArchived) return false;
        final reminder = state.getReminder(note.id);
        return reminder != null &&
            reminder.status == NoteReminderStatus.scheduled &&
            !reminder.scheduledAtUtc.toLocal().isAfter(DateTime.now());
      case NotesLibrarySection.pinned:
        return note.isPinned && !note.isArchived;
      case NotesLibrarySection.recent:
        return !note.isArchived;
      case NotesLibrarySection.archived:
        return note.isArchived;
    }
  }

  Note? _selectedNote(List<Note> visible) {
    if (visible.isEmpty) return null;
    final selectedId = _selectedNoteId;
    if (selectedId != null) {
      for (final note in visible) {
        if (note.id == selectedId) return note;
      }
    }
    return visible.first;
  }

  Widget _buildNoteCard(
    NoteState state,
    NoteController controller,
    Note note, {
    required bool selected,
    required bool opensEditor,
  }) {
    final reminder = state.getReminder(note.id);
    return NoteLibraryCard(
      key: ValueKey('note-card-${note.id}'),
      title: note.title,
      body: note.body,
      tag: note.tags.isEmpty ? note.category : note.tags.first,
      updatedLabel: _updatedLabel(note.updatedAt),
      reminderLabel: _reminderLabel(reminder),
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isSelected: selected,
      accent: _accentFor(note),
      onTap: () {
        controller.selectNote(note.id);
        if (opensEditor) {
          _openEditor(note.id);
        } else {
          setState(() => _selectedNoteId = note.id);
        }
      },
      onTogglePin: note.isArchived ? null : () => controller.togglePin(note.id),
      onToggleArchive: () {
        if (note.isArchived) {
          controller.restore(note.id);
        } else {
          controller.archive(note.id);
        }
      },
    );
  }

  Widget _buildDetail(
    NoteState state,
    NoteController controller,
    Note note,
  ) {
    final reminder = state.getReminder(note.id);
    return NoteDetailSurface(
      key: ValueKey('note-detail-${note.id}'),
      title: note.title,
      body: note.body,
      tag: note.tags.isEmpty ? note.category : note.tags.first,
      updatedLabel: _updatedLabel(note.updatedAt),
      reminderLabel: _reminderLabel(reminder),
      accent: _accentFor(note),
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      onEdit: () => _openEditor(note.id),
      onReminder: () => _openReminder(note.id),
      onFocus: () => _startFocus(controller, note),
      onReview: () async {
        await controller.markReviewed(note.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota marcada como repasada')),
        );
      },
      onTogglePin: note.isArchived ? null : () => controller.togglePin(note.id),
      onToggleArchive: () {
        if (note.isArchived) {
          controller.restore(note.id);
        } else {
          controller.archive(note.id);
        }
      },
      onDelete: () => _confirmDelete(controller, note),
    );
  }

  void _search(NoteController controller, String value) {
    controller.search(value);
    setState(() {
      _query = value;
      _selectedNoteId = null;
    });
  }

  void _clearSearch(NoteController controller) {
    _searchController.clear();
    controller.search('');
    setState(() {
      _query = '';
      _selectedNoteId = null;
    });
  }

  Future<void> _createNote() async {
    final noteId = await Navigator.of(context).push<String>(
      PageTransitions.slideFromRight(const NoteSurface()),
    );
    if (noteId == null || !mounted) return;
    setState(() {
      _section = NotesLibrarySection.recent;
      _selectedNoteId = noteId;
    });
  }

  Future<void> _openEditor(String noteId) async {
    final savedNoteId = await Navigator.of(context).push<String>(
      PageTransitions.slideFromRight(NoteSurface(noteId: noteId)),
    );
    if (!mounted || savedNoteId == null) return;
    setState(() => _selectedNoteId = savedNoteId);
  }

  Future<void> _openReminder(String noteId) async {
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        NoteReminderScreen(noteId: noteId),
      ),
    );
  }

  Future<void> _startFocus(NoteController controller, Note note) async {
    controller.selectNote(note.id);
    await Navigator.of(context).push(
      PageTransitions.slideFromRight(
        PomodoroScreen(
          initialTitle: note.title,
          linkedNoteId: note.id,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    NoteController controller,
    Note note,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar nota',
      message:
          '¿Eliminar "${note.title.isEmpty ? 'Nota sin título' : note.title}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      icon: Icons.delete_forever_outlined,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    await controller.delete(note.id);
    if (mounted) setState(() => _selectedNoteId = null);
  }

  Color _accentFor(Note note) {
    final palette = context.zentraPalette;
    return switch (note.accentKey) {
      'peach' => palette.warmPeach,
      'water' => palette.water,
      'movement' => palette.movement,
      'sleep' => palette.sleep,
      'focus' => palette.focus,
      _ => palette.brandTeal,
    };
  }

  String _updatedLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final valueDay = DateTime(local.year, local.month, local.day);
    if (valueDay == today) {
      return 'Editada hoy · ${TimeOfDay.fromDateTime(local).format(context)}';
    }
    if (valueDay == today.subtract(const Duration(days: 1))) {
      return 'Editada ayer';
    }
    return 'Editada ${MaterialLocalizations.of(context).formatMediumDate(local)}';
  }

  String? _reminderLabel(NoteReminder? reminder) {
    if (reminder == null || reminder.status != NoteReminderStatus.scheduled) {
      return null;
    }
    final date = reminder.scheduledAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(date.year, date.month, date.day);
    final prefix = reminderDay == today
        ? 'Hoy'
        : reminderDay == today.add(const Duration(days: 1))
            ? 'Mañana'
            : MaterialLocalizations.of(context).formatShortDate(date);
    return '$prefix · ${TimeOfDay.fromDateTime(date).format(context)}';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u');
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(context.radii.extraLarge),
      border: Border.all(color: colorScheme.outlineVariant),
    );
  }
}

class _NotesPageFrame extends StatelessWidget {
  final ResponsiveLayoutData layout;
  final double maxWidth;
  final Widget child;

  const _NotesPageFrame({
    required this.layout,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPagePadding,
        layout.verticalPagePadding,
        layout.horizontalPagePadding,
        context.spacing.lg,
      ),
      child: ResponsiveContentFrame(
        maxWidth: maxWidth,
        child: child,
      ),
    );
  }
}

class _NotesHeader extends StatelessWidget {
  final bool isCompact;
  final VoidCallback onCreate;

  const _NotesHeader({
    required this.isCompact,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ideas que vuelven cuando sirven',
          style: isCompact
              ? theme.textTheme.titleLarge
              : theme.textTheme.headlineSmall,
        ),
        SizedBox(height: context.spacing.xs),
        Text(
          'Captura, recuerda y convierte una nota en un siguiente paso claro.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (isCompact) return copy;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: copy),
        SizedBox(width: context.spacing.md),
        FilledButton.icon(
          key: const ValueKey('notes-add'),
          onPressed: onCreate,
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Nueva nota'),
        ),
      ],
    );
  }
}

class _NotesLoadingState extends StatelessWidget {
  const _NotesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Cargando notas',
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var index = 0; index < 4; index++) ...[
              Container(
                height: index == 0 ? 88 : 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(context.radii.large),
                ),
              ),
              if (index < 3) SizedBox(height: context.spacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotesErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: 48,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'No pudimos cargar tus notas',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoNoteSelected extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoNoteSelected({required this.onCreate});

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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 56,
                  color: context.zentraPalette.brandTeal,
                ),
                SizedBox(height: context.spacing.md),
                Text(
                  'Elige una nota para leerla',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.spacing.xs),
                Text(
                  'También puedes empezar una nueva idea sin organizarla todavía.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.spacing.lg),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva nota'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
