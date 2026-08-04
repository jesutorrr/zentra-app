import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account_repository.dart';
import '../domain/auth_models.dart';

class SharedPreferencesAccountRepository implements AccountRepository {
  static const _accountsKey = 'all_users';
  static const _currentAccountKey = 'local_user';
  static const _currentProfileKey = 'user_profile';
  static const _activeSessionUserIdKey = 'active_session_user_id';

  final SharedPreferences? _preferences;

  const SharedPreferencesAccountRepository({
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? await SharedPreferences.getInstance();

  @override
  Future<List<LocalUser>> loadAccounts() async {
    final prefs = await _prefs;
    final accountsJson = prefs.getString(_accountsKey);
    final decodedAccounts = accountsJson == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(accountsJson) as List<dynamic>)
            .map((value) => value as Map<String, dynamic>)
            .toList();
    final accounts =
        decodedAccounts.map(LocalUser.fromJson).toList(growable: true);
    final hadDeprecatedCredentials = decodedAccounts.any(
      (account) => account.containsKey('passwordHash'),
    );

    final legacyAccountJson = prefs.getString(_currentAccountKey);
    if (legacyAccountJson != null) {
      final legacyJson = jsonDecode(legacyAccountJson) as Map<String, dynamic>;
      final sanitizedLegacyAccount = LocalUser.fromJson(legacyJson);
      if (legacyJson.containsKey('passwordHash')) {
        await saveCurrentAccount(sanitizedLegacyAccount);
      }
      if (accounts.isEmpty) {
        accounts.add(sanitizedLegacyAccount);
      }
    }

    if (hadDeprecatedCredentials ||
        (accountsJson == null && accounts.isNotEmpty)) {
      await saveAccounts(accounts);
    }

    return accounts;
  }

  @override
  Future<void> saveAccounts(List<LocalUser> accounts) async {
    final prefs = await _prefs;
    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  @override
  Future<LocalUser?> loadCurrentAccount() async {
    final prefs = await _prefs;
    final accountJson = prefs.getString(_currentAccountKey);
    if (accountJson == null) return null;
    return LocalUser.fromJson(
      jsonDecode(accountJson) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveCurrentAccount(LocalUser account) async {
    final prefs = await _prefs;
    await prefs.setString(
      _currentAccountKey,
      jsonEncode(account.toJson()),
    );
  }

  @override
  Future<String?> loadActiveSessionUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_activeSessionUserIdKey);
  }

  @override
  Future<void> saveActiveSessionUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_activeSessionUserIdKey, userId);
  }

  @override
  Future<void> clearActiveSession() async {
    final prefs = await _prefs;
    await prefs.remove(_activeSessionUserIdKey);
  }

  @override
  Future<Map<String, dynamic>?> loadProfile(String? userId) async {
    final prefs = await _prefs;
    final profileJson = prefs.getString(
      userId == null ? _currentProfileKey : _profileKey(userId),
    );
    if (profileJson == null) return null;
    return jsonDecode(profileJson) as Map<String, dynamic>;
  }

  @override
  Future<void> saveProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey(userId), jsonEncode(profile));
  }

  @override
  Future<void> saveCurrentProfile(Map<String, dynamic> profile) async {
    final prefs = await _prefs;
    await prefs.setString(_currentProfileKey, jsonEncode(profile));
  }

  @override
  Future<void> copyProfileToCurrent(String userId) async {
    final prefs = await _prefs;
    final profileJson = prefs.getString(_profileKey(userId));
    if (profileJson != null) {
      await prefs.setString(_currentProfileKey, profileJson);
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    final prefs = await _prefs;
    await prefs.remove(_profileKey(userId));
  }

  @override
  Future<void> clearCurrentAccount() async {
    final prefs = await _prefs;
    await prefs.remove(_currentAccountKey);
    await prefs.remove(_currentProfileKey);
  }

  String _profileKey(String userId) => 'user_profile_$userId';
}
