// ═══════════════════════════════════════════════════════════════════
// CONDITION_PRESETS_SCREEN.DART — Manage Condition Presets
// Create, edit, delete condition templates.
// Sorted alphabetically. All presets (including defaults) can be
// edited or deleted. Emoji picker shows common emoji options.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/deletable_list_tile.dart';
import '../../../data/models/condition.dart';

const _uuid = Uuid();

/// Searchable emoji map: emoji → list of keywords.
const _emojiMap = {
  // Health
  '🤒': ['sick', 'fever', 'ill', 'illness', 'temperature', 'flu'],
  '🤕': ['injured', 'hurt', 'bandage', 'head', 'injury', 'wound'],
  '🤧': ['sneeze', 'cold', 'allergy', 'flu', 'sick'],
  '🤮': ['vomit', 'nausea', 'sick', 'stomach', 'food poisoning'],
  '🤢': ['nausea', 'sick', 'queasy', 'stomach'],
  '😷': ['mask', 'sick', 'covid', 'flu', 'contagious', 'quarantine'],
  '🩺': ['doctor', 'medical', 'checkup', 'exam', 'hospital'],
  '🩹': ['bandaid', 'wound', 'cut', 'heal', 'recovery'],
  '💉': ['injection', 'vaccine', 'shot', 'needle', 'blood'],
  '💊': ['medicine', 'pill', 'medication', 'drug', 'pharmacy'],
  '🏥': ['hospital', 'emergency', 'medical', 'surgery', 'clinic'],
  '🌡️': ['thermometer', 'temperature', 'fever', 'hot', 'cold'],
  '🩸': ['blood', 'period', 'menstrual', 'cycle', 'donation'],
  '🦠': ['virus', 'bacteria', 'germ', 'covid', 'infection', 'disease'],
  '🩻': ['xray', 'bone', 'scan', 'medical', 'fracture'],
  '🩼': ['crutch', 'broken', 'leg', 'walk', 'disabled'],
  '♿': ['wheelchair', 'disabled', 'accessibility', 'mobility'],

  // Body & Mind
  '🧠': ['brain', 'mental', 'mind', 'think', 'psychology', 'health'],
  '❤️': ['heart', 'love', 'health', 'cardiac'],
  '💔': ['heartbreak', 'sad', 'broken', 'grief', 'loss'],
  '❤️‍🩹': ['healing', 'mending', 'recovery', 'heart', 'better'],
  '😴': ['sleep', 'tired', 'rest', 'nap', 'fatigue', 'exhausted'],
  '😔': ['sad', 'depressed', 'down', 'mental', 'unhappy', 'mood'],
  '😰': ['anxiety', 'stress', 'worried', 'nervous', 'panic'],
  '😵': ['dizzy', 'confused', 'faint', 'overwhelmed'],
  '🧘': ['meditation', 'yoga', 'calm', 'relax', 'mindful', 'zen'],
  '🤰': ['pregnant', 'pregnancy', 'baby', 'expecting', 'maternity'],
  '👶': ['baby', 'newborn', 'child', 'birth', 'infant', 'parenting'],
  '💪': ['strong', 'muscle', 'gym', 'exercise', 'fitness'],
  '🦴': ['bone', 'fracture', 'break', 'skeleton', 'orthopedic'],
  '🦷': ['tooth', 'dental', 'dentist', 'toothache'],

  // Travel & Places
  '✈️': ['travel', 'flight', 'airplane', 'trip', 'vacation', 'abroad'],
  '🚗': ['car', 'drive', 'road', 'trip', 'commute', 'travel'],
  '🚆': ['train', 'rail', 'commute', 'travel', 'transit'],
  '🏖️': ['beach', 'vacation', 'holiday', 'summer', 'relax'],
  '🏔️': ['mountain', 'hiking', 'outdoors', 'adventure', 'nature'],
  '🌍': ['world', 'global', 'international', 'travel', 'earth'],
  '🏠': ['home', 'house', 'family', 'stay', 'domestic'],
  '📦': ['moving', 'packing', 'relocation', 'box', 'move'],
  '🧳': ['luggage', 'travel', 'trip', 'suitcase', 'packing'],
  '⛺': ['camping', 'tent', 'outdoors', 'nature', 'adventure'],

  // Faith & Culture
  '🕌': ['mosque', 'islam', 'prayer', 'salah', 'muslim', 'masjid'],
  '🌙': ['moon', 'crescent', 'ramadan', 'fasting', 'night', 'islam', 'eid'],
  '🕋': ['kaaba', 'hajj', 'mecca', 'pilgrimage', 'islam', 'umrah'],
  '📿': ['prayer beads', 'dhikr', 'rosary', 'tasbih', 'worship'],
  '🤲': ['dua', 'prayer', 'hands', 'supplication', 'worship', 'palms'],
  '🕊️': ['dove', 'peace', 'bereavement', 'memorial', 'death', 'grief'],
  '🙏': ['prayer', 'gratitude', 'thanks', 'worship', 'hope', 'faith'],
  '⛪': ['church', 'christian', 'worship', 'sunday'],

  // Events
  '🎉': ['party', 'celebration', 'holiday', 'festival', 'event', 'eid'],
  '🎊': ['confetti', 'celebration', 'party', 'new year', 'event'],
  '🎂': ['birthday', 'cake', 'celebration', 'anniversary'],
  '🎓': ['graduation', 'school', 'education', 'ceremony', 'degree'],
  '💒': ['wedding', 'marriage', 'ceremony', 'church'],
  '🏆': ['trophy', 'win', 'achievement', 'competition', 'award'],
  '🎄': ['christmas', 'holiday', 'winter', 'tree', 'december'],

  // Weather & Nature
  '☀️': ['sun', 'sunny', 'hot', 'summer', 'weather', 'bright'],
  '🌧️': ['rain', 'rainy', 'weather', 'storm', 'wet'],
  '❄️': ['snow', 'cold', 'winter', 'freeze', 'ice', 'weather'],
  '🌊': ['wave', 'ocean', 'sea', 'water', 'flood', 'tsunami'],
  '🔥': ['fire', 'hot', 'burn', 'flame', 'heat', 'streak'],
  '🌸': ['flower', 'spring', 'blossom', 'cherry', 'nature'],
  '⛈️': ['storm', 'thunder', 'lightning', 'weather', 'rain'],

  // Work & Life
  '💼': ['work', 'business', 'job', 'office', 'career', 'meeting'],
  '📚': ['study', 'book', 'school', 'education', 'read', 'learn'],
  '💻': ['computer', 'work', 'laptop', 'coding', 'tech', 'remote'],
  '📝': ['note', 'write', 'journal', 'memo', 'document'],
  '🔧': ['fix', 'repair', 'tool', 'maintenance', 'wrench'],
  '⚖️': ['balance', 'law', 'justice', 'legal', 'court'],
  '🎯': ['goal', 'target', 'focus', 'aim', 'bullseye'],
  '⛔': ['stop', 'no', 'forbidden', 'blocked', 'restricted'],
  '🚫': ['no', 'prohibited', 'banned', 'forbidden', 'cancel'],
  '⏸️': ['pause', 'break', 'rest', 'stop', 'wait', 'hold'],
  '🛑': ['stop', 'halt', 'end', 'blocked', 'cease'],
  '🛏️': ['bed', 'sleep', 'rest', 'bedroom', 'recovery'],
  '🏗️': ['construction', 'building', 'work', 'renovation'],
};

