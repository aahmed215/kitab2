// ═══════════════════════════════════════════════════════════════════
// ACTIVITY_ACTION_SHEET.DART — Action Bottom Sheet for Activity Cards
// Returns the chosen action so the CALLER can save and refresh.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/entry.dart';
import '../../../data/models/period_status.dart';
import '../../../core/utils/condition_merge.dart' show createOrExtendCondition;
import '../../../core/engines/engines.dart';
import '../../../core/services/location_service.dart';
import '../../entry/entry_form_screen.dart';
import '../../../core/utils/provider_refresh.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../entry/start_condition_sheet.dart';

const _uuid = Uuid();

/// Shows the action bottom sheet and handles the chosen action.
/// Saves to DB and invalidates providers before returning.
Future<void> showActivityActionSheet(
  BuildContext context,
  WidgetRef ref, {
  required Activity activity,
  required ComputedPeriod period,
  required String currentStatus,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: KitabColors.gray300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: KitabSpacing.lg),
          Text(activity.isPrivate ? '••••••••' : activity.name, style: KitabTypography.h2),
          const SizedBox(height: KitabSpacing.lg),

          if (currentStatus != 'completed')
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: KitabColors.primary),
              title: const Text('Record Activity'),
              subtitle: const Text('Log this activity now'),
              onTap: () => Navigator.pop(ctx, 'record'),
            ),

          if (currentStatus != 'completed')
            ListTile(
              leading: const Icon(Icons.check_circle, color: KitabColors.success),
              title: const Text('Quick Complete'),
              subtitle: const Text('Mark as done right now'),
              onTap: () => Navigator.pop(ctx, 'complete'),
            ),

          if (currentStatus == 'pending')
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: KitabColors.error),
              title: const Text('Mark as Missed'),
              onTap: () => Navigator.pop(ctx, 'missed'),
            ),

          if (currentStatus == 'pending' || currentStatus == 'missed')
            ListTile(
              leading: const Icon(Icons.info_outline, color: KitabColors.warning),
              title: const Text('Add Reason'),
              subtitle: const Text('Excuse this period'),
              onTap: () => Navigator.pop(ctx, 'excused'),
            ),

          const SizedBox(height: KitabSpacing.md),
        ],
      ),
    ),
  );

  if (action == null) return; // Dismissed without choosing

  final userId = ref.read(currentUserIdProvider);
  final now = DateTime.now();

  try {
    switch (action) {
      case 'record':
        if (context.mounted) {
          await Navigator.push(context,
            MaterialPageRoute(builder: (_) => EntryFormScreen(preselectedActivity: activity)));
        }

      case 'complete':
        // Build preset field values
        final fieldValues = <String, dynamic>{};

        // Activity location from current GPS
        final location = ref.read(userLocationProvider).valueOrNull;
        if (location != null) {
          fieldValues['activity_location_lat'] = location.latitude;
          fieldValues['activity_location_lng'] = location.longitude;
          // activity_location_name omitted — reverse geocode not available here
        }

        // Expected start/end from schedule time window
        if (activity.schedule != null) {
          final expected = PeriodEngine.resolveExpectedTimes(
            scheduleJson: activity.schedule,
            date: DateTime.now(),
          );
          if (expected.start != null) {
            fieldValues['expected_start'] = expected.start!.toIso8601String();
          }
          if (expected.end != null) {
            fieldValues['expected_end'] = expected.end!.toIso8601String();
          }
        }

        final entry = Entry(
          id: _uuid.v4(),
          userId: userId,
          name: activity.name,
          activityId: activity.id,
          periodStart: period.start,
          periodEnd: period.end,
          linkType: 'auto',
          fieldValues: fieldValues,
          loggedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(entryRepositoryProvider).save(entry);
        if (context.mounted) {
          KitabToast.success(context, 'Activity completed');
        }

      case 'missed':
        final status = ActivityPeriodStatus(
          id: _uuid.v4(),
          userId: userId,
          activityId: activity.id,
          periodStart: period.start,
          periodEnd: period.end,
          status: 'missed',
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);
        if (context.mounted) {
          KitabToast.show(context, 'Marked as missed');
        }

      case 'excused':
        if (!context.mounted) return;
        var reason = await _showReasonPicker(context, ref, userId);
        if (reason == null) return;

        // Handle preset selection — create a condition from it
        if (reason.label.startsWith('__preset_') && reason.label.endsWith('__')) {
          final presetId = reason.label.replaceAll('__preset_', '').replaceAll('__', '');
          final conditionRepo = ref.read(conditionRepositoryProvider);
          final presets = await conditionRepo.getPresetsByUser(userId);
          final preset = presets.where((p) => p.id == presetId).firstOrNull;
          if (preset == null) return;

          // Create a condition instance from the preset
          final conditionId = await createOrExtendCondition(
            repo: conditionRepo,
            userId: userId,
            presetId: preset.id,
            label: preset.label,
            emoji: preset.emoji,
            startDate: now,
          );
          reason = _ExcuseReason(conditionId: conditionId, label: '${preset.emoji} ${preset.label}');
        }

        // Handle "Start a New Condition" — open full creation sheet
        if (reason.label == '__create_new__') {
          if (!context.mounted) return;
          final created = await showStartConditionSheet(context);
          if (created != true || !context.mounted) return;

          // Fetch the newest active condition (just created)
          final conditionRepo = ref.read(conditionRepositoryProvider);
          final allConditions = await conditionRepo.getByUser(userId);
          final newest = allConditions
              .where((c) => c.endDate == null)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (newest.isEmpty) return;
          reason = _ExcuseReason(conditionId: newest.first.id, label: '${newest.first.emoji} ${newest.first.label}');
        }

        final status = ActivityPeriodStatus(
          id: _uuid.v4(),
          userId: userId,
          activityId: activity.id,
          periodStart: period.start,
          periodEnd: period.end,
          status: 'excused',
          conditionId: reason.conditionId,
          resolvedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(periodStatusRepositoryProvider).saveActivityStatus(status);
        if (context.mounted) {
          KitabToast.success(context, 'Period excused: ${reason.label}');
        }
    }
  } catch (e) {
    if (context.mounted) {
      KitabToast.error(context, 'Error: $e');
    }
  }

  // Refresh all relevant providers AFTER the save completes
  refreshAllEntryProviders(ref);
}

class _ExcuseReason {
  final String? conditionId;
  final String label;
  const _ExcuseReason({this.conditionId, required this.label});
}

Future<_ExcuseReason?> _showReasonPicker(BuildContext context, WidgetRef ref, String userId) async {
  final conditionRepo = ref.read(conditionRepositoryProvider);
  final presets = await conditionRepo.getPresetsByUser(userId);
  final activeConditions = await conditionRepo.getByUser(userId);
  final now = DateTime.now();
  final currentConditions = activeConditions.where((c) => c.endDate == null || c.endDate!.isAfter(now)).toList();

  if (!context.mounted) return null;

  return showModalBottomSheet<_ExcuseReason>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: KitabSpacing.lg, right: KitabSpacing.lg, top: KitabSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + KitabSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: KitabColors.gray300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: KitabSpacing.lg),
            Text('Select a Reason', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            Text('Pick an active condition or start a new one.',
                style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
            const SizedBox(height: KitabSpacing.md),

            // Active conditions
            if (currentConditions.isNotEmpty) ...[
              Text('Active Conditions', style: KitabTypography.bodySmall.copyWith(
                color: KitabColors.gray600, fontWeight: FontWeight.w600)),
              const SizedBox(height: KitabSpacing.xs),
              ...currentConditions.map((c) => ListTile(
                leading: Text(c.emoji, style: const TextStyle(fontSize: 20)),
                title: Text(c.label),
                subtitle: Text('Active since ${_formatDate(c.startDate)}',
                    style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
                dense: true,
                trailing: const Icon(Icons.check_circle_outline, size: 18, color: KitabColors.primary),
                onTap: () => Navigator.pop(ctx, _ExcuseReason(conditionId: c.id, label: '${c.emoji} ${c.label}')),
              )),
              const Divider(),
            ],

            // Presets — quick-start a condition from a preset
            if (presets.isNotEmpty) ...[
              Text('Quick Start from Preset', style: KitabTypography.bodySmall.copyWith(
                color: KitabColors.gray600, fontWeight: FontWeight.w600)),
              const SizedBox(height: KitabSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((p) => ActionChip(
                  avatar: Text(p.emoji, style: const TextStyle(fontSize: 14)),
                  label: Text(p.label),
                  onPressed: () => Navigator.pop(ctx, _ExcuseReason(
                    label: '__preset_${p.id}__',
                  )),
                )).toList(),
              ),
              const Divider(),
            ],

            // Start a new condition (custom)
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: KitabColors.primary),
              title: const Text('Start a New Condition'),
              subtitle: const Text('Custom condition with full setup'),
              dense: true,
              onTap: () => Navigator.pop(ctx, const _ExcuseReason(label: '__create_new__')),
            ),

            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'yesterday';
  return '${date.month}/${date.day}';
}
