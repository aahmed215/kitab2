// ═══════════════════════════════════════════════════════════════════
// PRIVACY_PROVIDER.DART — Private Activity Visibility Toggle
// Double-tap "Kitab" title on Home screen reveals private activities.
// State is in-memory only — resets on app close.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether private activities are currently revealed.
/// false = blurred (default), true = visible.
final privateActivitiesRevealedProvider = StateProvider<bool>((ref) => false);
