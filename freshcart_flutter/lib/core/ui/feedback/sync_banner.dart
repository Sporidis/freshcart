import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/sync_banner_state.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';

/// The quiet bar under the list header that says the list is offline or
/// catching up (design v3, Flow 07). No colour alarm: being offline is
/// normal in a shop, and everything keeps working.
///
/// - Offline: "Offline – changes will sync", or how many are waiting.
/// - Back online, sending: "Syncing 2 changes…" over a 2px moving line.
/// - Done: "Up to date" for 1.6s, then the bar folds away.
///
/// [syncBannerStateProvider] decides offline/syncing/hidden; the short "Up to
/// date" moment is only this widget's, because it's about what the user
/// just saw (it only shows after syncing, never on a quiet launch).
///
/// It also says when syncing had to drop changes because someone else
/// changed the same thing first ([SyncConflictsController]): a toast, the
/// snackbar tier of decision #42, since the app is fine and the list
/// already shows what's really there.
class SyncBanner extends ConsumerStatefulWidget {
  const SyncBanner({super.key});

  /// How long "Up to date" stays (v3).
  static const Duration upToDateHold = Duration(milliseconds: 1600);

  /// The least time "Syncing" stays up once it starts.
  ///
  /// A replay can finish faster than a frame (one item, a fast network), so
  /// without this the bar would jump straight from "Waiting" to "Up to
  /// date" and the user would never see it sync. Same idea as
  /// [upToDateHold], for the state before it.
  static const Duration minSyncingHold = Duration(milliseconds: 500);

  @override
  ConsumerState<SyncBanner> createState() => _OfflineSyncingBannerState();
}

class _OfflineSyncingBannerState extends ConsumerState<SyncBanner> {
  // Both "Syncing" and "Up to date" can be too brief to land on their own
  // frame; holding whichever is current for a minimum stretch is what makes
  // it visible to a user rather than just to a trace. The two never
  // overlap, so one timer covers both.
  SyncBannerState? _holdSyncing;
  bool _upToDate = false;
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _hold(Duration duration, VoidCallback onExpire) {
    _holdTimer?.cancel();
    _holdTimer = Timer(duration, () {
      _holdTimer = null;
      if (mounted) onExpire();
    });
  }

  void _showUpToDate() {
    setState(() => _upToDate = true);
    _hold(SyncBanner.upToDateHold, () => setState(() => _upToDate = false));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    // Everything waiting just got sent: say so briefly. From "waiting" too,
    // not only "syncing": the queue count arrives from the database a
    // moment after the replay reports it's done, so the last step is
    // usually waiting → hidden. Online, the count only reaches zero by
    // being sent. Anything else coming in replaces it straight away.
    ref.listen(syncBannerStateProvider, (previous, next) {
      if (next is SyncBannerSyncing) {
        // A new (or still-running) replay: show it, and hold it up for at
        // least `minSyncingHold` from here, in case it's about to finish.
        setState(() => _holdSyncing = next);
        _hold(SyncBanner.minSyncingHold, () {
          setState(() => _holdSyncing = null);
          if (ref.read(syncBannerStateProvider) is SyncBannerHidden) {
            _showUpToDate();
          }
        });
        return;
      }
      if (_holdSyncing != null) return; // Still held; settled once it ends.

      final wasSending =
          previous is SyncBannerSyncing || previous is SyncBannerWaiting;
      if (wasSending && next is SyncBannerHidden) {
        _showUpToDate();
      } else if (next is! SyncBannerHidden && _upToDate) {
        setState(() => _upToDate = false);
      }
    });

    ref.listen(syncConflictsControllerProvider, (previous, next) {
      final dropped = next - (previous ?? 0);
      if (dropped <= 0) return;
      showUndoToast(
        context,
        message: t.sync.conflicts(n: dropped),
        t: t,
      );
    });

    // Always watched, even while "Syncing" is held: a build that skips the
    // watch would drop this widget's subscription to it.
    final live = ref.watch(syncBannerStateProvider);
    final banner = _holdSyncing ?? live;
    final content = switch (banner) {
      SyncBannerOffline(:final pending) => _Bar(
        key: const ValueKey('offline'),
        icon: Icons.wifi_off_rounded,
        message: pending == 0
            ? t.sync.offline
            : t.sync.offlineWaiting(n: pending),
      ),
      SyncBannerWaiting(:final pending) => _Bar(
        key: const ValueKey('waiting'),
        icon: Icons.cloud_upload_outlined,
        message: t.sync.waiting(n: pending),
      ),
      SyncBannerSyncing(:final pending) => _Bar(
        key: const ValueKey('syncing'),
        message: t.sync.syncing(n: pending),
        progress: true,
      ),
      SyncBannerHidden() when _upToDate => _Bar(
        key: const ValueKey('up-to-date'),
        icon: Icons.check_rounded,
        message: t.sync.upToDate,
      ),
      SyncBannerHidden() => const SizedBox(
        key: ValueKey('hidden'),
        width: double.infinity,
      ),
    };

    final duration = AppMotion.durationFor(context, AppMotion.standard);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        // Top-aligned, so a change of text doesn't jump the bar around.
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: content,
      ),
    );
  }
}

/// The bar itself: the translucent fill, 13px muted text, an optional 14px
/// icon, and for syncing a 2px indeterminate line underneath.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.message,
    this.icon,
    this.progress = false,
    super.key,
  });

  final String message;
  final IconData? icon;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final icon = this.icon;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: scheme.fill,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: 7,
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  if (icon != null) Icon(icon, size: 14, color: muted),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (progress)
            // Reduced motion: a still line, since "indeterminate" is pure
            // movement.
            LinearProgressIndicator(
              minHeight: 2,
              value: AppMotion.reduced(context) ? .4 : null,
              color: scheme.primary,
              backgroundColor: scheme.fill,
            ),
        ],
      ),
    );
  }
}
