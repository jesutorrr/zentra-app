import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/domain/profile_repository.dart';
import 'package:zentra/domain/progress_engine.dart';
import 'package:zentra/domain/user_profile.dart';

import '../support/riverpod_test_harness.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 7, 26, 18);

  test('loads isolated profiles for owners A and B', () async {
    final repositories = <String, _MemoryProfileRepository>{
      'owner-a': _MemoryProfileRepository(
        ownerId: 'owner-a',
        profile: _profile(ownerId: 'owner-a', name: 'Perfil A'),
      ),
      'owner-b': _MemoryProfileRepository(
        ownerId: 'owner-b',
        profile: _profile(ownerId: 'owner-b', name: 'Perfil B'),
      ),
    };
    final container = _createContainer(repositories, fixedNow);
    final ownerAProvider = profileControllerProvider('owner-a');
    final ownerBProvider = profileControllerProvider('owner-b');
    container.listen(ownerAProvider, (_, __) {}, fireImmediately: true);
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);

    final ownerA = await container.read(ownerAProvider.future);
    final ownerB = await container.read(ownerBProvider.future);

    expect(ownerA.ownerId, 'owner-a');
    expect(ownerA.profile?.name, 'Perfil A');
    expect(ownerB.ownerId, 'owner-b');
    expect(ownerB.profile?.name, 'Perfil B');
    expect(repositories['owner-a'], isNot(same(repositories['owner-b'])));
  });

  test('reload propagates repository failures and exposes AsyncError',
      () async {
    final repository = _MemoryProfileRepository(ownerId: 'owner-a');
    final container = _createContainer({'owner-a': repository}, fixedNow);
    final provider = profileControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    repository.loadError = StateError('profile reload failed');

    await expectLater(
      container.read(provider.notifier).reload(),
      throwsA(isA<StateError>()),
    );

    final reloaded = container.read(provider);
    expect(reloaded.hasError, isTrue);
    expect(reloaded.error, isA<StateError>());
  });

  test('create, update and delete remain scoped to one owner', () async {
    final ownerARepository = _MemoryProfileRepository(ownerId: 'owner-a');
    final ownerBRepository = _MemoryProfileRepository(
      ownerId: 'owner-b',
      profile: _profile(ownerId: 'owner-b', name: 'Perfil B'),
    );
    final container = _createContainer(
      {
        'owner-a': ownerARepository,
        'owner-b': ownerBRepository,
      },
      fixedNow,
    );
    final ownerAProvider = profileControllerProvider('owner-a');
    final ownerBProvider = profileControllerProvider('owner-b');
    container.listen(ownerAProvider, (_, __) {}, fireImmediately: true);
    container.listen(ownerBProvider, (_, __) {}, fireImmediately: true);
    await Future.wait([
      container.read(ownerAProvider.future),
      container.read(ownerBProvider.future),
    ]);
    final controller = container.read(ownerAProvider.notifier);

    await controller.createProfile(name: 'Uri', avatarEmoji: ':)');
    final created = container.read(ownerAProvider).valueOrNull!.profile!;
    expect(created.name, 'Uri');
    expect(created.avatarEmoji, ':)');
    expect(created.createdAt, fixedNow);
    expect(ownerARepository.profile?.id, created.id);

    await controller.updateProfile(
      name: 'Uri actualizado',
      avatarEmoji: '<3',
      talismanId: 'moon',
    );
    final updated = container.read(ownerAProvider).valueOrNull!.profile!;
    expect(updated.name, 'Uri actualizado');
    expect(updated.avatarEmoji, '<3');
    expect(updated.talismanId, 'moon');
    expect(ownerARepository.profile?.name, 'Uri actualizado');

    await controller.deleteProfile();
    expect(container.read(ownerAProvider).valueOrNull!.profile, isNull);
    expect(ownerARepository.profile, isNull);
    expect(
      container.read(ownerBProvider).valueOrNull!.profile?.name,
      'Perfil B',
    );
    expect(ownerBRepository.profile?.name, 'Perfil B');
  });

  test('syncProgress is idempotent and presents each achievement once',
      () async {
    final repository = _MemoryProfileRepository(
      ownerId: 'owner-a',
      profile: _profile(ownerId: 'owner-a', name: 'Uri'),
    );
    final container = _createContainer(
      {'owner-a': repository},
      fixedNow,
    );
    final provider = profileControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);
    final snapshot = _snapshot(
      habitIds: const ['habit-event-1'],
      knownHabitIds: const {'habit-1'},
    );

    await controller.syncProgress(snapshot: snapshot);
    final first = container.read(provider).valueOrNull!;
    final firstXp = first.profile!.totalXp;
    expect(first.profile!.totalHabitsCompleted, 1);
    expect(first.pendingAchievementIds, contains('first_habit'));
    expect(
      first.pendingAchievementIds.toSet(),
      hasLength(first.pendingAchievementIds.length),
    );

    controller.markAchievementPresented('first_habit');
    expect(
      container.read(provider).valueOrNull!.pendingAchievementIds,
      isNot(contains('first_habit')),
    );
    controller.markAchievementPresented('first_habit');

    await controller.syncProgress(snapshot: snapshot);
    final repeated = container.read(provider).valueOrNull!;
    expect(repeated.profile!.totalHabitsCompleted, 1);
    expect(repeated.profile!.totalXp, firstXp);
    expect(repeated.pendingAchievementIds, isNot(contains('first_habit')));
    expect(repository.profile!.totalHabitsCompleted, 1);
    expect(repository.profile!.creditedHabitEvents, ['habit-event-1']);
  });

  test('concurrent progress syncs run through one serialized queue', () async {
    final repository = _MemoryProfileRepository(
      ownerId: 'owner-a',
      profile: _profile(ownerId: 'owner-a', name: 'Uri'),
    )..blockNextSave();
    final container = _createContainer(
      {'owner-a': repository},
      fixedNow,
    );
    final provider = profileControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);

    final firstOperation = controller.syncProgress(
      snapshot: _snapshot(habitIds: const ['event-1']),
    );
    await repository.blockedSaveStarted;
    final secondOperation = controller.syncProgress(
      snapshot: _snapshot(habitIds: const ['event-1', 'event-2']),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.saveCalls, 1);
    expect(repository.maxConcurrentSaves, 1);

    repository.releaseBlockedSave();
    await Future.wait([firstOperation, secondOperation]);

    final state = container.read(provider).valueOrNull!;
    expect(repository.maxConcurrentSaves, 1);
    expect(repository.savedHabitCompletionTotals, [1, 2]);
    expect(state.profile!.totalHabitsCompleted, 2);
    expect(
      state.profile!.creditedHabitEvents,
      ['event-1', 'event-2'],
    );
  });

  test('profile edits serialize with progress without losing either change',
      () async {
    final repository = _MemoryProfileRepository(
      ownerId: 'owner-a',
      profile: _profile(ownerId: 'owner-a', name: 'Uri'),
    )..blockNextSave();
    final container = _createContainer(
      {'owner-a': repository},
      fixedNow,
    );
    final provider = profileControllerProvider('owner-a');
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.read(provider.future);
    final controller = container.read(provider.notifier);

    final progressWrite = controller.syncProgress(
      snapshot: _snapshot(habitIds: const ['event-1']),
    );
    await repository.blockedSaveStarted;
    final profileWrite = controller.updateProfile(
      name: 'Uri actualizado',
      avatarEmoji: '<3',
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.saveCalls, 1);
    expect(repository.maxConcurrentSaves, 1);

    repository.releaseBlockedSave();
    await Future.wait([progressWrite, profileWrite]);

    final profile = container.read(provider).valueOrNull!.profile!;
    expect(repository.maxConcurrentSaves, 1);
    expect(profile.name, 'Uri actualizado');
    expect(profile.avatarEmoji, '<3');
    expect(profile.totalHabitsCompleted, 1);
    expect(profile.creditedHabitEvents, ['event-1']);
    expect(repository.profile?.name, 'Uri actualizado');
    expect(repository.profile?.creditedHabitEvents, ['event-1']);
  });

  test('disposing owner A during a write cannot contaminate owner B', () async {
    final ownerARepository = _MemoryProfileRepository(
      ownerId: 'owner-a',
      profile: _profile(ownerId: 'owner-a', name: 'Perfil A'),
    )..blockNextSave();
    final ownerBRepository = _MemoryProfileRepository(
      ownerId: 'owner-b',
      profile: _profile(ownerId: 'owner-b', name: 'Perfil B'),
    );
    final observer = _RecordingObserver();
    final container = _createContainer(
      {
        'owner-a': ownerARepository,
        'owner-b': ownerBRepository,
      },
      fixedNow,
      observers: [observer],
    );
    final ownerAProvider = profileControllerProvider('owner-a');
    final ownerBProvider = profileControllerProvider('owner-b');
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

    final ownerAWrite = container
        .read(ownerAProvider.notifier)
        .syncProgress(snapshot: _snapshot(habitIds: const ['event-a']));
    await ownerARepository.blockedSaveStarted;

    ownerASubscription.close();
    container.invalidate(ownerAProvider);
    await container.pump();
    final ownerAUpdatesAfterDispose = observer.updatesFor(ownerAProvider);

    await container
        .read(ownerBProvider.notifier)
        .syncProgress(snapshot: _snapshot(habitIds: const ['event-b']));
    final ownerBBeforeRelease = container.read(ownerBProvider).valueOrNull!;

    ownerARepository.releaseBlockedSave();
    await ownerAWrite;
    await container.pump();

    final ownerBAfterRelease = container.read(ownerBProvider).valueOrNull!;
    expect(observer.updatesFor(ownerAProvider), ownerAUpdatesAfterDispose);
    expect(ownerBBeforeRelease.ownerId, 'owner-b');
    expect(ownerBAfterRelease.ownerId, 'owner-b');
    expect(ownerBAfterRelease.profile!.totalHabitsCompleted, 1);
    expect(ownerBAfterRelease.profile!.creditedHabitEvents, ['event-b']);
    expect(ownerBRepository.profile!.creditedHabitEvents, ['event-b']);
    expect(
      ownerBRepository.profile!.creditedHabitEvents,
      isNot(contains('event-a')),
    );
  });
}

