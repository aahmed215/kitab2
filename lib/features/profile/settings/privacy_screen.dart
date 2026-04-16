// ═══════════════════════════════════════════════════════════════════
// PRIVACY_SCREEN.DART — Privacy & Sharing Settings
// Default sharing, profile visibility, analytics opt-out.
// See SPEC.md §14.5 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/kitab_toast.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String _defaultSharing = 'private';
  String _profileVisibility = 'friends_only';
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Sharing', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          Text('Sharing Defaults', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          DropdownButtonFormField<String>(
            value: _defaultSharing,
            decoration: const InputDecoration(
              labelText: 'Default Sharing for New Activities',
            ),
            items: const [
              DropdownMenuItem(value: 'private', child: Text('Private')),
              DropdownMenuItem(value: 'friends', child: Text('Specific Friends')),
              DropdownMenuItem(value: 'all_friends', child: Text('All Friends')),
            ],
            onChanged: (v) =>
                setState(() => _defaultSharing = v ?? 'private'),
          ),

          const SizedBox(height: KitabSpacing.lg),
          const Divider(),
          const SizedBox(height: KitabSpacing.md),

          Text('Profile Visibility', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          DropdownButtonFormField<String>(
            value: _profileVisibility,
            decoration: const InputDecoration(
              labelText: 'Who Can See Your Profile',
            ),
            items: const [
              DropdownMenuItem(value: 'friends_only', child: Text('Friends Only')),
              DropdownMenuItem(value: 'anyone', child: Text('Anyone')),
              DropdownMenuItem(value: 'nobody', child: Text('Nobody')),
            ],
            onChanged: (v) =>
                setState(() => _profileVisibility = v ?? 'friends_only'),
          ),

          const SizedBox(height: KitabSpacing.lg),
          const Divider(),
          const SizedBox(height: KitabSpacing.md),

          Text('Data & Analytics', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          SwitchListTile(
            title: const Text('Analytics'),
            subtitle: const Text(
              'Help us improve Kitab by sharing anonymous usage data',
            ),
            value: _analyticsEnabled,
            onChanged: (v) => setState(() => _analyticsEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: KitabSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                KitabToast.success(context, 'Privacy settings saved');
              },
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
