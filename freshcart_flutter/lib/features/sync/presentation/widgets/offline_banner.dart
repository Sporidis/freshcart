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
        color: Colors.grey,
        icon: Icons.wifi_off,
        message: t.sync.offline,
      ),
      SyncBannerSyncing(:final pending) => _BuildBanner(
        color: Colors.grey,
        icon: Icons.sync,
        message: t.sync.syncing(n: pending),
      ),
    };
  }
}

class _BuildBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _BuildBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8.0),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
