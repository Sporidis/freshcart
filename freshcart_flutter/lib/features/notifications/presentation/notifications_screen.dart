import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/list_mute_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Push preferences: the four named moments, and per-list mute (Flow 10,
/// decisions #80).
///
/// Phase 1 of `docs/decisions.md` #80: only the "Per list" section, which
/// reuses a mute mechanism the server has carried since decisions #37 --
/// `setListMuted`/`isListMuted` already worked, nothing above the transport
/// layer could read the second one back. The "Push" section (the four
/// toggles: item added, someone joins, list finished, shopping reminder)
/// is a later phase of the same decision, deliberately not stubbed here in
/// the meantime -- a toggle wired to nothing is worse than a toggle not
/// there yet (see decisions #76's own Haptics finding).
class NotificationsScreen extends ConsumerWidget {
  /// Creates the screen.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final lists =
        ref.watch(listsControllerProvider).dataOrNull ?? const <ShoppingList>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text(
            t.notifications.perList.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final list in lists) _ListMuteRow(list: list, t: t),
        ],
      ),
    );
  }
}

class _ListMuteRow extends ConsumerWidget {
  const _ListMuteRow({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = ref.watch(listMuteControllerProvider(list.id)).value ?? false;
    final muteColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: () => ref
          .read(listMuteControllerProvider(list.id).notifier)
          .setMuted(!muted),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted ? muteColor : AppColors.ink,
              ),
            ),
            Expanded(
              child: Text(
                list.name,
                style: AppTextStyles.body.copyWith(
                  color: muted ? muteColor : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              muted ? t.notifications.muted : t.notifications.on,
              style: theme.textTheme.bodySmall?.copyWith(color: muteColor),
            ),
          ],
        ),
      ),
    );
  }
}
