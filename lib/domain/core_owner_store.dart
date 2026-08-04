import 'core_owner_snapshot.dart';

/// Owner-level local storage used by backup, restore and account cleanup.
abstract interface class CoreOwnerStore {
  bool supportsOwner(String ownerId);

  Future<CoreOwnerSnapshot> exportOwner(String ownerId);

  Future<CoreOwnerSnapshot> replaceOwner(CoreOwnerSnapshot snapshot);

  Future<void> deleteOwner(String ownerId);
}
