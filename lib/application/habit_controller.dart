import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/completed_task_repository.dart';
import '../domain/habit_reminder_service.dart';
import '../domain/models.dart';
import '../infrastructure/app_logger.dart';
import '../infrastructure/notification_service.dart';
import 'habit_state.dart';

typedef HabitRepositoryFactory = HabitRepository Function(String ownerId);
typedef CompletedTaskRepositoryFactory = CompletedTaskRepository Function(
  String ownerId,
);

final habitRepositoryFactoryProvider = Provider<HabitRepositoryFactory>((ref) {
  throw UnimplementedError(
    'habitRepositoryFactoryProvider must be overridden at the app root.',
  );
});

final completedTaskRepositoryFactoryProvider =
    Provider<CompletedTaskRepositoryFactory>((ref) {
  throw UnimplementedError(
    'completedTaskRepositoryFactoryProvider must be overridden at the app root.',
  );
});

final habitReminderServiceProvider = Provider<HabitReminderService>(
  (ref) => NotificationService(),
);

final habitClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final habitControllerProvider =
    AsyncNotifierProvider.family<HabitController, HabitState, String>(
  HabitController.new,
);

class HabitController extends FamilyAsyncNotifier<HabitState, String> {
  late HabitRepository _repository;
  late CompletedTaskRepository _completedTaskRepository;
  late HabitReminderService _reminderService;
  late DateTime Function() _clock;
  Timer? _importSettledTimer;
  bool _isDisposed = false;

  @override
  Future<HabitState> build(String ownerId) async {
    _isDisposed = false;
    _importSettledTimer?.cancel();
    _importSettledTimer = null;
    _repository = ref.watch(habitRepositoryFactoryProvider)(ownerId);
    _completedTaskRepository =
        ref.watch(completedTaskRepositoryFactoryProvider)(ownerId);
    _reminderService = ref.watch(habitReminderServiceProvider);
    _clock = ref.watch(habitClockProvider);
    ref.onDispose(() {
      _isDisposed = true;
      _importSettledTimer?.cancel();
    });

    try {
      final initial = await _load(ownerId);
      await _reschedule(initial.habits);
      return initial;
    } catch (error) {
      return HabitState(
        ownerId: ownerId,
        error: 'Error loading habits: $error',
      );
    }
  }

