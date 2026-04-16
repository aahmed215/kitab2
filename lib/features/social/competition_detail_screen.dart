// ═══════════════════════════════════════════════════════════════════
// COMPETITION_DETAIL_SCREEN.DART — Competition View
// Rules, leaderboard, personal progress, log entry, leave.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import '../../data/models/social.dart';

class CompetitionDetailScreen extends ConsumerWidget {
  final Competition competition;
  const CompetitionDetailScreen({super.key, required this.competition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final isCreator = competition.creatorId == userId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(competition.name, style: KitabTypography.h2),
          actions: [
            if (!isCreator)
              PopupMenuButton(
                itemBuilder: (_) => [const PopupMenuItem(value: 'leave', child: Text('Leave Competition', style: TextStyle(color: KitabColors.error)))],
                onSelected: (v) { if (v == 'leave') _confirmLeave(context); },
              ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Leaderboard'), Tab(text: 'Rules'), Tab(text: 'My Progress')]),
        ),
        body: TabBarView(children: [
          _LeaderboardTab(competition: competition),
          _RulesTab(competition: competition),
          _ProgressTab(competition: competition),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () { KitabToast.show(context, 'Log competition entry'); },
          icon: const Icon(Icons.add),
          label: const Text('Log Entry'),
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Leave Competition?'),
      content: const Text('Your entries will remain but you won\'t appear on the leaderboard.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: KitabColors.error), onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Leave')),
      ],
    ));
  }
}

class _LeaderboardTab extends StatelessWidget {
  final Competition competition;
  const _LeaderboardTab({required this.competition});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        Text('Leaderboard', style: KitabTypography.h3),
        const SizedBox(height: KitabSpacing.md),
        // Placeholder leaderboard entries
        ...List.generate(5, (i) => ListTile(
          leading: CircleAvatar(backgroundColor: i == 0 ? KitabColors.accent : KitabColors.gray200, child: Text('${i + 1}', style: TextStyle(color: i == 0 ? Colors.white : KitabColors.gray700))),
          title: Text('Participant ${i + 1}', style: KitabTypography.body),
          trailing: Text('${(5 - i) * 12} pts', style: KitabTypography.mono),
        )),
      ],
    );
  }
}

class _RulesTab extends StatelessWidget {
  final Competition competition;
  const _RulesTab({required this.competition});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KitabSpacing.lg),
      children: [
        _InfoRow('Status', competition.status[0].toUpperCase() + competition.status.substring(1)),
        _InfoRow('Visibility', competition.visibility),
        _InfoRow('Start Date', competition.startDate.toString().split(' ')[0]),
        _InfoRow('End Date', competition.endDate.toString().split(' ')[0]),
        if (competition.rules != null) ...[
          const SizedBox(height: KitabSpacing.lg),
          Text('Rules', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),
          Text(competition.rules.toString(), style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KitabSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: KitabTypography.body), Text(value, style: KitabTypography.mono)],
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final Competition competition;
  const _ProgressTab({required this.competition});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📈', style: TextStyle(fontSize: 48)),
          const SizedBox(height: KitabSpacing.md),
          Text('Your Progress', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),
          Text('0 entries logged', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
        ],
      ),
    );
  }
}
