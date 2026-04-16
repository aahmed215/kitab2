// ═══════════════════════════════════════════════════════════════════
// DRIFT_TABLES.DART — Local SQLite Table Definitions (Drift)
// Mirrors the Supabase cloud schema exactly.
// Same tables, same columns, same constraints.
// This enables seamless sync — rows are the same shape in both DBs.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';

/// ═══ CATEGORIES ═══
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('📁'))();
  TextColumn get color => text().withDefault(const Constant('#0D7377'))();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ACTIVITIES (Templates) ═══
class ActivitiesTable extends Table {
  @override
  String get tableName => 'activities';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isArchived => boolean().named('is_archived').withDefault(const Constant(false))();
  BoolColumn get isPrivate => boolean().named('is_private').withDefault(const Constant(false))();
  TextColumn get schedule => text().nullable()(); // JSONB stored as text
  TextColumn get fields => text().withDefault(const Constant('[]'))(); // JSONB
  TextColumn get goals => text().nullable()(); // JSONB
  TextColumn get primaryGoalId => text().named('primary_goal_id').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ENTRIES (Activity Logs) ═══
class EntriesTable extends Table {
  @override
  String get tableName => 'entries';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text().withDefault(const Constant('Untitled'))();
  TextColumn get activityId => text().named('activity_id').nullable()();
  DateTimeColumn get periodStart => dateTime().named('period_start').nullable()();
  DateTimeColumn get periodEnd => dateTime().named('period_end').nullable()();
  TextColumn get linkType => text().named('link_type').nullable()();
  TextColumn get fieldValues => text().named('field_values').withDefault(const Constant('{}'))(); // JSONB
  TextColumn get timerSegments => text().named('timer_segments').nullable()(); // JSONB
  TextColumn get notes => text().nullable()();
  TextColumn get routineEntryId => text().named('routine_entry_id').nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get externalId => text().named('external_id').nullable()();
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ CONDITION PRESETS ═══
class ConditionPresetsTable extends Table {
  @override
  String get tableName => 'condition_presets';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get label => text()();
  TextColumn get emoji => text()();
  BoolColumn get isSystem => boolean().named('is_system').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ CONDITIONS (Instances) ═══
class ConditionsTable extends Table {
  @override
  String get tableName => 'conditions';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get presetId => text().named('preset_id')();
  TextColumn get label => text()();
  TextColumn get emoji => text()();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ACTIVITY PERIOD STATUSES ═══
class ActivityPeriodStatusesTable extends Table {
  @override
  String get tableName => 'activity_period_statuses';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get activityId => text().named('activity_id')();
  DateTimeColumn get periodStart => dateTime().named('period_start')();
  DateTimeColumn get periodEnd => dateTime().named('period_end')();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get conditionId => text().named('condition_id').nullable()();
  DateTimeColumn get resolvedAt => dateTime().named('resolved_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ GOAL PERIOD STATUSES ═══
class GoalPeriodStatusesTable extends Table {
  @override
  String get tableName => 'goal_period_statuses';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get activityId => text().named('activity_id')();
  TextColumn get goalId => text().named('goal_id')();
  DateTimeColumn get periodStart => dateTime().named('period_start')();
  DateTimeColumn get periodEnd => dateTime().named('period_end')();
  TextColumn get status => text()();
  TextColumn get conditionId => text().named('condition_id').nullable()();
  TextColumn get reasonText => text().named('reason_text').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ USERS ═══
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get username => text().nullable()();
  DateTimeColumn get usernameChangedAt => dateTime().named('username_changed_at').nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().named('avatar_url').nullable()();
  TextColumn get bio => text().nullable()();
  DateTimeColumn get birthday => dateTime().nullable()();
  TextColumn get timezone => text().nullable()();
  TextColumn get settings => text().withDefault(const Constant('{}'))(); // JSONB
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ROUTINES ═══
class RoutinesTable extends Table {
  @override
  String get tableName => 'routines';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isArchived => boolean().named('is_archived').withDefault(const Constant(false))();
  BoolColumn get isPrivate => boolean().named('is_private').withDefault(const Constant(false))();
  TextColumn get activitySequence => text().named('activity_sequence').withDefault(const Constant('[]'))(); // JSONB
  TextColumn get schedule => text().nullable()(); // JSONB
  TextColumn get goals => text().nullable()(); // JSONB
  TextColumn get primaryGoalId => text().named('primary_goal_id').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ROUTINE ENTRIES (Routine Sessions) ═══
class RoutineEntriesTable extends Table {
  @override
  String get tableName => 'routine_entries';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get routineId => text().named('routine_id')();
  DateTimeColumn get startedAt => dateTime().named('started_at').nullable()();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  TextColumn get activeDuration => text().named('active_duration').nullable()(); // Interval as text
  TextColumn get idleDuration => text().named('idle_duration').nullable()(); // Interval as text
  TextColumn get totalDuration => text().named('total_duration').nullable()(); // Interval as text
  IntColumn get activitiesCompleted => integer().named('activities_completed').withDefault(const Constant(0))();
  IntColumn get activitiesTotal => integer().named('activities_total').withDefault(const Constant(0))();
  DateTimeColumn get periodStart => dateTime().named('period_start').nullable()();
  DateTimeColumn get periodEnd => dateTime().named('period_end').nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get conditionId => text().named('condition_id').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ROUTINE PERIOD STATUSES ═══
class RoutinePeriodStatusesTable extends Table {
  @override
  String get tableName => 'routine_period_statuses';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get routineId => text().named('routine_id')();
  DateTimeColumn get periodStart => dateTime().named('period_start')();
  DateTimeColumn get periodEnd => dateTime().named('period_end')();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get conditionId => text().named('condition_id').nullable()();
  DateTimeColumn get resolvedAt => dateTime().named('resolved_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ROUTINE GOAL PERIOD STATUSES ═══
class RoutineGoalPeriodStatusesTable extends Table {
  @override
  String get tableName => 'routine_goal_period_statuses';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get routineId => text().named('routine_id')();
  TextColumn get goalId => text().named('goal_id')();
  DateTimeColumn get periodStart => dateTime().named('period_start')();
  DateTimeColumn get periodEnd => dateTime().named('period_end')();
  TextColumn get status => text()();
  TextColumn get conditionId => text().named('condition_id').nullable()();
  TextColumn get reasonText => text().named('reason_text').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ FRIENDS ═══
class FriendsTable extends Table {
  @override
  String get tableName => 'friends';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')(); // Requester
  TextColumn get friendId => text().named('friend_id')(); // Recipient
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ ACTIVITY SHARES ═══
class ActivitySharesTable extends Table {
  @override
  String get tableName => 'activity_shares';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')(); // Owner
  TextColumn get activityId => text().named('activity_id').nullable()();
  TextColumn get routineId => text().named('routine_id').nullable()();
  TextColumn get sharedWith => text().named('shared_with').nullable()(); // null = all friends
  BoolColumn get isPrivateForViewer => boolean().named('is_private_for_viewer').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ REACTIONS ═══
class ReactionsTable extends Table {
  @override
  String get tableName => 'reactions';

  TextColumn get id => text()();
  TextColumn get senderId => text().named('sender_id')();
  TextColumn get recipientId => text().named('recipient_id')();
  TextColumn get activityId => text().named('activity_id')();
  TextColumn get reactionType => text().named('reaction_type')(); // 'emoji' or 'message'
  TextColumn get reactionValue => text().named('reaction_value')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ COMPETITIONS ═══
class CompetitionsTable extends Table {
  @override
  String get tableName => 'competitions';

  TextColumn get id => text()();
  TextColumn get creatorId => text().named('creator_id')();
  TextColumn get name => text()();
  TextColumn get activityConfig => text().named('activity_config').withDefault(const Constant('{}'))(); // JSONB
  TextColumn get rules => text().nullable()(); // JSONB
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get status => text().withDefault(const Constant('upcoming'))();
  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ COMPETITION PARTICIPANTS ═══
class CompetitionParticipantsTable extends Table {
  @override
  String get tableName => 'competition_participants';

  TextColumn get id => text()();
  TextColumn get competitionId => text().named('competition_id')();
  TextColumn get userId => text().named('user_id')();
  DateTimeColumn get joinedAt => dateTime().named('joined_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ COMPETITION ENTRIES ═══
class CompetitionEntriesTable extends Table {
  @override
  String get tableName => 'competition_entries';

  TextColumn get id => text()();
  TextColumn get competitionId => text().named('competition_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get personalEntryId => text().named('personal_entry_id').nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get externalId => text().named('external_id').nullable()();
  TextColumn get fieldValues => text().named('field_values').withDefault(const Constant('{}'))(); // JSONB
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ NOTIFICATIONS ═══
class NotificationsTable extends Table {
  @override
  String get tableName => 'notifications';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get actionType => text().named('action_type').nullable()();
  TextColumn get actionData => text().named('action_data').nullable()(); // JSONB
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ USER CHARTS ═══
class UserChartsTable extends Table {
  @override
  String get tableName => 'user_charts';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get chartType => text().named('chart_type')();
  TextColumn get dataSourceType => text().named('data_source_type')();
  TextColumn get dataSourceId => text().named('data_source_id').nullable()();
  TextColumn get measure => text()();
  TextColumn get measureFieldId => text().named('measure_field_id').nullable()();
  TextColumn get calculation => text().withDefault(const Constant('count'))();
  TextColumn get groupBy => text().named('group_by').withDefault(const Constant('daily'))();
  TextColumn get periodType => text().named('period_type').withDefault(const Constant('this_month'))();
  DateTimeColumn get periodStart => dateTime().named('period_start').nullable()();
  DateTimeColumn get periodEnd => dateTime().named('period_end').nullable()();
  IntColumn get periodHijriYear => integer().named('period_hijri_year').nullable()();
  BoolColumn get showConditions => boolean().named('show_conditions').withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().named('is_favorite').withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ USER REPORTS ═══
class UserReportsTable extends Table {
  @override
  String get tableName => 'user_reports';

  TextColumn get id => text()();
  TextColumn get reporterId => text().named('reporter_id')();
  TextColumn get reportedId => text().named('reported_id')();
  TextColumn get reason => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ BLOCKED USERS ═══
class BlockedUsersTable extends Table {
  @override
  String get tableName => 'blocked_users';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')(); // The blocker
  TextColumn get blockedId => text().named('blocked_id')(); // The blocked user
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ SYNC QUEUE (Local Only) ═══
/// Tracks local changes that need to be pushed to the cloud.
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payload => text()(); // Full record data as JSON
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ═══ LOCAL META (Local Only) ═══
/// Key-value store for local app state.
class LocalMetaTable extends Table {
  @override
  String get tableName => 'local_meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
