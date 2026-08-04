import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<bool> containsKey(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureKeyValueStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(migrateWithBackup: false),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  }) : _storage = storage;

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class SecureSupabaseSessionStorage extends LocalStorage {
  static const sessionKey = 'zentra_supabase_session_v1';

  final SecureKeyValueStore _store;

  const SecureSupabaseSessionStorage(this._store);

  @override
  Future<String?> accessToken() => _store.read(sessionKey);

  @override
  Future<bool> hasAccessToken() => _store.containsKey(sessionKey);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    return _store.write(sessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() => _store.delete(sessionKey);
}

/// Removes only the cached Supabase session from this device.
///
/// This never contacts Supabase and deliberately leaves every owner-scoped
/// Zentra record untouched.
Future<void> parkSupabaseSession({
  SecureKeyValueStore store = const FlutterSecureKeyValueStore(),
}) {
  return store.delete(SecureSupabaseSessionStorage.sessionKey);
}

class SecureSupabasePkceStorage extends GotrueAsyncStorage {
  static const _keyPrefix = 'zentra_supabase_pkce_v1_';

  final SecureKeyValueStore _store;

  const SecureSupabasePkceStorage(this._store);

  @override
  Future<String?> getItem({required String key}) {
    return _store.read('$_keyPrefix$key');
  }

  @override
  Future<void> removeItem({required String key}) {
    return _store.delete('$_keyPrefix$key');
  }

  @override
  Future<void> setItem({
    required String key,
    required String value,
  }) {
    return _store.write('$_keyPrefix$key', value);
  }
}
