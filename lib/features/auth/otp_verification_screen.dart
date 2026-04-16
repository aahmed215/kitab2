// ═══════════════════════════════════════════════════════════════════
// OTP_VERIFICATION_SCREEN.DART — Email OTP Verification
// 8-digit code, 1 hour expiry. Shows after sign up.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/widgets/kitab_toast.dart';
import '../onboarding/onboarding_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Start with a 60s cooldown since an email was just sent during sign-up
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _cooldownTimer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Email', style: KitabTypography.h2)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: KitabSpacing.xl),
            Text('Check your email', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.sm),
            Text('We sent a verification code to:', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
            const SizedBox(height: KitabSpacing.xs),
            Text(widget.email, style: KitabTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: KitabSpacing.xl),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: KitabColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: KitabColors.error)),
              ),
              const SizedBox(height: KitabSpacing.lg),
            ],

            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                hintText: 'Enter 8-digit code',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              autofocus: true,
              textAlign: TextAlign.center,
              style: KitabTypography.mono.copyWith(fontSize: 20, letterSpacing: 4),
            ),
            const SizedBox(height: KitabSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: KitabSpacing.lg),

            Center(
              child: TextButton(
                onPressed: _resendCooldown > 0 || _loading ? null : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend code in ${_resendCooldown}s'
                      : "Didn't receive a code? Resend",
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) { setState(() => _error = 'Enter the code'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.verifyOTP(type: OtpType.signup, email: widget.email, token: code);
      if (mounted) {
        // Navigate to root — _RootDecider will detect auth and route to onboarding
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _PostVerificationRouter()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Invalid or expired code. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.resend(type: OtpType.signup, email: widget.email);
      if (mounted) {
        KitabToast.success(context, 'New code sent');
        _startCooldown();
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to resend. Try again later.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Brief screen shown after successful verification.
/// Redirects to the app root so _RootDecider handles routing.
class _PostVerificationRouter extends StatefulWidget {
  const _PostVerificationRouter();

  @override
  State<_PostVerificationRouter> createState() => _PostVerificationRouterState();
}

class _PostVerificationRouterState extends State<_PostVerificationRouter> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Go directly to onboarding — user just created their account
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: KitabColors.success, size: 64),
            const SizedBox(height: KitabSpacing.lg),
            Text('Email Verified!', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.sm),
            Text('Welcome to Kitab', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
          ],
        ),
      ),
    );
  }
}
