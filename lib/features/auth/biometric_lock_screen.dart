// ═══════════════════════════════════════════════════════════════════
// BIOMETRIC_LOCK_SCREEN.DART — Biometric / PIN Lock
// Uses local_auth for fingerprint / Face ID on native.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/kitab_theme.dart';

class BiometricLockScreen extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const BiometricLockScreen({super.key, required this.child, this.enabled = false});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      _authenticate();
    } else {
      _unlocked = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app goes to background and comes back
    if (state == AppLifecycleState.resumed && widget.enabled && _unlocked) {
      setState(() => _unlocked = false);
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    _authenticating = true;

    try {
      final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) {
        setState(() => _unlocked = true);
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access Kitab',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );

      if (mounted) setState(() => _unlocked = authenticated);
    } on PlatformException {
      // Biometric not available — unlock
      if (mounted) setState(() => _unlocked = true);
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _unlocked) return widget.child;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Kitab', style: KitabTypography.display.copyWith(color: KitabColors.primary)),
            const SizedBox(height: KitabSpacing.xl),
            const Icon(Icons.lock_outline, size: 64, color: KitabColors.gray400),
            const SizedBox(height: KitabSpacing.lg),
            Text('Locked', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.md),
            FilledButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
