import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/features/sync/application/sync_provider.dart';
import 'package:freshcart_flutter/features/sync/application/sync_status.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_queue_provider.dart';

class OfflineSyncingBanner extends ConsumerWidget {
  const OfflineSyncingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncProvider).value;
    final pendingCount = ref.watch(queueCountProvider).value ?? 0;
    final isSyncing = status == SyncStatus.online && pendingCount > 0;

    if (status != SyncStatus.offline && !isSyncing) {
      return const SizedBox.shrink();
    }

    if (isSyncing) {
      return _SyncingBanner(pendingCount: pendingCount);
    }

    return const _OfflineBanner();
  }
}

class _SyncingBanner extends StatelessWidget {
  final int pendingCount;

  const _SyncingBanner({required this.pendingCount});

  @override
  Widget build(
    BuildContext context,
  ) {
    return _BuildBanner(
      color: Colors.grey,
      icon: Icons.sync,
      message: 'Syncing $pendingCount changes...',
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return const _BuildBanner(
      color: Colors.grey,
      icon: Icons.wifi_off,
      message: 'Offline - changes will sync',
    );
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
