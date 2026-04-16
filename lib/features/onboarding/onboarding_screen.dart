// ═══════════════════════════════════════════════════════════════════
// ONBOARDING_SCREEN.DART — First-Time User Setup Flow
// Native: Screen 0.5 (Welcome) → 1 (Name) → 2 (Carousel) →
//         3 (Islamic) → 4 (Activities) → 5 (Ready)
// Web:    Screen 1 (Name) → 2 (Carousel) → 3 (Islamic) →
//         4 (Activities) → 5 (Ready)
// See SPEC.md §14.7 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import '../../data/models/activity.dart';
import '../../data/models/category.dart' as domain;
import '../../data/models/condition.dart';
import '../auth/sign_in_screen.dart';
import '../splash/splash_screen.dart';

const _uuid = Uuid();

/// Whether onboarding has been completed.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final result = await Supabase.instance.client
        .from('categories')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    return (result as List).isNotEmpty;
  }
  final db = ref.watch(databaseProvider);
  final val = await db.syncDao.getMeta('onboarding_complete');
  return val == 'true';
});

// ═══════════════════════════════════════════════════════════════════
// TEMPLATE DATA — SPEC §14.7 Screen 4
// ═══════════════════════════════════════════════════════════════════

class _Template {
  final String icon, name, schedule, category, categoryIcon, categoryColor;
  final bool preSelected, islamicOnly;
  const _Template({required this.icon, required this.name, required this.schedule,
    required this.category, required this.categoryIcon, required this.categoryColor,
    this.preSelected = false, this.islamicOnly = false});
}

