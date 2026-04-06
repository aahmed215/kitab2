// ═══════════════════════════════════════════════════════════════════
// SUPABASE_CONFIG.DART — Supabase Client Initialization
// Configures and provides the Supabase client instance.
// Uses the publishable key from .env — NEVER the service role key.
// ═══════════════════════════════════════════════════════════════════

import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Initializes the Supabase client.
/// Must be called once during app startup, after dotenv is loaded.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    // Enable debug logging in development
    debug: false,
  );
}

/// Global accessor for the Supabase client.
/// Use this throughout the app to access Supabase services.
SupabaseClient get supabase => Supabase.instance.client;
