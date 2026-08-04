import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/habit_state.dart';
import 'package:zentra/application/progress_sync.dart';
import 'package:zentra/domain/pomodoro_activity.dart';

void main() {
  test('focus totals are derived from synchronized completed sessions', () {
    final snapshot = buildProgressSnapshotFromState(
      habitState: HabitState(ownerId: 'uri'),
      activityHistory: [
        PomodoroActivity(
          id: 'focus-remote',
          name: 'Trabajo profundo',
          startTime: DateTime.utc(2026, 7, 27, 12),
          endTime: DateTime.utc(2026, 7, 27, 13, 15),
          cyclesCompleted: 3,
          totalMinutes: 75,
          isCompleted: true,
        ),
      ],
      totalPomodoros: 0,
      totalFocusMinutes: 0,
      now: DateTime.utc(2026, 7, 27, 14),
    );

    expect(snapshot.totalPomodoros, 3);
    expect(snapshot.totalFocusMinutes, 75);
    expect(
      snapshot.focusEvents.map((event) => event.id),
      [
        'focus:focus-remote:1',
        'focus:focus-remote:2',
        'focus:focus-remote:3',
      ],
    );
  });
}
