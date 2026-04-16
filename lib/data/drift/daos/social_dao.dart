// ═══════════════════════════════════════════════════════════════════
// SOCIAL_DAO.DART — CRUD for friends, shares, reactions, competitions
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'social_dao.g.dart';

@DriftAccessor(tables: [
  FriendsTable,
  ActivitySharesTable,
  ReactionsTable,
  CompetitionsTable,
  CompetitionParticipantsTable,
  CompetitionEntriesTable,
])
class SocialDao extends DatabaseAccessor<KitabDatabase>
    with _$SocialDaoMixin {
  SocialDao(super.db);

  // ─── Friends ───

  /// Watch accepted friends for a user.
  Stream<List<FriendsTableData>> watchAcceptedFriends(String userId) {
    return (select(friendsTable)
          ..where((f) =>
              (f.userId.equals(userId) | f.friendId.equals(userId)) &
              f.status.equals('accepted') &
              f.deletedAt.isNull()))
        .watch();
  }

  /// Get pending friend requests received by a user.
  Future<List<FriendsTableData>> getPendingRequests(String userId) {
    return (select(friendsTable)
          ..where((f) =>
              f.friendId.equals(userId) &
              f.status.equals('pending') &
              f.deletedAt.isNull()))
        .get();
  }

  /// Insert or replace a friend record.
  Future<void> upsertFriend(FriendsTableCompanion friend) {
    return into(friendsTable).insertOnConflictUpdate(friend);
  }

  // ─── Activity Shares ───

  /// Get all active shares for a user (what they're sharing).
  Future<List<ActivitySharesTableData>> getSharesByUser(String userId) {
    return (select(activitySharesTable)
          ..where((s) => s.userId.equals(userId) & s.deletedAt.isNull()))
        .get();
  }

  /// Get shares visible to a specific friend.
  Future<List<ActivitySharesTableData>> getSharesVisibleTo(
      String ownerId, String viewerId) {
    return (select(activitySharesTable)
          ..where((s) =>
              s.userId.equals(ownerId) &
              s.deletedAt.isNull() &
              (s.sharedWith.isNull() | s.sharedWith.equals(viewerId))))
        .get();
  }

  /// Insert or replace a share.
  Future<void> upsertShare(ActivitySharesTableCompanion share) {
    return into(activitySharesTable).insertOnConflictUpdate(share);
  }

  // ─── Reactions ───

  /// Get reactions received by a user.
  Future<List<ReactionsTableData>> getReactionsForUser(String recipientId) {
    return (select(reactionsTable)
          ..where(
              (r) => r.recipientId.equals(recipientId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// Insert a reaction.
  Future<void> insertReaction(ReactionsTableCompanion reaction) {
    return into(reactionsTable).insertOnConflictUpdate(reaction);
  }

  // ─── Competitions ───

  /// Watch competitions a user participates in.
  Stream<List<CompetitionsTableData>> watchByUser(String userId) {
    final participantIds = selectOnly(competitionParticipantsTable)
      ..addColumns([competitionParticipantsTable.competitionId])
      ..where(competitionParticipantsTable.userId.equals(userId) &
          competitionParticipantsTable.deletedAt.isNull());

    return (select(competitionsTable)
          ..where((c) =>
              c.deletedAt.isNull() &
              (c.creatorId.equals(userId) |
                  c.id.isInQuery(participantIds)))
          ..orderBy([(c) => OrderingTerm.desc(c.startDate)]))
        .watch();
  }

  /// Get a single competition by ID.
  Future<CompetitionsTableData?> getCompetitionById(String id) {
    return (select(competitionsTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a competition.
  Future<void> upsertCompetition(CompetitionsTableCompanion competition) {
    return into(competitionsTable).insertOnConflictUpdate(competition);
  }

  /// Insert or replace a participant.
  Future<void> upsertParticipant(
      CompetitionParticipantsTableCompanion participant) {
    return into(competitionParticipantsTable)
        .insertOnConflictUpdate(participant);
  }

  /// Insert or replace a competition entry.
  Future<void> upsertCompetitionEntry(
      CompetitionEntriesTableCompanion entry) {
    return into(competitionEntriesTable).insertOnConflictUpdate(entry);
  }

  /// Get leaderboard entries for a competition.
  Future<List<CompetitionEntriesTableData>> getCompetitionEntries(
      String competitionId) {
    return (select(competitionEntriesTable)
          ..where((e) =>
              e.competitionId.equals(competitionId) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.desc(e.loggedAt)]))
        .get();
  }
}
