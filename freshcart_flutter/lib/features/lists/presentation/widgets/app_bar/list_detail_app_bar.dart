import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/move_to_shop_sheet.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/list_menu.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/member_avatar_button.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The app bar of the list screen. It changes with the [ItemsMode] (normal,
/// selecting, searching, rearranging), which it reads from
/// [ItemsSectionController], same as the items.
///
/// [list] is null while loading. Then it only shows the app name.
class ListDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ListDetailAppBar({
    required this.list,
    required this.searchField,
    super.key,
  });

  final ShoppingList? list;

  /// The search text controller (owned by the screen). Cleared when search
  /// opens or closes, so old text never shows.
  final TextEditingController searchField;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final list = this.list;
    final items = list == null
        ? null
        : ref.watch(itemsSectionControllerProvider(list));
    final vm = list == null
        ? null
        : ref.read(itemsSectionControllerProvider(list).notifier);
    final mode = items?.mode ?? ItemsMode.browse;

    void report(Failure? failure) {
      if (failure == null || !context.mounted) return;
      showFailureSnackBar(context, failure: failure, t: t);
    }

    Future<void> moveSelected() async {
      // Cancelled (null): keep the selection as it was.
      final outcome = await showMoveToShopSheet(
        context,
        shops: items?.shops ?? const <Shop>[],
        t: t,
      );
      if (outcome == null || vm == null) return;
      report(await vm.moveSelected(outcome.shopId));
    }

    return AppBar(
      // In select mode, the menu button becomes an X to stop selecting.
      // (Opening the drawer would lose the selection.) Search has its own
      // "Cancel" on the right.
      leading: mode == ItemsMode.select
          ? IconButton(
              icon: const Icon(Icons.close),
              tooltip: t.common.cancel,
              onPressed: vm?.clearSelection,
            )
          : null,
      // Fades between list name, selection count, search field and
      // rearrange title, so it feels like one bar changing its text.
      title: _title(
        context,
        ref,
        theme: theme,
        t: t,
        mode: mode,
        items: items,
        vm: vm,
      ),
      actions: list == null || vm == null
          ? const []
          : switch (mode) {
              ItemsMode.rearrange => [
                TextButton(
                  onPressed: vm.stopRearrange,
                  child: Text(t.common.done),
                ),
              ],
              ItemsMode.select => [
                TextButton(onPressed: moveSelected, child: Text(t.common.move)),
                TextButton(
                  onPressed: () async => report(await vm.deleteSelected()),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(t.common.delete),
                ),
              ],
              ItemsMode.search => [
                TextButton(
                  onPressed: () {
                    searchField.clear();
                    vm.closeSearch();
                  },
                  child: Text(t.common.cancel),
                ),
              ],
              ItemsMode.browse => [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: t.search.hint,
                  onPressed: () {
                    searchField.clear();
                    vm.openSearch();
                  },
                ),
                MemberAvatarButton(list: list),
                ListMenu(list: list, t: t),
              ],
            },
    );
  }

  Widget _title(
    BuildContext context,
    WidgetRef ref, {
    required ThemeData theme,
    required Translations t,
    required ItemsMode mode,
    required ItemsSectionState? items,
    required ItemsSectionController? vm,
  }) {
    final list = this.list;
    return AnimatedSwitcher(
      // 280 ms, from the design. One AnimatedSwitcher can only have one
      // duration, so all modes use this.
      duration: AppMotion.durationFor(
        context,
        const Duration(milliseconds: 280),
      ),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.enter,
      child: switch (mode) {
        ItemsMode.rearrange => Text(
          t.items.rearrangeHeader,
          key: const ValueKey('rearrange'),
        ),
        ItemsMode.select => Text(
          t.items.selectedCount(n: items?.selection.length ?? 0),
          key: const ValueKey('selection'),
        ),
        ItemsMode.search => TextField(
          key: const ValueKey('search'),
          controller: searchField,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: t.search.hint,
            isDense: true,
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface,
                width: 1.5,
              ),
            ),
          ),
          onChanged: vm?.updateQuery,
        ),
        ItemsMode.browse => KeyedSubtree(
          key: const ValueKey('normal'),
          child: list == null
              ? Text(t.appName)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The app name, small, above the list name.
                    Text(
                      t.appName,
                      style: AppTextStyles.labelStrong.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    _ListTitle(list: list, t: t),
                  ],
                ),
        ),
      },
    );
  }
}

/// The list name; tap to rename. A separate widget because it uses
/// [ListDetailScreenController], while the app bar uses the items
/// controller (rule: one controller per widget).
class _ListTitle extends ConsumerWidget {
  const _ListTitle({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the owner can rename.
    final isOwner = ref.watch(
      listDetailScreenControllerProvider(list.id).select((s) => s.isOwner),
    );
    return EditableListTitle(
      name: list.name,
      enabled: isOwner,
      onRename: (name) async {
        final failure = await ref
            .read(listDetailScreenControllerProvider(list.id).notifier)
            .rename(name);
        return failure?.toMessage(t);
      },
    );
  }
}
