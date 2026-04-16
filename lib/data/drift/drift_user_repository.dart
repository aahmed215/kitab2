// ═══════════════════════════════════════════════════════════════════
// DRIFT_USER_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart' as domain;
import '../repositories/user_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftUserRepository implements UserRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftUserRepository(this._db);

  @override
  Future<domain.UserProfile?> getById(String id) async {
    final row = await _db.usersDao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<domain.UserProfile?> watchById(String id) {
    return _db.usersDao.watchById(id).map((row) => row?.toDomain());
  }

  @override
  Future<domain.UserProfile> save(domain.UserProfile profile) async {
    final now = DateTime.now();
    final toSave = profile.copyWith(updatedAt: now);
    await _db.usersDao.upsert(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('users'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> updateSettings(
      String userId, domain.UserSettings settings) async {
    final settingsJson = jsonEncode(settings.toJson());
    await _db.usersDao.updateSettings(userId, settingsJson);

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('users'),
      recordId: Value(userId),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await Supabase.instance.client
          .from('users')
          .select('id')
          .ilike('username', username)
          .limit(1);
      return (result as List).isEmpty;
    } catch (_) {
      // Offline or error — assume available, Supabase will enforce on sync
      return true;
    }
  }
}
