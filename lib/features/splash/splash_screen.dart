// ═══════════════════════════════════════════════════════════════════
// SPLASH_SCREEN.DART — "The Opening Page"
// Uses a Rive animation of a book opening, with "Kitab" and
// tagline fading in below. Crossfades to the next screen.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../core/theme/kitab_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Text fade-in
  late final AnimationController _textController;
  // Final crossfade out
  late final AnimationController _fadeOutController;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Let the Rive animation play for a bit before showing text
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Fade in text
    await _textController.forward();
    if (!mounted) return;

    // Hold so user can read
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Crossfade out
    await _fadeOutController.forward();
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? KitabColors.darkBackground : const Color(0xFFFAFAF8);

    return AnimatedBuilder(
      animation: _fadeOutController,
      builder: (context, _) {
        return Opacity(
          opacity: 1.0 - _fadeOutController.value,
          child: Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Rive Book Animation ───
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: RiveAnimation.asset(
                      'assets/animations/splash_book.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── "Kitab" ───
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _textController,
                      curve: Curves.easeOut,
                    ),
                    child: Text(
                      'Kitab',
                      style: KitabTypography.display.copyWith(
                        color: KitabColors.primary,
                        fontSize: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ─── Tagline ───
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _textController,
                      curve:
                          const Interval(0.3, 1.0, curve: Curves.easeOut),
                    ),
                    child: Text(
                      'Track your journey. Grow every day.',
                      style: KitabTypography.body
                          .copyWith(color: KitabColors.gray500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
