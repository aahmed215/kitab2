// ═══════════════════════════════════════════════════════════════════
// SUPABASE_ROUTINE_REPOSITORY.DART — Cloud-only (web) implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/routine.dart' as domain;
import '../repositories/routine_repository.dart';
import 'supabase_helpers.dart';

class SupabaseRoutineRepository implements RoutineRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  SupabaseRoutineRepository() : _client = Supabase.instance.client;

  @override
  Stream<List<domain.Routine>> watchActiveByUser(String userId) {
    final controller = StreamController<List<domain.Routine>>();

    _client
        .from('routines')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) {
      final routines = rows
          .where((r) => r['deleted_at'] == null && r['is_archived'] == false)
          .map((r) => domain.Routine.fromJson(toCamelCase(r)))
          .toList();
      controller.add(routines);
    });

    return controller.stream;
  }

  @override
  Future<List<domain.Routine>> getByUser(String userId) async {
    final response = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return (response as List)
        .map((r) => domain.Routine.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.Routine?> getById(String id) async {
    final response = await _client.from('routines').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.Routine.fromJson(toCamelCase(response));
  }

  @override
  Future<domain.Routine> save(domain.Routine routine) async {
    final now = DateTime.now();
    final toSave = routine.copyWith(
      id: routine.id.isEmpty ? _uuid.v4() : routine.id,
      updatedAt: now,
    );
    await _client.from('routines').upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('routines').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<List<domain.RoutineEntry>> getEntriesByDateRange(
      String userId, DateTime start, DateTime end) async {
    final response = await _client
        .from('routine_entries')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String())
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => domain.RoutineEntry.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.RoutineEntry?> getEntryById(String id) async {
    final response = await _client.from('routine_entries').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.RoutineEntry.fromJson(toCamelCase(response));
  }

  @override
  Future<domain.RoutineEntry> saveEntry(domain.RoutineEntry entry) async {
    final now = DateTime.now();
    final toSave = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
      updatedAt: now,
    );
    await _client.from('routine_entries').upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }
}
