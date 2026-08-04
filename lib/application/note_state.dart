import '../domain/note_models.dart';

const Object _noteStateUnset = Object();

/// Immutable application state for one owner's notes workspace.
class NoteState {
  final String ownerId;
  final List<Note> notes;
  final Map<String, NoteReminder> remindersByNoteId;
  final String searchQuery;
  final String? selectedNoteId;
  final bool isLoading;
  final String? errorMessage;

  NoteState({
    required this.ownerId,
    List<Note> notes = const [],
    Map<String, NoteReminder> remindersByNoteId = const {},
    this.searchQuery = '',
    this.selectedNoteId,
    this.isLoading = false,
    this.errorMessage,
  })  : notes = List.unmodifiable(notes),
        remindersByNoteId = Map.unmodifiable(remindersByNoteId);

  List<NoteReminder> get reminders =>
      List.unmodifiable(remindersByNoteId.values);

  /// Every tag the owner has written, deduplicated and alphabetically sorted.
  ///
  /// This is the vocabulary the tag editor suggests from and the library
  /// filters by, so it is normalized here too instead of trusting each note to
  /// have been built through the model's own normalization.
  List<String> get allTags => List.unmodifiable(
        normalizeNoteTags(notes.expand((note) => note.tags)),
      );

  Note? get selectedNote {
    final id = selectedNoteId;
    if (id == null) return null;
    return getNote(id);
  }

  List<Note> get filteredNotes {
    final query = foldNoteSearch(searchQuery.trim());
    if (query.isEmpty) return notes;
    return notes.where((note) {
      final haystack = foldNoteSearch(
        [
          note.title,
          note.body,
          if (note.category != null) note.category!,
          ...note.tags,
        ].join('\n'),
      );
      return haystack.contains(query);
    }).toList(growable: false);
  }

  List<Note> dueForReviewAt(DateTime now) {
    final instant = now.toUtc();
    return notes.where((note) {
      if (note.isArchived) return false;
      final reminder = remindersByNoteId[note.id];
      return reminder != null &&
          reminder.status == NoteReminderStatus.scheduled &&
          !reminder.scheduledAtUtc.isAfter(instant);
    }).toList(growable: false);
  }

  Note? getNote(String noteId) {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  NoteReminder? getReminder(String noteId) => remindersByNoteId[noteId];

  NoteState copyWith({
    List<Note>? notes,
    Map<String, NoteReminder>? remindersByNoteId,
    String? searchQuery,
    Object? selectedNoteId = _noteStateUnset,
    bool? isLoading,
    Object? errorMessage = _noteStateUnset,
  }) {
    return NoteState(
      ownerId: ownerId,
      notes: notes ?? this.notes,
      remindersByNoteId: remindersByNoteId ?? this.remindersByNoteId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedNoteId: identical(selectedNoteId, _noteStateUnset)
          ? this.selectedNoteId
          : selectedNoteId as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _noteStateUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

String foldNoteSearch(String value) {
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  var result = value.toLowerCase();
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}