const _templates = [
  _Template(icon: '💧', name: 'Drink Water', schedule: 'daily', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659', preSelected: true),
  _Template(icon: '🏃', name: 'Exercise', schedule: '3x/week', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659'),
  _Template(icon: '📖', name: 'Read', schedule: 'daily', category: 'Personal', categoryIcon: '📚', categoryColor: '#2D6B8A', preSelected: true),
  _Template(icon: '😴', name: 'Track Sleep', schedule: 'daily', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659'),
  _Template(icon: '📝', name: 'Journal', schedule: 'daily', category: 'Personal', categoryIcon: '📚', categoryColor: '#2D6B8A'),
  _Template(icon: '🕐', name: 'Pray on Time', schedule: '5x/day', category: 'Spiritual', categoryIcon: '🕌', categoryColor: '#0D7377', preSelected: true, islamicOnly: true),
  _Template(icon: '📖', name: 'Read Quran', schedule: 'daily', category: 'Spiritual', categoryIcon: '🕌', categoryColor: '#0D7377', islamicOnly: true),
  _Template(icon: '🤲', name: 'Morning Athkar', schedule: 'daily', category: 'Spiritual', categoryIcon: '🕌', categoryColor: '#0D7377', islamicOnly: true),
  _Template(icon: '🤲', name: 'Evening Athkar', schedule: 'daily', category: 'Spiritual', categoryIcon: '🕌', categoryColor: '#0D7377', islamicOnly: true),
  _Template(icon: '📿', name: 'Dhikr Counter', schedule: 'daily', category: 'Spiritual', categoryIcon: '🕌', categoryColor: '#0D7377', islamicOnly: true),
  _Template(icon: '⚖️', name: 'Track Weight', schedule: 'daily', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659'),
  _Template(icon: '🧘', name: 'Meditate', schedule: 'daily', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659'),
  _Template(icon: '💊', name: 'Take Medication', schedule: 'daily', category: 'Health', categoryIcon: '💪', categoryColor: '#2D8659'),
  _Template(icon: '📚', name: 'Study', schedule: 'daily', category: 'Productivity', categoryIcon: '💼', categoryColor: '#C4841D'),
  _Template(icon: '💻', name: 'Deep Work', schedule: 'daily', category: 'Productivity', categoryIcon: '💼', categoryColor: '#C4841D'),
  _Template(icon: '📋', name: 'Plan Tomorrow', schedule: 'daily', category: 'Productivity', categoryIcon: '💼', categoryColor: '#C4841D'),
];

// ═══════════════════════════════════════════════════════════════════
// MAIN ONBOARDING WIDGET
// ═══════════════════════════════════════════════════════════════════

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  bool _islamicEnabled = false;
  final Set<String> _selectedTemplates = {};

  @override
  void initState() {
    super.initState();
    _selectedTemplates.addAll(['Drink Water', 'Read']);
  }

  @override
  void dispose() { _pageController.dispose(); _nameController.dispose(); super.dispose(); }

  void _next() { _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  void _back() { _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }

  List<Widget> _buildPages() {
    final pages = <Widget>[];
    if (!kIsWeb) pages.add(_WelcomePage(onGetStarted: _next));
    // Skip name screen on web — user already entered name during sign-up
    if (!kIsWeb) pages.add(_NamePage(controller: _nameController, onNext: _next, onBack: pages.isNotEmpty ? _back : null));
    pages.add(_CarouselPage(onNext: _next, onBack: _back));
    pages.add(_IslamicPage(
      onYes: () async {
        setState(() {
          _islamicEnabled = true;
          _selectedTemplates.add('Pray on Time');
        });
        // Save Islamic personalization to user settings
        ref.read(userSettingsProvider.notifier).update({
          'islamic_personalization': true,
          'hijri_calendar_enabled': true,
        });
        // Request location permission for prayer times
        final locationService = ref.read(locationServiceProvider);
        await locationService.requestPermission();
        // Fetch and cache location (don't block if denied)
        locationService.getLocation();
        _next();
      },
      onNo: () {
        setState(() => _islamicEnabled = false);
        ref.read(userSettingsProvider.notifier).update({
          'islamic_personalization': false,
        });
        _next();
      },
      onBack: _back,
    ));
    pages.add(_ActivitiesPage(islamicEnabled: _islamicEnabled, selected: _selectedTemplates,
      onToggle: (n) { setState(() { _selectedTemplates.contains(n) ? _selectedTemplates.remove(n) : _selectedTemplates.add(n); }); },
      onNext: _next, onBack: _back));
    pages.add(_ReadyPage(selectedCount: _selectedTemplates.length, onFinish: _complete, onBack: _back, saving: _saving));
    return pages;
  }

  bool _saving = false;

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final activityRepo = ref.read(activityRepositoryProvider);
      final now = DateTime.now();

      // Determine which categories are needed
      final neededCats = <String, _Template>{};
      for (final t in _templates) {
        if (_selectedTemplates.contains(t.name)) {
          neededCats.putIfAbsent(t.category, () => t);
        }
      }

      // Create categories
      final catIds = <String, String>{};
      var sort = 0;
      for (final e in neededCats.entries) {
        final id = _uuid.v4();
        await categoryRepo.save(domain.Category(
          id: id, userId: userId, name: e.key,
          icon: e.value.categoryIcon, color: e.value.categoryColor,
          sortOrder: sort++, createdAt: now, updatedAt: now,
        ));
        catIds[e.key] = id;
      }

      // Default category if nothing selected
      if (catIds.isEmpty) {
        final id = _uuid.v4();
        await categoryRepo.save(domain.Category(
          id: id, userId: userId, name: 'General',
          icon: '📁', color: '#0D7377',
          sortOrder: 0, createdAt: now, updatedAt: now,
        ));
      }

      // Create activities — start date is tomorrow so today doesn't
      // show as missed immediately after onboarding.
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      for (final t in _templates) {
        if (!_selectedTemplates.contains(t.name)) continue;
        final catId = catIds[t.category];
        if (catId == null) continue;
        await activityRepo.save(Activity(
          id: _uuid.v4(), userId: userId, categoryId: catId, name: t.name,
          schedule: {
            'versions': [{
              'effective_from': tomorrow.toIso8601String(),
              'effective_to': null,
              'config': {
                'frequency': 'daily',
                'calendar': 'gregorian',
                'start_date': tomorrow.toIso8601String(),
              },
            }],
          },
          createdAt: now, updatedAt: now,
        ));
      }

      // Seed default condition presets
      final conditionRepo = ref.read(conditionRepositoryProvider);
      final defaultPresets = [
        ('🤒', 'Illness', false),
        ('✈️', 'Travel', false),
        ('🤕', 'Injured', false),
        ('🩸', 'Menstrual Cycle', false),
        ('🏥', 'Hospitalization', false),
        ('🌙', 'Fasting', true), // Islamic only
        ('🕊️', 'Bereavement', false),
        ('📦', 'Moving', false),
        ('🎉', 'Holiday', false),
      ];

      for (final (emoji, label, islamicOnly) in defaultPresets) {
        if (islamicOnly && !_islamicEnabled) continue;
        await conditionRepo.savePreset(ConditionPreset(
          id: _uuid.v4(),
          userId: userId,
          label: label,
          emoji: emoji,
          isSystem: true,
          createdAt: now,
        ));
      }

      // Mark onboarding complete (native only)
      if (!kIsWeb) {
        final db = ref.read(databaseProvider);
        await db.syncDao.setMeta('onboarding_complete', 'true');
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        KitabToast.error(context, 'Error setting up: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage > 0 || kIsWeb)
              LinearProgressIndicator(value: (_currentPage + 1) / pages.length, backgroundColor: KitabColors.gray100, color: KitabColors.primary),
            Expanded(
              child: PageView(controller: _pageController, physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i), children: pages),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 0.5 — WELCOME (Native only)
// ═══════════════════════════════════════════════════════════════════

class _WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomePage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
      padding: const EdgeInsets.all(KitabSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text('Kitab', style: KitabTypography.display.copyWith(color: KitabColors.primary, fontSize: 48)),
          const SizedBox(height: KitabSpacing.sm),
          Text('Welcome to Kitab', style: KitabTypography.h2.copyWith(color: KitabColors.gray600)),
          const SizedBox(height: KitabSpacing.xxl),
          Text('Already have an account?', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
          const SizedBox(height: KitabSpacing.md),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
            child: const Text('Sign In'))),
          const SizedBox(height: KitabSpacing.xl),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.md),
              child: Text('or', style: KitabTypography.caption.copyWith(color: KitabColors.gray500))),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: KitabSpacing.xl),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: onGetStarted, child: const Text('Get Started'))),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SplashScreen(onComplete: () => Navigator.pop(context)))),
            icon: const Icon(Icons.replay, size: 16),
            label: Text('Replay Splash', style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
          ),
        ],
      ),
    ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 1 — YOUR NAME
