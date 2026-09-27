import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_v2_view_model.dart';
import 'package:freshcart_flutter/features/items/application/items_v2_view_state.dart';
import 'package:freshcart_flutter/features/items/presentation/items_section.dart'
    show ItemsSection;
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile_v2/item_tile_v2.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/shop_filter_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Dev-only entry point, reached from Settings' dev-tools row rather than
/// nested under a specific list's own route: picks the signed-in user's
/// first real list so this needs no route param, and doesn't touch
/// ListDetailScreen's already-nontrivial AppBar to add a link to it.
class ItemsSectionV2Screen extends ConsumerWidget {
  const ItemsSectionV2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);

    final failure = lists.loadFailure;
    if (failure != null) {
      return ErrorScreen(failure: failure, t: t, onExit: () {});
    }

    final loaded = lists.dataOrNull;
    if (loaded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (loaded.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No real lists to test against yet')),
      );
    }
    return ItemsSectionV2(list: loaded.first);
  }
}

/// The V2 interaction model on a real list's real data — the design's plain
/// "Browse" state: header, shop filter, rows, a floating add button, plus
/// multi-select and rearrange, both entered from a row's hold-menu ("Select
/// more…" / "Rearrange list") rather than long-press directly, since that
/// gesture already opens the menu.
///
/// This is a separate, dev-reachable screen so the new tile can be
/// exercised against real data without touching [ItemsSection] (the real,
/// still more capable production screen).
///
/// Pure UI: every derivation and multi-step action lives in
/// [ItemsV2ViewModel]. What stays here is what needs a `BuildContext` or an
/// element's lifetime -- sheets, snackbars, the search field's controller
/// and the reveal's key.
class ItemsSectionV2 extends ConsumerStatefulWidget {
  const ItemsSectionV2({required this.list, super.key});

  final ShoppingList list;

  @override
  ConsumerState<ItemsSectionV2> createState() => _ItemsSectionV2State();
}

class _ItemsSectionV2State extends ConsumerState<ItemsSectionV2> {
  // Reused across rebuilds via State rather than created fresh in build()
  // (a GlobalKey created in build() would change identity every frame and
  // stop Flutter from recognizing ShopThemeReveal as the same element) --
  // same reasoning list_detail_screen.dart's own copy carries.
  final GlobalKey<ShopThemeRevealState> _revealKey =
      GlobalKey<ShopThemeRevealState>();

  // Backs the header's search field once it is open -- its own controller
  // rather than `TextEditingController(text: ...)` rebuilt from provider
  // state every frame, which would fight the user's cursor position on
  // every keystroke. Same reasoning list_detail_screen.dart's own copy gives.
  final TextEditingController _searchField = TextEditingController();

  @override
  void dispose() {
    _searchField.dispose();
    super.dispose();
  }

  ItemsV2ViewModel get _vm =>
      ref.read(itemsV2ViewModelProvider(widget.list).notifier);

  void _report(Failure? failure, {VoidCallback? onRetry}) {
    if (failure == null || !mounted) return;
    showFailureSnackBar(
      context,
      failure: failure,
      t: ref.read(translationsProvider),
      onRetry: onRetry,
    );
  }

  // Both clear the field alongside the view model -- without it, the next
  // time search opens it would flash whatever was typed the time before.
  void _openSearch() {
    _searchField.clear();
    _vm.openSearch();
  }

  void _closeSearch() {
    _searchField.clear();
    _vm.closeSearch();
  }

