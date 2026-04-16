// ═══════════════════════════════════════════════════════════════════
// APP.DART — Root App Widget
// Sets up MaterialApp with theming, routing, and the app shell.
// Theme supports Light, Dark, and System Auto modes.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/kitab_theme.dart';
import 'core/utils/provider_refresh.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'core/widgets/adaptive_layout.dart';
import 'core/widgets/offline_banner.dart';
import 'core/widgets/fab_speed_dial.dart';
import 'core/widgets/timer_mini_bar.dart';
import 'features/book/book_screen.dart';
import 'features/home/providers/home_providers.dart';
import 'features/entry/habit_quick_log.dart';
import 'features/entry/metric_quick_log.dart';
import 'features/entry/start_condition_sheet.dart';
import 'features/entry/timer_quick_log.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/social/social_screen.dart';
import 'features/splash/splash_screen.dart';

/// The root widget of the Kitab app.
/// Wraps MaterialApp with the Kitab design system theme.
class KitabApp extends ConsumerWidget {
  const KitabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kitab',
      debugShowCheckedModeBanner: false,

      // ─── Theming ───
      theme: KitabTheme.light,
      darkTheme: KitabTheme.dark,
      themeMode: themeMode,

      // ─── Root Screen ───
      home: const _RootDecider(),
    );
  }
}

/// Controls the app startup flow per SPEC §2.7:
///
/// NATIVE:
///   Splash → [No account, first time] → Onboarding → Home
///   Splash → [No account, returning] → Home (local data)
///   Splash → [Has account] → Home (synced data)
///
/// WEB:
///   Splash → [Not signed in] → Sign In / Create Account
///   Splash → [Signed in, first time] → Onboarding → Home
///   Splash → [Signed in, returning] → Home
class _RootDecider extends ConsumerStatefulWidget {
  const _RootDecider();

  @override
  ConsumerState<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends ConsumerState<_RootDecider> {
  bool _splashDone = false;

  void _onSplashComplete() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Show splash screen
    if (!_splashDone) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    // Phase 2: Platform-specific routing

    if (kIsWeb) {
      // WEB: Must be signed in first
      final isAuthenticated = ref.watch(isAuthenticatedProvider);

      if (!isAuthenticated) {
        // Not signed in → show auth gate
        return const _WebAuthGate();
      }

      // Signed in → check if onboarding is done
      final onboardingAsync = ref.watch(onboardingCompleteProvider);
      return onboardingAsync.when(
        data: (complete) {
          if (complete) return const AppShell();
          return const OnboardingScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => const OnboardingScreen(),
      );
    }

    // NATIVE: No account required — check onboarding only
    final onboardingAsync = ref.watch(onboardingCompleteProvider);
    return onboardingAsync.when(
      data: (complete) {
        if (complete) return const AppShell();
        return const OnboardingScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const AppShell(),
    );
  }
}

/// Web-only: shown when user is not signed in.
/// Provides Sign In and Create Account options.
class _WebAuthGate extends StatelessWidget {
  const _WebAuthGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(KitabSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Text(
                    'Kitab',
                    style: KitabTypography.display.copyWith(
                      color: KitabColors.primary,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: KitabSpacing.sm),
                  Text(
                    'Track your journey. Grow every day.',
                    style: KitabTypography.body.copyWith(
                      color: KitabColors.gray500,
                    ),
                  ),
                  const SizedBox(height: KitabSpacing.xxl),
                  const SizedBox(height: KitabSpacing.xl),

                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInScreen(),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: KitabSpacing.md),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignUpScreen(),
                        ),
                      ),
                      child: const Text('Create Account'),
                    ),
                  ),

                  // ─── DEBUG: Replay Splash (remove before release) ───
                  const SizedBox(height: KitabSpacing.xxl),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SplashScreen(
                            onComplete: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay, size: 16),
                    label: Text(
                      'Replay Splash Animation',
                      style: KitabTypography.caption.copyWith(
                        color: KitabColors.gray400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The main app shell with adaptive navigation.
/// Phone: bottom nav. Tablet/Desktop: icon rail on left.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Currently selected tab index
  int _currentIndex = 0;
  final _bookScreenKey = GlobalKey<BookScreenState>();

  /// Handle tab change — check for unsaved changes before switching.
  void _handleTabChange(int index) {
    // If leaving the Book screen (index 1) with unsaved changes, prompt
    if (_currentIndex == 1 && index != 1) {
      final bookState = _bookScreenKey.currentState;
      if (bookState != null && bookState.hasDirtyForm) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard unsaved changes?'),
            content: const Text('You have unsaved entry changes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep Editing'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  bookState.discardChanges();
                  setState(() => _currentIndex = index);
                },
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  /// Refresh all entry/condition/status providers after any logged action.
  /// Delegates to the centralized helper so the list stays in sync.
  void _refreshAfterLog() => refreshAllEntryProviders(ref);

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: AdaptiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => _handleTabChange(index),
      screens: [
        const HomeScreen(),
        BookScreen(key: _bookScreenKey),
        const InsightsScreen(),
        const SocialScreen(),
        const ProfileScreen(),
      ],
      // ─── Timer mini-bar (above bottom nav) ───
      bottomWidget: TimerMiniBar(
        onTimerTapped: (timerId) async {
          await reopenTimerSheet(context, timerId);
          _refreshAfterLog();
        },
      ),
      // ─── FAB ───
      floatingActionButton: FabSpeedDial(
        onStartCondition: () async {
          await showStartConditionSheet(context);
          _refreshAfterLog();
        },
        onQuickLog: (type) async {
          switch (type) {
            case QuickLogType.timer:
              await showTimerQuickLog(context, ref: ref);
            case QuickLogType.habit:
              await showHabitQuickLog(context);
            case QuickLogType.metric:
              await showMetricQuickLog(context);
          }
          _refreshAfterLog();
        },
      ),
    ),
    );
  }
}
