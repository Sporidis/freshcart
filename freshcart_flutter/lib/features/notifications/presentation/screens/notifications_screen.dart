import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/settings_options/setting_toggle_option.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/list_mute/list_mute_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/notification_preferences/notification_preferences_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Push preferences: the three server-gated moments, and per-list mute
/// (Flow 10, decisions #80).
///
/// The fourth named moment in the design, "Shopping reminder," is a
/// scheduled *local* notification rather than server push -- a later phase
/// of the same decision, needing its own dependency
/// (`flutter_local_notifications`), deliberately not stubbed here in the
/// meantime (a toggle wired to nothing is worse than a toggle not there
/// yet, decisions #76's own Haptics finding).
class NotificationsScreen extends ConsumerWidget {
  /// Creates the screen.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final lists =
        ref.watch(listsControllerProvider).dataOrNull ?? const <ShoppingList>[];
    final preferences =
        ref.watch(notificationPreferencesControllerProvider).value ??
        const NotificationPreferences();
    final notifier = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text(
            t.notifications.push.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SettingToggleOption(
            title: t.notifications.itemAdded,
            description: t.notifications.itemAddedBody,
            value: preferences.itemAdded,
            onChanged: notifier.setItemAdded,
          ),
          SettingToggleOption(
            title: t.notifications.memberJoined,
            value: preferences.memberJoined,
            onChanged: notifier.setMemberJoined,
          ),
          SettingToggleOption(
            title: t.notifications.listFinished,
            description: t.notifications.listFinishedBody,
            value: preferences.listFinished,
            onChanged: notifier.setListFinished,
          ),
          const SizedBox(height: 24),
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
