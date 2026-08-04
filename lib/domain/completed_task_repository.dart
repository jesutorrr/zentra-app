import 'models.dart';

/// Owner-scoped persistence for the completed and deleted task history.
abstract interface class CompletedTaskRepository {
  String get ownerId;

  Future<List<CompletedTask>> loadCompletedTasks();

  Future<void> replaceCompletedTasks(List<CompletedTask> tasks);
}
