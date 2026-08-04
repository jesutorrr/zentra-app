import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

class SharedPreferencesProfileRepository implements ProfileRepository {
  final SharedPreferences _preferences;

  @override
  final String ownerId;

  SharedPreferencesProfileRepository(
    this._preferences, {
    required this.ownerId,
  }) {
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
  }

  String get _storageKey => 'user_profile_$ownerId';

  @override
  Future<UserProfile?> loadProfile() async {
    final value = _preferences.getString(_storageKey);
    if (value == null || value.isEmpty) return null;
    return UserProfile.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<void> deleteProfile() => _preferences.remove(_storageKey);
}
