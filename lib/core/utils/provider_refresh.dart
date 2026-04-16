// ═══════════════════════════════════════════════════════════════════
// PROVIDER_REFRESH.DART — Centralized provider invalidation
// Call after any entry, status, or condition change to ensure
// all screens reflect the latest data.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/book/book_screen.dart';
import '../../features/home/providers/home_providers.dart';
import '../../features/home/needs_attention_screen.dart';

/// Invalidate all providers that depend on entry data.
/// Call after any entry create, update, delete, or period status change.
void refreshAllEntryProviders(dynamic ref) {
  try {
    if (ref is WidgetRef) {
      ref.invalidate(bookEntriesProvider);
      ref.invalidate(bookConditionsProvider);
      ref.invalidate(scheduledTodayProvider);
      ref.invalidate(scheduledRoutinesTodayProvider);
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(todayEntriesProvider);
      ref.invalidate(needsAttentionProvider);
      ref.invalidate(activeConditionsProvider);
      ref.invalidate(allConditionsProvider);
      ref.invalidate(weeklyHistoryProvider);
    }
  } catch (_) {
    // Provider might not be in scope — safe to ignore
  }
}