final conditionPresetsProvider =
    FutureProvider<List<ConditionPreset>>((ref) async {
  final presets = await ref
      .watch(conditionRepositoryProvider)
      .getPresetsByUser(ref.watch(currentUserIdProvider));
  // Sort alphabetically
  presets.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return presets;
});

class ConditionPresetsScreen extends ConsumerWidget {
  const ConditionPresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(conditionPresetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Condition Presets', style: KitabTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPresetDialog(context, ref),
          ),
        ],
      ),
      body: presetsAsync.when(
        data: (presets) {
          if (presets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text('No condition presets', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  Text(
                    'Add presets for common reasons to excuse activities',
                    style: KitabTypography.body.copyWith(color: KitabColors.gray500),
                  ),
                  const SizedBox(height: KitabSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => _showPresetDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Preset'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return DeletableListTile(
                key: ValueKey(preset.id),
                leading: Text(preset.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(preset.label, style: KitabTypography.body),
                subtitle: preset.isSystem
                    ? Text('Default', style: KitabTypography.caption.copyWith(color: KitabColors.gray400))
                    : Text('Custom', style: KitabTypography.caption.copyWith(color: KitabColors.primary)),
                onTap: () => _showPresetDialog(context, ref, existing: preset),
                onDelete: () async {
                  await ref.read(conditionRepositoryProvider).deletePreset(preset.id);
                  ref.invalidate(conditionPresetsProvider);
                },
                deleteConfirmTitle: 'Delete Condition?',
                deleteConfirmMessage: 'Remove "${preset.label}"? Active conditions using this preset won\'t be affected.',
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showPresetDialog(BuildContext context, WidgetRef ref, {ConditionPreset? existing}) {
    final isEditing = existing != null;
    final labelController = TextEditingController(text: existing?.label ?? '');
    final searchController = TextEditingController();
    String selectedEmoji = existing?.emoji ?? '🤒';
    String emojiSearch = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filter emojis by search
          final filteredEmojis = emojiSearch.isEmpty
              ? _emojiMap.keys.toList()
              : _emojiMap.entries
                  .where((e) => e.value.any((kw) =>
                      kw.contains(emojiSearch.toLowerCase())))
                  .map((e) => e.key)
                  .toList();

          return AlertDialog(
            title: Text(isEditing ? 'Edit Condition' : 'New Condition'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Condition name first
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Condition Name'),
                    autofocus: !isEditing,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: KitabSpacing.lg),

                  // Selected emoji preview
                  Row(
                    children: [
                      Text('Icon: ', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KitabColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: KitabColors.primary, width: 2),
                        ),
                        child: Center(child: Text(selectedEmoji, style: const TextStyle(fontSize: 26))),
                      ),
                    ],
                  ),
                  const SizedBox(height: KitabSpacing.sm),

                  // Emoji search
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search emojis (e.g. "fire", "sick", "travel")',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => emojiSearch = v),
                  ),
                  const SizedBox(height: KitabSpacing.sm),

                  // Emoji grid (scrollable)
                  SizedBox(
                    height: 160,
                    child: filteredEmojis.isEmpty
                        ? Center(child: Text('No emojis match "$emojiSearch"',
                            style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray400)))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: filteredEmojis.length,
                            itemBuilder: (context, index) {
                              final emoji = filteredEmojis[index];
                              final isSelected = emoji == selectedEmoji;
                              return GestureDetector(
                                onTap: () => setState(() => selectedEmoji = emoji),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? KitabColors.primary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(color: KitabColors.primary, width: 2)
                                        : null,
                                  ),
                                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final label = labelController.text.trim();
                  if (label.isEmpty) return;

                  final preset = ConditionPreset(
                    id: existing?.id ?? _uuid.v4(),
                    userId: ref.read(currentUserIdProvider),
                    label: label,
                    emoji: selectedEmoji,
                    isSystem: existing?.isSystem ?? false,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  );

                  await ref.read(conditionRepositoryProvider).savePreset(preset);
                  ref.invalidate(conditionPresetsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