ProviderContainer _createContainer(
  Map<String, _MemoryProfileRepository> repositories,
  DateTime fixedNow, {
  List<ProviderObserver> observers = const [],
}) {
  ProfileRepository factory(String ownerId) {
    final repository = repositories[ownerId];
    if (repository == null) {
      throw StateError('Missing profile repository for $ownerId');
    }
    return repository;
  }

  return createTestProviderContainer(
    overrides: [
      profileRepositoryFactoryProvider.overrideWithValue(factory),
      profileClockProvider.overrideWithValue(() => fixedNow),
    ],
    observers: observers,
  );
}

UserProfile _profile({
  required String ownerId,
  required String name,
}) {
  return UserProfile(
    id: '$ownerId-profile',
    name: name,
    createdAt: DateTime.utc(2026, 7, 1),
    progressVersion: UserProfile.progressSchemaVersion,
  );
}

ProgressSnapshot _snapshot({
  List<String> habitIds = const [],
  Set<String> knownHabitIds = const {},
}) {
  return ProgressSnapshot(
    habitEvents: [
      for (var index = 0; index < habitIds.length; index++)
        HabitProgressEvent(
          id: habitIds[index],
          completedOn: DateTime(2026, 7, 20 + index),
          categoryName: 'agua',
        ),
    ],
    focusEvents: const [],
    knownHabitIds: knownHabitIds,
    longestStreak: 0,
    totalPomodoros: 0,
    totalFocusMinutes: 0,
  );
}

