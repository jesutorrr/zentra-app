import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/note_models.dart' as domain;
import '../domain/note_repository.dart';
import '../domain/sync/sync.dart';
import 'database/zentra_database.dart';
import 'drift_sync_repository.dart';
import 'notification_schedule_planner.dart';

class DriftNoteRepository implements NoteRepository {
  final ZentraDatabase _database;
  final DateTime Function() _clock;
  final String? _syncDeviceId;
  final void Function()? _onSyncNeeded;
  final String? _lockedOwnerId;
  String? _currentUserId;

  DriftNoteRepository(
    this._database, {
    DateTime Function()? clock,
    String? syncDeviceId,
    void Function()? onSyncNeeded,
  })  : _clock = clock ?? DateTime.now,
        _syncDeviceId = syncDeviceId,
        _onSyncNeeded = onSyncNeeded,
        _lockedOwnerId = null;

  /// Creates a repository instance permanently scoped to [ownerId].
  DriftNoteRepository.forOwner(
    this._database, {
    required String ownerId,
    DateTime Function()? clock,
    String? syncDeviceId,
    void Function()? onSyncNeeded,
  })  : _clock = clock ?? DateTime.now,
        _syncDeviceId = syncDeviceId,
        _onSyncNeeded = onSyncNeeded,
        _lockedOwnerId = _validateOwnerId(ownerId),
        _currentUserId = ownerId;

  @override
  String? get currentUserId => _currentUserId;

  @override
  void setCurrentUser(String? userId) {
    final lockedOwnerId = _lockedOwnerId;
    if (lockedOwnerId != null && userId != lockedOwnerId) {
      throw StateError(
        'This repository is locked to owner $lockedOwnerId '
        'and cannot switch to ${userId ?? 'no owner'}.',
      );
    }
    _currentUserId = userId;
  }

