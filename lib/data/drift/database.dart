// ═══════════════════════════════════════════════════════════════════
// DATABASE.DART — Drift (SQLite) Database Definition
// Central database class that registers all tables and DAOs.
// Uses lazy_database to open on-demand. Native = file on disk,
// Web = not used (cloud-only via Supabase).
// See SPEC.md §12 for sync architecture.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables/drift_tables.dart';
import 'daos/categories_dao.dart';
import 'daos/activities_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/conditions_dao.dart';
import 'daos/period_statuses_dao.dart';
import 'daos/users_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/social_dao.dart';
import 'daos/notifications_dao.dart';
import 'daos/user_charts_dao.dart';
import 'daos/sync_dao.dart';

part 'database.g.dart';

/// The single Drift database for Kitab.
/// Contains all 24 tables mirroring Supabase + local-only tables.
@DriftDatabase(
  tables: [
    // ─── Core Data ───
    UsersTable,
    CategoriesTable,
    ActivitiesTable,
    EntriesTable,

    // ─── Conditions ───
    ConditionPresetsTable,
    ConditionsTable,

    // ─── Period & Goal Statuses ───
    ActivityPeriodStatusesTable,
    GoalPeriodStatusesTable,

    // ─── Routines ───
    RoutinesTable,
    RoutineEntriesTable,
    RoutinePeriodStatusesTable,
    RoutineGoalPeriodStatusesTable,

    // ─── Social ───
    FriendsTable,
    ActivitySharesTable,
    ReactionsTable,
    CompetitionsTable,
    CompetitionParticipantsTable,
    CompetitionEntriesTable,

    // ─── Insights & Moderation ───
    NotificationsTable,
    UserChartsTable,
    UserReportsTable,
    BlockedUsersTable,

    // ─── Local Only ───
    SyncQueueTable,
    LocalMetaTable,
  ],
  daos: [
    CategoriesDao,
    ActivitiesDao,
    EntriesDao,
    ConditionsDao,
    PeriodStatusesDao,
    UsersDao,
    RoutinesDao,
    SocialDao,
    NotificationsDao,
    UserChartsDao,
    SyncDao,
  ],
)
class KitabDatabase extends _$KitabDatabase {
  KitabDatabase() : super(openConnection());

  /// For testing — accepts any QueryExecutor
  KitabDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future schema migrations go here.
          // For now, V1 → no migrations needed.
        },
      );
}
