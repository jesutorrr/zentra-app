import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/domain/auth_models.dart';
import 'package:zentra/domain/backup_gateways.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/infrastructure/local_backup_service.dart';
import 'package:zentra/infrastructure/shared_preferences_account_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('export preserves the versioned JSON contract and note owner', () async {
    final exportedAt = DateTime.utc(2026, 7, 26, 18);
    const ownerId = 'owner-export';
    final account = _account(ownerId, username: 'Uri');
    final profile = {
      'id': ownerId,
      'name': 'Uri',
      'createdAt': exportedAt.toIso8601String(),
    };
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    await accountRepository.saveCurrentAccount(account);
    await accountRepository.saveProfile(ownerId, profile);
    await preferences.setString(
      'habits_$ownerId',
      jsonEncode([
        {'id': 'habit-1'},
      ]),
    );
    await preferences.setString(
      'habit_logs_$ownerId',
      jsonEncode([
        {'id': 'log-1'},
      ]),
    );
    await preferences.setString(
      'pomodoro_activities_$ownerId',
      jsonEncode([
        {'id': 'activity-1'},
      ]),
    );
    await preferences.setString(
      'completed_tasks_$ownerId',
      jsonEncode([
        {'id': 'task-1'},
      ]),
    );
    await preferences.setInt('pomodoro_total_$ownerId', 9);
    await preferences.setInt('pomodoro_today_$ownerId', 2);
    await preferences.setInt('pomodoro_total_minutes_$ownerId', 225);
    await preferences.setInt('pomodoro_today_minutes_$ownerId', 50);
    await preferences.setString(
      'pomodoro_first_date_$ownerId',
      '2026-07-01T00:00:00.000Z',
    );
    await preferences.setString(
      'pomodoro_last_date_$ownerId',
      '2026-07-26T00:00:00.000Z',
    );
    await preferences.setString(
      'pomodoro_focus_progress_$ownerId',
      jsonEncode({
        'version': 1,
        'totalPomodoros': 11,
        'todayPomodoros': 3,
        'totalMinutes': 275,
        'todayMinutes': 75,
        'firstPomodoroDate': '2026-07-01T00:00:00.000Z',
        'lastPomodoroDate': '2026-07-26T00:00:00.000Z',
        'awardedSessionIds': ['focus-1'],
        'pendingNoteReviews': [
          {
            'sessionId': 'focus-2',
            'noteId': 'note-1',
            'reviewedAt': '2026-07-26T18:00:00.000Z',
          },
        ],
      }),
    );

    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final noteRepository = DriftNoteRepository(database);
    noteRepository.setCurrentUser(ownerId);
    await noteRepository.upsertNote(
      Note(
        id: 'note-1',
        userId: ownerId,
        title: 'Migración',
        body: 'Separar el backup de SessionController',
        createdAt: exportedAt,
        updatedAt: exportedAt,
        accentKey: 'focus',
      ),
    );
    noteRepository.setCurrentUser('previous-owner');

    final fileGateway = _FakeBackupFileGateway();
    final service = LocalBackupService(
      accountRepository: accountRepository,
      fileGateway: fileGateway,
      appVersionGateway: const _FakeAppVersionGateway('2.0.0+25'),
      backupProtector: const _PassthroughBackupProtector(),
      noteRepository: noteRepository,
      preferences: preferences,
      clock: () => exportedAt,
    );

    final path = await service.exportBackup(
      userId: ownerId,
      passphrase: 'a-secure-test-passphrase',
    );

    expect(
      path,
      '/fake/zentra_backup_2026-07-26T18-00-00.json',
    );
    expect(
      fileGateway.savedFileName,
      'zentra_backup_2026-07-26T18-00-00.json',
    );
    final json = jsonDecode(fileGateway.savedContents!) as Map<String, dynamic>;
    expect(json['backupVersion'], 4);
    expect(json['appVersion'], '2.0.0+25');
    expect(json['exportedAt'], exportedAt.toIso8601String());
    expect((json['user'] as Map<String, dynamic>)['id'], ownerId);
    expect(json['user'], isNot(contains('passwordHash')));
    expect(json['profile'], profile);
    expect(json['habits'], [
      {'id': 'habit-1'},
    ]);
    expect(json['logs'], [
      {'id': 'log-1'},
    ]);
    expect(json['pomodoroActivities'], [
      {'id': 'activity-1'},
    ]);
    expect(json['completedTasks'], [
      {'id': 'task-1'},
    ]);
    expect(json['pomodoroStats'], {
      'total': 11,
      'today': 3,
      'totalMinutes': 275,
      'todayMinutes': 75,
      'firstDate': '2026-07-01T00:00:00.000Z',
      'lastDate': '2026-07-26T00:00:00.000Z',
      'awardedSessionIds': ['focus-1'],
      'pendingNoteReviews': [
        {
          'sessionId': 'focus-2',
          'noteId': 'note-1',
          'reviewedAt': '2026-07-26T18:00:00.000Z',
        },
      ],
    });
    final noteSnapshot = json['noteSnapshot'] as Map<String, dynamic>;
    expect(noteSnapshot['ownerId'], ownerId);
    expect(noteSnapshot['notes'], hasLength(1));
    expect(noteRepository.currentUserId, 'previous-owner');
  });

  test('select accepts legacy JSON and returns null when picker is cancelled',
      () async {
    final exportedAt = DateTime.utc(2026, 7, 20);
    final account = _account('legacy-owner');
    final legacyJson = jsonEncode({
      'user': account.toJson(),
      'profile': <String, dynamic>{},
      'habits': <Map<String, dynamic>>[],
      'logs': <Map<String, dynamic>>[],
      'exportedAt': exportedAt.toIso8601String(),
    });
    final preferences = await SharedPreferences.getInstance();
    final fileGateway = _FakeBackupFileGateway(selectedContents: legacyJson);
    final service = LocalBackupService(
      accountRepository: SharedPreferencesAccountRepository(
        preferences: preferences,
      ),
      fileGateway: fileGateway,
      appVersionGateway: const _FakeAppVersionGateway('unused'),
      preferences: preferences,
    );

    final direct = await service.selectBackup(
      jsonData: legacyJson,
      passphrase: '',
    );

    expect(direct?.user.id, account.id);
    expect(direct?.appVersion, '1.0.0');
    expect(direct?.pomodoroActivities, isEmpty);
    expect(direct?.completedTasks, isEmpty);
    expect(direct?.pomodoroStats, isEmpty);
    expect(direct?.noteSnapshot, isEmpty);
    expect(fileGateway.selectionCount, 0);

    final selected = await service.selectBackup(passphrase: '');
    expect(selected?.user.id, account.id);
    expect(fileGateway.selectionCount, 1);

    fileGateway.selectedContents = null;
    expect(await service.selectBackup(passphrase: ''), isNull);
    expect(fileGateway.selectionCount, 2);
  });

  test('restore replaces owner data and restores the previous note owner',
      () async {
    final restoredAt = DateTime.utc(2026, 7, 26, 19);
    const targetOwnerId = 'restored-owner';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('pomodoro_today_$targetOwnerId', 99);
    await preferences.setString(
      'pomodoro_last_date_$targetOwnerId',
      'stale',
    );
    await preferences.setString(
      'pomodoro_focus_progress_$targetOwnerId',
      jsonEncode({
        'version': 1,
        'totalPomodoros': 99,
        'todayPomodoros': 99,
        'totalMinutes': 2475,
        'todayMinutes': 2475,
        'lastPomodoroDate': 'stale',
        'firstPomodoroDate': 'stale',
        'awardedSessionIds': ['stale-session'],
        'pendingNoteReviews': const [],
      }),
    );
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final noteRepository = DriftNoteRepository(database)
      ..setCurrentUser('previous-owner');
    final note = Note(
      id: 'restored-note',
      userId: 'backup-owner',
      title: 'Respaldada',
      body: 'Debe cambiar de owner',
      createdAt: restoredAt,
      updatedAt: restoredAt,
      accentKey: 'calm',
    );
    final backup = BackupData(
      user: _account(targetOwnerId),
      profile: {
        'id': targetOwnerId,
        'name': 'Uri restaurado',
      },
      habits: const [
        {'id': 'habit-restored'},
      ],
      logs: const [],
      pomodoroActivities: const [],
      completedTasks: const [],
      pomodoroStats: const {
        'total': 4,
        'totalMinutes': 100,
      },
      noteSnapshot: NoteOwnerSnapshot(
        ownerId: 'backup-owner',
        exportedAt: restoredAt,
        notes: [note],
        reminders: const [],
        reviews: const [],
      ).toJson().cast<String, dynamic>(),
      exportedAt: restoredAt,
      appVersion: '2.0.0+25',
    );
    final service = LocalBackupService(
      accountRepository: accountRepository,
      fileGateway: _FakeBackupFileGateway(),
      appVersionGateway: const _FakeAppVersionGateway('unused'),
      noteRepository: noteRepository,
      preferences: preferences,
    );

    final result = await service.restoreBackup(
      backup,
      currentUser: null,
      accounts: const [],
      preserveCurrentUser: false,
    );

    expect(result.targetUserId, targetOwnerId);
    expect(result.currentUser.id, targetOwnerId);
    expect(result.accounts.single.id, targetOwnerId);
    expect(result.restoredAccount, isTrue);
    expect((await accountRepository.loadCurrentAccount())?.id, targetOwnerId);
    expect(await accountRepository.loadActiveSessionUserId(), targetOwnerId);
    expect(
      await accountRepository.loadProfile(targetOwnerId),
      backup.profile,
    );
    expect(
      jsonDecode(preferences.getString('habits_$targetOwnerId')!),
      backup.habits,
    );
    expect(
      preferences.getString('pomodoro_activities_$targetOwnerId'),
      '[]',
    );
    expect(preferences.getString('completed_tasks_$targetOwnerId'), '[]');
    expect(preferences.getInt('pomodoro_total_$targetOwnerId'), 4);
    expect(preferences.getInt('pomodoro_total_minutes_$targetOwnerId'), 100);
    expect(preferences.containsKey('pomodoro_today_$targetOwnerId'), isFalse);
    expect(
      preferences.containsKey('pomodoro_last_date_$targetOwnerId'),
      isFalse,
    );
    expect(
      jsonDecode(
        preferences.getString(
          'pomodoro_focus_progress_$targetOwnerId',
        )!,
      ),
      {
        'version': 1,
        'totalPomodoros': 4,
        'todayPomodoros': 0,
        'totalMinutes': 100,
        'todayMinutes': 0,
        'lastPomodoroDate': null,
        'firstPomodoroDate': null,
        'awardedSessionIds': const [],
        'pendingNoteReviews': const [],
      },
    );
    expect(noteRepository.currentUserId, 'previous-owner');

    noteRepository.setCurrentUser(targetOwnerId);
    final restoredNotes = await noteRepository.getNotes();
    expect(restoredNotes.single.id, note.id);
    expect(restoredNotes.single.userId, targetOwnerId);
  });

  test('preserveCurrentUser imports activity without replacing the account',
      () async {
    final exportedAt = DateTime.utc(2026, 7, 26, 20);
    final currentAccount = _account('current-owner', username: 'Actual');
    final backup = BackupData(
      user: _account('backup-owner', username: 'Respaldo'),
      profile: const {'name': 'No debe reemplazar el perfil'},
      habits: const [
        {'id': 'habit-from-backup'},
      ],
      logs: const [],
      pomodoroStats: const {
        'total': 12,
        'today': 2,
        'totalMinutes': 300,
        'todayMinutes': 50,
        'firstDate': '2026-07-01T00:00:00.000Z',
        'lastDate': '2026-07-26T00:00:00.000Z',
      },
      exportedAt: exportedAt,
      appVersion: '2.0.0+25',
    );
    final preferences = await SharedPreferences.getInstance();
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    await accountRepository.saveCurrentAccount(currentAccount);
    await accountRepository.saveAccounts([currentAccount]);
    await accountRepository.saveProfile(
      currentAccount.id,
      const {'name': 'Perfil actual'},
    );
    await preferences.setString(
      'pomodoro_focus_progress_${currentAccount.id}',
      jsonEncode({
        'version': 1,
        'totalPomodoros': 99,
        'todayPomodoros': 99,
        'totalMinutes': 2475,
        'todayMinutes': 2475,
        'lastPomodoroDate': 'stale',
        'firstPomodoroDate': 'stale',
        'awardedSessionIds': ['stale-session'],
        'pendingNoteReviews': const [],
      }),
    );
    final service = LocalBackupService(
      accountRepository: accountRepository,
      fileGateway: _FakeBackupFileGateway(),
      appVersionGateway: const _FakeAppVersionGateway('unused'),
      preferences: preferences,
    );

    final result = await service.restoreBackup(
      backup,
      currentUser: currentAccount,
      accounts: [currentAccount],
      preserveCurrentUser: true,
    );

    expect(result.targetUserId, currentAccount.id);
    expect(result.currentUser.id, currentAccount.id);
    expect(result.accounts.single.id, currentAccount.id);
    expect(result.restoredAccount, isFalse);
    expect(
      (await accountRepository.loadCurrentAccount())?.id,
      currentAccount.id,
    );
    expect(
      await accountRepository.loadProfile(currentAccount.id),
      const {'name': 'Perfil actual'},
    );
    expect(
      jsonDecode(preferences.getString('habits_${currentAccount.id}')!),
      backup.habits,
    );
    final focusProgress = jsonDecode(
      preferences.getString(
        'pomodoro_focus_progress_${currentAccount.id}',
      )!,
    ) as Map<String, dynamic>;
    expect(focusProgress['totalPomodoros'], 12);
    expect(focusProgress['todayPomodoros'], 2);
    expect(focusProgress['totalMinutes'], 300);
    expect(focusProgress['todayMinutes'], 50);
    expect(focusProgress['awardedSessionIds'], isEmpty);
  });

  test('restore puts the previous note owner back when note import fails',
      () async {
    final exportedAt = DateTime.utc(2026, 7, 26, 21);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'habits_target-owner',
      '[{"id":"original-habit"}]',
    );
    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final noteRepository = DriftNoteRepository(database)
      ..setCurrentUser('previous-owner');
    final accountRepository = SharedPreferencesAccountRepository(
      preferences: preferences,
    );
    final service = LocalBackupService(
      accountRepository: accountRepository,
      fileGateway: _FakeBackupFileGateway(),
      appVersionGateway: const _FakeAppVersionGateway('unused'),
      noteRepository: noteRepository,
      preferences: preferences,
    );
    final backup = BackupData(
      user: _account('target-owner'),
      profile: const {},
      habits: const [],
      logs: const [],
      noteSnapshot: {
        'schemaVersion': 2,
        'ownerId': 'backup-owner',
        'exportedAt': exportedAt.toIso8601String(),
        'notes': const [],
        'reminders': const [],
        'reviews': const [],
      },
      exportedAt: exportedAt,
      appVersion: '2.0.0+25',
    );

    await expectLater(
      service.restoreBackup(
        backup,
        currentUser: null,
        accounts: const [],
        preserveCurrentUser: false,
      ),
      throwsStateError,
    );

    expect(noteRepository.currentUserId, 'previous-owner');
    expect(
      preferences.getString('habits_target-owner'),
      '[{"id":"original-habit"}]',
    );
    expect(
      preferences.containsKey('pomodoro_focus_progress_target-owner'),
      isFalse,
    );
    expect(await accountRepository.loadCurrentAccount(), isNull);
  });

  test('restore rolls back preferences, account and notes after a late failure',
      () async {
    final restoredAt = DateTime.utc(2026, 7, 26, 22);
    const originalOwnerId = 'original-owner';
    const targetOwnerId = 'target-owner';
    final preferences = await SharedPreferences.getInstance();
    final originalAccount = _account(originalOwnerId, username: 'Original');
    final targetAccount = _account(targetOwnerId, username: 'Backup');
    final accountRepository = _FailOnceActiveSessionAccountRepository(
      preferences: preferences,
    );
    await accountRepository.saveAccounts([originalAccount]);
    await accountRepository.saveCurrentAccount(originalAccount);
    await accountRepository.saveActiveSessionUserId(originalOwnerId);
    await accountRepository.saveProfile(
      targetOwnerId,
      const {'name': 'Target original'},
    );
    await preferences.setString(
      'habits_$targetOwnerId',
      '[{"id":"original-habit"}]',
    );
    await preferences.setInt('pomodoro_total_$targetOwnerId', 8);
    await preferences.setString(
      'pomodoro_focus_progress_$targetOwnerId',
      jsonEncode({
        'version': 1,
        'totalPomodoros': 8,
        'todayPomodoros': 1,
        'totalMinutes': 200,
        'todayMinutes': 25,
        'lastPomodoroDate': '2026-07-25T00:00:00.000Z',
        'firstPomodoroDate': '2026-07-01T00:00:00.000Z',
        'awardedSessionIds': const [],
        'pendingNoteReviews': const [],
      }),
    );

    final database = ZentraDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final noteRepository = DriftNoteRepository(database);
    noteRepository.setCurrentUser(targetOwnerId);
    await noteRepository.upsertNote(
      Note(
        id: 'original-note',
        userId: targetOwnerId,
        title: 'Original',
        body: 'Debe sobrevivir al rollback',
        createdAt: restoredAt,
        updatedAt: restoredAt,
        accentKey: 'calm',
      ),
    );
    noteRepository.setCurrentUser('previous-owner');

    final backup = BackupData(
      user: targetAccount,
      profile: const {'name': 'Desde backup'},
      habits: const [
        {'id': 'backup-habit'},
      ],
      logs: const [],
      pomodoroStats: const {
        'total': 20,
        'today': 3,
        'totalMinutes': 500,
        'todayMinutes': 75,
      },
      noteSnapshot: NoteOwnerSnapshot(
        ownerId: 'backup-owner',
        exportedAt: restoredAt,
        notes: [
          Note(
            id: 'backup-note',
            userId: 'backup-owner',
            title: 'Backup',
            body: 'No debe quedar después del rollback',
            createdAt: restoredAt,
            updatedAt: restoredAt,
            accentKey: 'focus',
          ),
        ],
        reminders: const [],
        reviews: const [],
      ).toJson().cast<String, dynamic>(),
      exportedAt: restoredAt,
      appVersion: '2.0.0+25',
    );
    final service = LocalBackupService(
      accountRepository: accountRepository,
      fileGateway: _FakeBackupFileGateway(),
      appVersionGateway: const _FakeAppVersionGateway('unused'),
      noteRepository: noteRepository,
      preferences: preferences,
    );
    accountRepository.failNextActiveSessionSave = true;

    await expectLater(
      service.restoreBackup(
        backup,
        currentUser: null,
        accounts: [originalAccount],
        preserveCurrentUser: false,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      (await accountRepository.loadCurrentAccount())?.id,
      originalOwnerId,
    );
    expect(
      (await accountRepository.loadAccounts()).map((user) => user.id),
      [originalOwnerId],
    );
    expect(
      await accountRepository.loadActiveSessionUserId(),
      originalOwnerId,
    );
    expect(
      await accountRepository.loadProfile(targetOwnerId),
      const {'name': 'Target original'},
    );
    expect(
      preferences.getString('habits_$targetOwnerId'),
      '[{"id":"original-habit"}]',
    );
    expect(preferences.getInt('pomodoro_total_$targetOwnerId'), 8);
    expect(
      jsonDecode(
        preferences.getString('pomodoro_focus_progress_$targetOwnerId')!,
      )['totalPomodoros'],
      8,
    );
    expect(noteRepository.currentUserId, 'previous-owner');
    noteRepository.setCurrentUser(targetOwnerId);
    final restoredNotes = await noteRepository.getNotes(includeArchived: true);
    expect(restoredNotes.map((note) => note.id), ['original-note']);
  });
}

