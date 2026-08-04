import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/note_state.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/note_repository.dart';

import '../support/riverpod_test_harness.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 7, 26, 18);

  test('loads isolated owner-bound repositories for owners A and B', () async {
    final repositories = <String, _MemoryNoteRepository>{
      'owner-a': _MemoryNoteRepository(
        ownerId: 'owner-a',
        notes: [
          _note(id: 'note-a', ownerId: 'owner-a', title: 'Nota de A'),
        ],
      ),
      'owner-b': _MemoryNoteRepository(
        ownerId: 'owner-b',
        notes: [
          _note(id: 'note-b', ownerId: 'owner-b', title: 'Nota de B'),
        ],
      ),
    };
    final container = _createContainer(repositories, fixedNow);
    final ownerAProvider = noteControllerProvider('owner-a');
    final ownerBProvider = noteControllerProvider('owner-b');
    container.listen(ownerAProvider, (_, __) {}, fireImmediately: true);
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);

    final ownerA = await container.read(ownerAProvider.future);
    final ownerB = await container.read(ownerBProvider.future);

    expect(ownerA.ownerId, 'owner-a');
    expect(ownerA.notes.map((note) => note.id), ['note-a']);
    expect(ownerB.ownerId, 'owner-b');
    expect(ownerB.notes.map((note) => note.id), ['note-b']);
    expect(repositories['owner-a']!.currentUserId, 'owner-a');
    expect(repositories['owner-b']!.currentUserId, 'owner-b');
    expect(repositories['owner-a'], isNot(same(repositories['owner-b'])));
  });

  test('search folds accents and filters the loaded owner state', () async {
    final repository = _MemoryNoteRepository(
      ownerId: 'owner-a',
      notes: [
        _note(
          id: 'algebra',
          ownerId: 'owner-a',
          title: 'Álgebra lineal',
          tags: const ['examen'],
        ),
        _note(
          id: 'ideas',
          ownerId: 'owner-a',
          title: 'Ideas para Zentra',
        ),
      ],
    );
    final container = _createContainer({'owner-a': repository}, fixedNow);
    final provider = noteControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);

    container.read(provider.notifier).search('algebra');

    final state = container.read(provider).valueOrNull!;
    expect(state.searchQuery, 'algebra');
    expect(state.filteredNotes.map((note) => note.id), ['algebra']);
  });

  test('create and save persist owner-scoped notes and update state', () async {
    final repository = _MemoryNoteRepository(ownerId: 'owner-a');
    final container = _createContainer({'owner-a': repository}, fixedNow);
    final provider = noteControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);

    final created = await controller.createNote(
      title: '  Repasar Álgebra  ',
      body: 'Matrices',
      category: '  Estudio  ',
      tags: const [' Examen ', 'examen'],
    );

    expect(created.userId, 'owner-a');
    expect(created.title, 'Repasar Álgebra');
    expect(created.category, 'Estudio');
    expect(created.createdAt, fixedNow);
    expect(repository.notes.single.id, created.id);
    expect(container.read(provider).valueOrNull!.selectedNoteId, created.id);

    await controller.saveNote(created.copyWith(body: 'Matrices y vectores'));

    expect(repository.notes.single.body, 'Matrices y vectores');
    expect(
      container.read(provider).valueOrNull!.getNote(created.id)?.body,
      'Matrices y vectores',
    );
  });

  test('load failure becomes an owner-scoped recoverable state', () async {
    final repository = _MemoryNoteRepository(
      ownerId: 'owner-a',
      loadError: StateError('database unavailable'),
    );
    final container = _createContainer({'owner-a': repository}, fixedNow);
    final provider = noteControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);

    final state = await container.read(provider.future);

    expect(state.ownerId, 'owner-a');
    expect(state.notes, isEmpty);
    expect(
      state.errorMessage,
      'No pudimos cargar tus notas. Intenta de nuevo.',
    );
    expect(container.read(provider).hasError, isFalse);
  });

  test('reload propagates repository failures and exposes AsyncError',
      () async {
    final repository = _MemoryNoteRepository(ownerId: 'owner-a');
    final container = _createContainer({'owner-a': repository}, fixedNow);
    final provider = noteControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    repository.loadError = StateError('note reload failed');

    await expectLater(
      container.read(provider.notifier).reload(),
      throwsA(isA<StateError>()),
    );

    final reloaded = container.read(provider);
    expect(reloaded.hasError, isTrue);
    expect(reloaded.error, isA<StateError>());
  });

  test('disposed stale write cannot contaminate another owner', () async {
    final ownerANote = _note(
      id: 'note-a',
      ownerId: 'owner-a',
      title: 'Nota de A',
    );
    final ownerBNote = _note(
      id: 'note-b',
      ownerId: 'owner-b',
      title: 'Nota de B',
    );
    final writeStarted = Completer<void>();
    final releaseWrite = Completer<void>();
    final repositories = <String, _MemoryNoteRepository>{
      'owner-a': _MemoryNoteRepository(
        ownerId: 'owner-a',
        notes: [ownerANote],
        upsertStarted: writeStarted,
        upsertGate: releaseWrite,
      ),
      'owner-b': _MemoryNoteRepository(
        ownerId: 'owner-b',
        notes: [ownerBNote],
      ),
    };
    final container = _createContainer(repositories, fixedNow);
    final ownerAProvider = noteControllerProvider('owner-a');
    final ownerBProvider = noteControllerProvider('owner-b');
    final ownerASubscription = container.listen(
      ownerAProvider,
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);
    await Future.wait([
      container.read(ownerAProvider.future),
      container.read(ownerBProvider.future),
    ]);

    final staleWrite = container
        .read(ownerAProvider.notifier)
        .saveNote(ownerANote.copyWith(body: 'Cambio tardío de A'));
    await writeStarted.future;

    ownerASubscription.close();
    await container.pump();
    expect(container.exists(ownerAProvider), isFalse);

    final createdForB = await container
        .read(ownerBProvider.notifier)
        .createNote(title: 'Nueva de B', body: 'Sólo B');
    releaseWrite.complete();
    await staleWrite;

    final ownerB = container.read(ownerBProvider).valueOrNull!;
    expect(ownerB.notes.map((note) => note.id), contains(createdForB.id));
    expect(ownerB.notes.map((note) => note.id), isNot(contains('note-a')));
    expect(
      repositories['owner-b']!.notes.every(
            (note) => note.userId == 'owner-b',
          ),
      isTrue,
    );
    expect(container.exists(ownerAProvider), isFalse);
  });
}

