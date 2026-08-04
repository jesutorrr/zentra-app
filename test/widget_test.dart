import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/domain/models.dart';

void main() {
  group('Smoke tests - Domain models integrity', () {
    test('Category enum has 5 values', () {
      expect(Category.values.length, 5);
    });

    test('Weekday enum has 7 values', () {
      expect(Weekday.values.length, 7);
    });

    test('Habit can be created and serialized', () {
      final habit = Habit(
        id: 'smoke-test',
        title: 'Test Habit',
        category: Category.agua,
        frequency: Frequency.daily(),
        createdAt: DateTime.now(),
      );
      final json = habit.toJson();
      expect(json['id'], 'smoke-test');
      expect(Habit.fromJson(json).title, 'Test Habit');
    });
  });
}
