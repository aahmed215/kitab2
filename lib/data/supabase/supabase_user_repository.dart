// ═══════════════════════════════════════════════════════════════════
// SUPABASE_USER_REPOSITORY.DART — Cloud-only (web) implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart' as domain;
import '../repositories/user_repository.dart';
import 'supabase_helpers.dart';

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _client;

  SupabaseUserRepository() : _client = Supabase.instance.client;

  @override
  Future<domain.UserProfile?> getById(String id) async {
    final response = await _client.from('users').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return domain.UserProfile.fromJson(toCamelCase(response));
  }

  @override
  Stream<domain.UserProfile?> watchById(String id) {
    final controller = StreamController<domain.UserProfile?>();

    _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .listen((rows) {
      if (rows.isEmpty) {
        controller.add(null);
      } else {
        controller.add(domain.UserProfile.fromJson(toCamelCase(rows.first)));
      }
    });

    return controller.stream;
  }

  @override
  Future<domain.UserProfile> save(domain.UserProfile profile) async {
    final now = DateTime.now();
    final toSave = profile.copyWith(updatedAt: now);
    await _client.from('users').upsert(toSnakeCase(toSave.toJson()));
    return toSave;
  }

  @override
  Future<void> updateSettings(String userId, domain.UserSettings settings) async {
    await _client.from('users').update({
      'settings': jsonEncode(settings.toJson()),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _client
        .from('users')
        .select('id')
        .ilike('username', username)
        .limit(1);
    return (result as List).isEmpty;
  }
}
