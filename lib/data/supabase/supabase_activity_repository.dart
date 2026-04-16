// ═══════════════════════════════════════════════════════════════════
// SUPABASE_ACTIVITY_REPOSITORY.DART — Cloud-only (web) implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart' as domain;
import '../repositories/activity_repository.dart';
import 'supabase_helpers.dart';

class SupabaseActivityRepository implements ActivityRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _table = 'activities';

  SupabaseActivityRepository() : _client = Supabase.instance.client;

  @override
  Stream<List<domain.Activity>> watchActiveByUser(String userId) {
    final controller = StreamController<List<domain.Activity>>();

    _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) {
      final activities = rows
          .where((r) => r['deleted_at'] == null && r['is_archived'] == false)
          .map((r) => domain.Activity.fromJson(toCamelCase(r)))
          .toList();
      controller.add(activities);
    });

    return controller.stream;
  }

  @override
  Future<List<domain.Activity>> getByUser(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((r) => domain.Activity.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.Activity>> getByCategory(String userId, String categoryId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((r) => domain.Activity.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.Activity?> getById(String id) async {
    final response = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.Activity.fromJson(toCamelCase(response));
  }

  @override
  Future<domain.Activity> save(domain.Activity activity) async {
    final now = DateTime.now();
    final toSave = activity.copyWith(
      id: activity.id.isEmpty ? _uuid.v4() : activity.id,
      updatedAt: now,
    );
    await _client.from(_table).upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> setArchived(String id, bool archived) async {
    await _client.from(_table).update({
      'is_archived': archived,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
