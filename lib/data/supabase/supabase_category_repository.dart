// ═══════════════════════════════════════════════════════════════════
// SUPABASE_CATEGORY_REPOSITORY.DART — Cloud-only (web) implementation
// Reads/writes directly to Supabase. No local storage.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart' as domain;
import '../repositories/category_repository.dart';
import 'supabase_helpers.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _table = 'categories';

  SupabaseCategoryRepository() : _client = Supabase.instance.client;

  @override
  Stream<List<domain.Category>> watchByUser(String userId) {
    // Supabase real-time streams are complex; use polling via a
    // StreamController that refreshes on subscription.
    final controller = StreamController<List<domain.Category>>();
    _fetchAndEmit(userId, controller);

    // Subscribe to real-time changes
    _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) {
      final categories = rows
          .where((r) => r['deleted_at'] == null)
          .map((r) => domain.Category.fromJson(toCamelCase(r)))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      controller.add(categories);
    });

    return controller.stream;
  }

  Future<void> _fetchAndEmit(
      String userId, StreamController<List<domain.Category>> controller) async {
    final categories = await getByUser(userId);
    if (!controller.isClosed) controller.add(categories);
  }

  @override
  Future<List<domain.Category>> getByUser(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('sort_order');

    return (response as List)
        .map((r) => domain.Category.fromJson(toCamelCase(Map<String, dynamic>.from(r))))
        .toList();
  }

  @override
  Future<domain.Category?> getById(String id) async {
    final response = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.Category.fromJson(toCamelCase(response));
  }

  @override
  Future<domain.Category> save(domain.Category category) async {
    final now = DateTime.now();
    final toSave = category.copyWith(
      id: category.id.isEmpty ? _uuid.v4() : category.id,
      updatedAt: now,
    );
    final data = toSnakeCase(toSave.toJson());
    await _client.from(_table).upsert(data);
    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _client.from(_table).update({
        'sort_order': i,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', orderedIds[i]);
    }
  }
}
