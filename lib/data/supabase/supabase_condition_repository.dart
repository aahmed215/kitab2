// ═══════════════════════════════════════════════════════════════════
// SUPABASE_CONDITION_REPOSITORY.DART — Cloud-only (web) implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/condition.dart' as domain;
import '../repositories/condition_repository.dart';
import 'supabase_helpers.dart';

class SupabaseConditionRepository implements ConditionRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  SupabaseConditionRepository() : _client = Supabase.instance.client;

  // ─── Presets ───

  @override
  Future<List<domain.ConditionPreset>> getPresetsByUser(String userId) async {
    final response = await _client
        .from('condition_presets')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((r) => domain.ConditionPreset.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.ConditionPreset> savePreset(domain.ConditionPreset preset) async {
    final toSave = preset.copyWith(id: preset.id.isEmpty ? _uuid.v4() : preset.id);
    await _client.from('condition_presets').upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }

  @override
  Future<void> deletePreset(String id) async {
    await _client.from('condition_presets').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ─── Condition Instances ───

  @override
  Stream<List<domain.Condition>> watchActiveByUser(String userId) {
    final controller = StreamController<List<domain.Condition>>();

    _client
        .from('conditions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) {
      final conditions = rows
          .where((r) => r['deleted_at'] == null && r['end_date'] == null)
          .map((r) => domain.Condition.fromJson(toCamelCase(r)))
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      controller.add(conditions);
    });

    return controller.stream;
  }

  @override
  Future<List<domain.Condition>> getByUser(String userId) async {
    final response = await _client
        .from('conditions')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('start_date', ascending: false);
    return (response as List)
        .map((r) => domain.Condition.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.Condition>> getActiveOnDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('conditions')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .lte('start_date', dateStr)
        .or('end_date.is.null,end_date.gte.$dateStr');
    return (response as List)
        .map((r) => domain.Condition.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.Condition> saveCondition(domain.Condition condition) async {
    final now = DateTime.now();
    final toSave = condition.copyWith(
      id: condition.id.isEmpty ? _uuid.v4() : condition.id,
      updatedAt: now,
    );
    await _client.from('conditions').upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }

  @override
  Future<void> endCondition(String id, DateTime endDate) async {
    await _client.from('conditions').update({
      'end_date': endDate.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteCondition(String id) async {
    await _client.from('conditions').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
