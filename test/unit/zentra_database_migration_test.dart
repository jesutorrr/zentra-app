import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';

void main() {
  test('schema 1 notes survive additive schema 2 through 5 migrations',
      () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE notes (
            id TEXT NOT NULL PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            category TEXT NULL,
            accent_key TEXT NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0
              CHECK (is_pinned IN (0, 1)),
            is_archived INTEGER NOT NULL DEFAULT 0
              CHECK (is_archived IN (0, 1)),
            archived_at INTEGER NULL,
            format_version INTEGER NOT NULL DEFAULT 1
          )
        ''');
        raw.execute('''
          CREATE TABLE note_tags (
            note_id TEXT NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
            user_id TEXT NOT NULL,
            value TEXT NOT NULL,
            PRIMARY KEY (note_id, value)
          )
        ''');
        raw.execute('''
          CREATE TABLE note_reminders (
            id TEXT NOT NULL PRIMARY KEY,
            note_id TEXT NOT NULL UNIQUE
              REFERENCES notes (id) ON DELETE CASCADE,
            user_id TEXT NOT NULL,
            scheduled_at_utc INTEGER NOT NULL,
            timezone_name TEXT NOT NULL,
            status TEXT NOT NULL,
            notification_id INTEGER NOT NULL,
            privacy_mode TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        raw.execute('''
          CREATE TABLE note_reviews (
            id TEXT NOT NULL PRIMARY KEY,
            note_id TEXT NOT NULL REFERENCES notes (id) ON DELETE CASCADE,
            user_id TEXT NOT NULL,
            reviewed_at INTEGER NOT NULL,
            focus_session_id TEXT NULL,
            outcome TEXT NOT NULL
          )
        ''');
        raw.execute(
          'CREATE INDEX note_owner_archive_updated_idx '
          'ON notes (user_id, is_archived, updated_at)',
        );
        raw.execute(
          'CREATE INDEX note_tag_owner_value_idx '
          'ON note_tags (user_id, value)',
        );
        raw.execute(
          'CREATE INDEX note_reminder_owner_schedule_idx '
          'ON note_reminders (user_id, status, scheduled_at_utc)',
        );
        raw.execute(
          'CREATE INDEX note_review_owner_reviewed_idx '
          'ON note_reviews (user_id, reviewed_at)',
        );
        raw.execute(
          '''
            INSERT INTO notes (
              id,
              user_id,
              title,
              body,
              created_at,
              updated_at,
              accent_key
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            'note-v1',
            'uri',
            'Antes de Gate 3',
            'Debe sobrevivir',
            DateTime.utc(2026, 7, 25).millisecondsSinceEpoch,
            DateTime.utc(2026, 7, 26).millisecondsSinceEpoch,
            'teal',
          ],
        );
        raw.execute('PRAGMA user_version = 1');
      },
    );
    final database = ZentraDatabase(executor);
    addTearDown(database.close);

    final note = await database.select(database.noteEntries).getSingle();
    final tableRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    final tableNames = tableRows.map((row) => row.read<String>('name')).toSet();
    final indexRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index'",
        )
        .get();
    final indexNames = indexRows.map((row) => row.read<String>('name')).toSet();
    final version =
        await database.customSelect('PRAGMA user_version').getSingle();

    expect(note.id, 'note-v1');
    expect(note.title, 'Antes de Gate 3');
    expect(note.deletedAt, isNull);
    expect(note.version, 1);
    expect(note.serverRevision, 0);
    expect(version.read<int>('user_version'), 5);
    expect(
      tableNames,
      containsAll({
        'profiles',
        'habits',
        'habit_schedules',
        'habit_day_states',
        'completed_tasks',
        'focus_sessions',
        'focus_progress',
        'user_preferences',
        'sync_outbox',
        'sync_state',
        'sync_conflicts',
        'local_owner_links',
        'local_notification_bindings',
        'local_migration_state',
      }),
    );
    expect(
      indexNames,
      containsAll({
        'profile_owner_idx',
        'habit_owner_archive_created_idx',
        'habit_schedule_owner_habit_idx',
        'habit_day_state_owner_date_idx',
        'completed_task_owner_completed_idx',
        'focus_session_owner_started_idx',
        'sync_outbox_owner_lifecycle_attempt_idx',
        'sync_conflict_owner_created_idx',
        'local_owner_remote_user_idx',
        'local_notification_owner_device_idx',
        'local_migration_owner_status_idx',
      }),
    );
  });

  test('schema 3 completed tasks survive additive schema 4 and 5 migrations',
      () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE completed_tasks (
            id TEXT NOT NULL PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            completed_at INTEGER NOT NULL,
            was_one_time INTEGER NOT NULL
              CHECK (was_one_time IN (0, 1))
          )
        ''');
        raw.execute(
          '''
            INSERT INTO completed_tasks (
              id,
              user_id,
              title,
              category,
              completed_at,
              was_one_time
            ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
          [
            'task-v3',
            'uri',
            'Antes de Gate 7',
            'foco',
            DateTime.utc(2026, 7, 27).millisecondsSinceEpoch,
            1,
          ],
        );
        raw.execute('PRAGMA user_version = 3');
      },
    );
    final database = ZentraDatabase(executor);
    addTearDown(database.close);

    final task =
        await database.select(database.completedTaskEntries).getSingle();
    final version =
        await database.customSelect('PRAGMA user_version').getSingle();

    expect(task.id, 'task-v3');
    expect(task.deletedAt, isNull);
    expect(task.version, 1);
    expect(task.serverRevision, 0);
    expect(version.read<int>('user_version'), 5);
  });
}
