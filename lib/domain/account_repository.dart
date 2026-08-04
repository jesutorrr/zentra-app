import 'auth_models.dart';

/// Persistence contract for local accounts and the active device session.
abstract interface class AccountRepository {
  Future<List<LocalUser>> loadAccounts();

  Future<void> saveAccounts(List<LocalUser> accounts);

  Future<LocalUser?> loadCurrentAccount();

  Future<void> saveCurrentAccount(LocalUser account);

  Future<String?> loadActiveSessionUserId();

  Future<void> saveActiveSessionUserId(String userId);

  Future<void> clearActiveSession();

  Future<Map<String, dynamic>?> loadProfile(String? userId);

  Future<void> saveProfile(
    String userId,
    Map<String, dynamic> profile,
  );

  Future<void> saveCurrentProfile(Map<String, dynamic> profile);

  Future<void> copyProfileToCurrent(String userId);

  Future<void> deleteProfile(String userId);

  Future<void> clearCurrentAccount();
}
