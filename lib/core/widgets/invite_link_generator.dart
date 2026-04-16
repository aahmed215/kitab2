// ═══════════════════════════════════════════════════════════════════
// INVITE_LINK_GENERATOR.DART — Friend Invite Link
// Generates and shares a unique invite link.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/kitab_theme.dart';
import 'kitab_toast.dart';

class InviteLinkGenerator {
  const InviteLinkGenerator._();

  /// Generate an invite link for the given username.
  static String generateLink(String username) {
    return 'https://mykitab.app/invite/$username';
  }

  /// Show a bottom sheet with the invite link and share options.
  static Future<void> showInviteSheet(BuildContext context, String username) {
    final link = generateLink(username);

    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: KitabColors.gray300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: KitabSpacing.lg),
            Text('Invite Friends', style: KitabTypography.h2),
            const SizedBox(height: KitabSpacing.md),
            Text('Share this link with friends:', style: KitabTypography.body.copyWith(color: KitabColors.gray500)),
            const SizedBox(height: KitabSpacing.lg),

            // Link display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: KitabColors.gray100, borderRadius: KitabRadii.borderSm),
              child: Row(
                children: [
                  Expanded(child: Text(link, style: KitabTypography.monoSmall)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      KitabToast.success(context, 'Link copied!');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: KitabSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Share.share('Join me on Kitab! $link', subject: 'Kitab Invite');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Invite Link'),
              ),
            ),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }
}
