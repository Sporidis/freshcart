import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_banner.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_providers.dart';

/// The strip above the list that says the device is offline, or still
/// pushing queued writes. Which of the two (if either) is decided by
/// [syncBannerProvider]; this only draws it.
class OfflineSyncingBanner extends ConsumerWidget {
  const OfflineSyncingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    return switch (ref.watch(syncBannerProvider)) {
      SyncBannerHidden() => const SizedBox.shrink(),
      SyncBannerOffline() => _BuildBanner(
        icon: Icons.wifi_off,
        message: t.sync.offline,
      ),
      SyncBannerSyncing(:final pending) => _BuildBanner(
        icon: Icons.sync,
        message: t.sync.syncing(n: pending),
      ),
    };
  }
}

/// The strip itself. The theme's inverse surface -- dark in light mode,
/// light in dark mode -- so it stands apart from the list in both, the same
/// pairing a snackbar uses.
class _BuildBanner extends StatelessWidget {
  const _BuildBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.inverseSurface,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, color: scheme.onInverseSurface),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(color: scheme.onInverseSurface)),
        ],
      ),
    );
  }
}
