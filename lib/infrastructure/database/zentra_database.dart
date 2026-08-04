import 'package:drift/drift.dart';

import 'core_tables.dart';
import 'note_tables.dart';
import 'sync_tables.dart';

part 'zentra_database.g.dart';

@DriftDatabase(
  tables: [
    NoteEntries,
    NoteTagEntries,
    NoteReminderEntries,
    NoteReviewEntries,
    ProfileEntries,
    HabitEntries,
    HabitScheduleEntries,
    HabitDayStateEntries,
    CompletedTaskEntries,
    FocusSessionEntries,
    FocusProgressEntries,
    UserPreferenceEntries,
    SyncOutboxEntries,
    SyncStateEntries,
    SyncConflictEntries,
    LocalOwnerLinkEntries,
    LocalNotificationBindingEntries,
    LocalMigrationStateEntries,
  ],
)
class ZentraDatabase extends _$ZentraDatabase {
  ZentraDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(profileEntries);
            await migrator.createTable(habitEntries);
            await migrator.createTable(habitScheduleEntries);
            await migrator.createTable(habitDayStateEntries);
            await migrator.createTable(completedTaskEntries);
            await migrator.createTable(focusSessionEntries);
            await migrator.createTable(focusProgressEntries);
            await migrator.createTable(userPreferenceEntries);
            await migrator.createTable(syncOutboxEntries);
            await migrator.createTable(syncStateEntries);
            await migrator.createTable(syncConflictEntries);
            await migrator.createTable(localOwnerLinkEntries);
            await migrator.createTable(localNotificationBindingEntries);
            await migrator.createTable(localMigrationStateEntries);
            await migrator.createIndex(profileOwnerIdx);
            await migrator.createIndex(habitOwnerArchiveCreatedIdx);
            await migrator.createIndex(habitScheduleOwnerHabitIdx);
            await migrator.createIndex(habitDayStateOwnerDateIdx);
            await migrator.createIndex(completedTaskOwnerCompletedIdx);
            await migrator.createIndex(focusSessionOwnerStartedIdx);
            await migrator.createIndex(syncOutboxOwnerLifecycleAttemptIdx);
            await migrator.createIndex(syncConflictOwnerCreatedIdx);
            await migrator.createIndex(localOwnerRemoteUserIdx);
            await migrator.createIndex(localNotificationOwnerDeviceIdx);
            await migrator.createIndex(localMigrationOwnerStatusIdx);
          }
          if (from < 3) {
            await migrator.addColumn(noteEntries, noteEntries.deletedAt);
            await migrator.addColumn(noteEntries, noteEntries.version);
            await migrator.addColumn(
              noteEntries,
              noteEntries.serverRevision,
            );
            await migrator.addColumn(
              noteReminderEntries,
              noteReminderEntries.deletedAt,
            );
            await migrator.addColumn(
              noteReminderEntries,
              noteReminderEntries.version,
            );
            await migrator.addColumn(
              noteReminderEntries,
              noteReminderEntries.serverRevision,
            );
            await migrator.addColumn(
              noteReviewEntries,
              noteReviewEntries.deletedAt,
            );
            await migrator.addColumn(
              noteReviewEntries,
              noteReviewEntries.version,
            );
            await migrator.addColumn(
              noteReviewEntries,
              noteReviewEntries.serverRevision,
            );
          }
          if (from >= 2 && from < 4) {
            await migrator.addColumn(
              completedTaskEntries,
              completedTaskEntries.deletedAt,
            );
            await migrator.addColumn(
              completedTaskEntries,
              completedTaskEntries.version,
            );
            await migrator.addColumn(
              completedTaskEntries,
              completedTaskEntries.serverRevision,
            );
          }
          if (from >= 2 && from < 5) {
            await migrator.createTable(userPreferenceEntries);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