class _MemoryProfileRepository implements ProfileRepository {
  @override
  final String ownerId;

  UserProfile? profile;
  Object? loadError;
  int saveCalls = 0;
  int _activeSaves = 0;
  int maxConcurrentSaves = 0;
  final List<int> savedHabitCompletionTotals = [];
  bool _shouldBlockNextSave = false;
  Completer<void>? _blockedSaveStarted;
  Completer<void>? _blockedSaveRelease;

  _MemoryProfileRepository({
    required this.ownerId,
    this.profile,
  });

  Future<void> get blockedSaveStarted {
    final completer = _blockedSaveStarted;
    if (completer == null) {
      throw StateError('No save was configured to block.');
    }
    return completer.future;
  }

  void blockNextSave() {
    _shouldBlockNextSave = true;
    _blockedSaveStarted = Completer<void>();
    _blockedSaveRelease = Completer<void>();
  }

  void releaseBlockedSave() {
    final completer = _blockedSaveRelease;
    if (completer == null || completer.isCompleted) {
      throw StateError('No blocked save is waiting.');
    }
    completer.complete();
  }

  @override
  Future<UserProfile?> loadProfile() async {
    final error = loadError;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile value) async {
    saveCalls += 1;
    _activeSaves += 1;
    if (_activeSaves > maxConcurrentSaves) {
      maxConcurrentSaves = _activeSaves;
    }
    try {
      if (_shouldBlockNextSave) {
        _shouldBlockNextSave = false;
        _blockedSaveStarted?.complete();
        await _blockedSaveRelease?.future;
      }
      profile = value;
      savedHabitCompletionTotals.add(value.totalHabitsCompleted);
    } finally {
      _activeSaves -= 1;
    }
  }

  @override
  Future<void> deleteProfile() async {
    profile = null;
  }
}

class _RecordingObserver extends ProviderObserver {
  final Map<ProviderBase<Object?>, int> _updates = {};

  int updatesFor(ProviderBase<Object?> provider) => _updates[provider] ?? 0;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _updates.update(provider, (count) => count + 1, ifAbsent: () => 1);
  }
}
