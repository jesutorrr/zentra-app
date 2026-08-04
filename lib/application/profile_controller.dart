import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/profile_repository.dart';
import '../domain/progress_engine.dart';
import '../domain/user_profile.dart';
import 'profile_state.dart';

typedef ProfileRepositoryFactory = ProfileRepository Function(String ownerId);

final profileRepositoryFactoryProvider =
    Provider<ProfileRepositoryFactory>((ref) {
  throw UnimplementedError(
    'profileRepositoryFactoryProvider must be overridden at the app root.',
  );
});

final profileUuidProvider = Provider<Uuid>((ref) => const Uuid());

final profileClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final profileControllerProvider =
    AsyncNotifierProvider.family<ProfileController, ProfileState, String>(
  ProfileController.new,
);

class ProfileController extends FamilyAsyncNotifier<ProfileState, String> {
  late ProfileRepository _repository;
  late Uuid _uuid;
  late DateTime Function() _clock;
  Future<void> _mutationQueue = Future<void>.value();
  bool _isDisposed = false;

  @override
  Future<ProfileState> build(String ownerId) async {
    _isDisposed = false;
    _repository = ref.watch(profileRepositoryFactoryProvider)(ownerId);
    _uuid = ref.watch(profileUuidProvider);
    _clock = ref.watch(profileClockProvider);
    ref.onDispose(() => _isDisposed = true);
    try {
      return ProfileState(
        ownerId: ownerId,
        profile: await _repository.loadProfile(),
      );
    } catch (error) {
      return ProfileState(
        ownerId: ownerId,
        error: 'Error loading profile: $error',
      );
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    try {
      final next = ProfileState(
        ownerId: arg,
        profile: await _repository.loadProfile(),
      );
      if (!_isDisposed) state = AsyncData(next);
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Refreshes durable state after a remote pull while preserving transient UI
  /// presentation such as queued achievement celebrations.
  Future<void> refreshAfterSync() async {
    final previous = state.valueOrNull;
    try {
      final profile = await _repository.loadProfile();
      if (_isDisposed) return;
      state = AsyncData(
        previous?.copyWith(profile: profile, clearError: true) ??
            ProfileState(ownerId: arg, profile: profile),
      );
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> createProfile({
    required String name,
    String? avatarEmoji,
  }) {
    return _serializeMutation(() async {
      final profile = UserProfile(
        id: _uuid.v4(),
        name: name,
        avatarEmoji: avatarEmoji ?? '😊',
        createdAt: _clock(),
      );
      await _repository.saveProfile(profile);
      _update(
        (current) => current.copyWith(
          profile: profile,
          pendingAchievementIds: const [],
          allAchievementsJustUnlocked: false,
          clearError: true,
        ),
      );
    });
  }

  Future<void> updateProfile({
    String? name,
    String? avatarEmoji,
    String? talismanId,
  }) {
    return _serializeMutation(() async {
      final current = _requireState();
      final profile = current.profile;
      if (profile == null) return;
      final updated = profile.copyWith(
        name: name,
        avatarEmoji: avatarEmoji,
        talismanId: talismanId,
      );
      await _repository.saveProfile(updated);
      _update((value) => value.copyWith(profile: updated, clearError: true));
    });
  }

  Future<void> syncProgress({
    required ProgressSnapshot snapshot,
    bool announceUnlocks = true,
  }) {
    return _serializeMutation(() async {
      final current = _requireState();
      final profile = current.profile;
      if (profile == null) return;

      final beforeUnlocked = current.unlockedAchievements.length;
      final result = ProgressEngine.synchronize(
        current: profile,
        snapshot: snapshot,
      );
      final pending = [...current.pendingAchievementIds];
      var allJustUnlocked = current.allAchievementsJustUnlocked;
      if (announceUnlocks) {
        for (final achievement in result.newlyUnlocked) {
          if (!pending.contains(achievement.id)) pending.add(achievement.id);
        }
        final unlockedAfter =
            Achievements.getUnlocked(result.profile.unlockedAchievements);
        if (beforeUnlocked < Achievements.all.length &&
            unlockedAfter.length == Achievements.all.length) {
          allJustUnlocked = true;
        }
      }

      await _repository.saveProfile(result.profile);
      if (_isDisposed) return;
      _update(
        (value) => value.copyWith(
          profile: result.profile,
          pendingAchievementIds: pending,
          allAchievementsJustUnlocked: allJustUnlocked,
          clearError: true,
        ),
      );
    });
  }

  void markAchievementPresented(String achievementId) {
    final current = state.valueOrNull;
    if (current == null ||
        !current.pendingAchievementIds.contains(achievementId)) {
      return;
    }
    _update(
      (value) => value.copyWith(
        pendingAchievementIds: value.pendingAchievementIds
            .where((id) => id != achievementId)
            .toList(growable: false),
      ),
    );
  }

  void clearNewlyUnlocked() {
    _update(
      (current) => current.copyWith(
        pendingAchievementIds: const [],
        allAchievementsJustUnlocked: false,
      ),
    );
  }

  Future<void> deleteProfile() {
    return _serializeMutation(() async {
      await _repository.deleteProfile();
      _update(
        (current) => current.copyWith(
          clearProfile: true,
          pendingAchievementIds: const [],
          allAchievementsJustUnlocked: false,
          clearError: true,
        ),
      );
    });
  }

  Future<void> _serializeMutation(Future<void> Function() mutation) {
    final previousOperation = _mutationQueue;
    final operation = () async {
      await previousOperation;
      if (_isDisposed) return;
      await mutation();
    }();

    _mutationQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Error mutating profile: $error');
        }
      },
    );
    return operation;
  }

  ProfileState _requireState() {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('El perfil todavía no está listo.');
    }
    return current;
  }

  void _update(ProfileState Function(ProfileState current) update) {
    if (_isDisposed) return;
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(update(current));
  }
}