// ═══════════════════════════════════════════════════════════════════

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const _NamePage({required this.controller, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
      padding: const EdgeInsets.all(KitabSpacing.xl),
      child: Column(children: [
        const Spacer(),
        Text('What should we call you?', style: KitabTypography.h2),
        const SizedBox(height: KitabSpacing.md),
        Text('This personalizes your experience.', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
        const SizedBox(height: KitabSpacing.xl),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Your first name', prefixIcon: Icon(Icons.person_outline)),
            textCapitalization: TextCapitalization.words, textAlign: TextAlign.center, autofocus: true)),
        const Spacer(),
        Row(children: [
          if (onBack != null) TextButton(onPressed: onBack, child: const Text('Back')),
          const Spacer(),
          TextButton(onPressed: onNext, child: const Text('Skip')),
          const SizedBox(width: KitabSpacing.sm),
          FilledButton(onPressed: onNext, child: const Text('Continue')),
        ]),
      ]),
    ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 2 — INTRO CAROUSEL
// ═══════════════════════════════════════════════════════════════════

class _CarouselPage extends StatefulWidget {
  final VoidCallback onNext, onBack;
  const _CarouselPage({required this.onNext, required this.onBack});
  @override
  State<_CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<_CarouselPage> {
  final _ctrl = PageController();
  int _page = 0;
  static const _slides = [
    ('📋', 'Track your habits, activities, and goals in one place.'),
    ('🔥', 'Build streaks, discover patterns, and grow every day.'),
    ('👥', 'Share progress with friends and compete in challenges.'),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Align(alignment: Alignment.topRight, child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.md),
        child: TextButton(onPressed: widget.onNext, child: const Text('Skip')))),
      Expanded(child: PageView.builder(
        controller: _ctrl, onPageChanged: (i) => setState(() => _page = i),
        itemCount: _slides.length, itemBuilder: (context, i) {
          final (icon, text) = _slides[i];
          return Padding(padding: const EdgeInsets.all(KitabSpacing.xl),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(icon, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: KitabSpacing.xl),
              Text(text, style: KitabTypography.bodyLarge.copyWith(color: KitabColors.gray600), textAlign: TextAlign.center),
            ]));
        })),
      Padding(padding: const EdgeInsets.all(KitabSpacing.lg), child: Row(children: [
        TextButton(onPressed: widget.onBack, child: const Text('Back')),
        const Spacer(),
        ...List.generate(_slides.length, (i) => Container(width: 8, height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: i == _page ? KitabColors.primary : KitabColors.gray300))),
        const Spacer(),
        FilledButton(
          onPressed: _page == _slides.length - 1 ? widget.onNext
            : () => _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          child: const Text('Next')),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 3 — ISLAMIC PERSONALIZATION
// ═══════════════════════════════════════════════════════════════════

class _IslamicPage extends StatelessWidget {
  final VoidCallback onYes, onNo, onBack;
  const _IslamicPage({required this.onYes, required this.onNo, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(padding: const EdgeInsets.all(KitabSpacing.xl), child: Column(children: [
      const Spacer(),
      const Text('🌙', style: TextStyle(fontSize: 64)),
      const SizedBox(height: KitabSpacing.xl),
      Text('Personalize Your Experience', style: KitabTypography.h2),
      const SizedBox(height: KitabSpacing.lg),
      Text('Kitab draws inspiration from Islamic tradition.\nWould you like Islamic personalization?',
        style: KitabTypography.body.copyWith(color: KitabColors.gray500), textAlign: TextAlign.center),
      const SizedBox(height: KitabSpacing.xl),
      ..._bullets(['Islamic greetings (Assalamu Alaikum)', 'Hijri calendar dates', 'Prayer time tracking', 'Ramadan insights & comparisons']),
      const SizedBox(height: KitabSpacing.xl),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: onYes, child: const Text('Yes, enable'))),
      const SizedBox(height: KitabSpacing.sm),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onNo, child: const Text('No thanks'))),
      const SizedBox(height: KitabSpacing.md),
      Text('You can change this anytime in Settings.', style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
      const Spacer(),
      Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: onBack, child: const Text('Back'))),
    ])),
    ),
    );
  }

  List<Widget> _bullets(List<String> items) => items.map((t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('•  ', style: TextStyle(color: KitabColors.primary, fontSize: 16)),
      Flexible(child: Text(t, style: KitabTypography.body)),
    ]))).toList();
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 4 — CHOOSE STARTING ACTIVITIES
// ═══════════════════════════════════════════════════════════════════

