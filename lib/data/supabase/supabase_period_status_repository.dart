// ═══════════════════════════════════════════════════════════════════
// SUPABASE_PERIOD_STATUS_REPOSITORY.DART — Cloud-only (web)
// ═══════════════════════════════════════════════════════════════════

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/period_status.dart' as domain;
import '../repositories/period_status_repository.dart';
import 'supabase_helpers.dart';

class SupabasePeriodStatusRepository implements PeriodStatusRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  SupabasePeriodStatusRepository() : _client = Supabase.instance.client;

  // ─── Activity Period Statuses ───

  @override
  Future<domain.ActivityPeriodStatus?> getActivityPeriodStatus(
      String userId, String activityId, DateTime periodStart, DateTime periodEnd) async {
    final response = await _client
        .from('activity_period_statuses')
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .eq('period_start', periodStart.toUtc().toIso8601String())
        .eq('period_end', periodEnd.toUtc().toIso8601String())
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (response == null) return null;
    return domain.ActivityPeriodStatus.fromJson(toCamelCase(response));
  }

  @override
  Future<List<domain.ActivityPeriodStatus>> getActivityStatusesByDateRange(
      String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('activity_period_statuses')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .gte('period_start', start.toUtc().toIso8601String())
        .lt('period_start', end.toUtc().toIso8601String());
    return (response as List)
        .map((r) => domain.ActivityPeriodStatus.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.ActivityPeriodStatus>> getActivityStatusHistory(
      String userId, String activityId) async {
    final response = await _client
        .from('activity_period_statuses')
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .isFilter('deleted_at', null)
        .order('period_start', ascending: false);
    return (response as List)
        .map((r) => domain.ActivityPeriodStatus.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<void> saveActivityStatus(domain.ActivityPeriodStatus status) async {
    final now = DateTime.now();
    final toSave = status.copyWith(
      id: status.id.isEmpty ? _uuid.v4() : status.id,
      updatedAt: now,
    );
    await _client.from('activity_period_statuses').upsert(
      toSnakeCase(toSave.toJson()),
      onConflict: 'user_id,activity_id,period_start,period_end',
    );
  }

  // ─── Goal Period Statuses ───

  @override
  Future<domain.GoalPeriodStatus?> getGoalPeriodStatus(
      String userId, String activityId, String goalId,
      DateTime periodStart, DateTime periodEnd) async {
    final response = await _client
        .from('goal_period_statuses')
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .eq('goal_id', goalId)
        .eq('period_start', periodStart.toUtc().toIso8601String())
        .eq('period_end', periodEnd.toUtc().toIso8601String())
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (response == null) return null;
    return domain.GoalPeriodStatus.fromJson(toCamelCase(response));
  }

  @override
  Future<List<domain.GoalPeriodStatus>> getGoalStatusHistory(
      String userId, String activityId, String goalId) async {
    final response = await _client
        .from('goal_period_statuses')
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .eq('goal_id', goalId)
        .isFilter('deleted_at', null)
        .order('period_start', ascending: false);
    return (response as List)
        .map((r) => domain.GoalPeriodStatus.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<void> saveGoalStatus(domain.GoalPeriodStatus status) async {
    final now = DateTime.now();
    final toSave = status.copyWith(
      id: status.id.isEmpty ? _uuid.v4() : status.id,
      updatedAt: now,
    );
    await _client.from('goal_period_statuses').upsert(toSnakeCase(toSave.toJson()));
  }

  // ─── Bulk Operations ───

  @override
  Future<void> deleteAllForActivity(String userId, String activityId) async {
    await _client.from('activity_period_statuses')
        .delete()
        .eq('user_id', userId)
        .eq('activity_id', activityId);
  }

  @override
  Future<void> deleteAllGoalStatusesForActivity(String userId, String activityId) async {
    await _client.from('goal_period_statuses')
        .delete()
        .eq('user_id', userId)
        .eq('activity_id', activityId);
  }

  @override
  Future<void> clearExcusesByConditionId(String conditionId) async {
    await _client.from('activity_period_statuses').update({
      'status': 'pending',
      'condition_id': null,
      'resolved_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('condition_id', conditionId).eq('status', 'excused');
  }

  @override
  Future<void> clearExcusesOutsideRange(String conditionId, DateTime start, DateTime end) async {
    // Get all excused statuses for this condition
    final response = await _client.from('activity_period_statuses')
        .select()
        .eq('condition_id', conditionId)
        .eq('status', 'excused');

    final now = DateTime.now().toUtc().toIso8601String();
    for (final row in (response as List)) {
      final periodStart = DateTime.parse(row['period_start'] as String);
      final periodDay = DateTime(periodStart.year, periodStart.month, periodStart.day);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);

      // If the period's day is outside the condition's new range, reset to pending
      if (periodDay.isBefore(startDay) || periodDay.isAfter(endDay)) {
        await _client.from('activity_period_statuses').update({
          'status': 'pending',
          'condition_id': null,
          'resolved_at': null,
          'updated_at': now,
        }).eq('id', row['id']);
      }
    }
  }
}
