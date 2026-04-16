// ═══════════════════════════════════════════════════════════════════
// SYNC_ENGINE.DART — Offline-First Sync Engine
// Push local changes to Supabase, pull remote changes locally.
// Last-write-wins conflict resolution.
// See SPEC.md §12 for full specification.
//
// Sync flow:
//  1. Push: Process sync_queue → upsert to Supabase → mark synced
//  2. Pull: Query updated_at > last_pull → merge locally
//  3. Real-time: Subscribe to changes for live updates
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../drift/database.dart';

/// Tables that participate in sync (order matters for foreign keys).
const _syncTables = [
  'categories',
  'activities',
  'entries',
  'condition_presets',
  'conditions',
  'activity_period_statuses',
  'goal_period_statuses',
  'routines',
  'routine_entries',
  'routine_period_statuses',
  'routine_goal_period_statuses',
  'notifications',
  'user_charts',
];

/// The sync engine: pushes local changes and pulls remote updates.
class SyncEngine {
  final KitabDatabase _db;
  final SupabaseClient _supabase;
  Timer? _periodicTimer;
  bool _syncing = false;

  SyncEngine(this._db, this._supabase);

  /// Start periodic sync (every 5 minutes).
  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => sync(),
    );
  }

  /// Stop periodic sync.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Run a full sync cycle: push then pull.
  Future<SyncResult> sync() async {
    if (_syncing) return SyncResult(pushed: 0, pulled: 0, errors: ['Sync already in progress']);

    _syncing = true;
    final errors = <String>[];
    int pushed = 0;
    int pulled = 0;

    try {
      // ─── PUSH PHASE ───
      pushed = await _push(errors);

      // ─── PULL PHASE ───
      pulled = await _pull(errors);

      // Update last sync timestamp
      await _db.syncDao.setMeta(
        'last_sync_at',
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      errors.add('Sync failed: $e');
    } finally {
      _syncing = false;
    }

    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  // ═══════════════════════════════════════════════════════════════════
  // PUSH: Local changes → Supabase
  // ═══════════════════════════════════════════════════════════════════

  Future<int> _push(List<String> errors) async {
    final pending = await _db.syncDao.getPendingItems();
    int count = 0;

    for (final item in pending) {
      try {
        final table = item.tableName_;
        final recordId = item.recordId;
        final operation = item.operation;

        if (operation == 'delete') {
          // Soft delete: update deleted_at on Supabase
          await _supabase.from(table).update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', recordId);
        } else {
          // Upsert: read current row from local DB and push
          final row = await _readLocalRow(table, recordId);
          if (row != null) {
            await _supabase.from(table).upsert(row);
          }
        }

        await _db.syncDao.markSynced(item.id);
        count++;
      } catch (e) {
        errors.add('Push failed for ${item.tableName_}/${item.recordId}: $e');
      }
    }

    return count;
  }

  /// Read a row from the local Drift database for push.
  Future<Map<String, dynamic>?> _readLocalRow(
      String table, String recordId) async {
    // Use raw query to read any table by name
    final result = await _db.customSelect(
      'SELECT * FROM $table WHERE id = ?',
      variables: [Variable.withString(recordId)],
    ).get();

    if (result.isEmpty) return null;

    final row = <String, dynamic>{};
    final data = result.first.data;
    for (final entry in data.entries) {
      row[entry.key] = entry.value;
    }
    return row;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PULL: Supabase changes → Local
  // ═══════════════════════════════════════════════════════════════════

  Future<int> _pull(List<String> errors) async {
    int count = 0;

    // Get last pull timestamp
    final lastPullStr = await _db.syncDao.getMeta('last_pull_at');
    final lastPull = lastPullStr != null
        ? DateTime.parse(lastPullStr)
        : DateTime(2020); // First sync: pull everything

    for (final table in _syncTables) {
      try {
        // Query rows updated after last pull
        final response = await _supabase
            .from(table)
            .select()
            .gt('updated_at', lastPull.toUtc().toIso8601String())
            .order('updated_at');

        final rows = response as List<dynamic>;

        for (final row in rows) {
          final map = Map<String, dynamic>.from(row as Map);
          await _mergeLocally(table, map);
          count++;
        }
      } catch (e) {
        // Some tables might not have updated_at (like condition_presets)
        // Try with created_at instead
        try {
          final response = await _supabase
              .from(table)
              .select()
              .gt('created_at', lastPull.toUtc().toIso8601String())
              .order('created_at');

          final rows = response as List<dynamic>;
          for (final row in rows) {
            final map = Map<String, dynamic>.from(row as Map);
            await _mergeLocally(table, map);
            count++;
          }
        } catch (e2) {
          errors.add('Pull failed for $table: $e2');
        }
      }
    }

    // Update last pull timestamp
    await _db.syncDao.setMeta(
      'last_pull_at',
      DateTime.now().toUtc().toIso8601String(),
    );

    return count;
  }

  /// Merge a remote row into the local database.
  /// Last-write-wins: remote row's updated_at vs local row's updated_at.
  Future<void> _mergeLocally(
      String table, Map<String, dynamic> remoteRow) async {
    final id = remoteRow['id'] as String;

    // Check if local row exists
    final localRows = await _db.customSelect(
      'SELECT * FROM $table WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();

    if (localRows.isEmpty) {
      // New row from remote — insert locally
      await _insertRow(table, remoteRow);
      return;
    }

    // Both exist: last-write-wins
    final localData = localRows.first.data;
    final localUpdated = _parseDateTime(localData['updated_at'] ?? localData['created_at']);
    final remoteUpdated = _parseDateTime(remoteRow['updated_at'] ?? remoteRow['created_at']);

    if (remoteUpdated != null &&
        (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
      // Remote wins — update local
      await _updateRow(table, remoteRow);
    }
    // Otherwise local wins — keep local version
  }

  /// Insert or replace a row in a local table using raw SQL.
  Future<void> _insertRow(String table, Map<String, dynamic> row) async {
    final columns = row.keys.toList();
    final colNames = columns.join(', ');
    final placeholders = columns.map((_) => '?').join(', ');
    final values = columns
        .map((col) {
          final v = row[col];
          if (v == null) return Variable.withString('');
          if (v is int) return Variable.withInt(v);
          if (v is double) return Variable.withReal(v);
          if (v is bool) return Variable.withBool(v);
          return Variable.withString(v.toString());
        })
        .toList();

    await _db.customInsert(
      'INSERT OR REPLACE INTO $table ($colNames) VALUES ($placeholders)',
      variables: values,
    );
  }

  /// Update a row in a local table.
  Future<void> _updateRow(String table, Map<String, dynamic> row) async {
    await _insertRow(table, row);
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Dispose resources.
  void dispose() {
    stopPeriodicSync();
  }
}

/// Result of a sync operation.
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;

  const SyncResult({
    required this.pushed,
    required this.pulled,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors;
  int get total => pushed + pulled;

  @override
  String toString() =>
      'SyncResult(pushed: $pushed, pulled: $pulled, errors: ${errors.length})';
}
