// ═══════════════════════════════════════════════════════════════════
// SOCIAL.DART — Social Feature Data Models
// Friend, ActivityShare, Reaction, Competition models.
// Maps to friends, activity_shares, reactions, competitions tables.
// See SPEC.md §14.6 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'social.freezed.dart';
part 'social.g.dart';

/// A friendship relationship between two users.
@freezed
class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String userId,    // Requester
    required String friendId,  // Recipient
    required String status,    // 'pending', 'accepted', 'declined'
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) =>
      _$FriendFromJson(json);
}

/// Sharing configuration for an activity or routine with a friend.
@freezed
class ActivityShare with _$ActivityShare {
  const factory ActivityShare({
    required String id,
    required String userId,       // Owner
    String? activityId,           // Set when sharing an activity
    String? routineId,            // Set when sharing a routine
    String? sharedWith,           // Specific friend ID, or null = all friends
    @Default(false) bool isPrivateForViewer, // Recipient can blur on their device
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _ActivityShare;

  factory ActivityShare.fromJson(Map<String, dynamic> json) =>
      _$ActivityShareFromJson(json);
}

/// An encouragement reaction sent to a friend on a shared activity.
@freezed
class Reaction with _$Reaction {
  const factory Reaction({
    required String id,
    required String senderId,
    required String recipientId,
    required String activityId,
    required String reactionType,  // 'emoji' or 'message'
    required String reactionValue, // The emoji or canned message text
    required DateTime createdAt,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}

/// A competition challenge between users.
@freezed
class Competition with _$Competition {
  const factory Competition({
    required String id,
    required String creatorId,
    required String name,
    required Map<String, dynamic> activityConfig,
    Map<String, dynamic>? rules,
    @Default('private') String visibility, // 'public' or 'private'
    @Default('upcoming') String status,    // 'upcoming', 'active', 'completed'
    required DateTime startDate,
    required DateTime endDate,             // Required, max 3 months
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Competition;

  factory Competition.fromJson(Map<String, dynamic> json) =>
      _$CompetitionFromJson(json);
}

/// A user's participation in a competition.
@freezed
class CompetitionParticipant with _$CompetitionParticipant {
  const factory CompetitionParticipant({
    required String id,
    required String competitionId,
    required String userId,
    required DateTime joinedAt,
    DateTime? deletedAt,
  }) = _CompetitionParticipant;

  factory CompetitionParticipant.fromJson(Map<String, dynamic> json) =>
      _$CompetitionParticipantFromJson(json);
}

/// An entry submitted to a competition.
@freezed
class CompetitionEntry with _$CompetitionEntry {
  const factory CompetitionEntry({
    required String id,
    required String competitionId,
    required String userId,
    String? personalEntryId, // Links to personal entry if dual-tracking
    String? source,          // V2: verification source
    String? externalId,      // V2: external source ID
    @Default({}) Map<String, dynamic> fieldValues,
    required DateTime loggedAt,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _CompetitionEntry;

  factory CompetitionEntry.fromJson(Map<String, dynamic> json) =>
      _$CompetitionEntryFromJson(json);
}
