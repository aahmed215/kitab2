// ═══════════════════════════════════════════════════════════════════
// RESET_PASSWORD_SCREEN.DART — Set New Password
// Shown after the user clicks the password reset link in their
// email. They land back in the app with a session token, and
// this screen lets them enter a new password.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/kitab_theme.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _confirmError;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onConfirmChanged(String value) {
    setState(() {
      _confirmError = value == _passwordController.text
          ? null
          : 'Passwords do not match';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(KitabSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: KitabColors.success, size: 64),
                const SizedBox(height: KitabSpacing.lg),
                Text('Password Updated', style: KitabTypography.h2),
                const SizedBox(height: KitabSpacing.md),
                Text('You can now sign in with your new password.',
                    style: KitabTypography.body
                        .copyWith(color: KitabColors.gray500)),
                const SizedBox(height: KitabSpacing.xl),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text('New Password', style: KitabTypography.h2)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a new password',
                    style: KitabTypography.h2),
                const SizedBox(height: KitabSpacing.sm),
                Text('Must be at least 8 characters.',
                    style: KitabTypography.body
                        .copyWith(color: KitabColors.gray500)),
                const SizedBox(height: KitabSpacing.xl),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KitabColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: TextStyle(color: KitabColors.error)),
                  ),
                  const SizedBox(height: KitabSpacing.lg),
                ],

                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: KitabSpacing.md),

                TextField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: _confirmError,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: _onConfirmChanged,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: KitabSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit && !_loading ? _submit : null,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _passwordController.text.length >= 8 &&
      _confirmController.text == _passwordController.text &&
      _confirmError == null;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .updatePassword(_passwordController.text);
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to update password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
