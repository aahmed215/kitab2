// ═══════════════════════════════════════════════════════════════════
// ABOUT_SCREEN.DART — About Screen
// Version, Terms of Service, Privacy Policy, Licenses, Contact.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/kitab_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          // App branding
          const SizedBox(height: KitabSpacing.xl),
          Center(
            child: Text(
              'Kitab',
              style: KitabTypography.display.copyWith(
                color: KitabColors.primary,
              ),
            ),
          ),
          Center(
            child: Text(
              'Track your journey. Grow every day.',
              style: KitabTypography.body
                  .copyWith(color: KitabColors.gray500),
            ),
          ),
          const SizedBox(height: KitabSpacing.xs),
          Center(
            child: Text(
              'Version 1.0.0',
              style: KitabTypography.caption
                  .copyWith(color: KitabColors.gray400),
            ),
          ),
          const SizedBox(height: KitabSpacing.xxl),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // TODO: Open ToS URL
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // TODO: Open Privacy Policy URL
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Kitab',
                applicationVersion: '1.0.0',
              );
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact & Feedback'),
            subtitle: const Text('support@kitabapp.com'),
            onTap: () {
              // TODO: Open email
            },
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Re-run Onboarding'),
            subtitle: const Text('See the welcome tutorial again'),
            onTap: () {
              // TODO: Re-run onboarding
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