LocalUser _account(String id, {String username = 'Uri'}) {
  final createdAt = DateTime.utc(2026, 7, 1);
  return LocalUser(
    id: id,
    username: username,
    createdAt: createdAt,
    lastLogin: createdAt,
  );
}

class _FakeBackupFileGateway implements BackupFileGateway {
  String? selectedContents;
  String? savedContents;
  String? savedFileName;
  int selectionCount = 0;

  _FakeBackupFileGateway({this.selectedContents});

  @override
  Future<String> saveJson({
    required String contents,
    required String fileName,
  }) async {
    savedContents = contents;
    savedFileName = fileName;
    return '/fake/$fileName';
  }

  @override
  Future<String?> selectJson() async {
    selectionCount += 1;
    return selectedContents;
  }
}

class _FakeAppVersionGateway implements AppVersionGateway {
  final String version;

  const _FakeAppVersionGateway(this.version);

  @override
  Future<String> loadAppVersion() async => version;
}

class _PassthroughBackupProtector implements BackupProtector {
  const _PassthroughBackupProtector();

  @override
  Future<String> protect({
    required String plaintext,
    required String passphrase,
  }) async =>
      plaintext;

  @override
  Future<String> unprotect({
    required String storedContents,
    required String passphrase,
  }) async =>
      storedContents;
}

class _FailOnceActiveSessionAccountRepository
    extends SharedPreferencesAccountRepository {
  bool failNextActiveSessionSave = false;

  _FailOnceActiveSessionAccountRepository({
    required SharedPreferences preferences,
  }) : super(preferences: preferences);

  @override
  Future<void> saveActiveSessionUserId(String userId) {
    if (failNextActiveSessionSave) {
      failNextActiveSessionSave = false;
      throw StateError('Injected late restore failure.');
    }
    return super.saveActiveSessionUserId(userId);
  }
}
