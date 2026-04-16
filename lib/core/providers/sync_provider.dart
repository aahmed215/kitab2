// ═══════════════════════════════════════════════════════════════════
// SYNC_PROVIDER.DART — Riverpod Provider for Sync Engine
// Only active on native (iOS/Android) when authenticated.
// Web doesn't need sync — it reads/writes Supabase directly.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sync/sync_engine.dart';
import 'auth_provider.dart';
import 'database_providers.dart';

/// The sync engine instance. Only active on native when authenticated.
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  // Web doesn't use sync — it's cloud-only
  if (kIsWeb) return null;

  final isAuth = ref.watch(isAuthenticatedProvider);
  if (!isAuth) return null;

  final db = ref.watch(databaseProvider);
  final supabase = Supabase.instance.client;
  final engine = SyncEngine(db, supabase);

  engine.startPeriodicSync();
  engine.sync();

  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Pending sync queue count (for status indicator). Native only.
final syncPendingCountProvider = StreamProvider<int>((ref) {
  if (kIsWeb) return const Stream.empty();
  final db = ref.watch(databaseProvider);
  return db.syncDao.watchPendingCount();
});

/// Trigger a manual sync (used by pull-to-refresh).
Future<SyncResult?> triggerSync(WidgetRef ref) async {
  final engine = ref.read(syncEngineProvider);
  if (engine == null) return null;
  return engine.sync();
}