ProviderContainer _createContainer(
  Map<String, _MemoryNoteRepository> repositories,
  DateTime fixedNow,
) {
  NoteRepository factory(String ownerId) {
    final repository = repositories[ownerId];
    if (repository == null) {
      throw StateError('Missing repository for $ownerId');
    }
    return repository;
  }

  return createTestProviderContainer(
    overrides: [
      noteRepositoryFactoryProvider.overrideWithValue(factory),
      noteClockProvider.overrideWithValue(() => fixedNow),
    ],
  );
}

Note _note({
  required String id,
  required String ownerId,
  required String title,
  List<String> tags = const [],
}) {
  return Note(
    id: id,
    userId: ownerId,
    title: title,
    body: 'Contenido',
    createdAt: DateTime.utc(2026, 7, 25, 12),
    updatedAt: DateTime.utc(2026, 7, 25, 12),
    category: 'Estudio',
    accentKey: 'focus',
    tags: tags,
  );
}

class _MemoryNoteRepository implements NoteRepository {
  final String ownerId;
  Object? loadError;
  final Completer<void>? upsertStarted;
  final Completer<void>? upsertGate;
  final List<Note> _notes;
  final Map<String, NoteReminder> _reminders = {};
  final List<NoteReview> _reviews = [];

  _MemoryNoteRepository({
    required this.ownerId,
    List<Note> notes = const [],
    this.loadError,
    this.upsertStarted,
    this.upsertGate,
  }) : _notes = [...notes];

