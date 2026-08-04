import 'package:drift/drift.dart';

@DataClassName('ProfileRow')
@TableIndex(
  name: 'profile_owner_idx',
  columns: {#userId},
  unique: true,
)
class ProfileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'profiles';
}

@DataClassName('HabitRow')
@TableIndex(
  name: 'habit_owner_archive_created_idx',
  columns: {#userId, #isArchived, #createdAt},
)
class HabitEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isOneTime => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'habits';
}

@DataClassName('HabitScheduleRow')
@TableIndex(
  name: 'habit_schedule_owner_habit_idx',
  columns: {#userId, #habitId},
  unique: true,
)
class HabitScheduleEntries extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(
        HabitEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text()();
  BoolColumn get isWeekly => boolean()();
  TextColumn get daysOfWeekJson => text()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();
  TextColumn get timeZone => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'habit_schedules';
}

@DataClassName('HabitDayStateRow')
@TableIndex(
  name: 'habit_day_state_owner_date_idx',
  columns: {#userId, #localDate},
)
class HabitDayStateEntries extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(
        HabitEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text()();
  TextColumn get localDate => text()();
  BoolColumn get completed => boolean()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, habitId, localDate},
      ];

  @override
  String get tableName => 'habit_day_states';
}

@DataClassName('CompletedTaskRow')
@TableIndex(
  name: 'completed_task_owner_completed_idx',
  columns: {#userId, #completedAt},
)
class CompletedTaskEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get wasOneTime => boolean()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'completed_tasks';
}

@DataClassName('FocusSessionRow')
@TableIndex(
  name: 'focus_session_owner_started_idx',
  columns: {#userId, #startedAt},
)
class FocusSessionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get cyclesCompleted => integer()();
  IntColumn get totalMinutes => integer()();
  BoolColumn get isCompleted => boolean()();
  TextColumn get noteId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String get tableName => 'focus_sessions';
}

@DataClassName('FocusProgressRow')
class FocusProgressEntries extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};

  @override
  String get tableName => 'focus_progress';
}

@DataClassName('UserPreferenceRow')
class UserPreferenceEntries extends Table {
  TextColumn get userId => text()();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get serverRevision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {userId};

  @override
  String get tableName => 'user_preferences';
}
