// ═══════════════════════════════════════════════════════════════════
// CATEGORY.DART — Category Data Model
// Represents an activity grouping with icon and color.
// Name is unique per user (case-insensitive).
// Maps to the `categories` table in Supabase.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// A category groups related activities and provides their visual identity
/// (icon + color). Activities inherit their category's icon and color —
/// there is no separate icon/color per activity.
@freezed
class Category with _$Category {
  const factory Category({
    /// Unique identifier (UUID)
    required String id,

    /// Owner's user ID
    required String userId,

    /// Category name — unique per user (case-insensitive)
    required String name,

    /// Emoji icon displayed alongside activities in this category
    @Default('📁') String icon,

    /// Hex color code used for the category's visual identity
    /// (e.g., activity card left border, chart bars)
    @Default('#0D7377') String color,

    /// Display order in the categories list
    @Default(0) int sortOrder,

    /// When this category was created
    required DateTime createdAt,

    /// When this category was last updated
    required DateTime updatedAt,

    /// Soft delete timestamp — null means active
    DateTime? deletedAt,
  }) = _Category;

  /// Creates a Category from a JSON map (e.g., from Supabase response)
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
