import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/habit_controller.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/pomodoro_provider.dart';
import 'package:zentra/application/profile_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/habit_reminder_service.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_storage_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_completed_task_repository.dart';
import 'package:zentra/infrastructure/shared_preferences_profile_repository.dart';
import 'package:zentra/presentation/theme.dart';

/// The note every harness starts from, so a test can open it by id without
/// seeding one of its own.
const String _algebraNoteId = 'note-algebra';

/// Wraps [home] in the harness provider graph without touching the media
/// query, so a caller can supply its own text scale or Reduced Motion above it.
Widget buildApp(OwnerBoundWidgetHarness harness, Widget home) {
  return UncontrolledProviderScope(
    container: harness.container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home,
    ),
  );
}

/// Isolated owner workspace for widget tests that exercise the application
/// graph below [activeOwnerIdProvider].
class OwnerBoundWidgetHarness {
  final String ownerId;
  final LocalStorageRepository habits;
  final SharedPreferencesProfileRepository profiles;
  final SharedPreferencesCompletedTaskRepository completedTasks;
  final DriftNoteRepository notes;
  final ZentraDatabase database;
  final ProviderContainer container;

  OwnerBoundWidgetHarness._({
    required this.ownerId,
    required this.habits,
    required this.profiles,
    required this.completedTasks,
    required this.notes,
    required this.database,
    required this.container,
  });

  static Future<OwnerBoundWidgetHarness> create({
    String ownerId = 'local-preview',
    bool initializePomodoro = false,
    String noteTitle = 'Álgebra lineal',
    String noteBody = 'Repasar transformaciones lineales.\n'
        'Espacios vectoriales y matrices.\n'
        '- [ ] Resolver los ejercicios',
  }) async {
    final expectedOwner = ownerId;
    final preferences = await SharedPreferences.getInstance();
    final habits = LocalStorageRepository.forOwner(
      preferences,
      ownerId: ownerId,
    );
    final profiles = SharedPreferencesProfileRepository(
      preferences,
      ownerId: ownerId,
    );
    final completedTasks = SharedPreferencesCompletedTaskRepository(
      preferences,
      ownerId: ownerId,
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    final notes = DriftNoteRepository.forOwner(
      database,
      ownerId: ownerId,
    );
    await notes.upsertNote(
      Note(
        id: _algebraNoteId,
        userId: ownerId,
        title: noteTitle,
        body: noteBody,
        createdAt: DateTime.utc(2026, 7, 25, 10),
        updatedAt: DateTime.utc(2026, 7, 26, 10),
        accentKey: 'focus',
        tags: const ['examen', 'estudio'],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
        habitRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          _requireOwner(requestedOwner, ownerId);
          return habits;
        }),
        completedTaskRepositoryFactoryProvider.overrideWithValue(
          (requestedOwner) {
            _requireOwner(requestedOwner, ownerId);
            return completedTasks;
          },
        ),
        profileRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          _requireOwner(requestedOwner, ownerId);
          return profiles;
        }),
        noteRepositoryFactoryProvider.overrideWithValue((requestedOwner) {
          _requireOwner(requestedOwner, ownerId);
          return notes;
        }),
        habitReminderServiceProvider.overrideWithValue(
          const _FakeHabitReminderService(),
        ),
        pomodoroEngineFactoryProvider.overrideWithValue(
          ({
            required String ownerId,
            required VoidCallback onChanged,
          }) {
            _requireOwner(ownerId, expectedOwner);
            return PomodoroEngine(
              initialUserId: ownerId,
              onChanged: onChanged,
            );
          },
        ),
      ],
    );
    final harness = OwnerBoundWidgetHarness._(
      ownerId: ownerId,
      habits: habits,
      profiles: profiles,
      completedTasks: completedTasks,
      notes: notes,
      database: database,
      container: container,
    );
    await harness.initialize(initializePomodoro: initializePomodoro);
    return harness;
  }

  String get algebraId => _algebraNoteId;

  /// Reads a note straight from the workspace, bypassing the widget tree.
  Note noteById(String id) =>
      container.read(noteControllerProvider(ownerId)).value!.getNote(id)!;

  HabitController get habitController =>
      container.read(habitControllerProvider(ownerId).notifier);

  ProfileController get profileController =>
      container.read(profileControllerProvider(ownerId).notifier);

  PomodoroController get pomodoroController =>
      container.read(pomodoroControllerProvider(ownerId).notifier);

  Future<void> initialize({required bool initializePomodoro}) async {
    container.listen(
      habitControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      profileControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    container.listen(
      noteControllerProvider(ownerId),
      (_, __) {},
      fireImmediately: true,
    );
    await Future.wait([
      container.read(habitControllerProvider(ownerId).future),
      container.read(profileControllerProvider(ownerId).future),
      container.read(noteControllerProvider(ownerId).future),
    ]);
    if (initializePomodoro) {
      await pomodoroController.initialize();
    }
  }

  Widget buildApp({
    required Widget home,
    required ThemeData theme,
    required double textScale,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

class _FakeHabitReminderService implements HabitReminderService {
  const _FakeHabitReminderService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancelHabitReminder(String habitId) async {}

  @override
  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek,
    bool isOneTime = false,
    DateTime? scheduledDate,
  }) async {
    return HabitReminderScheduleResult(
      requestedCount: daysOfWeek.length,
      scheduledCount: daysOfWeek.length,
    );
  }
}

void _requireOwner(String requestedOwner, String expectedOwner) {
  if (requestedOwner != expectedOwner) {
    throw StateError(
      'Expected owner $expectedOwner, received $requestedOwner.',
    );
  }
}
