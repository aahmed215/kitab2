// ═══════════════════════════════════════════════════════════════════
// NOTIFICATIONS_SCREEN.DART — Notification Settings
// Per-type toggles, reminder time configuration.
// See SPEC.md §14.5 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/kitab_toast.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _streakRisk = true;
  bool _streakMilestone = true;
  bool _reminders = true;
  String _reminderTime = '21:00';
  bool _friendRequests = true;
  bool _competitionUpdates = true;
  bool _conditionReminders = true;
  int _conditionReminderDays = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          Text('Activity Notifications', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          SwitchListTile(
            title: const Text('Streak at Risk'),
            subtitle: const Text("Alert when you haven't logged a scheduled activity"),
            value: _streakRisk,
            onChanged: (v) => setState(() => _streakRisk = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Streak Milestones'),
            subtitle: const Text('Celebrate 7, 14, 30, 100+ day streaks'),
            value: _streakMilestone,
            onChanged: (v) => setState(() => _streakMilestone = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Daily Reminder'),
            subtitle: Text('Remind at $_reminderTime to log activities'),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_reminders)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 16),
              title: const Text('Reminder Time'),
              trailing: Text(_reminderTime, style: KitabTypography.mono),
              onTap: () async {
                final parts = _reminderTime.split(':');
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  ),
                );
                if (time != null) {
                  setState(() {
                    _reminderTime =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),

          const Divider(),
          const SizedBox(height: KitabSpacing.md),
          Text('Social Notifications', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          SwitchListTile(
            title: const Text('Friend Requests'),
            value: _friendRequests,
            onChanged: (v) => setState(() => _friendRequests = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Competition Updates'),
            value: _competitionUpdates,
            onChanged: (v) => setState(() => _competitionUpdates = v),
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),
          const SizedBox(height: KitabSpacing.md),
          Text('Condition Notifications', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          SwitchListTile(
            title: const Text('Condition Reminders'),
            subtitle: Text('Remind every $_conditionReminderDays days to check conditions'),
            value: _conditionReminders,
            onChanged: (v) => setState(() => _conditionReminders = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_conditionReminders)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 16),
              title: const Text('Reminder Interval'),
              trailing: DropdownButton<int>(
                value: _conditionReminderDays,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 days')),
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (v) =>
                    setState(() => _conditionReminderDays = v ?? 7),
              ),
            ),

          const SizedBox(height: KitabSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                KitabToast.success(context, 'Notification settings saved');
              },
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
