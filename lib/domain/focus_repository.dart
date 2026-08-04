import 'pomodoro_activity.dart';

/// Canonical local persistence for completed focus work.
///
/// Device-only timer configuration and an in-flight timer remain outside this
/// contract because they should not be restored or synchronized as user data.
abstract interface class FocusRepository {
  String get ownerId;

  Future<List<PomodoroActivity>> loadFocusSessions();

  Future<void> replaceFocusSessions(List<PomodoroActivity> sessions);

  Future<Map<String, Object?>> loadFocusProgress();

  Future<void> saveFocusProgress(Map<String, Object?> progress);
}
