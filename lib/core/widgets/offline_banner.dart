// ═══════════════════════════════════════════════════════════════════
// OFFLINE_BANNER.DART — "You're Offline" Banner
// Shows when the device has no internet connection.
// Dismissible, reappears on connectivity change.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';
import 'kitab_toast.dart';

/// Provider-style widget that shows an offline banner when
/// the device loses internet connectivity.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          MaterialBanner(
            content: const Text("You're offline. Changes are saved locally."),
            leading: const Icon(Icons.wifi_off, color: KitabColors.warning),
            backgroundColor: KitabColors.warning.withValues(alpha: 0.1),
            actions: [
              TextButton(
                onPressed: () => setState(() => _isOffline = false),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Shows a network error snackbar with a retry button.
void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
  KitabToast.error(
    context,
    'Network error. Check your connection.',
    action: onRetry != null
        ? ToastAction(label: 'Retry', onPressed: onRetry)
        : null,
  );
}
