// ═══════════════════════════════════════════════════════════════════
// ROUTINES_LIST_SCREEN.DART — List of user's routines
// See SPEC.md §6 for routine specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../data/models/routine.dart';
import 'routine_detail_screen.dart';
import 'routine_form_screen.dart';

final _activeRoutinesProvider = StreamProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).watchActiveByUser(ref.watch(currentUserIdProvider));
});

class RoutinesListScreen extends ConsumerStatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  ConsumerState<RoutinesListScreen> createState() => _RoutinesListScreenState();
}

class _RoutinesListScreenState extends ConsumerState<RoutinesListScreen> {
  void _refreshProviders() {
    ref.invalidate(_activeRoutinesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(_activeRoutinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Routines', style: KitabTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RoutineFormScreen()));
              _refreshProviders();
            },
          ),
        ],
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text('No routines yet', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  Text(
                    'Routines let you chain activities together\n'
                    'for habit stacking',
                    style: KitabTypography.body
                        .copyWith(color: KitabColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KitabSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RoutineFormScreen()));
                      _refreshProviders();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Routine'),
                  ),
                ],
              ),
            );
          }

          final sorted = [...routines]
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final routine = sorted[index];
              return ListTile(
                leading: const Icon(Icons.repeat, color: KitabColors.primary),
                title: Text(
                  routine.isPrivate ? '••••••••' : routine.name,
                  style: KitabTypography.body,
                ),
                subtitle: Text(
                  '${routine.activitySequence.length} activities',
                  style: KitabTypography.caption
                      .copyWith(color: KitabColors.gray500),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: KitabColors.gray400),
                onTap: () async {
                  await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)));
                  _refreshProviders();
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
