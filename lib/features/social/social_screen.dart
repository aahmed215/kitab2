// ═══════════════════════════════════════════════════════════════════
// SOCIAL_SCREEN.DART — Social Hub
// Three tabs: Friends, Shared, Competitions.
// Requires authentication — shows gate if not signed in.
// See SPEC.md §14.6 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import '../auth/sign_in_screen.dart';

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return _AuthGate();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Social', style: KitabTypography.h1),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Shared'),
              Tab(text: 'Competitions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FriendsTab(),
            _SharedTab(),
            _CompetitionsTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AUTH GATE — Shown when user isn't signed in
// ═══════════════════════════════════════════════════════════════════

class _AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social', style: KitabTypography.h1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KitabSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👥', style: TextStyle(fontSize: 64)),
              const SizedBox(height: KitabSpacing.lg),
              Text('Connect with Friends',
                  style: KitabTypography.h2),
              const SizedBox(height: KitabSpacing.md),
              Text(
                'Create an account to share activities,\n'
                'encourage friends, and join competitions.',
                style: KitabTypography.body
                    .copyWith(color: KitabColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KitabSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignInScreen()),
                ),
                child: const Text('Sign In / Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FRIENDS TAB
// ═══════════════════════════════════════════════════════════════════

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        // Add friend button
        OutlinedButton.icon(
          onPressed: () => _showAddFriendDialog(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Add Friend'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: KitabSpacing.xl),

        // Pending requests section
        Text('Pending Requests', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        _EmptySection(text: 'No pending friend requests'),

        const SizedBox(height: KitabSpacing.xl),

        // Friends list
        Text('Friends', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        _EmptySection(
          text: 'No friends yet.\nAdd friends by username or email.',
        ),
      ],
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username or Email',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Send friend request via Supabase
              Navigator.pop(ctx);
              KitabToast.success(context, 'Friend request sent');
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED TAB
// ═══════════════════════════════════════════════════════════════════

class _SharedTab extends ConsumerWidget {
  const _SharedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        Text('Sharing Management', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        Text(
          'Control which activities and routines are shared with friends.',
          style: KitabTypography.body.copyWith(color: KitabColors.gray500),
        ),
        const SizedBox(height: KitabSpacing.lg),
        _EmptySection(
          text: 'No shared activities.\n'
              'Go to an activity\'s settings to share it with friends.',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMPETITIONS TAB
// ═══════════════════════════════════════════════════════════════════

class _CompetitionsTab extends ConsumerWidget {
  const _CompetitionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Competition creation flow
            KitabToast.show(context, 'Competition creation coming soon');
          },
          icon: const Icon(Icons.emoji_events),
          label: const Text('Create Competition'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: KitabSpacing.xl),

        Text('Active Competitions', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        _EmptySection(text: 'No active competitions'),

        const SizedBox(height: KitabSpacing.xl),

        Text('Completed', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.sm),
        _EmptySection(text: 'No completed competitions'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KitabSpacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: KitabRadii.borderMd,
      ),
      child: Text(
        text,
        style: KitabTypography.body.copyWith(color: KitabColors.gray400),
        textAlign: TextAlign.center,
      ),
    );
  }
}