  Future<void> reload({bool isImporting = false}) async {
    _importSettledTimer?.cancel();
    state = const AsyncLoading();
    try {
      final next = (await _load(arg)).copyWith(isImporting: isImporting);
      if (_isDisposed) return;
      state = AsyncData(next);
      await _reschedule(next.habits);
      if (isImporting && !_isDisposed) {
        _importSettledTimer = Timer(const Duration(milliseconds: 500), () {
          _update((value) => value.copyWith(isImporting: false));
        });
      }
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Refreshes durable state after a remote pull without flashing loading UI.
  Future<void> refreshAfterSync() async {
    final previous = state.valueOrNull;
    try {
      var next = await _load(arg);
      if (_isDisposed) return;
      if (previous != null) {
        next = next.copyWith(
          isImporting: previous.isImporting,
          reminderWarning: previous.reminderWarning,
        );
      }
      state = AsyncData(next);
      await _reschedule(next.habits);
    } catch (error, stackTrace) {
      if (!_isDisposed) state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  String? consumeReminderWarning() {
    final warning = state.valueOrNull?.reminderWarning;
    if (warning != null) {
      _update((current) => current.copyWith(reminderWarning: null));
    }
    return warning;
  }

  Future<void> toggleHabitToday(String habitId) =>
      toggleHabit(habitId, _clock());

  Future<void> toggleHabit(String habitId, DateTime date) async {
    final current = _requireState();
    try {
      final logger = AppLogger();
      final habit = current.getHabitById(habitId);
      final wasCompleted = current.isHabitCompleted(habitId, date);
      final statsBefore = current.getTodayStats(_clock());
      logger.info(
        'HabitController',
        'toggleHabit: wasCompleted=$wasCompleted, '
            'before stats=${statsBefore['completed']}/${statsBefore['total']}',
      );

      await _repository.toggleLog(habitId, date);
      final logs = await _repository.getAllLogs();
      if (_isDisposed) return;
      _update((value) => value.copyWith(logs: logs, error: null));

      final statsAfter = _requireState().getTodayStats(_clock());
      logger.info(
        'HabitController',
        'toggleHabit: '
            'after stats=${statsAfter['completed']}/${statsAfter['total']}',
      );

      if (habit != null && habit.isOneTime && !wasCompleted) {
        await _addToCompletedTasks(habit, wasOneTime: true);
        await _cancelHabitReminder(habitId);
        await _repository.deleteHabit(habitId);
        await _refreshHabits();
      }
    } catch (error) {
      _update(
        (value) => value.copyWith(error: 'Error toggling habit: $error'),
      );
    }
  }

  Future<void> createHabit(Habit habit) async {
    _setLoadingError(null);
    try {
      await _repository.saveHabit(habit);
      await _refreshHabits();
      await _syncHabitReminder(habit, cancelWhenDisabled: false);
    } catch (error, stack) {
      AppLogger().error(
        'HabitController',
        'Error in createHabit',
        error,
        stack,
      );
      _setDataError('Error creating habit: $error');
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    _setLoadingError(null);
    try {
      await _repository.updateHabit(habit);
      await _refreshHabits();
      await _syncHabitReminder(habit);
    } catch (error) {
      _setDataError('Error updating habit: $error');
      rethrow;
    }
  }

  Future<void> deleteHabit(
    String habitId, {
    bool addToHistory = true,
  }) async {
    final habit = _requireState().getHabitById(habitId);
    _setLoadingError(null);
    try {
      await _repository.deleteHabit(habitId);
      await _refreshHabitsAndLogs();
      if (addToHistory && habit != null && !habit.isOneTime) {
        await _addToCompletedTasks(habit, wasOneTime: false);
      }
      await _cancelHabitReminder(habitId);
    } catch (error) {
      _setDataError('Error deleting habit: $error');
      rethrow;
    }
  }

  Future<void> toggleArchive(String habitId) async {
    final habit = _requireState().getHabitById(habitId);
    if (habit == null) return;
    await updateHabit(habit.copyWith(isArchived: !habit.isArchived));
  }

  Future<void> clearCompletedTasks() async {
    await _completedTaskRepository.replaceCompletedTasks(const []);
    _update((current) => current.copyWith(completedTasks: const []));
  }

  Future<void> rescheduleHabitReminders() async {
    await _reschedule(_requireState().habits);
  }

  Future<void> cancelActiveReminders() async {
    for (final habit in _requireState().habits) {
      await _cancelHabitReminder(habit.id);
    }
  }

  void clearError() {
    _update((current) => current.copyWith(error: null));
  }

  Future<HabitState> _load(String ownerId) async {
    final values = await Future.wait<Object>([
      _repository.getHabits(),
      _repository.getAllLogs(),
      _completedTaskRepository.loadCompletedTasks(),
    ]);
    return HabitState(
      ownerId: ownerId,
      habits: values[0] as List<Habit>,
      logs: values[1] as List<HabitLog>,
      completedTasks: values[2] as List<CompletedTask>,
    );
  }

  Future<void> _refreshHabits() async {
    final habits = await _repository.getHabits();
    if (_isDisposed) return;
    _update((current) => current.copyWith(habits: habits, error: null));
  }

  Future<void> _refreshHabitsAndLogs() async {
    final values = await Future.wait<Object>([
      _repository.getHabits(),
      _repository.getAllLogs(),
    ]);
    if (_isDisposed) return;
    _update(
      (current) => current.copyWith(
        habits: values[0] as List<Habit>,
        logs: values[1] as List<HabitLog>,
        error: null,
      ),
    );
  }

  Future<void> _addToCompletedTasks(
    Habit habit, {
    required bool wasOneTime,
  }) async {
    final current = _requireState();
    final task = CompletedTask(
      id: habit.id,
      title: habit.title,
      category: habit.category,
      completedAt: _clock(),
      wasOneTime: wasOneTime,
    );
    final tasks = [
      task,
      ...current.completedTasks.where((value) => value.id != habit.id),
    ];
    await _completedTaskRepository.replaceCompletedTasks(tasks);
    if (_isDisposed) return;
    _update((value) => value.copyWith(completedTasks: tasks));
  }

  Future<void> _reschedule(List<Habit> habits) async {
    for (final habit in habits) {
      if (_isDisposed) return;
      await _syncHabitReminder(habit, cancelWhenDisabled: false);
    }
  }

  Future<void> _syncHabitReminder(
    Habit habit, {
    bool cancelWhenDisabled = true,
  }) async {
    try {
      if (!habit.hasReminder ||
          habit.isArchived ||
          habit.reminderHour == null ||
          habit.reminderMinute == null) {
        if (cancelWhenDisabled) {
          await _reminderService.initialize();
          await _reminderService.cancelHabitReminder(habit.id);
        }
        return;
      }

      await _reminderService.initialize();
      final days = habit.isOneTime || habit.frequency.daysOfWeek.isEmpty
          ? const [1, 2, 3, 4, 5, 6, 7]
          : habit.frequency.daysOfWeek;
      final result = await _reminderService.scheduleHabitReminder(
        habitId: habit.id,
        habitTitle: habit.title,
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
        daysOfWeek: days,
        isOneTime: habit.isOneTime,
        scheduledDate: habit.isOneTime ? habit.scheduledDate : null,
      );
      if (result.wasLimited) {
        final warning = habit.isOneTime && result.scheduledCount == 0
            ? 'La actividad se guardó, pero su recordatorio no pudo '
                'programarse. '
                'Revisa que la fecha y la hora sigan en el futuro.'
            : 'El sistema solo pudo programar ${result.scheduledCount} de '
                '${result.requestedCount} recordatorios para "${habit.title}".';
        _update((current) => current.copyWith(reminderWarning: warning));
      }
    } catch (error, stack) {
      AppLogger().error(
        'HabitController',
        'Error syncing reminder for ${habit.id}',
        error,
        stack,
      );
      _update(
        (current) => current.copyWith(
          reminderWarning: habit.isOneTime
              ? 'La actividad se guardó, pero su recordatorio no pudo '
                  'programarse.'
              : 'El hábito se guardó, pero su recordatorio no pudo '
                  'programarse.',
        ),
      );
    }
  }

  Future<void> _cancelHabitReminder(String habitId) async {
    try {
      await _reminderService.initialize();
      await _reminderService.cancelHabitReminder(habitId);
    } catch (error, stack) {
      AppLogger().error(
        'HabitController',
        'Error canceling reminder for $habitId',
        error,
        stack,
      );
    }
  }

  HabitState _requireState() {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('El espacio de hábitos todavía no está listo.');
    }
    return current;
  }

  void _update(HabitState Function(HabitState current) update) {
    if (_isDisposed) return;
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(update(current));
  }

  void _setLoadingError(String? error) {
    final current = state.valueOrNull;
    if (current == null || _isDisposed) return;
    state = AsyncData(current.copyWith(error: error));
  }

  void _setDataError(String error) {
    _update((current) => current.copyWith(error: error));
  }
}
