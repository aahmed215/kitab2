// ═══════════════════════════════════════════════════════════════════
// AUTH_PROVIDER.DART — Authentication State Management
// Wraps Supabase Auth and provides the current user ID to the
// entire app. All providers read userId from here instead of
// using a hardcoded temp ID.
// See SPEC.md §15 for auth specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The current Supabase auth state, reactive.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// The current user, or null if not signed in.
/// Watches authStateProvider so it re-evaluates on sign-in/sign-out.
final currentUserProvider = Provider<User?>((ref) {
  // Watch the auth state stream so this provider invalidates
  // whenever auth changes (sign in, sign out, token refresh).
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// The current user ID. Falls back to 'local-user' for offline/anonymous.
/// This is THE single source of truth for userId across the entire app.
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? 'local-user';
});

/// Whether the user is authenticated (has a Supabase session).
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Auth service for sign up, sign in, sign out operations.
class AuthService {
  final SupabaseClient _client;

  AuthService() : _client = Supabase.instance.client;

  /// Sign up with email + password.
  /// Supabase auto-creates a profile row via the DB trigger.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
      },
    );
    return response;
  }

  /// Sign in with email + password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.kitab://login-callback/',
    );
  }

  /// Sign in with Apple.
  Future<bool> signInWithApple() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.kitab://login-callback/',
    );
  }

  /// Send password reset email.
  /// The redirectTo URL must be configured in Supabase Dashboard →
  /// Auth → URL Configuration → Redirect URLs.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://mykitab.app/reset-password',
    );
  }

  /// Update password (called after user clicks reset link).
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sign out. Preserves local data.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Delete account. Cloud data is deleted via Supabase cascade.
  /// Local data is preserved (user can still browse offline).
  Future<void> deleteAccount() async {
    // The actual deletion happens via a Supabase Edge Function
    // that deletes the user and cascades to all their data.
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }

  /// Get current session.
  Session? get currentSession => _client.auth.currentSession;

  /// Get current user.
  User? get currentUser => _client.auth.currentUser;
}

/// Singleton auth service provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
