// ═══════════════════════════════════════════════════════════════════
// CATEGORIES_SCREEN.DART — Category Management
// Create, edit, delete activity categories.
// Sorted alphabetically. Must always have at least 1 category.
// Same emoji picker pattern as condition presets + color picker.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/widgets/deletable_list_tile.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/kitab_toast.dart';
import '../../../data/models/category.dart';

/// Searchable emoji map for categories — broad variety across life domains.
const _emojiMap = {
  // General
  '📁': ['folder', 'file', 'category', 'general', 'default'],
  '📋': ['clipboard', 'list', 'tasks', 'todo', 'checklist'],
  '⭐': ['star', 'favorite', 'important', 'special', 'top'],
  '🎯': ['goal', 'target', 'focus', 'aim', 'productivity'],
  '🔥': ['fire', 'hot', 'streak', 'motivation', 'intense'],
  '✨': ['sparkle', 'magic', 'special', 'new', 'shine'],
  '💡': ['idea', 'lightbulb', 'think', 'creative', 'insight'],
  '🏷️': ['tag', 'label', 'category', 'mark'],

  // Faith & Spiritual
  '🕌': ['mosque', 'islam', 'prayer', 'worship', 'spiritual', 'faith', 'masjid'],
  '🌙': ['moon', 'crescent', 'ramadan', 'fasting', 'islam', 'night'],
  '🕋': ['kaaba', 'hajj', 'mecca', 'pilgrimage', 'islam', 'umrah'],
  '📿': ['beads', 'dhikr', 'tasbih', 'worship', 'prayer', 'rosary'],
  '🤲': ['dua', 'prayer', 'hands', 'supplication', 'palms', 'worship'],
  '🙏': ['prayer', 'gratitude', 'thanks', 'worship', 'faith', 'hope'],
  '📖': ['quran', 'book', 'read', 'scripture', 'holy', 'bible'],
  '⛪': ['church', 'christian', 'worship', 'faith'],
  '🕊️': ['dove', 'peace', 'faith', 'spiritual', 'hope'],
  '☪️': ['islam', 'muslim', 'crescent', 'star'],

  // Health & Fitness
  '💪': ['strong', 'muscle', 'gym', 'exercise', 'fitness', 'health'],
  '🏃': ['run', 'exercise', 'sport', 'jog', 'cardio', 'fitness'],
  '🏋️': ['weightlifting', 'gym', 'strength', 'workout', 'barbell'],
  '🚴': ['cycling', 'bike', 'bicycle', 'exercise', 'cardio'],
  '🏊': ['swimming', 'pool', 'water', 'exercise', 'sport'],
  '🧘': ['meditation', 'yoga', 'calm', 'relax', 'mindful', 'zen'],
  '❤️': ['heart', 'love', 'health', 'wellbeing', 'self care', 'cardio'],
  '💊': ['medicine', 'health', 'pill', 'medication', 'vitamin'],
  '🩺': ['doctor', 'medical', 'checkup', 'health', 'hospital'],
  '🧠': ['brain', 'mental', 'mind', 'think', 'psychology', 'focus'],
  '😴': ['sleep', 'rest', 'tired', 'nap', 'recovery'],
  '💧': ['water', 'drink', 'hydration', 'drop', 'liquid'],
  '🥗': ['salad', 'healthy', 'food', 'diet', 'nutrition', 'vegetable'],
  '⚖️': ['scale', 'weight', 'balance', 'measure', 'body'],

  // Food & Nutrition
  '🍎': ['food', 'nutrition', 'diet', 'apple', 'health', 'eat', 'fruit'],
  '🍳': ['cooking', 'breakfast', 'food', 'kitchen', 'eggs', 'meal'],
  '🥤': ['drink', 'beverage', 'smoothie', 'juice'],
  '☕': ['coffee', 'tea', 'drink', 'morning', 'cafe', 'caffeine'],
  '🍽️': ['meal', 'dining', 'food', 'restaurant', 'plate', 'eat'],

  // Work & Productivity
  '💼': ['work', 'business', 'job', 'office', 'career', 'briefcase'],
  '💻': ['computer', 'work', 'laptop', 'coding', 'tech', 'remote'],
  '📊': ['chart', 'analytics', 'data', 'stats', 'business', 'graph'],
  '📈': ['growth', 'trending', 'up', 'progress', 'improve', 'stock'],
  '📧': ['email', 'mail', 'inbox', 'message', 'communication'],
  '🗓️': ['calendar', 'schedule', 'plan', 'date', 'event', 'organize'],
  '⏰': ['clock', 'time', 'alarm', 'schedule', 'morning', 'timer'],
  '📌': ['pin', 'important', 'note', 'bookmark', 'save'],

  // Learning & Education
  '📚': ['book', 'study', 'school', 'education', 'read', 'learn', 'library'],
  '🎓': ['graduation', 'school', 'education', 'degree', 'university'],
  '📝': ['note', 'write', 'journal', 'memo', 'document', 'essay'],
  '🔬': ['science', 'research', 'lab', 'experiment', 'study'],
  '🌐': ['globe', 'language', 'international', 'web', 'internet', 'world'],
  '🧮': ['math', 'calculate', 'abacus', 'numbers', 'count'],

  // Creative & Hobbies
  '🎨': ['art', 'creative', 'design', 'paint', 'hobby', 'draw', 'color'],
  '🎵': ['music', 'song', 'instrument', 'play', 'listen', 'audio'],
  '🎸': ['guitar', 'music', 'instrument', 'band', 'play', 'rock'],
  '🎹': ['piano', 'keyboard', 'music', 'instrument', 'play'],
  '📸': ['camera', 'photo', 'photography', 'picture', 'snap'],
  '✏️': ['pencil', 'draw', 'write', 'sketch', 'art', 'design'],
  '🧶': ['knitting', 'craft', 'yarn', 'sewing', 'hobby', 'crochet'],
  '🎮': ['game', 'gaming', 'play', 'entertainment', 'fun', 'video'],
  '📺': ['tv', 'television', 'watch', 'show', 'movie', 'entertainment'],
  '🎬': ['movie', 'film', 'cinema', 'video', 'director', 'production'],

  // Home & Family
  '🏠': ['home', 'house', 'family', 'domestic', 'chores', 'shelter'],
  '👨‍👩‍👧': ['family', 'parents', 'children', 'home', 'together'],
  '👶': ['baby', 'child', 'parenting', 'family', 'kid', 'infant'],
  '🧹': ['clean', 'chores', 'house', 'tidy', 'sweep', 'housework'],
  '🛏️': ['bed', 'sleep', 'rest', 'bedroom', 'morning', 'night'],
  '🪴': ['plant', 'indoor', 'houseplant', 'green', 'decor'],
  '🧺': ['laundry', 'clothes', 'wash', 'clean', 'basket'],

  // Nature & Outdoors
  '🌱': ['plant', 'grow', 'garden', 'nature', 'green', 'growth', 'seed'],
  '🌿': ['herb', 'leaf', 'nature', 'green', 'organic', 'plant'],
  '🌳': ['tree', 'nature', 'outdoors', 'forest', 'park', 'green'],
  '🌊': ['ocean', 'sea', 'wave', 'water', 'beach', 'surf'],
  '⛰️': ['mountain', 'hiking', 'outdoors', 'adventure', 'climb', 'nature'],
  '☀️': ['sun', 'morning', 'bright', 'day', 'energy', 'weather'],
  '🌸': ['flower', 'spring', 'blossom', 'cherry', 'nature', 'beautiful'],

  // Social & Communication
  '🤝': ['handshake', 'social', 'friends', 'meeting', 'community', 'deal'],
  '👥': ['people', 'group', 'team', 'community', 'social', 'crowd'],
  '💬': ['chat', 'talk', 'message', 'conversation', 'speech', 'communicate'],
  '📱': ['phone', 'mobile', 'app', 'tech', 'screen', 'call'],
  '🎉': ['party', 'celebration', 'event', 'fun', 'holiday', 'birthday'],

  // Travel & Transport
  '✈️': ['travel', 'flight', 'airplane', 'trip', 'vacation', 'abroad'],
  '🚗': ['car', 'drive', 'commute', 'road', 'trip', 'transport'],
  '🏖️': ['beach', 'vacation', 'holiday', 'summer', 'relax', 'tropical'],
  '🗺️': ['map', 'travel', 'explore', 'adventure', 'navigate', 'trip'],
  '🧳': ['luggage', 'travel', 'trip', 'suitcase', 'packing', 'vacation'],

  // Finance & Money
  '💰': ['money', 'finance', 'budget', 'savings', 'bank', 'wealth'],
  '💳': ['credit', 'card', 'payment', 'shopping', 'bank', 'debit'],
  '🏦': ['bank', 'finance', 'money', 'savings', 'investment'],
  '📉': ['down', 'loss', 'decrease', 'spending', 'expense', 'stock'],

  // Animals & Pets
  '🐾': ['pet', 'animal', 'dog', 'cat', 'paw', 'walk'],
  '🐕': ['dog', 'pet', 'puppy', 'walk', 'animal'],
  '🐈': ['cat', 'pet', 'kitten', 'animal'],
  '🐴': ['horse', 'ride', 'equestrian', 'animal', 'ranch'],

  // Misc & Symbols
  '🎗️': ['ribbon', 'awareness', 'cause', 'support', 'charity'],
  '♻️': ['recycle', 'environment', 'eco', 'green', 'sustainability'],
  '🔧': ['tool', 'fix', 'repair', 'maintenance', 'wrench', 'diy'],
  '🚿': ['shower', 'hygiene', 'clean', 'bathroom', 'wash', 'routine'],
  '👔': ['formal', 'business', 'suit', 'professional', 'dress'],
  '🎭': ['theater', 'drama', 'acting', 'performance', 'arts'],
  '🏆': ['trophy', 'win', 'achievement', 'competition', 'award', 'champion'],
  '🧪': ['chemistry', 'experiment', 'lab', 'science', 'test'],
  '⚡': ['energy', 'power', 'electric', 'fast', 'lightning', 'quick'],
  '🛡️': ['shield', 'protect', 'security', 'safety', 'defense'],
};

