// ═══════════════════════════════════════════════════════════════════
// MAIN.DART — App Entry Point
// Initializes environment, Supabase, and launches the app.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'config/env.dart';
import 'config/supabase_config.dart';

void main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  Env.validate();

  // Initialize Supabase client
  await initSupabase();

  // Launch the app wrapped in Riverpod's ProviderScope
  // ProviderScope is the root of all Riverpod state management
  runApp(
    const ProviderScope(
      child: KitabApp(),
    ),
  );
}
