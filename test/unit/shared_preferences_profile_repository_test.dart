import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  UserProfile profile({
    required String id,
    required String name,
    int totalHabitsCompleted = 0,
  }) {
    return UserProfile(
      id: id,
      name: name,
      avatarEmoji: ':)',
      talismanId: 'seed',
      createdAt: DateTime.utc(2026, 7, 26),
      totalHabitsCompleted: totalHabitsCompleted,
      progressVersion: UserProfile.progressSchemaVersion,
      creditedHabitEvents: const ['habit-1'],
    );
  }

  test('owners A and B persist, replace and delete isolated profiles',
      () async {
    final ownerA = SharedPreferencesProfileRepository(
      preferences,
      ownerId: 'owner-a',
    );
    final ownerB = SharedPreferencesProfileRepository(
      preferences,
      ownerId: 'owner-b',
    );

    await ownerA.saveProfile(
      profile(id: 'profile-a', name: 'A', totalHabitsCompleted: 1),
    );
    await ownerB.saveProfile(
      profile(id: 'profile-b', name: 'B', totalHabitsCompleted: 2),
    );

    expect((await ownerA.loadProfile())?.id, 'profile-a');
    expect((await ownerA.loadProfile())?.totalHabitsCompleted, 1);
    expect((await ownerB.loadProfile())?.id, 'profile-b');
    expect((await ownerB.loadProfile())?.totalHabitsCompleted, 2);

    await ownerA.saveProfile(
      profile(id: 'profile-a', name: 'A actualizada')
          .copyWith(talismanId: 'moon'),
    );
    expect((await ownerA.loadProfile())?.name, 'A actualizada');
    expect((await ownerA.loadProfile())?.talismanId, 'moon');
    expect((await ownerB.loadProfile())?.name, 'B');

    await ownerA.deleteProfile();
    expect(await ownerA.loadProfile(), isNull);
    expect((await ownerB.loadProfile())?.id, 'profile-b');
  });

  test('rejects a blank owner before accessing shared storage', () {
    expect(
      () => SharedPreferencesProfileRepository(
        preferences,
        ownerId: '  ',
      ),
      throwsArgumentError,
    );
  });
}
