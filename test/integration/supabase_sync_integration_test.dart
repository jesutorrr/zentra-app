import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zentra/application/sync_coordinator.dart';
import 'package:zentra/domain/models.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/domain/pomodoro_activity.dart';
import 'package:zentra/domain/sync/sync.dart';
import 'package:zentra/domain/user_profile.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_core_repository.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/drift_sync_workspace.dart';
import 'package:zentra/infrastructure/local_persistence_runtime.dart';
import 'package:zentra/infrastructure/supabase_sync_transport.dart';

void main() {
  const url = String.fromEnvironment('SUPABASE_TEST_URL');
  const publishableKey =
      String.fromEnvironment('SUPABASE_TEST_PUBLISHABLE_KEY');
  final canRun = url.isNotEmpty && publishableKey.isNotEmpty;

  test(
    'real local Supabase round-trips an offline-first habit across devices',
    () async {
      final client = SupabaseClient(
        url,
        publishableKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final response = await client.auth.signUp(
        email: 'zentra-sync-$suffix@example.com',
        password: 'Local-sync-test-$suffix!',
      );
      final session = response.session;
      expect(session, isNotNull);
      final ownerId = session!.user.id;
      final transport = SupabaseSyncTransport(client);
      final habitId = const Uuid().v4();
      final now = DateTime.utc(2026, 7, 27, 12);

      final firstDatabase = ZentraDatabase(NativeDatabase.memory());
      final firstCore = DriftCoreRepository.forOwner(
        firstDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
        clock: () => now,
      );
      await firstCore.saveHabit(
        Habit(
          id: habitId,
          title: 'Caminar contra Supabase local',
          category: Category.movimiento,
          frequency: Frequency.weekdays(),
          createdAt: now,
        ),
      );
      final firstCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: firstDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now,
      );
      final pushed = await firstCoordinator.syncNow();
      expect(
        pushed.state.experienceState,
        SyncExperienceState.synced,
        reason: pushed.state.toJson().toString(),
      );
      expect(pushed.pushedMutations, 2);
      await firstDatabase.close();

      final secondDatabase = ZentraDatabase(NativeDatabase.memory());
      final secondCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: secondDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now.add(const Duration(minutes: 1)),
      );
      final pulled = await secondCoordinator.syncNow();
      expect(pulled.state.experienceState, SyncExperienceState.synced);
      expect(pulled.pulledChanges, 2);
      final secondCore = DriftCoreRepository.forOwner(
        secondDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
      );
      expect((await secondCore.getHabits()).single.id, habitId);
      expect(
        (await secondCore.getHabits()).single.frequency.daysOfWeek,
        [1, 2, 3, 4, 5],
      );

      var currentHabit = (await secondCore.getHabits()).single;
      await secondCore.updateHabit(
        currentHabit.copyWith(title: 'Caminar 30 minutos'),
      );
      var lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 2);
      expect(
        (await secondCore.getHabits()).single.title,
        'Caminar 30 minutos',
      );

      currentHabit = (await secondCore.getHabits()).single;
      await secondCore.updateHabit(currentHabit.copyWith(isArchived: true));
      lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 3);
      expect((await secondCore.getHabits()).single.isArchived, isTrue);

      currentHabit = (await secondCore.getHabits()).single;
      await secondCore.updateHabit(currentHabit.copyWith(isArchived: false));
      lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 3);
      expect((await secondCore.getHabits()).single.isArchived, isFalse);

      await secondCore.toggleLog(habitId, now);
      lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 1);
      expect(await secondCore.getAllLogs(), hasLength(1));

      await secondCore.toggleLog(habitId, now);
      lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 1);
      expect(await secondCore.getAllLogs(), isEmpty);

      await secondCore.deleteHabit(habitId);
      lifecycleSync = await secondCoordinator.syncNow();
      expect(lifecycleSync.state.experienceState, SyncExperienceState.synced);
      expect(lifecycleSync.pushedMutations, 1);
      expect(await secondCore.getHabits(), isEmpty);

      await secondDatabase.close();
      client.dispose();
    },
    skip: canRun
        ? false
        : 'Set SUPABASE_TEST_URL and SUPABASE_TEST_PUBLISHABLE_KEY.',
  );

  test(
    'real local Supabase syncs note lifecycle and preserves concurrent bodies',
    () async {
      final client = SupabaseClient(
        url,
        publishableKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final response = await client.auth.signUp(
        email: 'zentra-note-sync-$suffix@example.com',
        password: 'Local-note-sync-test-$suffix!',
      );
      final session = response.session;
      expect(session, isNotNull);
      final ownerId = session!.user.id;
      final transport = SupabaseSyncTransport(client);
      final noteId = const Uuid().v4();
      final reminderId = const Uuid().v4();
      final reviewId = const Uuid().v4();
      final now = DateTime.utc(2026, 7, 27, 15);

      final firstDatabase = ZentraDatabase(NativeDatabase.memory());
      final firstNotes = DriftNoteRepository.forOwner(
        firstDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
        clock: () => now,
      );
      final original = Note(
        id: noteId,
        userId: ownerId,
        title: 'Idea en Supabase local',
        body: 'Texto original',
        createdAt: now,
        updatedAt: now,
        category: 'Ideas',
        accentKey: 'lavender',
        isPinned: true,
        tags: const ['gate-7', 'nube'],
      );
      await firstNotes.upsertNote(original);
      await firstNotes.upsertReminder(
        NoteReminder(
          id: reminderId,
          noteId: noteId,
          userId: ownerId,
          scheduledAtUtc: now.add(const Duration(days: 1)),
          timezoneName: 'America/Mexico_City',
          status: NoteReminderStatus.scheduled,
          notificationId: 2100000001,
          privacyMode: NotePrivacyMode.titleOnly,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await firstNotes.addReview(
        NoteReview(
          id: reviewId,
          noteId: noteId,
          userId: ownerId,
          reviewedAt: now,
          outcome: NoteReviewOutcome.reviewed,
        ),
      );
      final firstCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: firstDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now,
      );
      final initialSync = await firstCoordinator.syncNow();
      expect(
        initialSync.state.experienceState,
        SyncExperienceState.synced,
        reason: initialSync.state.toJson().toString(),
      );
      expect(initialSync.pushedMutations, 3);

      final secondDatabase = ZentraDatabase(NativeDatabase.memory());
      final secondCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: secondDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now.add(const Duration(minutes: 1)),
      );
      final initialPull = await secondCoordinator.syncNow();
      expect(initialPull.pulledChanges, 3);
      final secondNotes = DriftNoteRepository.forOwner(
        secondDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
        clock: () => now.add(const Duration(minutes: 1)),
      );
      expect((await secondNotes.getNote(noteId))?.tags, ['gate-7', 'nube']);
      expect(
        (await secondNotes.getReminderForNote(noteId))?.timezoneName,
        'America/Mexico_City',
      );
      expect(
        (await secondNotes.getReviewsForNote(noteId)).single.id,
        reviewId,
      );

      final firstCurrent = (await firstNotes.getNote(noteId))!;
      await firstNotes.upsertNote(
        firstCurrent.copyWith(
          body: 'Texto editado desde el primer dispositivo',
          updatedAt: now.add(const Duration(minutes: 2)),
        ),
      );
      final remoteEdit = await firstCoordinator.syncNow();
      expect(remoteEdit.pushedMutations, 1);

      final secondCurrent = (await secondNotes.getNote(noteId))!;
      await secondNotes.upsertNote(
        secondCurrent.copyWith(
          body: 'Texto editado en paralelo desde el segundo dispositivo',
          updatedAt: now.add(const Duration(minutes: 3)),
        ),
      );
      final conflictRun = await secondCoordinator.syncNow();
      expect(conflictRun.pushedMutations, 0);
      final conflictSnapshot = await DriftSyncWorkspace(
        database: secondDatabase,
        ownerId: ownerId,
      ).loadSnapshot();
      expect(conflictSnapshot.conflicts, hasLength(1));
      expect(
        conflictSnapshot.conflicts.single.localRecord['body'],
        'Texto editado en paralelo desde el segundo dispositivo',
      );
      expect(
        conflictSnapshot.conflicts.single.remoteRecord['body'],
        'Texto editado desde el primer dispositivo',
      );
      expect(
        conflictSnapshot.outbox.single.lifecycle,
        SyncMutationLifecycle.blockedByConflict,
      );

      var lifecycleNote = (await firstNotes.getNote(noteId))!;
      await firstNotes.upsertNote(
        lifecycleNote.copyWith(
          isArchived: true,
          archivedAt: now.add(const Duration(minutes: 4)),
          updatedAt: now.add(const Duration(minutes: 4)),
        ),
      );
      var lifecycleSync = await firstCoordinator.syncNow();
      expect(lifecycleSync.pushedMutations, 2);
      expect(
        (await firstNotes.getNotes(includeArchived: true)).single.isArchived,
        isTrue,
      );

      lifecycleNote = (await firstNotes.getNotes(includeArchived: true)).single;
      await firstNotes.upsertNote(
        lifecycleNote.copyWith(
          isArchived: false,
          archivedAt: null,
          updatedAt: now.add(const Duration(minutes: 5)),
        ),
      );
      lifecycleSync = await firstCoordinator.syncNow();
      expect(lifecycleSync.pushedMutations, 2);
      expect((await firstNotes.getNote(noteId))?.isArchived, isFalse);

      await firstNotes.deleteReminderForNote(noteId);
      lifecycleSync = await firstCoordinator.syncNow();
      expect(lifecycleSync.pushedMutations, 1);
      expect(await firstNotes.getReminderForNote(noteId), isNull);

      await firstNotes.deleteNote(noteId);
      lifecycleSync = await firstCoordinator.syncNow();
      expect(lifecycleSync.pushedMutations, 1);
      expect(await firstNotes.getNote(noteId), isNull);

      await firstDatabase.close();
      await secondDatabase.close();
      client.dispose();
    },
    skip: canRun
        ? false
        : 'Set SUPABASE_TEST_URL and SUPABASE_TEST_PUBLISHABLE_KEY.',
  );

  test(
    'real local Supabase syncs completed history and focus events',
    () async {
      final client = SupabaseClient(
        url,
        publishableKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final response = await client.auth.signUp(
        email: 'zentra-activity-sync-$suffix@example.com',
        password: 'Local-activity-sync-test-$suffix!',
      );
      final session = response.session;
      expect(session, isNotNull);
      final ownerId = session!.user.id;
      final transport = SupabaseSyncTransport(client);
      final taskId = const Uuid().v4();
      final focusId = const Uuid().v4();
      final now = DateTime.utc(2026, 7, 27, 16);

      final firstDatabase = ZentraDatabase(NativeDatabase.memory());
      final firstCore = DriftCoreRepository.forOwner(
        firstDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
        clock: () => now,
      );
      await firstCore.replaceCompletedTasks([
        CompletedTask(
          id: taskId,
          title: 'Cerrar historial remoto',
          category: Category.foco,
          completedAt: now,
          wasOneTime: true,
        ),
      ]);
      await firstCore.replaceFocusSessions([
        PomodoroActivity(
          id: focusId,
          name: 'Gate 7',
          startTime: now,
          endTime: now.add(const Duration(minutes: 25)),
          cyclesCompleted: 1,
          totalMinutes: 25,
          isCompleted: true,
        ),
      ]);
      final firstCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: firstDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now,
      );
      final pushed = await firstCoordinator.syncNow();
      expect(
        pushed.state.experienceState,
        SyncExperienceState.synced,
        reason: pushed.state.toJson().toString(),
      );
      expect(pushed.pushedMutations, 2);

      final secondDatabase = ZentraDatabase(NativeDatabase.memory());
      final secondCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: secondDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now.add(const Duration(minutes: 1)),
      );
      final pulled = await secondCoordinator.syncNow();
      expect(pulled.pulledChanges, 2);
      final secondCore = DriftCoreRepository.forOwner(
        secondDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
      );
      expect((await secondCore.getCompletedTasks()).single.id, taskId);
      expect((await secondCore.getFocusSessions()).single.id, focusId);
      expect((await secondCore.getFocusSessions()).single.totalMinutes, 25);

      await firstCore.replaceCompletedTasks(const []);
      final deleted = await firstCoordinator.syncNow();
      expect(deleted.pushedMutations, 1);
      final pulledDelete = await secondCoordinator.syncNow();
      expect(pulledDelete.pulledChanges, 1);
      expect(await secondCore.getCompletedTasks(), isEmpty);
      expect((await secondCore.getFocusSessions()).single.id, focusId);

      await firstDatabase.close();
      await secondDatabase.close();
      client.dispose();
    },
    skip: canRun
        ? false
        : 'Set SUPABASE_TEST_URL and SUPABASE_TEST_PUBLISHABLE_KEY.',
  );

  test(
    'Realtime wakes a second device into an incremental pull',
    () async {
      final client = SupabaseClient(
        url,
        publishableKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final response = await client.auth.signUp(
        email: 'zentra-realtime-$suffix@example.com',
        password: 'Local-realtime-test-$suffix!',
      );
      final session = response.session;
      expect(session, isNotNull);
      final ownerId = session!.user.id;
      final transport = SupabaseSyncTransport(client);
      final now = DateTime.utc(2026, 7, 27, 17);

      final receivingDatabase = ZentraDatabase(NativeDatabase.memory());
      final receivingCore = DriftCoreRepository.forOwner(
        receivingDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
      );
      final realtimeReady = Completer<void>();
      final remoteChanges =
          transport.watchRemoteChanges(ownerId: ownerId).map((_) {
        if (!realtimeReady.isCompleted) realtimeReady.complete();
      });
      final receivingCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: receivingDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        remoteChanges: remoteChanges,
        remoteWakeDebounce: const Duration(milliseconds: 50),
        clock: () => now.add(const Duration(minutes: 1)),
      );
      await receivingCoordinator.syncNow();
      await realtimeReady.future.timeout(const Duration(seconds: 20));

      final sendingDatabase = ZentraDatabase(NativeDatabase.memory());
      final habitId = const Uuid().v4();
      final sendingCore = DriftCoreRepository.forOwner(
        sendingDatabase,
        ownerId: ownerId,
        syncDeviceId: const Uuid().v4(),
        clock: () => now,
      );
      await sendingCore.saveHabit(
        Habit(
          id: habitId,
          title: 'Despertar por Realtime',
          category: Category.foco,
          frequency: Frequency.daily(),
          createdAt: now,
        ),
      );
      await sendingCore.savePortableThemeMode('dark');
      final sendingCoordinator = SyncCoordinator(
        ownerId: ownerId,
        workspace: DriftSyncWorkspace(
          database: sendingDatabase,
          ownerId: ownerId,
        ),
        transport: transport,
        clock: () => now,
      );
      final sent = await sendingCoordinator.syncNow();
      expect(sent.pushedMutations, 3);

      await _waitUntil(
        () async =>
            (await receivingCore.getHabits())
                .any((habit) => habit.id == habitId) &&
            (await receivingCore.loadPortablePreferences())?.themeMode ==
                'dark',
        reason: 'the receiving workspace never handled the Realtime wake-up',
      );
      expect(
        (await receivingCore.getHabits()).single.title,
        'Despertar por Realtime',
      );
      expect(
        (await receivingCore.loadPortablePreferences())?.themeMode,
        'dark',
      );

      await receivingCoordinator.dispose();
      await sendingCoordinator.dispose();
      await receivingDatabase.close();
      await sendingDatabase.close();
      client.dispose();
    },
    skip: canRun
        ? false
        : 'Set SUPABASE_TEST_URL and SUPABASE_TEST_PUBLISHABLE_KEY.',
  );

  test(
    'local workspace links into auth.uid and uploads its supported core',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = SupabaseClient(
        url,
        publishableKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final response = await client.auth.signUp(
        email: 'zentra-link-$suffix@example.com',
        password: 'Local-link-test-$suffix!',
      );
      final session = response.session;
      expect(session, isNotNull);
      final remoteOwnerId = session!.user.id;
      final sourceOwnerId = const Uuid().v4();
      final sourceHabitId = const Uuid().v4();
      final sourceNoteId = const Uuid().v4();
      final now = DateTime.utc(2026, 7, 27, 14);
      final transport = SupabaseSyncTransport(client);

      final linkedDatabase = ZentraDatabase(NativeDatabase.memory());
      final runtime = LocalPersistenceRuntime(
        preferences: await SharedPreferences.getInstance(),
        database: linkedDatabase,
      );
      await runtime.initialize();
      await runtime.profileRepositoryFor(sourceOwnerId).saveProfile(
            UserProfile(
              id: sourceOwnerId,
              name: 'Uri vinculado',
              createdAt: now,
            ),
          );
      await runtime.habitRepositoryFor(sourceOwnerId).saveHabit(
            Habit(
              id: sourceHabitId,
              title: 'Respirar antes de sincronizar',
              category: Category.foco,
              frequency: Frequency.daily(),
              createdAt: now,
            ),
          );
      await DriftNoteRepository.forOwner(
        linkedDatabase,
        ownerId: sourceOwnerId,
      ).upsertNote(
        Note(
          id: sourceNoteId,
          userId: sourceOwnerId,
          title: 'Nota local preservada',
          body: 'También debe viajar por el transporte remoto.',
          createdAt: now,
          updatedAt: now,
          accentKey: 'lavender',
        ),
      );

      final preview = await runtime.previewCloudLink(sourceOwnerId);
      expect(preview.counts['habits'], 1);
      expect(preview.counts['notes'], 1);
      runtime.prepareCloudOwner(remoteOwnerId);
      final coordinator = SyncCoordinator(
        ownerId: remoteOwnerId,
        workspace: runtime.syncWorkspaceFor(remoteOwnerId),
        transport: transport,
        clock: () => now,
      );
      expect(
        (await coordinator.syncNow()).state.experienceState,
        SyncExperienceState.synced,
        reason: coordinator.state.toJson().toString(),
      );

      final linked = await runtime.migrateLocalOwnerToCloud(
        sourceOwnerId: sourceOwnerId,
        remoteOwnerId: remoteOwnerId,
      );
      expect(linked.remoteWasEmpty, isTrue);
      expect((await runtime.exportOwner(sourceOwnerId)).habits, hasLength(1));
      expect(
        await DriftNoteRepository.forOwner(
          linkedDatabase,
          ownerId: sourceOwnerId,
        ).getNotes(),
        hasLength(1),
      );
      final uploaded = await coordinator.syncNow();
      expect(
        uploaded.state.experienceState,
        SyncExperienceState.synced,
        reason: uploaded.state.toJson().toString(),
      );
      expect(uploaded.pushedMutations, 4);
      await linkedDatabase.close();

      final freshDatabase = ZentraDatabase(NativeDatabase.memory());
      final freshCoordinator = SyncCoordinator(
        ownerId: remoteOwnerId,
        workspace: DriftSyncWorkspace(
          database: freshDatabase,
          ownerId: remoteOwnerId,
        ),
        transport: transport,
        clock: () => now.add(const Duration(minutes: 1)),
      );
      final downloaded = await freshCoordinator.syncNow();
      expect(downloaded.state.experienceState, SyncExperienceState.synced);
      expect(downloaded.pulledChanges, 4);
      final freshCore = DriftCoreRepository.forOwner(
        freshDatabase,
        ownerId: remoteOwnerId,
      );
      expect(
        (await freshCore.getHabits()).single.title,
        'Respirar antes de sincronizar',
      );
      expect((await freshCore.loadProfile())?.name, 'Uri vinculado');
      final freshNotes = DriftNoteRepository.forOwner(
        freshDatabase,
        ownerId: remoteOwnerId,
      );
      expect((await freshNotes.getNote(sourceNoteId))?.title, isNull);
      expect(
        (await freshNotes.getNotes()).single.title,
        'Nota local preservada',
      );

      await freshDatabase.close();
      client.dispose();
    },
    skip: canRun
        ? false
        : 'Set SUPABASE_TEST_URL and SUPABASE_TEST_PUBLISHABLE_KEY.',
  );
}

Future<void> _waitUntil(
  Future<bool> Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TestFailure(reason);
}
