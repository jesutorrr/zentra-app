import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/note_models.dart';

void main() {
  final createdAt = DateTime.parse('2026-07-26T09:00:00-06:00');
  final updatedAt = DateTime.parse('2026-07-26T10:30:00-06:00');

  Note buildNote() => Note(
        id: 'note-algebra',
        userId: 'uri',
        title: 'Álgebra lineal',
        body: 'Repasar transformaciones lineales.',
        createdAt: createdAt,
        updatedAt: updatedAt,
        category: 'Estudio',
        accentKey: 'teal',
        isPinned: true,
        isArchived: true,
        archivedAt: updatedAt,
        formatVersion: 1,
        tags: const [' Examen ', 'estudio', 'EXAMEN', '  guía   final '],
      );

  test('note normalizes dates and tags without losing display data', () {
    final note = buildNote();

    expect(note.createdAt.isUtc, isTrue);
    expect(note.updatedAt.isUtc, isTrue);
    expect(note.archivedAt?.isUtc, isTrue);
    expect(note.title, 'Álgebra lineal');
    expect(note.category, 'Estudio');
    expect(note.tags, ['estudio', 'examen', 'guía final']);
    expect(
      () => note.tags.add('mutable'),
      throwsUnsupportedError,
    );
  });

  test('copyWith can clear nullable note fields explicitly', () {
    final note = buildNote();
    final restored = note.copyWith(
      category: null,
      isArchived: false,
      archivedAt: null,
    );

    expect(restored.category, isNull);
    expect(restored.isArchived, isFalse);
    expect(restored.archivedAt, isNull);
    expect(restored.id, note.id);
    expect(restored.createdAt, note.createdAt);
  });

  test('all note records survive a JSON backup round trip', () {
    final note = buildNote();
    final reminder = NoteReminder(
      id: 'reminder-algebra',
      noteId: note.id,
      userId: note.userId,
      scheduledAtUtc: DateTime.parse('2026-07-27T01:00:00Z'),
      timezoneName: 'America/Mexico_City',
      status: NoteReminderStatus.scheduled,
      notificationId: 41001,
      privacyMode: NotePrivacyMode.titleOnly,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    final review = NoteReview(
      id: 'review-algebra',
      noteId: note.id,
      userId: note.userId,
      reviewedAt: DateTime.parse('2026-07-27T02:00:00Z'),
      focusSessionId: 'focus-25',
      outcome: NoteReviewOutcome.focusCompleted,
    );
    final snapshot = NoteOwnerSnapshot(
      ownerId: note.userId,
      exportedAt: DateTime.parse('2026-07-27T03:00:00Z'),
      notes: [note],
      reminders: [reminder],
      reviews: [review],
    );

    final encoded = jsonEncode(snapshot.toJson());
    final restored = NoteOwnerSnapshot.fromJson(
      (jsonDecode(encoded) as Map).cast<String, Object?>(),
    );

    expect(restored.schemaVersion, 1);
    expect(restored.ownerId, note.userId);
    expect(restored.exportedAt, snapshot.exportedAt);
    expect(restored.notes, hasLength(1));
    expect(restored.notes.single.toJson(), note.toJson());
    expect(restored.reminders.single.toJson(), reminder.toJson());
    expect(restored.reviews.single.toJson(), review.toJson());
  });

  test('unknown stored enum values fall back to privacy-safe states', () {
    expect(
      NoteReminderStatus.fromStorage('future-status'),
      NoteReminderStatus.failed,
    );
    expect(
      NotePrivacyMode.fromStorage('future-mode'),
      NotePrivacyMode.hidden,
    );
    expect(
      NoteReviewOutcome.fromStorage('future-outcome'),
      NoteReviewOutcome.reviewed,
    );
  });
}
