import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/notifications/application/list_mute/list_mute_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/notifications_screen/notifications_screen_controller.dart';
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
    final s = ref.watch(notificationsScreenControllerProvider);
    final vm = ref.read(notificationsScreenControllerProvider.notifier);
    final preferences = s.preferences;

    void report(Failure? failure) {
      if (failure == null || !context.mounted) return;
      showFailureSnackBar(context, failure: failure, t: t);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          SettingsSection(
            label: t.notifications.push,
            children: [
              if (preferences == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.screen),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SettingToggleOption(
                  title: t.notifications.itemAdded,
                  description: t.notifications.itemAddedBody,
                  value: preferences.itemAdded,
                  onChanged: (v) async => report(await vm.setItemAdded(v)),
                ),
                SettingToggleOption(
                  title: t.notifications.memberJoined,
                  value: preferences.memberJoined,
                  onChanged: (v) async => report(await vm.setMemberJoined(v)),
                ),
                SettingToggleOption(
                  title: t.notifications.listFinished,
                  description: t.notifications.listFinishedBody,
                  value: preferences.listFinished,
                  onChanged: (v) async => report(await vm.setListFinished(v)),
                ),
              ],
            ],
          ),
          // Nothing to mute without a list -- no label over an empty group.
          if (s.lists.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.screen),
            SettingsSection(
              label: t.notifications.perList,
              children: [
                for (final list in s.lists) _ListMuteRow(list: list, t: t),
              ],
            ),
          ],
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
    final muteColor = theme.textTheme.bodySmall?.color;

    // Announced as a toggle with its state, not as a plain button whose
    // trailing "On"/"Muted" text a screen reader would read as a label.
    return Semantics(
      toggled: !muted,
      child: SettingRow(
        onTap: () => ref
            .read(listMuteControllerProvider(list.id).notifier)
            .setMuted(!muted),
        leading: Container(
          width: AppSizes.tabDot,
          height: AppSizes.tabDot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: muted ? muteColor : theme.colorScheme.onSurface,
          ),
        ),
        title: list.name,
        titleStyle: AppTextStyles.body.copyWith(
          color: muted ? muteColor : theme.colorScheme.onSurface,
        ),
        trailing: SettingValueText(
          muted ? t.notifications.muted : t.notifications.on,
        ),
      ),
    );
  }
}
