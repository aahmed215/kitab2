// ═══════════════════════════════════════════════════════════════════
// ENV.DART — Environment Configuration
// Loads environment variables from .env file.
// NEVER hardcode secrets — always read from .env (gitignored).
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provides type-safe access to environment variables.
/// All values are loaded from the .env file at app startup.
class Env {
  /// Supabase project URL (e.g., https://xxxxx.supabase.co)
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase publishable/anon key (safe for client code)
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// PostHog API key for analytics (empty until configured)
  static String get posthogApiKey =>
      dotenv.env['POSTHOG_API_KEY'] ?? '';

  /// Sentry DSN for crash reporting (empty until configured)
  static String get sentryDsn =>
      dotenv.env['SENTRY_DSN'] ?? '';

  /// Validates that required environment variables are set.
  /// Call this during app initialization.
  static void validate() {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL is not set in .env');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is not set in .env');
  }
}
