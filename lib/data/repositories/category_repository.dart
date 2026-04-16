// ═══════════════════════════════════════════════════════════════════
// CATEGORY_REPOSITORY.DART — Abstract interface for category data
// Platform-agnostic: Drift on native, Supabase on web.
// ═══════════════════════════════════════════════════════════════════

import '../models/category.dart';

/// Contract for category data access. Implementations handle
/// the actual storage mechanism (Drift or Supabase).
abstract class CategoryRepository {
  /// Watch all active categories for a user, ordered by sort_order.
  Stream<List<Category>> watchByUser(String userId);

  /// Get all active categories for a user.
  Future<List<Category>> getByUser(String userId);

  /// Get a single category by ID.
  Future<Category?> getById(String id);

  /// Create or update a category. Returns the saved category.
  Future<Category> save(Category category);

  /// Soft-delete a category.
  Future<void> delete(String id);

  /// Reorder categories by providing new sort_order values.
  Future<void> reorder(List<String> orderedIds);
}
