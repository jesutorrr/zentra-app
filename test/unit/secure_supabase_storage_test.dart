import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/infrastructure/secure_supabase_storage.dart';

void main() {
  test('session storage persists and removes only its namespaced value',
      () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabaseSessionStorage(store);

    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession('session-json');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'session-json');

    await store.write('unrelated', 'keep');
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await store.read('unrelated'), 'keep');
  });

  test('PKCE storage namespaces provider keys away from the session', () async {
    final store = _MemorySecureStore();
    final storage = SecureSupabasePkceStorage(store);

    await storage.setItem(key: 'code-verifier', value: 'secret-verifier');
    expect(
      await storage.getItem(key: 'code-verifier'),
      'secret-verifier',
    );
    expect(
      await store.read(SecureSupabaseSessionStorage.sessionKey),
      isNull,
    );

    await storage.removeItem(key: 'code-verifier');
    expect(await storage.getItem(key: 'code-verifier'), isNull);
  });

  test('parking removes the cloud session without touching local secrets',
      () async {
    final store = _MemorySecureStore();
    await store.write(
      SecureSupabaseSessionStorage.sessionKey,
      'session-json',
    );
    await store.write('zentra-backup-key', 'keep');

    await parkSupabaseSession(store: store);

    expect(
      await store.read(SecureSupabaseSessionStorage.sessionKey),
      isNull,
    );
    expect(await store.read('zentra-backup-key'), 'keep');
  });
}

class _MemorySecureStore implements SecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
