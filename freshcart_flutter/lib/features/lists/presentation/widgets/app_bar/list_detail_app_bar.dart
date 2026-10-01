import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/move_to_shop_sheet.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/list_menu.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/app_bar/member_avatar_button.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list screen's app bar, in whichever of the four [ItemsMode]s the
/// items are in -- read from the same [ItemsSectionController] the items
/// area uses, so the header and the rows can never disagree.
///
/// [list] is null while the list is still loading: the bar then shows just
/// the app name, with no actions to offer yet.
class ListDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ListDetailAppBar({
    required this.list,
    required this.searchField,
    super.key,
  });

  final ShoppingList? list;

  /// Owned by the screen (it outlives this bar's rebuilds); cleared here
  /// whenever search opens or closes, so reopening never flashes the text
  /// from last time.
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
      // Cancelling (null) leaves the selection exactly as it was -- the
      // sheet is a detour, not a commitment the moment it opens.
      final outcome = await showMoveToShopSheet(
        context,
        shops: items?.shops ?? const <Shop>[],
        t: t,
      );
      if (outcome == null || vm == null) return;
      report(await vm.moveSelected(outcome.shopId));
    }

    return AppBar(
      // A way out of selection mode, replacing the drawer hamburger:
      // switching lists mid-select would abandon the selection. Search has
      // its own way out (the trailing "Cancel"), so it leaves this alone.
      leading: mode == ItemsMode.select
          ? IconButton(
              icon: const Icon(Icons.close),
              tooltip: t.common.cancel,
              onPressed: vm?.clearSelection,
            )
          : null,
      // Cross-fades between the list name, the selection count, the search
      // field and the rearrange header (§16), so it reads as one bar
      // changing what it says, not a screen change.
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
                    foregroundColor: AppColors.destructive,
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
      // 280 ms per §16 -- its own value, distinct from the 260 ms token
      // the selection cross-fade uses; one switcher can only run one
      // duration, so this is what both transitions share.
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
                    // The app's own name as a small kicker over the
                    // list's, the way the design's every list screen
                    // carries it — this is whose product this is,
                    // not what kind of screen it is.
                    Text(
                      t.appName,
                      style: AppTextStyles.labelStrong.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    EditableListTitle(
                      name: list.name,
                      onRename: (name) async {
                        final result = await ref
                            .read(listsControllerProvider.notifier)
                            .rename(list.id, name);
                        return switch (result) {
                          Ok<ShoppingList>() => null,
                          Err<ShoppingList>(:final failure) =>
                            failure.toMessage(t),
                        };
                      },
                    ),
                  ],
                ),
        ),
      },
    );
  }
}
