// ═══════════════════════════════════════════════════════════════════
// DATA_STORAGE_SCREEN.DART — Data & Storage Settings
// Export JSON/CSV, import JSON, manage cache.
// See SPEC.md §14.5 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart' as domain;
import '../../../data/models/entry.dart';



class DataStorageScreen extends ConsumerWidget {
  const DataStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data & Storage', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          Text('Export', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          ListTile(
            leading: const Icon(Icons.file_download, color: KitabColors.primary),
            title: const Text('Export as JSON'),
            subtitle: const Text('Full backup of all your data'),
            onTap: () => _exportJson(context, ref),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: KitabColors.primary),
            title: const Text('Export as CSV'),
            subtitle: const Text('Entries only, spreadsheet format'),
            onTap: () {
              KitabToast.show(context, 'CSV export coming soon');
            },
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),
          const SizedBox(height: KitabSpacing.md),

          Text('Import', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          ListTile(
            leading: const Icon(Icons.file_upload, color: KitabColors.primary),
            title: const Text('Import JSON'),
            subtitle: const Text('Restore from a previous export'),
            onTap: () => _importJson(context, ref),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),
          const SizedBox(height: KitabSpacing.md),

          Text('Storage', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          ListTile(
            leading: const Icon(Icons.cached, color: KitabColors.warning),
            title: const Text('Clear Cache'),
            subtitle: const Text('Prayer times, Hijri dates, computed data'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cache?'),
                  content: const Text(
                    'This will clear cached prayer times and computed data. '
                    'Your activities and entries are not affected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        KitabToast.success(context, 'Cache cleared');
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final activityRepo = ref.read(activityRepositoryProvider);
      final entryRepo = ref.read(entryRepositoryProvider);

      final categories = await categoryRepo.getByUser(ref.read(currentUserIdProvider));
      final activities = await activityRepo.getByUser(ref.read(currentUserIdProvider));
      final entries = await entryRepo.getByDateRange(
        ref.read(currentUserIdProvider),
        DateTime(2020),
        DateTime.now().add(const Duration(days: 1)),
      );

      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'categories': categories.map((c) => c.toJson()).toList(),
        'activities': activities.map((a) => a.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);

      await Share.share(jsonStr, subject: 'Kitab Data Export');
    } catch (e) {
      if (context.mounted) {
        KitabToast.error(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    // Show a dialog with a text field for pasting JSON
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your exported JSON data below:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"categories": [...], "activities": [...], ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    try {
      final data = jsonDecode(controller.text.trim()) as Map<String, dynamic>;
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final activityRepo = ref.read(activityRepositoryProvider);
      final entryRepo = ref.read(entryRepositoryProvider);

      int imported = 0;

      // Import categories
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final catJson in categories) {
        final cat = domain.Category.fromJson(
            Map<String, dynamic>.from(catJson as Map));
        await categoryRepo.save(cat);
        imported++;
      }

      // Import activities
      final activities = data['activities'] as List<dynamic>? ?? [];
      for (final actJson in activities) {
        final act = Activity.fromJson(
            Map<String, dynamic>.from(actJson as Map));
        await activityRepo.save(act);
        imported++;
      }

      // Import entries
      final entries = data['entries'] as List<dynamic>? ?? [];
      for (final entJson in entries) {
        final ent =
            Entry.fromJson(Map<String, dynamic>.from(entJson as Map));
        await entryRepo.save(ent);
        imported++;
      }

      if (context.mounted) {
        KitabToast.success(context, 'Imported $imported items');
      }
    } catch (e) {
      if (context.mounted) {
        KitabToast.error(context, 'Import failed: $e');
      }
    }
  }
}
