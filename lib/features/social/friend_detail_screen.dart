// ═══════════════════════════════════════════════════════════════════
// FRIEND_DETAIL_SCREEN.DART — Friend Profile + Shared Activities
// Shows streaks, completion rates, shared activities, reactions.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';

class FriendDetailScreen extends ConsumerWidget {
  final String friendId;
  final String friendName;

  const FriendDetailScreen({super.key, required this.friendId, required this.friendName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(friendName, style: KitabTypography.h2)),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          // Friend profile card
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: KitabColors.primary.withValues(alpha: 0.1), child: Text(friendName[0].toUpperCase(), style: KitabTypography.display.copyWith(color: KitabColors.primary))),
                const SizedBox(height: KitabSpacing.md),
                Text(friendName, style: KitabTypography.h2),
              ],
            ),
          ),
          const SizedBox(height: KitabSpacing.xl),

          // Shared activities
          Text('Shared Activities', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),
          Container(
            padding: const EdgeInsets.all(KitabSpacing.xl),
            decoration: BoxDecoration(border: Border.all(color: KitabColors.gray200), borderRadius: KitabRadii.borderMd),
            child: Text('No shared activities yet', style: KitabTypography.body.copyWith(color: KitabColors.gray400), textAlign: TextAlign.center),
          ),
          const SizedBox(height: KitabSpacing.xl),

          // Reactions
          Text('Send Encouragement', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.md),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReactionButton(emoji: '🔥', label: 'Fire'),
              _ReactionButton(emoji: '💪', label: 'Strong'),
              _ReactionButton(emoji: '👏', label: 'Clap'),
              _ReactionButton(emoji: '⭐', label: 'Star'),
              _ReactionButton(emoji: '🤲', label: 'Dua', isIslamic: true),
            ],
          ),
          const SizedBox(height: KitabSpacing.lg),

          // Canned messages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('Keep going!'), onPressed: () {}),
              ActionChip(label: const Text('You got this!'), onPressed: () {}),
              ActionChip(label: const Text('Proud of you!'), onPressed: () {}),
              ActionChip(label: const Text('Amazing!'), onPressed: () {}),
              ActionChip(label: const Text('MashAllah!'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isIslamic;

  const _ReactionButton({required this.emoji, required this.label, this.isIslamic = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        KitabToast.success(context, '$emoji sent!');
      },
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: KitabColors.gray100, border: Border.all(color: KitabColors.gray200)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 4),
          Text(label, style: KitabTypography.caption),
        ],
      ),
    );
  }
}
