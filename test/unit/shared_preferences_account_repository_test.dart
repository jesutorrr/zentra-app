import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/infrastructure/shared_preferences_account_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadAccounts migrates the legacy current account without deleting it',
      () async {
    final account = _account(id: 'legacy-owner');
    SharedPreferences.setMockInitialValues({
      'local_user': jsonEncode(account.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );

    final accounts = await repository.loadAccounts();

    expect(accounts, hasLength(1));
    expect(accounts.single.id, account.id);
    expect(preferences.getString('local_user'), isNotNull);
    final savedAccounts =
        jsonDecode(preferences.getString('all_users')!) as List<dynamic>;
    expect(savedAccounts.single['id'], account.id);
  });

  test('loadAccounts scrubs deprecated password hashes without losing users',
      () async {
    final account = _account(id: 'legacy-credential-owner');
    final legacyJson = {
      ...account.toJson(),
      'email': 'uri@zentra.local',
      'passwordHash': 'legacy-unsalted-sha256-value',
    };
    SharedPreferences.setMockInitialValues({
      'all_users': jsonEncode([legacyJson]),
      'local_user': jsonEncode(legacyJson),
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );

    final accounts = await repository.loadAccounts();

    expect(accounts.single.id, account.id);
    expect(accounts.single.email, 'uri@zentra.local');
    final persistedAccounts =
        jsonDecode(preferences.getString('all_users')!) as List<dynamic>;
    final persistedCurrent = jsonDecode(preferences.getString('local_user')!)
        as Map<String, dynamic>;
    expect(persistedAccounts.single, isNot(contains('passwordHash')));
    expect(persistedCurrent, isNot(contains('passwordHash')));
  });

  test('accounts, active session and profile mirrors round trip', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final account = _account(id: 'owner-1');
    final profile = {
      'id': account.id,
      'name': 'Uri',
      'createdAt': account.createdAt.toIso8601String(),
    };

    await repository.saveAccounts([account]);
    await repository.saveCurrentAccount(account);
    await repository.saveActiveSessionUserId(account.id);
    await repository.saveProfile(account.id, profile);
    await repository.copyProfileToCurrent(account.id);

    expect((await repository.loadAccounts()).single.id, account.id);
    expect((await repository.loadCurrentAccount())?.id, account.id);
    expect(await repository.loadActiveSessionUserId(), account.id);
    expect(await repository.loadProfile(account.id), profile);
    expect(await repository.loadProfile(null), profile);

    await repository.clearActiveSession();

    expect(await repository.loadActiveSessionUserId(), isNull);
    expect((await repository.loadCurrentAccount())?.id, account.id);
  });

  test('account cleanup keeps profile and session deletion explicit', () async {
    final account = _account(id: 'owner-to-delete');
    SharedPreferences.setMockInitialValues({
      'all_users': jsonEncode([account.toJson()]),
      'local_user': jsonEncode(account.toJson()),
      'user_profile_${account.id}': jsonEncode({'id': account.id}),
      'user_profile': jsonEncode({'id': account.id}),
      'active_session_user_id': account.id,
      'habits_${account.id}': '[]',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );

    await repository.deleteProfile(account.id);
    await repository.clearCurrentAccount();
    await repository.clearActiveSession();

    expect(preferences.getString('all_users'), isNotNull);
    expect(preferences.getString('habits_${account.id}'), '[]');
    expect(preferences.getString('local_user'), isNull);
    expect(preferences.getString('user_profile_${account.id}'), isNull);
    expect(preferences.getString('user_profile'), isNull);
    expect(preferences.getString('active_session_user_id'), isNull);
  });
}

LocalUser _account({required String id}) {
  final createdAt = DateTime.utc(2026, 7, 26);
  return LocalUser(
    id: id,
    username: 'Uri',
    createdAt: createdAt,
    lastLogin: createdAt,
  );
}