/// Colors that work well in both light and dark mode.
/// Avoids whites, near-whites, near-blacks that would conflict.
const _colorOptions = [
  // Primary & Accent
  '#0D7377', '#C8963E',
  // Reds
  '#C43D3D', '#E74C3C', '#B71C1C',
  // Oranges
  '#E67E22', '#F39C12', '#D35400',
  // Yellows (deeper, not too bright)
  '#C49000', '#9E7C0C',
  // Greens
  '#2D8659', '#27AE60', '#1ABC9C', '#16A085',
  // Blues
  '#2D6B8A', '#3498DB', '#2980B9', '#1565C0',
  // Purples
  '#9B59B6', '#8E44AD', '#6C3483', '#7B1FA2',
  // Pinks
  '#C2185B', '#AD1457', '#E91E63',
  // Teals
  '#00838F', '#00695C', '#00897B',
  // Browns
  '#6D4C41', '#795548', '#8D6E63',
  // Grays (mid-tone, visible on both)
  '#546E7A', '#607D8B', '#455A64',
];

/// Provider for all categories, sorted alphabetically.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref
      .watch(categoryRepositoryProvider)
      .watchByUser(ref.watch(currentUserIdProvider))
      .map((list) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Categories', style: KitabTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text('No categories yet', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return DeletableListTile(
                key: ValueKey(category.id),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _parseColor(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(category.icon, style: const TextStyle(fontSize: 24)),
                  ],
                ),
                title: Text(category.name, style: KitabTypography.body),
                onTap: () => _showCategoryDialog(context, ref, existing: category),
                onDelete: () {
                  if (categories.length <= 1) {
                    KitabToast.error(context, 'Cannot delete the last category.');
                    return;
                  }
                  ref.read(categoryRepositoryProvider).delete(category.id);
                },
                deleteConfirmTitle: 'Delete Category?',
                deleteConfirmMessage: 'Activities in "${category.name}" will need to be moved to another category.',
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final searchController = TextEditingController();
    String selectedEmoji = existing?.icon ?? '📁';
    String selectedColor = existing?.color ?? '#0D7377';
    String emojiSearch = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredEmojis = emojiSearch.isEmpty
              ? _emojiMap.keys.toList()
              : _emojiMap.entries
                  .where((e) => e.value.any((kw) => kw.contains(emojiSearch.toLowerCase())))
                  .map((e) => e.key)
                  .toList();

          return AlertDialog(
            title: Text(isEditing ? 'Edit Category' : 'New Category'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g., Health, Spiritual, Work',
                      ),
                      autofocus: !isEditing,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: KitabSpacing.lg),

                    // Color picker
                    Text('Color', style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
                    const SizedBox(height: KitabSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _colorOptions.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _parseColor(color),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: _parseColor(color).withValues(alpha: 0.5), blurRadius: 6)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
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
                            color: _parseColor(selectedColor).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _parseColor(selectedColor), width: 2),
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
                        hintText: 'Search emojis...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) => setState(() => emojiSearch = v),
                    ),
                    const SizedBox(height: KitabSpacing.sm),

                    // Emoji grid
                    SizedBox(
                      height: 140,
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
                                          ? _parseColor(selectedColor).withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? Border.all(color: _parseColor(selectedColor), width: 2)
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final now = DateTime.now();
                  final category = Category(
                    id: existing?.id ?? const Uuid().v4(),
                    userId: ref.read(currentUserIdProvider),
                    name: name,
                    icon: selectedEmoji,
                    color: selectedColor,
                    sortOrder: existing?.sortOrder ?? 0,
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                  );

                  await ref.read(categoryRepositoryProvider).save(category);
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

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return KitabColors.primary;
  }
}
