// ═══════════════════════════════════════════════════════════════════
// SUPABASE_ENTRY_REPOSITORY.DART — Cloud-only (web) implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/entry.dart' as domain;
import '../repositories/entry_repository.dart';
import 'supabase_helpers.dart';

class SupabaseEntryRepository implements EntryRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _table = 'entries';

  SupabaseEntryRepository() : _client = Supabase.instance.client;

  @override
  Stream<List<domain.Entry>> watchByUser(String userId) {
    final controller = StreamController<List<domain.Entry>>();

    _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('logged_at')
        .listen((rows) {
      final entries = rows
          .where((r) => r['deleted_at'] == null)
          .map((r) => domain.Entry.fromJson(toCamelCase(r)))
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      controller.add(entries);
    });

    return controller.stream;
  }

  @override
  Future<List<domain.Entry>> getByActivityAndDateRange(
      String userId, String activityId, DateTime start, DateTime end) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .isFilter('deleted_at', null)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String());
    return (response as List)
        .map((r) => domain.Entry.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.Entry>> getByPeriod(
      String userId, String activityId, DateTime periodStart, DateTime periodEnd) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('activity_id', activityId)
        .isFilter('deleted_at', null)
        .eq('period_start', periodStart.toUtc().toIso8601String())
        .eq('period_end', periodEnd.toUtc().toIso8601String());
    return (response as List)
        .map((r) => domain.Entry.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.Entry>> getByDateRange(String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: false);
    return (response as List)
        .map((r) => domain.Entry.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<List<domain.Entry>> getByRoutineEntry(String routineEntryId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('routine_entry_id', routineEntryId)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((r) => domain.Entry.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.Entry?> getById(String id) async {
    final response = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.Entry.fromJson(toCamelCase(response));
  }

  @override
  Future<domain.Entry> save(domain.Entry entry) async {
    final now = DateTime.now();
    final toSave = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
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
  Future<void> unlinkAllForActivity(String userId, String activityId) async {
    await _client.from(_table).update({
      'period_start': null,
      'period_end': null,
      'link_type': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', userId).eq('activity_id', activityId).isFilter('deleted_at', null);
  }
}