  Future<void> _openEditSheet(ItemsV2ViewState s, ShoppingItem item) async {
    final t = ref.read(translationsProvider);
    final outcome = await showModalBottomSheet<ItemSheetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemSheet.edit(item: item, shops: s.shops, t: t),
    );
    switch (outcome) {
      case null:
        return;
      case ItemSheetRemove():
        _report(await _vm.remove(item));
      case ItemSheetSave(
        :final name,
        :final quantity,
        :final shopId,
        :final noteText,
      ):
        _report(
          await _vm.edit(
            item,
            name: name,
            quantity: quantity,
            shopId: shopId,
            noteText: noteText,
          ),
        );
    }
  }

  // QuickAddBar's onOpenDetails contract: return whether something was
  // actually added, so it knows whether to clear/collapse itself or leave
  // the typed text in place for a retry.
  Future<bool> _openAddSheet(ItemsV2ViewState s, String initialName) async {
    final t = ref.read(translationsProvider);
    final outcome = await showModalBottomSheet<ItemSheetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemSheet.add(
        initialName: initialName,
        shops: s.shops,
        t: t,
        initialShopId: s.shopFilter,
      ),
    );
    if (outcome is! ItemSheetSave) return false;
    final failure = await _vm.add(
      name: outcome.name,
      quantity: outcome.quantity,
      shopId: outcome.shopId,
      noteText: outcome.noteText,
    );
    _report(failure);
    return failure == null;
  }

  Future<bool> _quickAdd(String name) async {
    final failure = await _vm.quickAdd(name);
    _report(failure);
    return failure == null;
  }

  Future<void> _moveSelected(ItemsV2ViewState s) async {
    final t = ref.read(translationsProvider);
    final outcome = await showModalBottomSheet<_MoveToShopV2Outcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoveToShopV2Sheet(shops: s.shops, t: t),
    );
    if (outcome == null) return;
    _report(await _vm.moveSelected(outcome.shopId));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(itemsV2ViewModelProvider(widget.list));
    final vm = _vm;
    final list = s.list;
    final activeShopColor = ref.watch(activeShopColorProvider(list.id));
    final scopedSeed = activeShopColor == null
        ? AppTheme.brandSeed
        : Color(activeShopColor.argb);

    Color? dotFor(ShopId? shopId) {
      final shop = s.shopFor(shopId);
      return shop == null ? null : Color(shop.color.argb);
    }

    final me = s.me;

    return Scaffold(
      // Only while browsing or searching -- opening the list switcher
      // mid-select would abandon the selection with no way back, same
      // reasoning list_detail_screen.dart's own copy of this gate gives;
      // rearrange mode has its own dedicated "Done" way out instead.
      drawer: switch (s.mode) {
        ItemsV2Mode.select || ItemsV2Mode.rearrange => null,
        _ => ListsDrawer(currentListId: list.id),
      },
      appBar: AppBar(
        // No leading icon while searching -- the reference's own search
        // header is just the bordered field plus a "Cancel" trailing action,
        // not a second way out (same as list_detail_screen.dart's copy).
        leading: s.mode == ItemsV2Mode.select
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: vm.clearSelection,
              )
            : null,
        title: switch (s.mode) {
          ItemsV2Mode.rearrange => Text(t.items.rearrangeHeader),
          ItemsV2Mode.select => Text(
            t.items.selectedCount(n: s.selection.length),
          ),
          ItemsV2Mode.search => TextField(
            controller: _searchField,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.search.hint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
            onChanged: vm.updateQuery,
          ),
          ItemsV2Mode.browse => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.appName,
                style: AppTextStyles.labelStrong.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(list.name),
            ],
          ),
        },
        actions: switch (s.mode) {
          ItemsV2Mode.rearrange => [
            TextButton(
              onPressed: vm.stopRearrange,
              child: Text(t.common.done),
            ),
          ],
          ItemsV2Mode.select => [
            TextButton(
              onPressed: () => _moveSelected(s),
              child: Text(t.common.move),
            ),
            TextButton(
              onPressed: () async => _report(await vm.deleteSelected()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive,
              ),
              child: Text(t.common.delete),
            ),
          ],
          ItemsV2Mode.search => [
            TextButton(onPressed: _closeSearch, child: Text(t.common.cancel)),
          ],
          ItemsV2Mode.browse => [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: t.search.hint,
              onPressed: _openSearch,
            ),
            if (me != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: UserAvatar(
                  seed: me.userId.value,
                  initial:
                      me.displayName.characters.firstOrNull?.toUpperCase() ??
                      '?',
                  photoUrl: me.avatarPhotoUrl,
                  color: me.avatarColor,
                  radius: 16,
                ),
              ),
          ],
        },
      ),
      body: Column(
        children: [
          // Search results already span every shop, so a filter that would
          // only narrow them back down has nothing to do while it's active;
          // rearrange mode has its own dedicated top bar in its place.
          if (s.mode == ItemsV2Mode.browse || s.mode == ItemsV2Mode.select) ...[
            ShopFilterBar(listId: list.id, revealKey: _revealKey),
            const Divider(height: 1),
          ],
          Expanded(
            child: ShopThemeReveal(
              key: _revealKey,
              seed: scopedSeed,
              // A Stack, not a docked bottom bar: the design's own FAB
              // floats over the list rather than shrinking it to make room
              // (see ItemsSection's own copy of this reasoning).
              child: Stack(
                children: [
                  Positioned.fill(
                    child: s.mode == ItemsV2Mode.search
                        ? SearchResults(
                            list: list,
                            allItems: s.allItems,
                            query: s.searchQuery,
                            t: t,
                            controller: ref.read(
                              itemsControllerProvider(list.id).notifier,
                            ),
                            report: _report,
                          )
                        : s.isEmpty
                        ? _ItemsV2EmptyState(shop: s.activeShop, t: t)
                        : _ItemListV2(
                            state: s,
                            vm: vm,
                            t: t,
                            dotFor: dotFor,
                            report: _report,
                            onEdit: (item) => _openEditSheet(s, item),
                          ),
                  ),
                  // Neither the celebration nor the add control has anything
                  // to do while multi-selecting or searching -- selection has
                  // its own contextual bar (in the AppBar above), and search
                  // offers its own "Add to list" inside its no-results state.
                  if (s.mode == ItemsV2Mode.browse)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.showCelebration)
                            CompletionCelebrationCard(
                              list: list,
                              itemCount: s.allItems.length,
                              shopColors: s.shops.isEmpty
                                  ? AppColors.presetShopColors
                                  : [
                                      for (final shop in s.shops)
                                        Color(shop.color.argb),
                                    ],
                              t: t,
                              report: _report,
                            ),
                          QuickAddBar(
                            listId: list.id,
                            t: t,
                            activeShopName: s.activeShop?.name,
                            firstRun: s.firstRun,
                            onQuickAdd: _quickAdd,
                            onOpenDetails: (name) => _openAddSheet(s, name),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clears the floating add control that sits on top of the items area, the
/// same reason [ItemsSection]'s own copy of this constant exists -- so
/// neither the last row nor the empty-state copy renders underneath it.
const double _floatingClusterInset = 84;

/// The rows themselves, split into open and Done -- checked items collect
/// below a collapsible [DoneDivider] with a "Clear checked" action, the same
/// split [ItemsSection]'s own `_ItemList` makes.
///
/// Deliberately simpler than that one: no 600ms hold-in-place before a
/// just-checked row leaves the open section (`RecentlyChecked`) -- the
/// design mock doesn't call for it, and it isn't worth the extra state for
/// this screen's purposes.
///
/// Selection and rearrange only ever apply to open rows: a settled, checked
/// item has its own bulk action already ("Clear checked").
class _ItemListV2 extends StatelessWidget {
  const _ItemListV2({
    required this.state,
    required this.vm,
    required this.t,
    required this.dotFor,
    required this.report,
    required this.onEdit,
  });

  final ItemsV2ViewState state;
  final ItemsV2ViewModel vm;
  final Translations t;
  final Color? Function(ShopId?) dotFor;
  final void Function(Failure?, {VoidCallback? onRetry}) report;
  final void Function(ShoppingItem) onEdit;

  @override
  Widget build(BuildContext context) {
    final selectionMode = state.mode == ItemsV2Mode.select;

    Widget tileFor(
      ShoppingItem item, {
      bool selectable = false,
      int? index,
    }) => ItemTileV2(
      t: t,
      key: ValueKey(item.id.value),
      item: item,
      shopColor: dotFor(item.shopId),
      onToggle: () async => report(await vm.toggle(item)),
      onEdit: () => onEdit(item),
      onDelete: () => vm.swipeDelete(item),
      onQuantityChanged: (quantity) async =>
          report(await vm.setQuantity(item, quantity)),
      selected: selectable && state.selection.contains(item.id),
      selectionMode: selectable && selectionMode,
      onSelectionToggle: selectable ? () => vm.toggleSelection(item.id) : null,
      onSelectMore: selectable ? () => vm.toggleSelection(item.id) : null,
      // On "All", the menu's "Rearrange list" row just closes the menu.
      onRearrange: selectable && state.canRearrange ? vm.startRearrange : null,
      dragHandle: index == null
          ? null
          : ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, size: 16),
            ),
      checkedByMember: item.checkedBy == null
          ? null
          : state.list.memberFor(item.checkedBy!),
    );

    final open = state.openItems;
    final done = state.doneItems;

    return ListView(
      padding: const EdgeInsets.only(bottom: _floatingClusterInset),
      children: [
        if (state.mode == ItemsV2Mode.rearrange)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) => unawaited(
              vm.reorderOpen(oldIndex, newIndex).then(report),
            ),
            children: [
              for (final (index, item) in open.indexed)
                tileFor(item, index: index),
            ],
          )
        else
          for (final item in open) tileFor(item, selectable: true),
        if (done.isNotEmpty) ...[
          DoneDivider(
            label: t.items.doneCount(n: done.length),
            collapsed: state.doneCollapsed,
            onToggle: vm.toggleDoneCollapsed,
            clearLabel: t.items.clearChecked,
            onClear: () async => report(await vm.clearChecked()),
          ),
          if (!state.doneCollapsed)
            for (final item in done) tileFor(item),
        ],
      ],
    );
  }
}

/// The empty state for this screen's items area, in its two forms -- the
/// same split [ItemsSection]'s own private `_ItemsEmptyState` makes, since
/// the design draws them differently (an empty shop tab names the shop and
/// tints to its colour; an empty list points at adding the first item).
class _ItemsV2EmptyState extends StatelessWidget {
  const _ItemsV2EmptyState({required this.shop, required this.t});

  /// The filtered-to shop, or null on "All" (or a filter whose shop hasn't
  /// loaded) -- both of which get the generic copy.
  final Shop? shop;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final shop = this.shop;
    return Padding(
      padding: const EdgeInsets.only(bottom: _floatingClusterInset),
      child: shop == null
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: t.items.emptyTitle,
              body: t.items.emptyBody,
            )
          : EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: t.items.emptyShopTitle(shop: shop.name),
              body: t.items.emptyShopBody,
              tint: Color(shop.color.argb),
            ),
    );
  }
}

/// What [_MoveToShopV2Sheet] resolved to -- distinct from `null`, which
/// means "dismissed without choosing", so "moved to no shop" (untagged, a
/// real choice) is never confused with "cancelled".
class _MoveToShopV2Outcome {
  const _MoveToShopV2Outcome(this.shopId);

  final ShopId? shopId;
}

/// The multi-select "Move" sheet -- a duplicate of
/// `list_detail_screen.dart`'s own private `_MoveToShopSheet` rather than a
/// shared widget extracted early: that file's version is private to it, and
/// this screen otherwise never reaches into the real screen's internals.
class _MoveToShopV2Sheet extends StatelessWidget {
  const _MoveToShopV2Sheet({required this.shops, required this.t});

  final List<Shop> shops;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sheetH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.items.moveTo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.shops.none),
                  selected: false,
                  onSelected: (_) => Navigator.of(
                    context,
                  ).pop(const _MoveToShopV2Outcome(null)),
                ),
                for (final shop in shops)
                  ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(shop.color.argb),
                      radius: 8,
                    ),
                    label: Text(shop.name),
                    selected: false,
                    onSelected: (_) => Navigator.of(
                      context,
                    ).pop(_MoveToShopV2Outcome(shop.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