  List<Note> get notes => List.unmodifiable(_notes);

  @override
  String get currentUserId => ownerId;

  @override
  void setCurrentUser(String? userId) {
    if (userId != ownerId) {
      throw StateError('Repository is bound to $ownerId, not $userId');
    }
  }

  @override
  Future<List<Note>> getNotes({bool includeArchived = false}) async {
    final error = loadError;
    if (error != null) throw error;
    return _notes
        .where((note) => includeArchived || !note.isArchived)
        .toList(growable: false);
  }

  @override
  Future<Note?> getNote(String noteId) async {
    for (final note in _notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  @override
  Future<void> upsertNote(Note note) async {
    _assertOwner(note.userId);
    final started = upsertStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = upsertGate;
    if (gate != null) await gate.future;

    final index = _notes.indexWhere((existing) => existing.id == note.id);
    if (index == -1) {
      _notes.add(note);
    } else {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    _reminders.remove(noteId);
    _reviews.removeWhere((review) => review.noteId == noteId);
  }

  @override
  Future<List<Note>> searchNotes(
    String query, {
    bool includeArchived = false,
  }) async {
    final folded = foldNoteSearch(query);
    return _notes.where((note) {
      if (!includeArchived && note.isArchived) return false;
      return foldNoteSearch(
        '${note.title}\n${note.body}\n${note.category}\n${note.tags.join(' ')}',
      ).contains(folded);
    }).toList(growable: false);
  }

  @override
  Future<NoteReminder?> getReminderForNote(String noteId) async {
    return _reminders[noteId];
  }

  @override
  Future<List<NoteReminder>> getScheduledReminders({
    DateTime? throughUtc,
  }) async {
    return _reminders.values.where((reminder) {
      if (reminder.status != NoteReminderStatus.scheduled) return false;
      return throughUtc == null ||
          !reminder.scheduledAtUtc.isAfter(throughUtc.toUtc());
    }).toList(growable: false);
  }

  @override
  Future<void> upsertReminder(NoteReminder reminder) async {
    _assertOwner(reminder.userId);
    _reminders[reminder.noteId] = reminder;
  }

  @override
  Future<void> deleteReminderForNote(String noteId) async {
    _reminders.remove(noteId);
  }

  @override
  Future<List<NoteReview>> getReviewsForNote(String noteId) async {
    return _reviews
        .where((review) => review.noteId == noteId)
        .toList(growable: false);
  }

  @override
  Future<void> addReview(NoteReview review) async {
    _assertOwner(review.userId);
    _reviews.add(review);
  }

  @override
  Future<NoteOwnerSnapshot> exportOwner() async {
    return NoteOwnerSnapshot(
      ownerId: ownerId,
      exportedAt: DateTime.utc(2026, 7, 26),
      notes: _notes,
      reminders: _reminders.values.toList(),
      reviews: _reviews,
    );
  }

  @override
  Future<void> importOwner(
    NoteOwnerSnapshot snapshot, {
    bool replaceExisting = true,
  }) async {
    if (replaceExisting) {
      _notes.clear();
      _reminders.clear();
      _reviews.clear();
    }
    _notes.addAll(snapshot.notes.map((note) => note.copyWith(userId: ownerId)));
    for (final reminder in snapshot.reminders) {
      _reminders[reminder.noteId] = reminder.copyWith(userId: ownerId);
    }
    _reviews.addAll(
      snapshot.reviews.map((review) => review.copyWith(userId: ownerId)),
    );
  }

  @override
  Future<void> deleteOwner() async {
    _notes.clear();
    _reminders.clear();
    _reviews.clear();
  }

  void _assertOwner(String entityOwnerId) {
    if (entityOwnerId != ownerId) {
      throw StateError('$entityOwnerId does not belong to $ownerId');
    }
  }
}
