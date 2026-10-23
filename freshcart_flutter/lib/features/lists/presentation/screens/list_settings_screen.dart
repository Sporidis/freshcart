import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/lists/application/list_settings_screen/list_settings_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/confirm_list_removal.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/error_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_settings/list_members_section.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_settings/list_name_field.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_settings/list_shops_section.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_settings/list_switcher.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop.dart';
import 'package:go_router/go_router.dart';

/// Settings for one list: name, shops, household, behavior, and leave or
/// delete.
///
/// Opened from a list's row in Settings. The "Managing" card at the top
/// lets you switch to another list without leaving this screen.
///
/// Household and shop management are links to their own screens
/// (`HouseholdScreen`, `ManageShopsScreen`), not copies of them
/// (decisions.md #69). Here you can only turn shops on or off.
///
/// "Clear checked after shopping" (decisions.md #79): when every item is
/// checked, the checked items are removed right away, without asking, and
/// the "all done" card isn't shown.
class ListSettingsScreen extends ConsumerWidget {
  /// Creates the screen for [listId].
  const ListSettingsScreen({required this.listId, super.key});

  /// Which list this is.
  final ListId listId;

  /// Space above each section title (v3: 22).
  static const double _sectionGap = 22;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(listSettingsScreenControllerProvider(listId));
    final vm = ref.read(listSettingsScreenControllerProvider(listId).notifier);

    void report(Failure? failure) =>
        showFailureSnackBar(context, failure: failure, t: t);

    // If the list couldn't load, show an error screen. Without the list
    // there's no form to show.
    final loadFailure = s.loadFailure;
    if (loadFailure != null) {
      return ErrorScreen(
        failure: loadFailure,
        t: t,
        onExit: () {
          unawaited(vm.refreshLists());
          context.go(Routes.lists);
        },
      );
    }

    // Copied into a local variable, so Dart knows it's not null after the
    // check below.
    final list = s.list;
    return Scaffold(
      // v3: the bar only holds Back; the title is large, in the page.
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                40,
              ),
              children: [
                Text(t.lists.settingsTitle, style: AppTextStyles.largeTitle),
                const SizedBox(height: AppSpacing.xl),
                ListSwitcher(
                  current: list,
                  lists: s.allLists,
                  t: t,
                  onPick: (id) => context.go(Routes.listSettings(id)),
                ),
                const SizedBox(height: AppSpacing.xl),
                ListNameField(
                  initialName: list.name,
                  label: t.lists.nameLabel,
                  onRename: vm.rename,
                  t: t,
                ),
                const SizedBox(height: _sectionGap),
                ListShopsSection(
                  shops: s.shops,
                  onToggle: (shop) async =>
                      report(await vm.toggleShopActive(shop)),
                  // Same "add shop" flow as everywhere else.
                  onAdd: () => addShop(context, ref, listId, s.shops),
                  onManage: () => context.push(Routes.manageShops(listId)),
                  t: t,
                ),
                const SizedBox(height: _sectionGap),
                ListMembersSection(
                  list: list,
                  t: t,
                  onOpenHousehold: () => context.push(Routes.household(listId)),
                ),
                const SizedBox(height: _sectionGap),
                SettingsSection(
                  label: t.lists.behaviour,
                  children: [
                    SettingToggleOption(
                      title: t.lists.clearCheckedAfterShopping,
                      description: t.lists.clearCheckedAfterShoppingBody,
                      value: list.clearCheckedAfterShopping,
                      onChanged: (value) async => report(
                        await vm.setClearCheckedAfterShopping(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _sectionGap),
                // Leave/delete: their own card at the very bottom, away
                // from everything else.
                SettingsSection(
                  children: [
                    if (s.isOwner)
                      _DangerRow(
                        title: t.lists.deleteForEveryone,
                        onTap: () => confirmDeleteList(
                          context,
                          list: list,
                          itemCount: vm.itemCountForDialog(),
                          t: t,
                          delete: vm.deleteList,
                        ),
                      )
                    else
                      _DangerRow(
                        title: t.lists.leave,
                        onTap: () => confirmLeaveList(
                          context,
                          list: list,
                          t: t,
                          leave: vm.leaveList,
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// A red row for leave/delete. No ">" arrow. Always asks "are you sure?"
/// first.
class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SettingRow(
    title: title,
    titleStyle: AppTextStyles.body.copyWith(
      color: Theme.of(context).colorScheme.error,
    ),
    onTap: onTap,
  );
}
