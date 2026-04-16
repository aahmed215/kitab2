// ═══════════════════════════════════════════════════════════════════
// SYNC_DAO.DART — CRUD for sync queue and local meta
// Manages the offline→cloud push queue and app state key-value store.
// See SPEC.md §12 for sync engine architecture.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable, LocalMetaTable])
class SyncDao extends DatabaseAccessor<KitabDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  // ─── Sync Queue ───

  /// Get all un-synced items, oldest first.
  Future<List<SyncQueueTableData>> getPendingItems() {
    return (select(syncQueueTable)
          ..where((q) => q.syncedAt.isNull())
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get pending item count (for sync badge/indicator).
  Stream<int> watchPendingCount() {
    final count = syncQueueTable.id.count();
    final query = selectOnly(syncQueueTable)
      ..addColumns([count])
      ..where(syncQueueTable.syncedAt.isNull());
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Enqueue a change for sync.
  Future<void> enqueue(SyncQueueTableCompanion item) {
    return into(syncQueueTable).insert(item);
  }

  /// Mark an item as synced.
  Future<void> markSynced(String id) {
    return (update(syncQueueTable)..where((q) => q.id.equals(id)))
        .write(SyncQueueTableCompanion(syncedAt: Value(DateTime.now())));
  }

  /// Remove synced items older than a threshold (cleanup).
  Future<int> cleanupSynced(DateTime before) {
    return (delete(syncQueueTable)
          ..where(
              (q) => q.syncedAt.isNotNull() & q.syncedAt.isSmallerThanValue(before)))
        .go();
  }

  // ─── Local Meta (Key-Value Store) ───

  /// Get a meta value by key.
  Future<String?> getMeta(String key) async {
    final result = await (select(localMetaTable)
          ..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Set a meta value (insert or update).
  Future<void> setMeta(String key, String value) {
    return into(localMetaTable).insertOnConflictUpdate(
      LocalMetaTableCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// Delete a meta key.
  Future<void> deleteMeta(String key) {
    return (delete(localMetaTable)..where((m) => m.key.equals(key))).go();
  }

  /// Common meta keys:
  /// - 'last_sync_at': ISO 8601 timestamp of last successful sync
  /// - 'last_pull_at': Last pull timestamp per table (JSON map)
  /// - 'prayer_times_cache': Cached prayer times JSON
  /// - 'hijri_date_cache': Cached Hijri date info
}