class _ActivitiesPage extends StatelessWidget {
  final bool islamicEnabled;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext, onBack;
  const _ActivitiesPage({required this.islamicEnabled, required this.selected,
    required this.onToggle, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final popular = ['Drink Water', 'Exercise', 'Read', 'Track Sleep', 'Journal'];
    final sections = <String, List<_Template>>{
      'Popular': _templates.where((t) => popular.contains(t.name)).toList(),
      if (islamicEnabled) 'Spiritual': _templates.where((t) => t.islamicOnly).toList(),
      'Health': _templates.where((t) => t.category == 'Health' && !popular.contains(t.name)).toList(),
      'Productivity': _templates.where((t) => t.category == 'Productivity').toList(),
    };
    sections.removeWhere((k, v) => v.isEmpty);

    return Column(children: [
      Padding(padding: const EdgeInsets.all(KitabSpacing.lg), child: Column(children: [
        Text('What would you like to track?', style: KitabTypography.h2),
        const SizedBox(height: KitabSpacing.xs),
        Text('Pick a few to get started. You can always add more later.',
          style: KitabTypography.body.copyWith(color: KitabColors.gray500), textAlign: TextAlign.center),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg), children: [
        for (final entry in sections.entries) ...[
          Padding(padding: const EdgeInsets.only(top: KitabSpacing.md, bottom: KitabSpacing.sm),
            child: Text('── ${entry.key} ──', style: KitabTypography.caption.copyWith(color: KitabColors.gray500, letterSpacing: 1))),
          ...entry.value.map((t) => CheckboxListTile(
            value: selected.contains(t.name), onChanged: (_) => onToggle(t.name),
            title: Text('${t.icon}  ${t.name}'),
            subtitle: Text(t.schedule, style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
            dense: true, controlAffinity: ListTileControlAffinity.leading)),
        ],
      ])),
      Container(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: KitabColors.gray100))),
        child: Column(children: [
          Text('Selected: ${selected.length} activities',
            style: KitabTypography.caption.copyWith(color: KitabColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: KitabSpacing.sm),
          Row(children: [
            TextButton(onPressed: onBack, child: const Text('Back')),
            const Spacer(),
            FilledButton(onPressed: onNext,
              child: Text(selected.isEmpty ? "Skip — I'll set up my own" : 'Continue with ${selected.length}')),
          ]),
        ]),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// SCREEN 5 — YOU'RE READY
// ═══════════════════════════════════════════════════════════════════

class _ReadyPage extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onFinish, onBack;
  final bool saving;
  const _ReadyPage({required this.selectedCount, required this.onFinish, required this.onBack, this.saving = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(padding: const EdgeInsets.all(KitabSpacing.xl), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: KitabSpacing.xl),
            Text('Your Kitab is ready!', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.md),
            if (selectedCount > 0) Text('$selectedCount activities added to your book.',
              style: KitabTypography.body.copyWith(color: KitabColors.gray500), textAlign: TextAlign.center),
            const SizedBox(height: KitabSpacing.xl),
            if (!kIsWeb) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: KitabColors.primary.withValues(alpha: 0.05),
                borderRadius: KitabRadii.borderMd, border: Border.all(color: KitabColors.primary.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline, color: KitabColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Your data is saved on this device. Create an account anytime to sync across devices and connect with friends.',
                  style: KitabTypography.bodySmall)),
              ])),
            if (kIsWeb) Text("You'll stay signed in automatically.\nJust open Kitab and start tracking.",
              style: KitabTypography.body.copyWith(color: KitabColors.gray500), textAlign: TextAlign.center),
            const Spacer(),
            Row(children: [TextButton(onPressed: onBack, child: const Text('Back')), const Spacer()]),
            const SizedBox(height: KitabSpacing.sm),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: saving ? null : onFinish,
              child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Start Your Journey'),
            )),
          ])),
      ),
    );
  }
}
