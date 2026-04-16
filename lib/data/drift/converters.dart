// ═══════════════════════════════════════════════════════════════════
// CONVERTERS.DART — Drift ↔ Domain Model Converters
// Converts between Drift's generated data classes and our freezed
// domain models. This keeps mapping logic centralized.
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/category.dart' as domain;
import '../models/activity.dart' as domain;
import '../models/entry.dart' as domain;
import '../models/condition.dart' as domain;
import '../models/period_status.dart' as domain;
import '../models/user_profile.dart' as domain;
import '../models/routine.dart' as domain;
import 'database.dart';

// ═══════════════════════════════════════════════════════════════════
// CATEGORY CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension CategoryFromDrift on CategoriesTableData {
  domain.Category toDomain() => domain.Category(
        id: id,
        userId: userId,
        name: name,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension CategoryToDrift on domain.Category {
  CategoriesTableCompanion toCompanion() => CategoriesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
        sortOrder: Value(sortOrder),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension ActivityFromDrift on ActivitiesTableData {
  domain.Activity toDomain() => domain.Activity(
        id: id,
        userId: userId,
        categoryId: categoryId,
        name: name,
        description: description,
        isArchived: isArchived,
        isPrivate: isPrivate,
        schedule: _decodeJsonNullable(schedule),
        fields: _decodeJsonListOfMaps(fields),
        goals: _decodeJsonNullable(goals),
        primaryGoalId: primaryGoalId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension ActivityToDrift on domain.Activity {
  ActivitiesTableCompanion toCompanion() => ActivitiesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        categoryId: Value(categoryId),
        name: Value(name),
        description: Value(description),
        isArchived: Value(isArchived),
        isPrivate: Value(isPrivate),
        schedule: Value(schedule != null ? jsonEncode(schedule) : null),
        fields: Value(jsonEncode(fields)),
        goals: Value(goals != null ? jsonEncode(goals) : null),
        primaryGoalId: Value(primaryGoalId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// ENTRY CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension EntryFromDrift on EntriesTableData {
  domain.Entry toDomain() => domain.Entry(
        id: id,
        userId: userId,
        name: name,
        activityId: activityId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        linkType: linkType,
        fieldValues: _decodeJsonMap(fieldValues),
        timerSegments: _decodeJsonListOfMapsNullable(timerSegments),
        notes: notes,
        routineEntryId: routineEntryId,
        source: source,
        externalId: externalId,
        loggedAt: loggedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension EntryToDrift on domain.Entry {
  EntriesTableCompanion toCompanion() => EntriesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        name: Value(name),
        activityId: Value(activityId),
        periodStart: Value(periodStart),
        periodEnd: Value(periodEnd),
        linkType: Value(linkType),
        fieldValues: Value(jsonEncode(fieldValues)),
        timerSegments: Value(
            timerSegments != null ? jsonEncode(timerSegments) : null),
        notes: Value(notes),
        routineEntryId: Value(routineEntryId),
        source: Value(source),
        externalId: Value(externalId),
        loggedAt: Value(loggedAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// CONDITION CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension ConditionPresetFromDrift on ConditionPresetsTableData {
  domain.ConditionPreset toDomain() => domain.ConditionPreset(
        id: id,
        userId: userId,
        label: label,
        emoji: emoji,
        isSystem: isSystem,
        createdAt: createdAt,
        deletedAt: deletedAt,
      );
}

extension ConditionPresetToDrift on domain.ConditionPreset {
  ConditionPresetsTableCompanion toCompanion() =>
      ConditionPresetsTableCompanion(
        id: Value(id),
        userId: Value(userId),
        label: Value(label),
        emoji: Value(emoji),
        isSystem: Value(isSystem),
        createdAt: Value(createdAt),
        deletedAt: Value(deletedAt),
      );
}

extension ConditionFromDrift on ConditionsTableData {
  domain.Condition toDomain() => domain.Condition(
        id: id,
        userId: userId,
        presetId: presetId,
        label: label,
        emoji: emoji,
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension ConditionToDrift on domain.Condition {
  ConditionsTableCompanion toCompanion() => ConditionsTableCompanion(
        id: Value(id),
        userId: Value(userId),
        presetId: Value(presetId),
        label: Value(label),
        emoji: Value(emoji),
        startDate: Value(startDate),
        endDate: Value(endDate),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// PERIOD STATUS CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension ActivityPeriodStatusFromDrift on ActivityPeriodStatusesTableData {
  domain.ActivityPeriodStatus toDomain() => domain.ActivityPeriodStatus(
        id: id,
        userId: userId,
        activityId: activityId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: status,
        conditionId: conditionId,
        resolvedAt: resolvedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension ActivityPeriodStatusToDrift on domain.ActivityPeriodStatus {
  ActivityPeriodStatusesTableCompanion toCompanion() =>
      ActivityPeriodStatusesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        activityId: Value(activityId),
        periodStart: Value(periodStart),
        periodEnd: Value(periodEnd),
        status: Value(status),
        conditionId: Value(conditionId),
        resolvedAt: Value(resolvedAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

extension GoalPeriodStatusFromDrift on GoalPeriodStatusesTableData {
  domain.GoalPeriodStatus toDomain() => domain.GoalPeriodStatus(
        id: id,
        userId: userId,
        activityId: activityId,
        goalId: goalId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: status,
        conditionId: conditionId,
        reasonText: reasonText,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension GoalPeriodStatusToDrift on domain.GoalPeriodStatus {
  GoalPeriodStatusesTableCompanion toCompanion() =>
      GoalPeriodStatusesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        activityId: Value(activityId),
        goalId: Value(goalId),
        periodStart: Value(periodStart),
        periodEnd: Value(periodEnd),
        status: Value(status),
        conditionId: Value(conditionId),
        reasonText: Value(reasonText),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// USER PROFILE CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension UserProfileFromDrift on UsersTableData {
  domain.UserProfile toDomain() => domain.UserProfile(
        id: id,
        email: email,
        username: username,
        usernameChangedAt: usernameChangedAt,
        name: name,
        avatarUrl: avatarUrl,
        bio: bio,
        birthday: birthday,
        timezone: timezone,
        settings: _decodeJsonMap(settings),
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension UserProfileToDrift on domain.UserProfile {
  UsersTableCompanion toCompanion() => UsersTableCompanion(
        id: Value(id),
        email: Value(email),
        username: Value(username),
        usernameChangedAt: Value(usernameChangedAt),
        name: Value(name),
        avatarUrl: Value(avatarUrl),
        bio: Value(bio),
        birthday: Value(birthday),
        timezone: Value(timezone),
        settings: Value(jsonEncode(settings)),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// ROUTINE CONVERTERS
// ═══════════════════════════════════════════════════════════════════

extension RoutineFromDrift on RoutinesTableData {
  domain.Routine toDomain() => domain.Routine(
        id: id,
        userId: userId,
        categoryId: categoryId,
        name: name,
        description: description,
        isArchived: isArchived,
        isPrivate: isPrivate,
        activitySequence: _decodeJsonListOfMaps(activitySequence),
        schedule: _decodeJsonNullable(schedule),
        goals: _decodeJsonNullable(goals),
        primaryGoalId: primaryGoalId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension RoutineToDrift on domain.Routine {
  RoutinesTableCompanion toCompanion() => RoutinesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        categoryId: Value(categoryId),
        name: Value(name),
        description: Value(description),
        isArchived: Value(isArchived),
        isPrivate: Value(isPrivate),
        activitySequence: Value(jsonEncode(activitySequence)),
        schedule: Value(schedule != null ? jsonEncode(schedule) : null),
        goals: Value(goals != null ? jsonEncode(goals) : null),
        primaryGoalId: Value(primaryGoalId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

extension RoutineEntryFromDrift on RoutineEntriesTableData {
  domain.RoutineEntry toDomain() => domain.RoutineEntry(
        id: id,
        userId: userId,
        routineId: routineId,
        startedAt: startedAt,
        endedAt: endedAt,
        activeDuration: activeDuration,
        idleDuration: idleDuration,
        totalDuration: totalDuration,
        activitiesCompleted: activitiesCompleted,
        activitiesTotal: activitiesTotal,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: status,
        conditionId: conditionId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension RoutineEntryToDrift on domain.RoutineEntry {
  RoutineEntriesTableCompanion toCompanion() => RoutineEntriesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        routineId: Value(routineId),
        startedAt: Value(startedAt),
        endedAt: Value(endedAt),
        activeDuration: Value(activeDuration),
        idleDuration: Value(idleDuration),
        totalDuration: Value(totalDuration),
        activitiesCompleted: Value(activitiesCompleted),
        activitiesTotal: Value(activitiesTotal),
        periodStart: Value(periodStart),
        periodEnd: Value(periodEnd),
        status: Value(status),
        conditionId: Value(conditionId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

// ═══════════════════════════════════════════════════════════════════
// JSON HELPERS
// ═══════════════════════════════════════════════════════════════════

/// Decode a JSON string to a Map, defaulting to empty map.
Map<String, dynamic> _decodeJsonMap(String json) {
  try {
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  } catch (_) {
    return {};
  }
}

/// Decode a nullable JSON string to a Map.
Map<String, dynamic>? _decodeJsonNullable(String? json) {
  if (json == null) return null;
  try {
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  } catch (_) {
    return null;
  }
}

/// Decode a nullable JSON string to a List of Maps.
List<Map<String, dynamic>>? _decodeJsonListOfMapsNullable(String? json) {
  if (json == null) return null;
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return null;
  }
}

/// Decode a JSON string to a List of Maps.
List<Map<String, dynamic>> _decodeJsonListOfMaps(String json) {
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}