  @override
  Future<List<domain.Note>> getNotes({
    bool includeArchived = false,
  }) async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.noteEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      );
    if (!includeArchived) {
      query.where((row) => row.isArchived.equals(false));
    }
    query.orderBy([
      (row) => OrderingTerm(
            expression: row.isPinned,
            mode: OrderingMode.desc,
          ),
      (row) => OrderingTerm(
            expression: row.updatedAt,
            mode: OrderingMode.desc,
          ),
    ]);
    return _hydrateNotes(await query.get(), ownerId);
  }

  @override
  Future<domain.Note?> getNote(String noteId) async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.noteEntries)
      ..where(
        (row) =>
            row.id.equals(noteId) &
            row.userId.equals(ownerId) &
            row.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (await _hydrateNotes([row], ownerId)).single;
  }

  @override
  Future<void> upsertNote(domain.Note note) async {
    final ownerId = _requireOwner();
    _assertOwner(note.userId, ownerId, entity: 'note');
    final previous = await _noteRow(note.id);
    await _database.transaction(() async {
      await _upsertNote(note, ownerId, previous: previous);
      await _enqueueNoteMutations(
        note: note,
        ownerId: ownerId,
        previous: previous,
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final ownerId = _requireOwner();
    final existing = await _noteRow(noteId);
    if (existing == null || existing.userId != ownerId) return;
    await _database.transaction(() async {
      if (_syncDeviceId == null) {
        await (_database.delete(_database.noteEntries)
              ..where(
                (row) => row.id.equals(noteId) & row.userId.equals(ownerId),
              ))
            .go();
        return;
      }
      final deletedAt = _clock().toUtc();
      await (_database.update(_database.noteEntries)
            ..where(
              (row) => row.id.equals(noteId) & row.userId.equals(ownerId),
            ))
          .write(
        NoteEntriesCompanion(
          isPinned: const Value(false),
          isArchived: const Value(true),
          archivedAt: Value(existing.archivedAt ?? deletedAt),
          deletedAt: Value(deletedAt),
          updatedAt: Value(deletedAt),
        ),
      );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.note,
        entityId: noteId,
        operation: SyncMutationOperation.noteDelete,
        baseVersion: _baseVersion(
          existing.version,
          existing.serverRevision,
        ),
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<List<domain.Note>> searchNotes(
    String query, {
    bool includeArchived = false,
  }) async {
    final foldedQuery = _foldForSearch(query.trim());
    if (foldedQuery.isEmpty) {
      return getNotes(includeArchived: includeArchived);
    }

    final notes = await getNotes(includeArchived: includeArchived);
    return notes.where((note) {
      final haystack = [
        note.title,
        note.body,
        if (note.category != null) note.category!,
        ...note.tags,
      ].map(_foldForSearch).join('\n');
      return haystack.contains(foldedQuery);
    }).toList();
  }

  @override
  Future<domain.NoteReminder?> getReminderForNote(String noteId) async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.noteReminderEntries)
      ..where(
        (row) =>
            row.noteId.equals(noteId) &
            row.userId.equals(ownerId) &
            row.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapReminder(row);
  }

  @override
  Future<List<domain.NoteReminder>> getScheduledReminders({
    DateTime? throughUtc,
  }) async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.noteReminderEntries)
      ..where(
        (row) =>
            row.userId.equals(ownerId) &
            row.status.equals(domain.NoteReminderStatus.scheduled.name) &
            row.deletedAt.isNull(),
      );
    if (throughUtc != null) {
      query.where(
        (row) => row.scheduledAtUtc.isSmallerOrEqualValue(
          throughUtc.toUtc(),
        ),
      );
    }
    query.orderBy([
      (row) => OrderingTerm.asc(row.scheduledAtUtc),
    ]);
    return (await query.get()).map(_mapReminder).toList();
  }

  @override
  Future<void> upsertReminder(domain.NoteReminder reminder) async {
    final ownerId = _requireOwner();
    _assertOwner(reminder.userId, ownerId, entity: 'reminder');
    final previous = await _reminderRowForNote(ownerId, reminder.noteId);
    await _database.transaction(() async {
      await _upsertReminder(reminder, ownerId, previous: previous);
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.noteReminder,
        entityId: reminder.id,
        operation: SyncMutationOperation.noteReminderSet,
        payload: _reminderPayload(reminder),
        baseVersion: previous == null
            ? null
            : _baseVersion(previous.version, previous.serverRevision),
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> deleteReminderForNote(String noteId) async {
    final ownerId = _requireOwner();
    final existing = await _reminderRowForNote(ownerId, noteId);
    if (existing == null) return;
    await _database.transaction(() async {
      if (_syncDeviceId == null) {
        await (_database.delete(_database.noteReminderEntries)
              ..where(
                (row) => row.noteId.equals(noteId) & row.userId.equals(ownerId),
              ))
            .go();
        return;
      }
      final deletedAt = _clock().toUtc();
      await (_database.update(_database.noteReminderEntries)
            ..where(
              (row) => row.id.equals(existing.id) & row.userId.equals(ownerId),
            ))
          .write(
        NoteReminderEntriesCompanion(
          status: Value(domain.NoteReminderStatus.cancelled.name),
          updatedAt: Value(deletedAt),
          deletedAt: Value(deletedAt),
        ),
      );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.noteReminder,
        entityId: existing.id,
        operation: SyncMutationOperation.noteReminderSet,
        payload: {
          'note_id': noteId,
          'deleted': true,
        },
        baseVersion: _baseVersion(
          existing.version,
          existing.serverRevision,
        ),
      );
    });
    _notifySyncNeeded();
  }

  @override
  Future<List<domain.NoteReview>> getReviewsForNote(String noteId) async {
    final ownerId = _requireOwner();
    final query = _database.select(_database.noteReviewEntries)
      ..where(
        (row) =>
            row.noteId.equals(noteId) &
            row.userId.equals(ownerId) &
            row.deletedAt.isNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.reviewedAt),
      ]);
    return (await query.get()).map(_mapReview).toList();
  }

  @override
  Future<void> addReview(domain.NoteReview review) async {
    final ownerId = _requireOwner();
    _assertOwner(review.userId, ownerId, entity: 'review');
    final existing = await _reviewRow(review.id);
    var inserted = false;
    await _database.transaction(() async {
      await _ensureOwnedNote(review.noteId, ownerId);
      final focusSessionId = review.focusSessionId;
      if (focusSessionId != null) {
        final existingQuery = _database.select(_database.noteReviewEntries)
          ..where(
            (row) =>
                row.userId.equals(ownerId) &
                row.focusSessionId.equals(focusSessionId) &
                row.deletedAt.isNull(),
          )
          ..limit(1);
        if (await existingQuery.getSingleOrNull() != null) return;
      }
      await _ensureIdAvailable(
        table: _database.noteReviewEntries,
        id: review.id,
        ownerId: ownerId,
        ownerColumn: _database.noteReviewEntries.userId,
        idColumn: _database.noteReviewEntries.id,
        entity: 'review',
      );
      await _database.into(_database.noteReviewEntries).insertOnConflictUpdate(
            NoteReviewEntriesCompanion(
              id: Value(review.id),
              noteId: Value(review.noteId),
              userId: Value(ownerId),
              reviewedAt: Value(review.reviewedAt.toUtc()),
              focusSessionId: Value(review.focusSessionId),
              outcome: Value(review.outcome.name),
              deletedAt: const Value(null),
              version: Value(existing?.version ?? 1),
              serverRevision: Value(existing?.serverRevision ?? 0),
            ),
          );
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.noteReview,
        entityId: review.id,
        operation: SyncMutationOperation.noteReviewAdd,
        payload: _reviewPayload(review),
        baseVersion: existing == null
            ? null
            : _baseVersion(existing.version, existing.serverRevision),
      );
      inserted = true;
    });
    if (inserted) _notifySyncNeeded();
  }

  @override
  Future<domain.NoteOwnerSnapshot> exportOwner() async {
    final ownerId = _requireOwner();
    final notes = await getNotes(includeArchived: true);

    final reminderQuery = _database.select(_database.noteReminderEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.scheduledAtUtc),
      ]);
    final reviewQuery = _database.select(_database.noteReviewEntries)
      ..where(
        (row) => row.userId.equals(ownerId) & row.deletedAt.isNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.reviewedAt),
      ]);

    return domain.NoteOwnerSnapshot(
      ownerId: ownerId,
      exportedAt: DateTime.now().toUtc(),
      notes: notes,
      reminders: (await reminderQuery.get()).map(_mapReminder).toList(),
      reviews: (await reviewQuery.get()).map(_mapReview).toList(),
    );
  }

  @override
  Future<void> importOwner(
    domain.NoteOwnerSnapshot snapshot, {
    bool replaceExisting = true,
  }) async {
    final ownerId = _requireOwner();
    if (snapshot.schemaVersion > 1) {
      throw StateError(
        'Unsupported note snapshot schema ${snapshot.schemaVersion}.',
      );
    }

    final snapshotNoteIds = snapshot.notes.map((note) => note.id).toSet();
    if (snapshotNoteIds.length != snapshot.notes.length) {
      throw StateError('The note snapshot contains duplicate note IDs.');
    }
    for (final reminder in snapshot.reminders) {
      if (!snapshotNoteIds.contains(reminder.noteId) && replaceExisting) {
        throw StateError(
          'Reminder ${reminder.id} references a missing note.',
        );
      }
    }
    for (final review in snapshot.reviews) {
      if (!snapshotNoteIds.contains(review.noteId) && replaceExisting) {
        throw StateError(
          'Review ${review.id} references a missing note.',
        );
      }
    }

    await _database.transaction(() async {
      if (replaceExisting) {
        await _deleteOwnerRows(ownerId);
      }

      for (final note in snapshot.notes) {
        final remapped = note.copyWith(userId: ownerId);
        final previous = await _noteRow(remapped.id);
        await _upsertNote(remapped, ownerId, previous: previous);
        await _enqueueNoteMutations(
          note: remapped,
          ownerId: ownerId,
          previous: previous,
        );
      }
      for (final reminder in snapshot.reminders) {
        final remapped = reminder.copyWith(userId: ownerId);
        final previous = await _reminderRowForNote(
          ownerId,
          remapped.noteId,
        );
        await _upsertReminder(
          remapped,
          ownerId,
          previous: previous,
        );
        await _enqueueMutation(
          ownerId: ownerId,
          entityType: SyncEntityType.noteReminder,
          entityId: remapped.id,
          operation: SyncMutationOperation.noteReminderSet,
          payload: _reminderPayload(remapped),
          baseVersion: previous == null
              ? null
              : _baseVersion(previous.version, previous.serverRevision),
        );
      }
      for (final review in snapshot.reviews) {
        final remapped = review.copyWith(userId: ownerId);
        await _ensureOwnedNote(remapped.noteId, ownerId);
        await _ensureIdAvailable(
          table: _database.noteReviewEntries,
          id: remapped.id,
          ownerId: ownerId,
          ownerColumn: _database.noteReviewEntries.userId,
          idColumn: _database.noteReviewEntries.id,
          entity: 'review',
        );
        await _database
            .into(_database.noteReviewEntries)
            .insertOnConflictUpdate(
              NoteReviewEntriesCompanion(
                id: Value(remapped.id),
                noteId: Value(remapped.noteId),
                userId: Value(ownerId),
                reviewedAt: Value(remapped.reviewedAt.toUtc()),
                focusSessionId: Value(remapped.focusSessionId),
                outcome: Value(remapped.outcome.name),
                deletedAt: const Value(null),
              ),
            );
        await _enqueueMutation(
          ownerId: ownerId,
          entityType: SyncEntityType.noteReview,
          entityId: remapped.id,
          operation: SyncMutationOperation.noteReviewAdd,
          payload: _reviewPayload(remapped),
        );
      }
    });
    _notifySyncNeeded();
  }

  @override
  Future<void> deleteOwner() async {
    final ownerId = _requireOwner();
    await _database.transaction(() => _deleteOwnerRows(ownerId));
  }

  Future<Map<SyncEntityKey, SyncLocalEntity>> loadSyncEntities() async {
    final ownerId = _requireOwner();
    final notes = await (_database.select(_database.noteEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final tags = await (_database.select(_database.noteTagEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final reminders = await (_database.select(_database.noteReminderEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final reviews = await (_database.select(_database.noteReviewEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .get();
    final tagsByNote = <String, List<String>>{};
    for (final tag in tags) {
      tagsByNote.putIfAbsent(tag.noteId, () => []).add(tag.value);
    }

    return {
      for (final row in notes)
        SyncEntityKey(type: SyncEntityType.note, id: row.id): SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.note, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _noteWireRecord(row, tagsByNote[row.id] ?? const []),
        ),
      for (final row in reminders)
        SyncEntityKey(type: SyncEntityType.noteReminder, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(
            type: SyncEntityType.noteReminder,
            id: row.id,
          ),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _reminderWireRecord(row),
        ),
      for (final row in reviews)
        SyncEntityKey(type: SyncEntityType.noteReview, id: row.id):
            SyncLocalEntity(
          key: SyncEntityKey(type: SyncEntityType.noteReview, id: row.id),
          version: row.version,
          serverRevision: row.serverRevision,
          record: _reviewWireRecord(row),
        ),
    };
  }

  Future<void> replaceSyncEntities(
    Map<SyncEntityKey, SyncLocalEntity> entities,
  ) async {
    final ownerId = _requireOwner();
    final previousReminders =
        await (_database.select(_database.noteReminderEntries)
              ..where((row) => row.userId.equals(ownerId)))
            .get();
    final notificationIdsByReminder = {
      for (final row in previousReminders) row.id: row.notificationId,
    };
    final notificationIdsByNote = {
      for (final row in previousReminders) row.noteId: row.notificationId,
    };

    await _deleteOwnerRows(ownerId);

    final ordered = entities.values.toList()
      ..sort(
        (left, right) => left.key.type.index.compareTo(right.key.type.index),
      );
    for (final entity in ordered) {
      switch (entity.key.type) {
        case SyncEntityType.note:
          await _insertSyncedNote(entity, ownerId);
        case SyncEntityType.noteReminder:
          await _insertSyncedReminder(
            entity,
            ownerId,
            notificationIdsByReminder: notificationIdsByReminder,
            notificationIdsByNote: notificationIdsByNote,
          );
        case SyncEntityType.noteReview:
          await _insertSyncedReview(entity, ownerId);
        case SyncEntityType.profile:
        case SyncEntityType.habit:
        case SyncEntityType.habitSchedule:
        case SyncEntityType.habitDayState:
        case SyncEntityType.completedTask:
        case SyncEntityType.focusSession:
        case SyncEntityType.userPreferences:
          throw StateError(
            'Unsupported note sync entity ${entity.key.type.wireName}.',
          );
      }
    }
  }

  Future<void> _upsertNote(
    domain.Note note,
    String ownerId, {
    NoteRow? previous,
  }) async {
    await _ensureIdAvailable(
      table: _database.noteEntries,
      id: note.id,
      ownerId: ownerId,
      ownerColumn: _database.noteEntries.userId,
      idColumn: _database.noteEntries.id,
      entity: 'note',
    );
    final archivedAt =
        note.isArchived ? (note.archivedAt ?? note.updatedAt).toUtc() : null;
    await _database.into(_database.noteEntries).insertOnConflictUpdate(
          NoteEntriesCompanion(
            id: Value(note.id),
            userId: Value(ownerId),
            title: Value(note.title.trim()),
            body: Value(note.body),
            createdAt: Value(note.createdAt.toUtc()),
            updatedAt: Value(note.updatedAt.toUtc()),
            category: Value(note.category?.trim()),
            accentKey: Value(note.accentKey),
            isPinned: Value(note.isPinned),
            isArchived: Value(note.isArchived),
            archivedAt: Value(archivedAt),
            deletedAt: const Value(null),
            formatVersion: Value(note.formatVersion),
            version: Value(previous?.version ?? 1),
            serverRevision: Value(previous?.serverRevision ?? 0),
          ),
        );

    await (_database.delete(_database.noteTagEntries)
          ..where(
            (tag) => tag.noteId.equals(note.id) & tag.userId.equals(ownerId),
          ))
        .go();
    for (final tag in domain.normalizeNoteTags(note.tags)) {
      await _database.into(_database.noteTagEntries).insert(
            NoteTagEntriesCompanion.insert(
              noteId: note.id,
              userId: ownerId,
              value: tag,
            ),
          );
    }
  }

  Future<void> _upsertReminder(
    domain.NoteReminder reminder,
    String ownerId, {
    NoteReminderRow? previous,
  }) async {
    await _ensureOwnedNote(reminder.noteId, ownerId);
    await _ensureIdAvailable(
      table: _database.noteReminderEntries,
      id: reminder.id,
      ownerId: ownerId,
      ownerColumn: _database.noteReminderEntries.userId,
      idColumn: _database.noteReminderEntries.id,
      entity: 'reminder',
    );

    await (_database.delete(_database.noteReminderEntries)
          ..where(
            (row) =>
                row.noteId.equals(reminder.noteId) &
                row.userId.equals(ownerId) &
                row.id.equals(reminder.id).not(),
          ))
        .go();
    await _database.into(_database.noteReminderEntries).insertOnConflictUpdate(
          NoteReminderEntriesCompanion(
            id: Value(reminder.id),
            noteId: Value(reminder.noteId),
            userId: Value(ownerId),
            scheduledAtUtc: Value(reminder.scheduledAtUtc.toUtc()),
            timezoneName: Value(reminder.timezoneName),
            status: Value(reminder.status.name),
            notificationId: Value(reminder.notificationId),
            privacyMode: Value(reminder.privacyMode.name),
            createdAt: Value(reminder.createdAt.toUtc()),
            updatedAt: Value(reminder.updatedAt.toUtc()),
            deletedAt: const Value(null),
            version: Value(previous?.version ?? 1),
            serverRevision: Value(previous?.serverRevision ?? 0),
          ),
        );
  }

  Future<List<domain.Note>> _hydrateNotes(
    List<NoteRow> rows,
    String ownerId,
  ) async {
    if (rows.isEmpty) return [];
    final noteIds = rows.map((row) => row.id).toList();
    final tagQuery = _database.select(_database.noteTagEntries)
      ..where(
        (tag) => tag.userId.equals(ownerId) & tag.noteId.isIn(noteIds),
      )
      ..orderBy([
        (tag) => OrderingTerm.asc(tag.value),
      ]);
    final tagsByNote = <String, List<String>>{};
    for (final tag in await tagQuery.get()) {
      tagsByNote.putIfAbsent(tag.noteId, () => []).add(tag.value);
    }
    return rows
        .map(
          (row) => domain.Note(
            id: row.id,
            userId: row.userId,
            title: row.title,
            body: row.body,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            category: row.category,
            accentKey: row.accentKey,
            isPinned: row.isPinned,
            isArchived: row.isArchived,
            archivedAt: row.archivedAt,
            formatVersion: row.formatVersion,
            tags: tagsByNote[row.id] ?? const [],
          ),
        )
        .toList();
  }

  domain.NoteReminder _mapReminder(NoteReminderRow row) {
    return domain.NoteReminder(
      id: row.id,
      noteId: row.noteId,
      userId: row.userId,
      scheduledAtUtc: row.scheduledAtUtc,
      timezoneName: row.timezoneName,
      status: domain.NoteReminderStatus.fromStorage(row.status),
      notificationId: row.notificationId,
      privacyMode: domain.NotePrivacyMode.fromStorage(row.privacyMode),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  domain.NoteReview _mapReview(NoteReviewRow row) {
    return domain.NoteReview(
      id: row.id,
      noteId: row.noteId,
      userId: row.userId,
      reviewedAt: row.reviewedAt,
      focusSessionId: row.focusSessionId,
      outcome: domain.NoteReviewOutcome.fromStorage(row.outcome),
    );
  }

  Future<void> _ensureOwnedNote(String noteId, String ownerId) async {
    final query = _database.select(_database.noteEntries)
      ..where(
        (row) =>
            row.id.equals(noteId) &
            row.userId.equals(ownerId) &
            row.deletedAt.isNull(),
      );
    if (await query.getSingleOrNull() == null) {
      throw StateError('Note $noteId does not belong to the active owner.');
    }
  }

  Future<void> _ensureIdAvailable<T extends Table, D>({
    required TableInfo<T, D> table,
    required String id,
    required String ownerId,
    required GeneratedColumn<String> ownerColumn,
    required GeneratedColumn<String> idColumn,
    required String entity,
  }) async {
    final rows = await (_database.select(table)
          ..where((_) => idColumn.equals(id)))
        .get();
    if (rows.isEmpty) return;

    final ownedRows = await (_database.select(table)
          ..where(
            (_) => idColumn.equals(id) & ownerColumn.equals(ownerId),
          ))
        .get();
    if (ownedRows.isEmpty) {
      throw StateError(
        'Cannot reuse $entity ID $id from another owner.',
      );
    }
  }

  Future<void> _deleteOwnerRows(String ownerId) async {
    await (_database.delete(_database.noteReviewEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.noteReminderEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.noteTagEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
    await (_database.delete(_database.noteEntries)
          ..where((row) => row.userId.equals(ownerId)))
        .go();
  }

  Future<void> _insertSyncedNote(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    await _database.into(_database.noteEntries).insert(
          NoteEntriesCompanion.insert(
            id: entity.key.id,
            userId: ownerId,
            title: record['title']! as String,
            body: record['body']! as String,
            createdAt: _wireDateTime(record['created_at']) ?? _clock().toUtc(),
            updatedAt: _wireDateTime(record['updated_at']) ?? _clock().toUtc(),
            category: Value(record['category'] as String?),
            accentKey: record['accent_key'] as String? ?? 'mint',
            isPinned: Value(record['is_pinned'] as bool? ?? false),
            isArchived: Value(record['is_archived'] as bool? ?? false),
            archivedAt: Value(_wireDateTime(record['archived_at'])),
            deletedAt: Value(_wireDateTime(record['deleted_at'])),
            formatVersion:
                Value((record['format_version'] as num?)?.toInt() ?? 1),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
    final tags = (record['tags'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    for (final tag in domain.normalizeNoteTags(tags)) {
      await _database.into(_database.noteTagEntries).insert(
            NoteTagEntriesCompanion.insert(
              noteId: entity.key.id,
              userId: ownerId,
              value: tag,
            ),
          );
    }
  }

  Future<void> _insertSyncedReminder(
    SyncLocalEntity entity,
    String ownerId, {
    required Map<String, int> notificationIdsByReminder,
    required Map<String, int> notificationIdsByNote,
  }) async {
    final record = entity.record;
    final noteId = record['note_id']! as String;
    await _database.into(_database.noteReminderEntries).insert(
          NoteReminderEntriesCompanion.insert(
            id: entity.key.id,
            noteId: noteId,
            userId: ownerId,
            scheduledAtUtc:
                _wireDateTime(record['scheduled_at_utc']) ?? _clock().toUtc(),
            timezoneName: record['timezone_name'] as String? ?? 'UTC',
            status: record['status'] as String? ??
                domain.NoteReminderStatus.failed.name,
            notificationId: notificationIdsByReminder[entity.key.id] ??
                notificationIdsByNote[noteId] ??
                stableNoteNotificationId(noteId),
            privacyMode: record['privacy_mode'] as String? ??
                domain.NotePrivacyMode.hidden.name,
            createdAt: _wireDateTime(record['created_at']) ?? _clock().toUtc(),
            updatedAt: _wireDateTime(record['updated_at']) ?? _clock().toUtc(),
            deletedAt: Value(_wireDateTime(record['deleted_at'])),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _insertSyncedReview(
    SyncLocalEntity entity,
    String ownerId,
  ) async {
    final record = entity.record;
    await _database.into(_database.noteReviewEntries).insert(
          NoteReviewEntriesCompanion.insert(
            id: entity.key.id,
            noteId: record['note_id']! as String,
            userId: ownerId,
            reviewedAt:
                _wireDateTime(record['reviewed_at']) ?? _clock().toUtc(),
            focusSessionId: Value(record['focus_session_id'] as String?),
            outcome: record['outcome'] as String? ??
                domain.NoteReviewOutcome.reviewed.name,
            deletedAt: Value(_wireDateTime(record['deleted_at'])),
            version: Value(entity.version),
            serverRevision: Value(entity.serverRevision),
          ),
        );
  }

  Future<void> _enqueueNoteMutations({
    required domain.Note note,
    required String ownerId,
    required NoteRow? previous,
  }) async {
    if (_syncDeviceId == null) return;
    final baseVersion = previous == null
        ? null
        : _baseVersion(previous.version, previous.serverRevision);
    await _enqueueMutation(
      ownerId: ownerId,
      entityType: SyncEntityType.note,
      entityId: note.id,
      operation: SyncMutationOperation.noteUpsert,
      payload: _notePayload(note),
      baseVersion: baseVersion,
    );
    if (note.isArchived != (previous?.isArchived ?? false)) {
      await _enqueueMutation(
        ownerId: ownerId,
        entityType: SyncEntityType.note,
        entityId: note.id,
        operation: note.isArchived
            ? SyncMutationOperation.noteArchive
            : SyncMutationOperation.noteRestore,
        baseVersion: baseVersion,
      );
    }
  }

  Future<void> _enqueueMutation({
    required String ownerId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncMutationOperation operation,
    Map<String, Object?> payload = const {},
    int? baseVersion,
  }) async {
    final deviceId = _syncDeviceId;
    if (deviceId == null) return;
    var createdAt = _clock().toUtc();
    final latest = await (_database.select(_database.syncOutboxEntries)
          ..where((row) => row.ownerId.equals(ownerId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (latest != null) {
      final minimumNextTimestamp =
          latest.createdAt.toUtc().add(const Duration(seconds: 1));
      if (createdAt.isBefore(minimumNextTimestamp)) {
        createdAt = minimumNextTimestamp;
      }
    }
    await DriftSyncRepository.forOwner(
      _database,
      ownerId: ownerId,
      clock: _clock,
    ).enqueue(
      SyncMutation(
        mutationId: const Uuid().v4(),
        ownerId: ownerId,
        deviceId: deviceId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        baseVersion: baseVersion,
        createdAt: createdAt,
      ),
    );
  }

  void _notifySyncNeeded() {
    if (_syncDeviceId != null) _onSyncNeeded?.call();
  }

  Future<NoteRow?> _noteRow(String noteId) {
    return (_database.select(_database.noteEntries)
          ..where((row) => row.id.equals(noteId)))
        .getSingleOrNull();
  }

  Future<NoteReminderRow?> _reminderRowForNote(
    String ownerId,
    String noteId,
  ) {
    return (_database.select(_database.noteReminderEntries)
          ..where(
            (row) => row.userId.equals(ownerId) & row.noteId.equals(noteId),
          ))
        .getSingleOrNull();
  }

  Future<NoteReviewRow?> _reviewRow(String reviewId) {
    return (_database.select(_database.noteReviewEntries)
          ..where((row) => row.id.equals(reviewId)))
        .getSingleOrNull();
  }

  String _requireOwner() {
    final ownerId = _currentUserId;
    if (ownerId == null || ownerId.trim().isEmpty) {
      throw StateError('A current user is required for note access.');
    }
    return ownerId;
  }

  void _assertOwner(
    String entityOwner,
    String activeOwner, {
    required String entity,
  }) {
    if (entityOwner != activeOwner) {
      throw StateError(
        'The $entity belongs to a different owner.',
      );
    }
  }
}

Map<String, Object?> _notePayload(domain.Note note) => {
      'title': note.title.trim(),
      'body': note.body,
      'category': note.category?.trim(),
      'accent_key': note.accentKey,
      'is_pinned': note.isPinned,
      'tags': domain.normalizeNoteTags(note.tags),
      'format_version': note.formatVersion,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };

Map<String, Object?> _reminderPayload(domain.NoteReminder reminder) => {
      'note_id': reminder.noteId,
      'scheduled_at_utc': reminder.scheduledAtUtc.toUtc().toIso8601String(),
      'timezone_name': reminder.timezoneName,
      'status': reminder.status.name,
      'privacy_mode': reminder.privacyMode.name,
      'created_at': reminder.createdAt.toUtc().toIso8601String(),
      'updated_at': reminder.updatedAt.toUtc().toIso8601String(),
      'deleted': false,
    };

Map<String, Object?> _reviewPayload(domain.NoteReview review) => {
      'note_id': review.noteId,
      'reviewed_at': review.reviewedAt.toUtc().toIso8601String(),
      'focus_session_id': review.focusSessionId,
      'outcome': review.outcome.name,
    };

Map<String, Object?> _noteWireRecord(
  NoteRow row,
  List<String> tags,
) =>
    {
      'id': row.id,
      'title': row.title,
      'body': row.body,
      'category': row.category,
      'accent_key': row.accentKey,
      'is_pinned': row.isPinned,
      'is_archived': row.isArchived,
      'archived_at': row.archivedAt?.toUtc().toIso8601String(),
      'tags': domain.normalizeNoteTags(tags),
      'format_version': row.formatVersion,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };

Map<String, Object?> _reminderWireRecord(NoteReminderRow row) => {
      'id': row.id,
      'note_id': row.noteId,
      'scheduled_at_utc': row.scheduledAtUtc.toUtc().toIso8601String(),
      'timezone_name': row.timezoneName,
      'status': row.status,
      'privacy_mode': row.privacyMode,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };

Map<String, Object?> _reviewWireRecord(NoteReviewRow row) => {
      'id': row.id,
      'note_id': row.noteId,
      'reviewed_at': row.reviewedAt.toUtc().toIso8601String(),
      'focus_session_id': row.focusSessionId,
      'outcome': row.outcome,
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };

int? _baseVersion(int version, int serverRevision) {
  return serverRevision == 0 ? null : version;
}

DateTime? _wireDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.parse(value as String).toUtc();
}

String _validateOwnerId(String ownerId) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'Must not be blank.');
  }
  return ownerId;
}

String _foldForSearch(String value) {
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
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
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(replacements[character] ?? character);
  }
  return buffer.toString();
}
