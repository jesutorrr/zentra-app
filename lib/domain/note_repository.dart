import 'note_models.dart';

/// Owner-scoped access to active notes and their related records.
///
/// Implementations must reject writes for an entity that belongs to a user
/// different from [currentUserId].
abstract interface class NoteRepository {
  String? get currentUserId;

  void setCurrentUser(String? userId);

  Future<List<Note>> getNotes({bool includeArchived = false});

  Future<Note?> getNote(String noteId);

  Future<void> upsertNote(Note note);

  Future<void> deleteNote(String noteId);

  Future<List<Note>> searchNotes(
    String query, {
    bool includeArchived = false,
  });

  Future<NoteReminder?> getReminderForNote(String noteId);

  Future<List<NoteReminder>> getScheduledReminders({
    DateTime? throughUtc,
  });

  Future<void> upsertReminder(NoteReminder reminder);

  Future<void> deleteReminderForNote(String noteId);

  Future<List<NoteReview>> getReviewsForNote(String noteId);

  Future<void> addReview(NoteReview review);

  Future<NoteOwnerSnapshot> exportOwner();

  /// Imports the snapshot into [currentUserId].
  ///
  /// Entity IDs are preserved, while snapshot ownership is remapped to the
  /// active owner. With [replaceExisting], all existing note data for that
  /// owner is removed first inside the same transaction.
  Future<void> importOwner(
    NoteOwnerSnapshot snapshot, {
    bool replaceExisting = true,
  });

  Future<void> deleteOwner();
}
