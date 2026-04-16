// ═══════════════════════════════════════════════════════════════════
// DATABASE_PROVIDERS.DART — Platform-Aware Repository Routing
// Native (iOS/Android): Drift/SQLite (local-first, offline capable)
// Web: Supabase direct (cloud-only, no local database)
// See SPEC.md §2.8 for platform differences.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drift/database.dart';
import '../../data/drift/drift_activity_repository.dart';
import '../../data/drift/drift_category_repository.dart';
import '../../data/drift/drift_condition_repository.dart';
import '../../data/drift/drift_entry_repository.dart';
import '../../data/drift/drift_period_status_repository.dart';
import '../../data/drift/drift_routine_repository.dart';
import '../../data/drift/drift_user_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../data/supabase/supabase_activity_repository.dart';
import '../../data/supabase/supabase_category_repository.dart';
import '../../data/supabase/supabase_condition_repository.dart';
import '../../data/supabase/supabase_entry_repository.dart';
import '../../data/supabase/supabase_period_status_repository.dart';
import '../../data/supabase/supabase_routine_repository.dart';
import '../../data/supabase/supabase_user_repository.dart';

// ─── Database Instance (Native Only) ───
// On web, this provider should NOT be accessed by repository code.
// It's only used on native for the Drift database.
final databaseProvider = Provider<KitabDatabase>((ref) {
  if (kIsWeb) {
    // Web doesn't use Drift. Return a dummy that throws on access.
    // This should never be called on web — all repos use Supabase directly.
    throw UnsupportedError(
      'KitabDatabase (Drift) is not available on web. '
      'Use Supabase repositories instead.',
    );
  }
  final db = KitabDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ═══════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS — Platform-aware routing
// ═══════════════════════════════════════════════════════════════════

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  if (kIsWeb) return SupabaseCategoryRepository();
  return DriftCategoryRepository(ref.watch(databaseProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (kIsWeb) return SupabaseActivityRepository();
  return DriftActivityRepository(ref.watch(databaseProvider));
});

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  if (kIsWeb) return SupabaseEntryRepository();
  return DriftEntryRepository(ref.watch(databaseProvider));
});

final conditionRepositoryProvider = Provider<ConditionRepository>((ref) {
  if (kIsWeb) return SupabaseConditionRepository();
  return DriftConditionRepository(ref.watch(databaseProvider));
});

final periodStatusRepositoryProvider = Provider<PeriodStatusRepository>((ref) {
  if (kIsWeb) return SupabasePeriodStatusRepository();
  return DriftPeriodStatusRepository(ref.watch(databaseProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (kIsWeb) return SupabaseUserRepository();
  return DriftUserRepository(ref.watch(databaseProvider));
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  if (kIsWeb) return SupabaseRoutineRepository();
  return DriftRoutineRepository(ref.watch(databaseProvider));
});
