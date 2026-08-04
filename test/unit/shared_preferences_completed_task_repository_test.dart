import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps completed task history isolated and ordered by owner', () async {
    final preferences = await SharedPreferences.getInstance();
    final ownerA = SharedPreferencesCompletedTaskRepository(
      preferences,
      ownerId: 'owner-a',
    );
    final ownerB = SharedPreferencesCompletedTaskRepository(
      preferences,
      ownerId: 'owner-b',
    );
    final older = CompletedTask(
      id: 'older',
      title: 'Anterior',
      category: Category.movimiento,
      completedAt: DateTime.utc(2026, 7, 20),
      wasOneTime: false,
    );
    final newer = CompletedTask(
      id: 'newer',
      title: 'Reciente',
      category: Category.foco,
      completedAt: DateTime.utc(2026, 7, 21),
      wasOneTime: true,
    );

    await ownerA.replaceCompletedTasks([older, newer]);

    expect(
      (await ownerA.loadCompletedTasks()).map((task) => task.id),
      ['newer', 'older'],
    );
    expect(await ownerB.loadCompletedTasks(), isEmpty);
  });

  test('rejects a blank owner', () async {
    final preferences = await SharedPreferences.getInstance();

    expect(
      () => SharedPreferencesCompletedTaskRepository(
        preferences,
        ownerId: ' ',
      ),
      throwsArgumentError,
    );
  });
}
