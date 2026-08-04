import 'package:drift/drift.dart';

@DataClassName('NoteRow')
@TableIndex(
  name: 'note_owner_archive_updated_idx',
  columns: {#userId, #isArchived, #updatedAt},
)
class NoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get accentKey => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get formatVersion => integer().withDefault(const Constant(1))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'notes';
}

@DataClassName('NoteTagRow')
@TableIndex(
  name: 'note_tag_owner_value_idx',
  columns: {#userId, #value},
)
class NoteTagEntries extends Table {
  TextColumn get noteId => text().references(
        NoteEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {noteId, value};

  @override
  String get tableName => 'note_tags';
}

@DataClassName('NoteReminderRow')
@TableIndex(
  name: 'note_reminder_owner_schedule_idx',
  columns: {#userId, #status, #scheduledAtUtc},
)
class NoteReminderEntries extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(
        NoteEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text()();
  DateTimeColumn get scheduledAtUtc => dateTime()();
  TextColumn get timezoneName => text()();
  TextColumn get status => text()();
  IntColumn get notificationId => integer()();
  TextColumn get privacyMode => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {noteId},
      ];

  @override
  String get tableName => 'note_reminders';
}

@DataClassName('NoteReviewRow')
@TableIndex(
  name: 'note_review_owner_reviewed_idx',
  columns: {#userId, #reviewedAt},
)
class NoteReviewEntries extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(
        NoteEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text()();
  DateTimeColumn get reviewedAt => dateTime()();
  TextColumn get focusSessionId => text().nullable()();
  TextColumn get outcome => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'note_reviews';
}
