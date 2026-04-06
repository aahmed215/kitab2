// ═══════════════════════════════════════════════════════════════════
// ENTRY.DART — Activity Entry (Log) Data Model
// A single recorded instance of an activity.
// Has two-layer linkage: template (Layer 1) + period (Layer 2).
// Maps to the `entries` table in Supabase.
// See SPEC.md §8 Entry Points for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry.freezed.dart';
part 'entry.g.dart';

/// An activity entry — a single logged instance of an activity.
/// Every time a user records an activity (via FAB, Home card, or Book),
/// an Entry is created.
@freezed
class Entry with _$Entry {
  const factory Entry({
    /// Unique identifier (UUID)
    required String id,

    /// Owner's user ID
    required String userId,

    /// Display name — stored independently from template.
    /// If linked to a template, set to template's name at creation.
    /// For ad-hoc entries, whatever the user typed or "Untitled".
    required String name,

    /// Layer 1 link: which activity template this entry belongs to.
    /// Null = ad-hoc/quick entry (not linked to any template).
    String? activityId,

    /// Layer 2 link: frozen period start (UTC) at time of linkage.
    /// Null = not linked to any period (orphaned or no schedule).
    DateTime? periodStart,

    /// Layer 2 link: frozen period end (UTC) at time of linkage.
    DateTime? periodEnd,

    /// How the link was established: 'explicit' or null.
    String? linkType,

    /// Captured metric values — key-value pairs: { field_id: value }
    /// Values stored in their native types.
    @Default({}) Map<String, dynamic> fieldValues,

    /// Timer segments for timed entries.
    /// Array of { "start": "UTC timestamp", "end": "UTC timestamp" }
    /// Null for non-timer entries.
    List<Map<String, dynamic>>? timerSegments,

    /// Freeform notes (always available on every entry)
    String? notes,

    /// Links this entry to the routine session it was created in.
    /// Null for standalone entries (not part of a routine).
    String? routineEntryId,

    /// How this entry was created:
    /// null or 'manual' = user logged it.
    /// V2: 'apple_health', 'google_health', 'fitbit', etc.
    String? source,

    /// V2: unique ID from external source to prevent duplicate imports.
    String? externalId,

    /// When the activity occurred (user's intended time, may be retroactive).
    /// Independent from periodStart/periodEnd — those are the period boundaries.
    required DateTime loggedAt,

    /// System timestamp of record creation
    required DateTime createdAt,

    /// When this entry was last updated
    required DateTime updatedAt,

    /// Soft delete timestamp
    DateTime? deletedAt,
  }) = _Entry;

  factory Entry.fromJson(Map<String, dynamic> json) =>
      _$EntryFromJson(json);
}
