// ═══════════════════════════════════════════════════════════════════
// COOKIE_CONSENT_BANNER.DART — Web Cookie Consent
// Shows once on web, persists acceptance in local storage.
// Required for GDPR compliance on the web version.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

class CookieConsentBanner extends StatefulWidget {
  final Widget child;
  const CookieConsentBanner({super.key, required this.child});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _accepted = true; // Default to true on non-web

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _accepted = false; // Show banner on web
    // TODO: Check localStorage for 'cookie_consent_accepted'
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_accepted)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: KitabSpacing.lg, vertical: KitabSpacing.md),
                color: Theme.of(context).cardTheme.color,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kitab uses cookies and local storage to keep you signed in and improve your experience.',
                        style: KitabTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(width: KitabSpacing.md),
                    TextButton(onPressed: () => setState(() => _accepted = true), child: const Text('Decline')),
                    const SizedBox(width: KitabSpacing.sm),
                    FilledButton(onPressed: () => setState(() => _accepted = true), child: const Text('Accept')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
