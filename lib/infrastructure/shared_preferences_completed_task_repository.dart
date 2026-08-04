import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/completed_task_repository.dart';
import '../domain/models.dart';

class SharedPreferencesCompletedTaskRepository
    implements CompletedTaskRepository {
  final SharedPreferences _preferences;

  @override
  final String ownerId;

  SharedPreferencesCompletedTaskRepository(
    this._preferences, {
    required this.ownerId,
  }) {
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
  }

  String get _storageKey => 'completed_tasks_$ownerId';

  @override
  Future<List<CompletedTask>> loadCompletedTasks() async {
    final value = _preferences.getString(_storageKey);
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value) as List<dynamic>;
    final tasks = decoded
        .map(
          (entry) => CompletedTask.fromJson(
            entry as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));
    return List.unmodifiable(tasks);
  }

  @override
  Future<void> replaceCompletedTasks(List<CompletedTask> tasks) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList(growable: false)),
    );
  }
}
