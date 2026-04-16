// ═══════════════════════════════════════════════════════════════════
// PROFILE_SCREEN.DART — Profile & Settings Screen
// The user's hub for managing their account, activities,
// routines, categories, and all app settings.
// See SPEC.md §14.5 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/kitab_theme.dart';
import '../auth/sign_in_screen.dart';
import 'activities/activities_list_screen.dart';
import 'categories/categories_screen.dart';
import 'edit_profile_screen.dart';
import 'routines/routines_list_screen.dart';
import 'settings/appearance_screen.dart';
import 'settings/calendar_settings_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/privacy_screen.dart';
import 'settings/condition_presets_screen.dart';
import 'settings/data_storage_screen.dart';
import 'settings/about_screen.dart';

/// Profile data from public.users table (name, last_name, avatar_url).
/// This is the source of truth — NOT auth metadata.
class _ProfileData {
  final String? name;
  final String? lastName;
  final String? avatarUrl;
  const _ProfileData({this.name, this.lastName, this.avatarUrl});

  String get displayName {
    final parts = [if (name != null && name!.isNotEmpty) name!];
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isEmpty ? 'User' : parts.join(' ');
  }

  String? get initial => name != null && name!.isNotEmpty ? name![0].toUpperCase() : null;
}

final _profileDataProvider = FutureProvider<_ProfileData>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'local-user') return const _ProfileData();
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, last_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return const _ProfileData();
    return _ProfileData(
      name: response['name'] as String?,
      lastName: response['last_name'] as String?,
      avatarUrl: response['avatar_url'] as String?,
    );
  } catch (_) {
    return const _ProfileData();
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: KitabTypography.h1),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg),
        children: [
          // ─── Profile Card (Guest Mode) ───
          _ProfileCard(),
          const SizedBox(height: KitabSpacing.xl),

          // ─── Content Management ───
          _SectionHeader(title: 'Content'),
          _SettingsTile(
            icon: Icons.healing,
            title: 'Condition Presets',
            subtitle: 'Illness, travel, and custom conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ConditionPresetsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.folder_outlined,
            title: 'Categories',
            subtitle: 'Organize your activities',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategoriesScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.fitness_center,
            title: 'My Activities',
            subtitle: 'Create and manage activity templates',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ActivitiesListScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.repeat,
            title: 'My Routines',
            subtitle: 'Habit stacking sequences',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RoutinesListScreen()),
            ),
          ),

          const SizedBox(height: KitabSpacing.lg),

          // ─── Settings ───
          _SectionHeader(title: 'Settings'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Light, Dark, or System Auto',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.calendar_today,
            title: 'Calendar & Date',
            subtitle: 'Hijri, prayer times, date format',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalendarSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Reminders, streaks, social',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & Sharing',
            subtitle: 'Default sharing, profile visibility',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Data & Storage',
            subtitle: 'Export, import, cache',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DataStorageScreen()),
            ),
          ),

          const SizedBox(height: KitabSpacing.lg),

          // ─── Account ───
          _SectionHeader(title: 'Account'),
          Consumer(
            builder: (context, ref, _) {
              final isAuthenticated = ref.watch(isAuthenticatedProvider);
              if (isAuthenticated) {
                return _SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: kIsWeb ? 'You will need to sign in again' : 'Your local data will be preserved',
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out?'),
                        content: Text(kIsWeb
                            ? 'You will be returned to the sign in screen.'
                            : 'Your data will remain on this device.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authServiceProvider).signOut();
                      if (kIsWeb && context.mounted) {
                        // Web: navigate back to root which shows auth gate
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const KitabApp()),
                          (_) => false,
                        );
                      }
                      // Native: stays on current screen with local data
                    }
                  },
                );
              }
              return _SettingsTile(
                icon: Icons.person_add_outlined,
                title: 'Sign In / Create Account',
                subtitle: 'Sync across devices and access social features',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignInScreen()),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version, licenses, contact',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),

          const SizedBox(height: KitabSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROFILE CARD
// ═══════════════════════════════════════════════════════════════════

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isSignedIn = user != null;
    final email = user?.email;

    // Read profile data from public.users (source of truth)
    final profileData = ref.watch(_profileDataProvider).valueOrNull ?? const _ProfileData();
    final displayName = isSignedIn ? profileData.displayName : 'Guest User';
    final initial = profileData.initial;
    final avatarUrl = profileData.avatarUrl;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        // Refresh profile data after returning from edit
        ref.invalidate(_profileDataProvider);
      },
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: KitabRadii.borderMd,
        boxShadow: isDark ? null : KitabShadows.level1,
        border: isDark ? Border.all(color: KitabColors.darkBorder) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: KitabColors.primary.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? (initial != null
                    ? Text(initial, style: KitabTypography.h2.copyWith(color: KitabColors.primary))
                    : const Icon(Icons.person, color: KitabColors.primary, size: 28))
                : null,
          ),
          const SizedBox(width: KitabSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: KitabTypography.h3),
                const SizedBox(height: 2),
                Text(
                  isSignedIn ? (email ?? 'Tap to edit profile') : 'Create an account to sync and share',
                  style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: KitabColors.gray400),
        ],
      ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: KitabSpacing.sm,
        bottom: KitabSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: KitabTypography.caption.copyWith(
          color: KitabColors.gray500,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: KitabColors.primary),
      title: Text(title, style: KitabTypography.body),
      subtitle: Text(
        subtitle,
        style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
      ),
      trailing: const Icon(Icons.chevron_right, color: KitabColors.gray400),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
