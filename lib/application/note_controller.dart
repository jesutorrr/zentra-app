import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/note_models.dart';
import '../domain/note_repository.dart';
import '../infrastructure/notification_service.dart';
import 'note_state.dart';

typedef NoteRepositoryFactory = NoteRepository Function(String ownerId);

final noteRepositoryFactoryProvider = Provider<NoteRepositoryFactory>((ref) {
  throw UnimplementedError(
    'noteRepositoryFactoryProvider must be overridden at the app root.',
  );
});

final noteNotificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final noteUuidProvider = Provider<Uuid>((ref) => const Uuid());

final noteClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final noteControllerProvider = AsyncNotifierProvider.autoDispose
    .family<NoteController, NoteState, String>(NoteController.new);

class NoteController extends AutoDisposeFamilyAsyncNotifier<NoteState, String> {
  late NoteRepository _repository;
  late NotificationService _notificationService;
  late Uuid _uuid;
  late DateTime Function() _clock;
  bool _isDisposed = false;

  @override
  Future<NoteState> build(String ownerId) async {
    _isDisposed = false;
    _repository = ref.watch(noteRepositoryFactoryProvider)(ownerId);
    _notificationService = ref.watch(noteNotificationServiceProvider);
    _uuid = ref.watch(noteUuidProvider);
    _clock = ref.watch(noteClockProvider);
    ref.onDispose(() => _isDisposed = true);
    try {
      return await _load(ownerId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error loading notes: $error');
      }
      return NoteState(
        ownerId: ownerId,
        errorMessage: 'No pudimos cargar tus notas. Intenta de nuevo.',
      );
    }
  }

