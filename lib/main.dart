// ═══════════════════════════════════════════════════════════════════
// MAIN.DART — App Entry Point
// Initializes environment, Supabase, PostHog, Sentry, and
// launches the app.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'config/env.dart';
import 'config/supabase_config.dart';

Future<void> _appRunner() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');
  Env.validate();

  // Initialize Supabase
  await initSupabase();

  // Initialize PostHog analytics (may fail on web — non-fatal)
  if (Env.posthogApiKey.isNotEmpty) {
    try {
      final posthogConfig = PostHogConfig(Env.posthogApiKey);
      posthogConfig.host = Env.posthogHost;
      if (!kIsWeb) {
        posthogConfig.captureApplicationLifecycleEvents = true;
      }
      await Posthog().setup(posthogConfig);
    } catch (e) {
      debugPrint('PostHog init failed (non-fatal): $e');
    }
  }

  runApp(const ProviderScope(child: KitabApp()));
}

void main() async {
  // All initialization happens inside SentryFlutter.init's appRunner
  // to ensure Flutter bindings and runApp share the same zone.
  // If SENTRY_DSN is empty (not configured), Sentry becomes a no-op
  // but the zone management still works correctly.
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 0.2;
      options.environment = 'production';
    },
    appRunner: _appRunner,
  );
}
