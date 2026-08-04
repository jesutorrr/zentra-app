import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Habit habit(String id) {
    return Habit(
      id: id,
      title: id,
      category: Category.foco,
      frequency: const Frequency(isWeekly: true, daysOfWeek: [1]),
      createdAt: DateTime.utc(2026, 7, 26),
    );
  }

  test('forOwner locks identity and isolates SharedPreferences keys', () async {
    final ownerA = LocalStorageRepository.forOwner(
      preferences,
      ownerId: 'owner-a',
    );
    final ownerB = LocalStorageRepository.forOwner(
      preferences,
      ownerId: 'owner-b',
    );

    expect(ownerA.currentUserId, 'owner-a');
    expect(() => ownerA.setCurrentUser('owner-a'), returnsNormally);
    expect(
      () => ownerA.setCurrentUser('owner-b'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => ownerA.setCurrentUser(null),
      throwsA(isA<StateError>()),
    );
    expect(ownerA.currentUserId, 'owner-a');

    await ownerA.saveHabit(habit('habit-a'));
    await ownerB.saveHabit(habit('habit-b'));
    await ownerA.toggleLog('habit-a', DateTime(2026, 7, 26));

    expect((await ownerA.getHabits()).map((entry) => entry.id), ['habit-a']);
    expect((await ownerB.getHabits()).map((entry) => entry.id), ['habit-b']);
    expect((await ownerA.getAllLogs()).map((entry) => entry.habitId), [
      'habit-a',
    ]);
    expect(await ownerB.getAllLogs(), isEmpty);
  });

  test('forOwner rejects a blank identity', () {
    expect(
      () => LocalStorageRepository.forOwner(
        preferences,
        ownerId: '  ',
      ),
      throwsArgumentError,
    );
  });
}