  Future<void> reload() async {
    final previous = state.valueOrNull;
    final ownerId = previous?.ownerId ?? arg;
    state = const AsyncLoading();
    try {
      final next = await _load(ownerId);
      if (!_isDisposed) state = AsyncData(next);
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Refreshes durable state after a remote pull without flashing loading UI.
  Future<void> refreshAfterSync() async {
    final previous = state.valueOrNull;
    try {
      var next = await _load(previous?.ownerId ?? arg);
      if (_isDisposed) return;
      if (previous != null) {
        final selectedNoteId = previous.selectedNoteId;
        next = next.copyWith(
          searchQuery: previous.searchQuery,
          selectedNoteId:
              selectedNoteId != null && next.getNote(selectedNoteId) != null
                  ? selectedNoteId
                  : null,
        );
      }
      state = AsyncData(next);
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void search(String query) {
    _update((current) => current.copyWith(searchQuery: query));
  }

  void selectNote(String? noteId) {
    _update((current) => current.copyWith(selectedNoteId: noteId));
  }

  Future<Note> createNote({
    required String title,
    required String body,
    List<String> tags = const [],
    String? category,
    String accentKey = 'mint',
  }) async {
    final current = _requireState();
    final now = _clock().toUtc();
    final note = Note(
      id: _uuid.v4(),
      userId: current.ownerId,
      title: title.trim(),
      body: body,
      createdAt: now,
      updatedAt: now,
      category: category?.trim().isEmpty == true ? null : category?.trim(),
      accentKey: accentKey,
      tags: tags,
    );
    await saveNote(note);
    selectNote(note.id);
    return note;
  }

  Future<void> saveNote(Note note) async {
    final current = _requireState();
    _assertOwner(note.userId, current.ownerId);
    _update((value) => value.copyWith(errorMessage: null));
    try {
      final saved = note.copyWith(updatedAt: _clock().toUtc());
      await _repository.upsertNote(saved);
      if (_isDisposed) return;
      _update(
        (value) => value.copyWith(
          notes: _replaceNote(value.notes, saved),
          errorMessage: null,
        ),
      );
    } catch (error) {
      if (!_isDisposed) {
        _update(
          (value) => value.copyWith(
            errorMessage: 'No pudimos guardar la nota.',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> togglePin(String noteId) async {
    final note = _requireNote(noteId);
    await saveNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> archive(String noteId) async {
    final note = _requireNote(noteId);
    await cancelReminder(noteId);
    await saveNote(
      note.copyWith(
        isArchived: true,
        isPinned: false,
        archivedAt: _clock().toUtc(),
      ),
    );
  }

  Future<void> restore(String noteId) async {
    final note = _requireNote(noteId);
    await saveNote(
      note.copyWith(
        isArchived: false,
        archivedAt: null,
      ),
    );
  }

  Future<void> delete(String noteId) async {
    await _notificationService.cancelNoteReminder(noteId);
    await _repository.deleteNote(noteId);
    if (_isDisposed) return;
    _update((current) {
      final reminders = Map<String, NoteReminder>.from(
        current.remindersByNoteId,
      )..remove(noteId);
      return current.copyWith(
        notes: current.notes
            .where((note) => note.id != noteId)
            .toList(growable: false),
        remindersByNoteId: reminders,
        selectedNoteId:
            current.selectedNoteId == noteId ? null : current.selectedNoteId,
      );
    });
  }

  Future<bool> scheduleReminder({
    required String noteId,
    required DateTime scheduledAt,
    NotePrivacyMode privacyMode = NotePrivacyMode.hidden,
  }) async {
    final note = _requireNote(noteId);
    final permission =
        await _notificationService.isSystemNotificationPermissionGranted() ||
            await _notificationService.requestNotificationPermission();
    if (!permission) {
      _update(
        (current) => current.copyWith(
          errorMessage:
              'Activa las notificaciones para recibir este recordatorio.',
        ),
      );
      return false;
    }

    await _notificationService.refreshTimezone();
    final notificationId = await _notificationService.scheduleNoteReminder(
      noteId: noteId,
      noteTitle: note.title,
      noteBody: note.body,
      scheduledAtUtc: scheduledAt.toUtc(),
      privacyMode: privacyMode,
    );
    if (notificationId == null) {
      _update(
        (current) => current.copyWith(
          errorMessage:
              'No pudimos programar ese momento. Revisa la fecha y tus permisos.',
        ),
      );
      return false;
    }

    final current = _requireState();
    final now = _clock().toUtc();
    final existing = current.remindersByNoteId[noteId];
    final reminder = NoteReminder(
      id: existing?.id ?? _uuid.v4(),
      noteId: noteId,
      userId: current.ownerId,
      scheduledAtUtc: scheduledAt.toUtc(),
      timezoneName: _notificationService.timezoneIdentifier,
      status: NoteReminderStatus.scheduled,
      notificationId: notificationId,
      privacyMode: privacyMode,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsertReminder(reminder);
    if (_isDisposed) return true;
    _update((value) {
      final reminders = Map<String, NoteReminder>.from(
        value.remindersByNoteId,
      )..[noteId] = reminder;
      return value.copyWith(
        remindersByNoteId: reminders,
        errorMessage: null,
      );
    });
    return true;
  }

  Future<void> cancelReminder(String noteId) async {
    await _notificationService.cancelNoteReminder(noteId);
    await _repository.deleteReminderForNote(noteId);
    if (_isDisposed) return;
    _update((current) {
      final reminders = Map<String, NoteReminder>.from(
        current.remindersByNoteId,
      )..remove(noteId);
      return current.copyWith(remindersByNoteId: reminders);
    });
  }

  Future<void> rescheduleReminders() async {
    final current = _requireState();
    final now = _clock().toUtc();
    final active = current.remindersByNoteId.values.where(
      (reminder) =>
          reminder.status == NoteReminderStatus.scheduled &&
          reminder.scheduledAtUtc.isAfter(now),
    );
    for (final reminder in active) {
      if (_isDisposed) return;
      final note = current.getNote(reminder.noteId);
      if (note == null || note.isArchived) {
        await cancelReminder(reminder.noteId);
        continue;
      }
      await _notificationService.scheduleNoteReminder(
        noteId: note.id,
        noteTitle: note.title,
        noteBody: note.body,
        scheduledAtUtc: reminder.scheduledAtUtc,
        privacyMode: reminder.privacyMode,
      );
    }
  }

  Future<void> markReviewed(
    String noteId, {
    DateTime? reviewedAt,
    NoteReviewOutcome outcome = NoteReviewOutcome.reviewed,
    String? focusSessionId,
  }) async {
    final current = _requireState();
    _requireNote(noteId);
    await _repository.addReview(
      NoteReview(
        id: _uuid.v4(),
        noteId: noteId,
        userId: current.ownerId,
        reviewedAt: reviewedAt ?? _clock().toUtc(),
        focusSessionId: focusSessionId,
        outcome: outcome,
      ),
    );
    final latest = state.valueOrNull;
    final reminder = latest?.remindersByNoteId[noteId];
    if (reminder != null &&
        !reminder.scheduledAtUtc.isAfter(_clock().toUtc())) {
      await cancelReminder(noteId);
    }
  }

  Future<void> markFocusCompleted(
    String noteId,
    DateTime reviewedAt, {
    String? focusSessionId,
  }) {
    return markReviewed(
      noteId,
      reviewedAt: reviewedAt,
      focusSessionId: focusSessionId,
      outcome: NoteReviewOutcome.focusCompleted,
    );
  }

  Future<NoteState> _load(String ownerId) async {
    final loaded = await _repository.getNotes(includeArchived: true);
    final reminderEntries = await Future.wait(
      loaded.map((note) => _repository.getReminderForNote(note.id)),
    );
    return NoteState(
      ownerId: ownerId,
      notes: loaded,
      remindersByNoteId: {
        for (final reminder in reminderEntries)
          if (reminder != null) reminder.noteId: reminder,
      },
    );
  }

  NoteState _requireState() {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('El espacio de notas todavía no está listo.');
    }
    return current;
  }

  Note _requireNote(String noteId) {
    final note = _requireState().getNote(noteId);
    if (note == null) throw StateError('La nota ya no existe.');
    return note;
  }

  void _assertOwner(String entityOwnerId, String activeOwnerId) {
    if (entityOwnerId != activeOwnerId) {
      throw StateError('La nota no pertenece al espacio activo.');
    }
  }

  void _update(NoteState Function(NoteState current) update) {
    if (_isDisposed) return;
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(update(current));
  }
}

List<Note> _replaceNote(List<Note> notes, Note value) {
  final next = [...notes];
  final index = next.indexWhere((entry) => entry.id == value.id);
  if (index == -1) {
    next.add(value);
  } else {
    next[index] = value;
  }
  next.sort((left, right) {
    if (left.isPinned != right.isPinned) return left.isPinned ? -1 : 1;
    return right.updatedAt.compareTo(left.updatedAt);
  });
  return next;
}
