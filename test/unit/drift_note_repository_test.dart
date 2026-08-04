import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/sync/sync.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/drift_sync_workspace.dart';
import 'package:zentra/infrastructure/notification_schedule_planner.dart';

void main() {
  late ZentraDatabase database;
  late DriftNoteRepository repository;

  setUp(() {
    database = ZentraDatabase(NativeDatabase.memory());
    repository = DriftNoteRepository(database)..setCurrentUser('uri');
  });

  tearDown(() async {
    await database.close();
  });

  Note note({
    required String id,
    String owner = 'uri',
    String? title,
    String body = 'Contenido',
    String? category = 'Estudio',
    bool pinned = false,
    bool archived = false,
    DateTime? updatedAt,
    List<String> tags = const [],
  }) {
    final update = updatedAt ?? DateTime.parse('2026-07-26T12:00:00Z');
    return Note(
      id: id,
      userId: owner,
      title: title ?? id,
      body: body,
      createdAt: DateTime.parse('2026-07-25T12:00:00Z'),
      updatedAt: update,
      category: category,
      accentKey: 'teal',
      isPinned: pinned,
      isArchived: archived,
      archivedAt: archived ? update : null,
      tags: tags,
    );
  }

  NoteReminder reminder({
    required String id,
    required String noteId,
    String owner = 'uri',
    NoteReminderStatus status = NoteReminderStatus.scheduled,
    DateTime? scheduledAt,
  }) {
    final now = DateTime.parse('2026-07-26T12:00:00Z');
    return NoteReminder(
      id: id,
      noteId: noteId,
      userId: owner,
      scheduledAtUtc: scheduledAt ?? DateTime.parse('2026-07-27T01:00:00Z'),
      timezoneName: 'America/Mexico_City',
      status: status,
      notificationId: id.hashCode & 0x7fffffff,
      privacyMode: NotePrivacyMode.titleOnly,
      createdAt: now,
      updatedAt: now,
    );
  }

  NoteReview review({
    required String id,
    required String noteId,
    String owner = 'uri',
    DateTime? reviewedAt,
    NoteReviewOutcome outcome = NoteReviewOutcome.reviewed,
  }) {
    return NoteReview(
      id: id,
      noteId: noteId,
      userId: owner,
      reviewedAt: reviewedAt ?? DateTime.parse('2026-07-27T02:00:00Z'),
      focusSessionId: outcome == NoteReviewOutcome.reviewed ? null : 'focus-25',
      outcome: outcome,
    );
  }

  test('requires an active owner before reading or writing', () async {
    repository.setCurrentUser(null);

    await expectLater(
      repository.getNotes(),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.upsertNote(note(id: 'blocked')),
      throwsA(isA<StateError>()),
    );
  });

  test('forOwner locks identity and isolates notes', () async {
    final ownerA = DriftNoteRepository.forOwner(
      database,
      ownerId: 'owner-a',
    );
    final ownerB = DriftNoteRepository.forOwner(
      database,
      ownerId: 'owner-b',
    );

    expect(ownerA.currentUserId, 'owner-a');
    expect(() => ownerA.setCurrentUser('owner-a'), returnsNormally);
    expect(
      () => ownerA.setCurrentUser('owner-b'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => ownerA.setCurrentUser(null),
      throwsA(isA<StateError>()),
    );
    expect(ownerA.currentUserId, 'owner-a');

    await ownerA.upsertNote(note(id: 'note-a', owner: 'owner-a'));
    await ownerB.upsertNote(note(id: 'note-b', owner: 'owner-b'));

    expect((await ownerA.getNotes()).map((entry) => entry.id), ['note-a']);
    expect((await ownerB.getNotes()).map((entry) => entry.id), ['note-b']);
  });

  test('forOwner rejects a blank identity', () {
    expect(
      () => DriftNoteRepository.forOwner(
        database,
        ownerId: '  ',
      ),
      throwsArgumentError,
    );
  });

  test('CRUD preserves tags and orders pinned notes before recent notes',
      () async {
    final older = note(
      id: 'older',
      title: 'Lectura anterior',
      updatedAt: DateTime.parse('2026-07-25T12:00:00Z'),
    );
    final recent = note(
      id: 'recent',
      title: 'Apuntes recientes',
      updatedAt: DateTime.parse('2026-07-27T12:00:00Z'),
      tags: const [' Examen ', 'ESTUDIO', 'examen'],
    );
    final pinned = note(
      id: 'pinned',
      title: 'Guía fijada',
      pinned: true,
      updatedAt: DateTime.parse('2026-07-24T12:00:00Z'),
    );

    await repository.upsertNote(older);
    await repository.upsertNote(recent);
    await repository.upsertNote(pinned);

    final notes = await repository.getNotes();
    expect(notes.map((entry) => entry.id), ['pinned', 'recent', 'older']);
    expect((await repository.getNote('recent'))?.tags, ['estudio', 'examen']);

    await repository.upsertNote(
      recent.copyWith(
        title: 'Apuntes corregidos',
        body: 'Contenido actualizado',
        isPinned: true,
        tags: const ['final'],
      ),
    );
    final updated = await repository.getNote('recent');
    expect(updated?.title, 'Apuntes corregidos');
    expect(updated?.body, 'Contenido actualizado');
    expect(updated?.isPinned, isTrue);
    expect(updated?.tags, ['final']);

    await repository.deleteNote('recent');
    expect(await repository.getNote('recent'), isNull);
  });

  test('archive and restore control default visibility', () async {
    final active = note(id: 'active');
    await repository.upsertNote(active);

    await repository.upsertNote(
      active.copyWith(
        isArchived: true,
        archivedAt: DateTime.parse('2026-07-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-07-27T12:00:00Z'),
      ),
    );
    expect(await repository.getNotes(), isEmpty);
    expect(
      (await repository.getNotes(includeArchived: true)).single.isArchived,
      isTrue,
    );

    await repository.upsertNote(
      active.copyWith(
        isArchived: false,
        archivedAt: null,
        updatedAt: DateTime.parse('2026-07-28T12:00:00Z'),
      ),
    );
    final restored = (await repository.getNotes()).single;
    expect(restored.isArchived, isFalse);
    expect(restored.archivedAt, isNull);
  });

  test('owners cannot read, mutate, or reuse another owner entity ID',
      () async {
    await repository.upsertNote(note(id: 'uri-note'));

    repository.setCurrentUser('other');
    expect(await repository.getNotes(includeArchived: true), isEmpty);
    expect(await repository.getNote('uri-note'), isNull);
    await expectLater(
      repository.upsertNote(note(id: 'wrong-owner')),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.upsertNote(
        note(id: 'uri-note', owner: 'other'),
      ),
      throwsA(isA<StateError>()),
    );

    await repository.upsertNote(
      note(id: 'other-note', owner: 'other'),
    );
    expect(
      (await repository.getNotes()).map((entry) => entry.id),
      ['other-note'],
    );

    repository.setCurrentUser('uri');
    expect(
      (await repository.getNotes()).map((entry) => entry.id),
      ['uri-note'],
    );
  });

  test('search is accent-insensitive across title, body, category and tags',
      () async {
    await repository.upsertNote(
      note(
        id: 'algebra',
        title: 'Álgebra lineal',
        body: 'Transformaciones y matrices',
        category: 'Educación',
        tags: const ['guía final'],
      ),
    );
    await repository.upsertNote(
      note(
        id: 'archived',
        title: 'Álgebra antigua',
        archived: true,
      ),
    );
    await repository.upsertNote(
      note(
        id: 'personal',
        title: 'Lista personal',
        body: 'Comprar agua',
        category: 'Casa',
      ),
    );

    expect(
      (await repository.searchNotes('algebra')).map((entry) => entry.id),
      ['algebra'],
    );
    expect(
      (await repository.searchNotes('educacion')).map((entry) => entry.id),
      ['algebra'],
    );
    expect(
      (await repository.searchNotes('GUIA FINAL')).map((entry) => entry.id),
      ['algebra'],
    );
    expect(
      (await repository.searchNotes(
        'algebra',
        includeArchived: true,
      ))
          .map((entry) => entry.id),
      unorderedEquals(['algebra', 'archived']),
    );
    expect(await repository.searchNotes('no existe'), isEmpty);
  });

  test('a note keeps exactly one reminder and scheduled queries are scoped',
      () async {
    await repository.upsertNote(note(id: 'algebra'));
    await repository.upsertNote(note(id: 'biology'));
    final first = reminder(
      id: 'first',
      noteId: 'algebra',
      scheduledAt: DateTime.parse('2026-07-27T03:00:00Z'),
    );
    final replacement = reminder(
      id: 'replacement',
      noteId: 'algebra',
      scheduledAt: DateTime.parse('2026-07-27T01:00:00Z'),
    );
    final completed = reminder(
      id: 'completed',
      noteId: 'biology',
      status: NoteReminderStatus.completed,
      scheduledAt: DateTime.parse('2026-07-27T00:30:00Z'),
    );

    await repository.upsertReminder(first);
    await repository.upsertReminder(replacement);
    await repository.upsertReminder(completed);

    expect((await repository.getReminderForNote('algebra'))?.id, 'replacement');
    expect(
      (await repository.getScheduledReminders()).map((entry) => entry.id),
      ['replacement'],
    );
    expect(
      await repository.getScheduledReminders(
        throughUtc: DateTime.parse('2026-07-27T00:59:59Z'),
      ),
      isEmpty,
    );

    repository.setCurrentUser('other');
    await repository.upsertNote(
      note(id: 'other-note', owner: 'other'),
    );
    await repository.upsertReminder(
      reminder(
        id: 'other-reminder',
        noteId: 'other-note',
        owner: 'other',
      ),
    );
    expect(
      (await repository.getScheduledReminders()).map((entry) => entry.id),
      ['other-reminder'],
    );
  });

  test('reviews are owner-scoped and returned newest first', () async {
    await repository.upsertNote(note(id: 'algebra'));
    await repository.addReview(
      review(
        id: 'older',
        noteId: 'algebra',
        reviewedAt: DateTime.parse('2026-07-27T01:00:00Z'),
      ),
    );
    await repository.addReview(
      review(
        id: 'newer',
        noteId: 'algebra',
        reviewedAt: DateTime.parse('2026-07-27T03:00:00Z'),
        outcome: NoteReviewOutcome.focusCompleted,
      ),
    );

    final reviews = await repository.getReviewsForNote('algebra');
    expect(reviews.map((entry) => entry.id), ['newer', 'older']);
    expect(reviews.first.focusSessionId, 'focus-25');

    repository.setCurrentUser('other');
    expect(await repository.getReviewsForNote('algebra'), isEmpty);
    await expectLater(
      repository.addReview(
        review(id: 'foreign', noteId: 'algebra', owner: 'other'),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('focus review is idempotent by owner and focus session', () async {
    await repository.upsertNote(note(id: 'algebra'));
    await repository.addReview(
      review(
        id: 'first',
        noteId: 'algebra',
        outcome: NoteReviewOutcome.focusCompleted,
      ),
    );
    await repository.addReview(
      review(
        id: 'retry',
        noteId: 'algebra',
        outcome: NoteReviewOutcome.focusCompleted,
      ),
    );

    final reviews = await repository.getReviewsForNote('algebra');
    expect(reviews, hasLength(1));
    expect(reviews.single.id, 'first');
    expect(reviews.single.focusSessionId, 'focus-25');
  });

  test('deleting a note cascades its reminder, reviews and tags', () async {
    await repository.upsertNote(
      note(id: 'algebra', tags: const ['examen']),
    );
    await repository.upsertReminder(
      reminder(id: 'reminder', noteId: 'algebra'),
    );
    await repository.addReview(
      review(id: 'review', noteId: 'algebra'),
    );

    await repository.deleteNote('algebra');

    expect(await repository.getNote('algebra'), isNull);
    expect(await repository.getReminderForNote('algebra'), isNull);
    expect(await repository.getReviewsForNote('algebra'), isEmpty);
    expect((await repository.exportOwner()).notes, isEmpty);
  });

  test('export and import replace one owner atomically and remap ownership',
      () async {
    await repository.upsertNote(
      note(id: 'algebra', archived: true, tags: const ['examen']),
    );
    await repository.upsertReminder(
      reminder(id: 'reminder', noteId: 'algebra'),
    );
    await repository.addReview(
      review(id: 'review', noteId: 'algebra'),
    );
    final exported = await repository.exportOwner();
    final portable = NoteOwnerSnapshot.fromJson(exported.toJson());

    await database.close();
    database = ZentraDatabase(NativeDatabase.memory());
    final target = DriftNoteRepository(database)
      ..setCurrentUser('restored-owner');
    await target.upsertNote(
      note(id: 'old-target', owner: 'restored-owner'),
    );

    await target.importOwner(portable);

    expect(await target.getNote('old-target'), isNull);
    final restored = await target.getNote('algebra');
    expect(restored?.userId, 'restored-owner');
    expect(restored?.tags, ['examen']);
    expect(restored?.isArchived, isTrue);
    expect(
      (await target.getReminderForNote('algebra'))?.userId,
      'restored-owner',
    );
    expect(
      (await target.getReviewsForNote('algebra')).single.userId,
      'restored-owner',
    );
  });

  test('invalid import does not erase existing owner data', () async {
    await repository.upsertNote(note(id: 'existing'));
    final invalid = NoteOwnerSnapshot(
      ownerId: 'backup-owner',
      exportedAt: DateTime.parse('2026-07-27T03:00:00Z'),
      notes: const [],
      reminders: [
        reminder(
          id: 'orphan',
          noteId: 'missing-note',
          owner: 'backup-owner',
        ),
      ],
      reviews: const [],
    );

    await expectLater(
      repository.importOwner(invalid),
      throwsA(isA<StateError>()),
    );
    expect(await repository.getNote('existing'), isNotNull);
  });

  test('deleteOwner removes only the active owner records', () async {
    await repository.upsertNote(note(id: 'uri-note'));
    repository.setCurrentUser('other');
    await repository.upsertNote(
      note(id: 'other-note', owner: 'other'),
    );

    repository.setCurrentUser('uri');
    await repository.deleteOwner();
    expect(await repository.getNotes(includeArchived: true), isEmpty);

    repository.setCurrentUser('other');
    expect(
      (await repository.getNotes()).map((entry) => entry.id),
      ['other-note'],
    );
  });

  test('cloud note writes enqueue ordered mutations and keep tombstones',
      () async {
    var syncNotifications = 0;
    final synced = DriftNoteRepository.forOwner(
      database,
      ownerId: 'uri',
      syncDeviceId: 'iphone-uri',
      clock: () => DateTime.utc(2026, 7, 27, 12),
      onSyncNeeded: () => syncNotifications++,
    );
    final value = note(id: 'cloud-note', tags: const ['gate-7']);

    await synced.upsertNote(value);
    await synced.upsertNote(
      value.copyWith(
        isArchived: true,
        archivedAt: DateTime.utc(2026, 7, 27, 13),
      ),
    );
    await synced.upsertReminder(
      reminder(id: 'cloud-reminder', noteId: value.id),
    );
    await synced.addReview(
      review(id: 'cloud-review', noteId: value.id),
    );
    await synced.deleteReminderForNote(value.id);
    await synced.deleteNote(value.id);

    final snapshot = await DriftSyncWorkspace(
      database: database,
      ownerId: 'uri',
    ).loadSnapshot();
    expect(
      snapshot.outbox.map((mutation) => mutation.operation),
      [
        SyncMutationOperation.noteUpsert,
        SyncMutationOperation.noteUpsert,
        SyncMutationOperation.noteArchive,
        SyncMutationOperation.noteReminderSet,
        SyncMutationOperation.noteReviewAdd,
        SyncMutationOperation.noteReminderSet,
        SyncMutationOperation.noteDelete,
      ],
    );
    expect(
      snapshot.outbox
          .map((mutation) => mutation.createdAt)
          .toList(growable: false),
      orderedEquals(
        List<DateTime>.generate(
          7,
          (index) => DateTime.utc(2026, 7, 27, 12).add(
            Duration(seconds: index),
          ),
        ),
      ),
    );
    expect(snapshot.outbox[5].payload['deleted'], isTrue);
    expect(syncNotifications, 6);
    expect(await synced.getNote(value.id), isNull);
    expect(
      snapshot.entities.entries
          .singleWhere((entry) => entry.key.id == value.id)
          .value
          .isDeleted,
      isTrue,
    );
  });

  test('note and outbox mutation roll back together on queue failure',
      () async {
    final synced = DriftNoteRepository.forOwner(
      database,
      ownerId: 'uri',
      syncDeviceId: 'iphone-uri',
    );
    await database.customStatement('''
      CREATE TRIGGER reject_note_outbox
      BEFORE INSERT ON sync_outbox
      WHEN NEW.entity_type = 'note'
      BEGIN
        SELECT RAISE(ABORT, 'forced outbox failure');
      END
    ''');

    await expectLater(
      synced.upsertNote(note(id: 'atomic-note')),
      throwsA(anything),
    );

    expect(await synced.getNote('atomic-note'), isNull);
    expect(
      await database.select(database.syncOutboxEntries).get(),
      isEmpty,
    );
  });

  test('workspace materializes remote notes reminders and reviews', () async {
    const noteKey = SyncEntityKey(
      type: SyncEntityType.note,
      id: 'remote-note',
    );
    const reminderKey = SyncEntityKey(
      type: SyncEntityType.noteReminder,
      id: 'remote-reminder',
    );
    const reviewKey = SyncEntityKey(
      type: SyncEntityType.noteReview,
      id: 'remote-review',
    );
    final workspace = DriftSyncWorkspace(
      database: database,
      ownerId: 'uri',
    );
    await workspace.commitSnapshot(
      SyncSnapshot(
        cursor: 3,
        entities: {
          noteKey: SyncLocalEntity(
            key: noteKey,
            version: 2,
            serverRevision: 1,
            record: const {
              'id': 'remote-note',
              'title': 'Desde iPad',
              'body': 'Ambos textos deben sobrevivir.',
              'category': 'Ideas',
              'accent_key': 'lavender',
              'is_pinned': true,
              'is_archived': false,
              'archived_at': null,
              'tags': ['nube'],
              'format_version': 1,
              'created_at': '2026-07-27T10:00:00.000Z',
              'updated_at': '2026-07-27T11:00:00.000Z',
              'deleted_at': null,
            },
          ),
          reminderKey: SyncLocalEntity(
            key: reminderKey,
            version: 1,
            serverRevision: 2,
            record: const {
              'id': 'remote-reminder',
              'note_id': 'remote-note',
              'scheduled_at_utc': '2026-07-28T14:00:00.000Z',
              'timezone_name': 'America/Mexico_City',
              'status': 'scheduled',
              'privacy_mode': 'titleOnly',
              'created_at': '2026-07-27T11:00:00.000Z',
              'updated_at': '2026-07-27T11:00:00.000Z',
              'deleted_at': null,
            },
          ),
          reviewKey: SyncLocalEntity(
            key: reviewKey,
            version: 1,
            serverRevision: 3,
            record: const {
              'id': 'remote-review',
              'note_id': 'remote-note',
              'reviewed_at': '2026-07-27T12:00:00.000Z',
              'focus_session_id': null,
              'outcome': 'reviewed',
              'deleted_at': null,
            },
          ),
        },
      ),
    );

    final remote = DriftNoteRepository.forOwner(
      database,
      ownerId: 'uri',
    );
    final stored = await remote.getNote('remote-note');
    expect(stored?.title, 'Desde iPad');
    expect(stored?.tags, ['nube']);
    expect(
      (await remote.getReminderForNote('remote-note'))?.notificationId,
      stableNoteNotificationId('remote-note'),
    );
    expect(
      (await remote.getReviewsForNote('remote-note')).single.id,
      'remote-review',
    );
    expect((await workspace.loadSnapshot()).cursor, 3);
  });
}
