// ═══════════════════════════════════════════════════════════════════
// SIGN_UP_SCREEN.DART — Create Account Form
// First name, username (live check), email (format validation),
// password + confirm, age checkbox, ToS with link, social sign-in.
// See SPEC.md §15 for auth specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/utils/content_filter.dart';
import 'otp_verification_screen.dart';
import 'sign_in_screen.dart';


class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _ageConfirmed = false;
  bool _tosAccepted = false;
  String? _error;

  // Live validation state
  String? _usernameError;
  String? _usernameSuccess;
  bool _checkingUsername = false;
  Timer? _usernameDebounce;

  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // ─── Live username check ───
  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final username = value.trim().toLowerCase();

    if (username.isEmpty) {
      setState(() { _usernameError = null; _usernameSuccess = null; });
      return;
    }

    // Format check
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!regex.hasMatch(username)) {
      setState(() {
        _usernameError = username.length < 3
            ? 'Too short (min 3 characters)'
            : 'Only letters, numbers, and underscores';
        _usernameSuccess = null;
      });
      return;
    }

    // Content filter: reserved names + profanity/slurs/extremist
    final contentCheck = ContentFilter.checkUsername(username);
    if (!contentCheck.isClean) {
      setState(() {
        _usernameError = contentCheck.reason;
        _usernameSuccess = null;
      });
      return;
    }

    // Debounce the Supabase availability check (500ms)
    setState(() { _checkingUsername = true; _usernameError = null; _usernameSuccess = null; });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final available = await ref.read(userRepositoryProvider).isUsernameAvailable(username);
        if (!mounted) return;
        setState(() {
          _checkingUsername = false;
          if (available) {
            _usernameError = null;
            _usernameSuccess = 'Username available ✓';
          } else {
            _usernameError = 'Username already taken';
            _usernameSuccess = null;
          }
        });
      } catch (e) {
        if (mounted) setState(() { _checkingUsername = false; });
      }
    });
  }

  // ─── Live email check ───
  void _onEmailChanged(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    setState(() {
      _emailError = emailRegex.hasMatch(email) ? null : 'Enter a valid email address';
    });
  }

  // ─── Live password check ───
  void _onPasswordChanged(String value) {
    setState(() {
      _passwordError = value.length >= 8 ? null : 'At least 8 characters';
      // Also recheck confirm if it has content
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmError = value == _confirmPasswordController.text
            ? null
            : 'Passwords do not match';
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account', style: KitabTypography.h2),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(KitabSpacing.lg),
              children: [
                const SizedBox(height: KitabSpacing.md),

                Center(
                  child: Text('Kitab',
                      style: KitabTypography.display
                          .copyWith(color: KitabColors.primary)),
                ),
                Center(
                  child: Text('Track your journey. Grow every day.',
                      style: KitabTypography.body
                          .copyWith(color: KitabColors.gray500)),
                ),
                const SizedBox(height: KitabSpacing.xl),

                // ─── Social Sign-In ───
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: KitabSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: KitabSpacing.lg),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.md),
                      child: Text('or sign up with email',
                          style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: KitabSpacing.lg),

                // Error banner
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KitabColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: KitabColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: KitabColors.error))),
                      ],
                    ),
                  ),
                  const SizedBox(height: KitabSpacing.lg),
                ],

                // ─── First Name ───
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: KitabSpacing.md),

                // ─── Username (live check) ───
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    helperText: _usernameSuccess,
                    helperStyle: _usernameSuccess != null
                        ? const TextStyle(color: KitabColors.success)
                        : null,
                    errorText: _usernameError,
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameSuccess != null
                            ? const Icon(Icons.check_circle, color: KitabColors.success)
                            : null,
                  ),
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onChanged: _onUsernameChanged,
                ),
                const SizedBox(height: KitabSpacing.md),

                // ─── Email (format validation) ───
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                    suffixIcon: _emailError == null && _emailController.text.trim().isNotEmpty
                        ? const Icon(Icons.check_circle, color: KitabColors.success)
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onChanged: _onEmailChanged,
                ),
                const SizedBox(height: KitabSpacing.md),

                // ─── Password ───
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: _onPasswordChanged,
                ),
                const SizedBox(height: KitabSpacing.md),

                // ─── Confirm Password ───
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: _confirmError,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: _onConfirmChanged,
                ),
                const SizedBox(height: KitabSpacing.lg),

                // ─── Age confirmation ───
                CheckboxListTile(
                  value: _ageConfirmed,
                  onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                  title: const Text('I am 13 years or older'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // ─── ToS acceptance (with links) ───
                CheckboxListTile(
                  value: _tosAccepted,
                  onChanged: (v) => setState(() => _tosAccepted = v ?? false),
                  title: Wrap(
                    children: [
                      const Text('I agree to the '),
                      GestureDetector(
                        onTap: () => _showLegalScreen(context, 'Terms of Service', _termsText),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: KitabColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(' and '),
                      GestureDetector(
                        onTap: () => _showLegalScreen(context, 'Privacy Policy', _privacyText),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: KitabColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: KitabSpacing.lg),

                // ─── Create Account button ───
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit && !_loading ? _signUp : null,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: KitabSpacing.xl),

                // ─── Sign In link ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: KitabTypography.body),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignInScreen()),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: KitabSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _ageConfirmed &&
      _tosAccepted &&
      _emailController.text.trim().isNotEmpty &&
      _emailError == null &&
      _passwordController.text.length >= 8 &&
      _passwordError == null &&
      _confirmPasswordController.text == _passwordController.text &&
      _confirmError == null &&
      (_usernameController.text.trim().isEmpty || _usernameError == null);

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Content filter on name and username
    final nameCheck = ContentFilter.check(name);
    if (!nameCheck.isClean) {
      setState(() => _error = 'First Name: ${nameCheck.reason}');
      return;
    }
    final usernameCheck = ContentFilter.checkUsername(username);
    if (!usernameCheck.isClean) {
      setState(() => _error = 'Username: ${usernameCheck.reason}');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(authServiceProvider).signUp(
            email: email,
            password: password,
            name: name.isEmpty ? null : name,
            username: username.isEmpty ? null : username,
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showLegalScreen(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title, style: KitabTypography.h2)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            child: Text(content, style: KitabTypography.body),
          ),
        ),
      ),
    );
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already registered')) return 'This email is already registered';
    if (msg.contains('weak password')) return 'Password is too weak. Use at least 8 characters.';
    if (msg.contains('invalid email')) return 'Please enter a valid email address';
    if (msg.contains('network')) return 'Network error. Check your connection.';
    return 'Something went wrong. Please try again.';
  }
}

// ═══════════════════════════════════════════════════════════════════
// LEGAL TEXT (placeholder — replace with real legal text)
// ═══════════════════════════════════════════════════════════════════

const _termsText = '''
Terms of Service — Kitab

Last updated: April 6, 2026

1. Acceptance of Terms
By creating an account or using Kitab ("the App"), you agree to be bound by these Terms of Service.

2. Description of Service
Kitab is a habit and activity tracking application. The App allows users to create activity templates, log entries, track streaks and goals, and optionally share progress with friends.

3. User Accounts
- You must be 13 years or older to use this App.
- You are responsible for maintaining the security of your account.
- You may not use another person's account.
- Usernames must not be offensive, impersonate others, or violate these terms.

4. User Content
- You retain ownership of all data you enter into the App.
- You grant Kitab a limited license to store and process your data solely to provide the service.
- We will never sell your data to third parties.

5. Acceptable Use
You agree not to:
- Use the App for illegal purposes
- Harass, abuse, or threaten other users
- Attempt to gain unauthorized access to the App or its systems
- Use automated tools to access the App
- Upload malicious content

6. Privacy
Your privacy is important to us. Please review our Privacy Policy for details on how we collect, use, and protect your data.

7. Termination
- You may delete your account at any time from Settings → Account → Delete Account.
- We may suspend or terminate accounts that violate these terms.
- Upon account deletion, your cloud data is permanently removed. Local data on your device is preserved.

8. Disclaimer
The App is provided "as is" without warranties of any kind. We do not guarantee uninterrupted service.

9. Changes to Terms
We may update these terms. Continued use after changes constitutes acceptance.

10. Contact
For questions about these terms, contact us at support@mykitab.app.
''';

const _privacyText = '''
Privacy Policy — Kitab

Last updated: April 6, 2026

1. Information We Collect

Personal Information:
- Email address (for account creation and communication)
- Name and username (for your profile)
- Profile photo (optional)

Activity Data:
- Activities, entries, goals, streaks, and other tracking data you create
- This data is yours and is stored to provide the service

Device Information:
- Device type, operating system version
- App version
- Crash reports (via Sentry, anonymized)

Usage Analytics:
- Screen views and feature usage (via PostHog)
- No personally identifiable information is included in analytics
- You can opt out in Settings → Privacy → Analytics

Location Data:
- Only collected when you explicitly enable prayer time features
- Used solely to calculate accurate prayer times for your location
- Never shared with third parties

2. How We Use Your Data
- To provide and improve the App
- To sync your data across devices
- To send notifications you've opted into
- To detect and prevent abuse
- To generate anonymized, aggregated insights about App usage

3. Data Storage
- Cloud data is stored on Supabase (hosted on AWS, us-east-1)
- Local data on native apps is stored in an encrypted SQLite database on your device
- All data in transit is encrypted via TLS

4. Data Sharing
We do not sell your data. We share data only:
- With Supabase (our database provider) to store your data
- With Sentry (crash reporting) — anonymized crash data only
- With PostHog (analytics) — anonymized usage data only
- When required by law

5. Your Rights
- Access: You can export all your data from Settings → Data & Storage → Export
- Deletion: You can delete your account and all cloud data from Settings → Account → Delete Account
- Portability: Export is available in JSON format
- Opt-out: You can disable analytics in Settings → Privacy

6. Children's Privacy
Kitab is not intended for children under 13. We do not knowingly collect data from children under 13.

7. Changes to This Policy
We may update this policy. We will notify you of significant changes via in-app notification.

8. Contact
For privacy questions, contact us at privacy@mykitab.app.
''';
