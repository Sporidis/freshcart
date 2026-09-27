import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/haptics/haptics_provider.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/celebration_dismissed_provider.dart';
import 'package:freshcart_flutter/features/items/application/done_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/recently_added_provider.dart';
import 'package:freshcart_flutter/features/items/application/search_controller.dart';
import 'package:freshcart_flutter/features/items/application/selection_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The items of one list, filtered by the active shop, with the add field
/// pinned underneath.
class ItemsSection extends ConsumerWidget {
  /// Creates the section for [list].
  const ItemsSection({required this.list, super.key});

  /// Clears the floating add control (56px resting circle + its own
  /// margins) that sits on top of this section -- shared by [_ItemList]'s
  /// own bottom padding and [_ItemsEmptyState]'s, so neither the last row
  /// nor the empty-state copy renders underneath it, or centres itself
  /// against the full height behind it instead of the space actually left
  /// above it.
  static const double _floatingClusterInset = 84;

  /// The list whose items to show. Members come from here so a checked-off item
  /// can name the person who ticked it without another request.
  final ShoppingList list;

  /// Applies the active shop filter.
  ///
  /// The rule itself lives on the entity — an untagged item matches every
  /// filter, so a forgotten tag never hides someone's shopping.
  static List<ShoppingItem> visibleIn(
    List<ShoppingItem> all,
    ShopId? filter,
  ) => [
    for (final item in all)
      if (item.matchesShopFilter(filter)) item,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final items = ref.watch(itemsControllerProvider(list.id));
    final controller = ref.read(itemsControllerProvider(list.id).notifier);
    final shopFilter = ref.watch(shopFilterProvider(list.id));
    final shops =
        ref.watch(shopsControllerProvider(list.id)).dataOrNull ??
        const <Shop>[];
    final activeShop = shopFilter == null
        ? null
        : shops.where((s) => s.id == shopFilter).firstOrNull;
    final selectionMode = ref.watch(
      selectionControllerProvider(list.id).select((s) => s.isNotEmpty),
    );
    final search = ref.watch(searchControllerProvider(list.id));

    // The completion celebration looks at *every* item on the list, not
    // just the active shop tab -- "all done" means the whole list, the same
    // way the design's own `allDone` check does.
    final allItems = items.dataOrNull ?? const <ShoppingItem>[];
    final allDone = allItems.isNotEmpty && allItems.every((i) => i.isChecked);
    final celebrationDismissed = ref.watch(
      celebrationDismissedProvider(list.id),
    );

    // The moment the list stops being fully checked -- an item added,
    // unchecked, or cleared -- forget the dismissal, so the celebration is
    // ready to show again the next time it actually applies, rather than
    // staying silenced by one long-ago tap.
    ref.listen(itemsControllerProvider(list.id), (previous, next) {
      final nextItems = next.dataOrNull;
      if (nextItems == null) return;
      final stillAllDone =
          nextItems.isNotEmpty && nextItems.every((i) => i.isChecked);
      if (!stillAllDone) {
        ref.read(celebrationDismissedProvider(list.id).notifier).reset();
      }
    });

    /// Shows the message behind a rolled-back optimistic update.
    ///
    /// Without this a row would tick, untick itself and leave the user
    /// wondering whether they mis-tapped.
    void report(Failure? failure, {VoidCallback? onRetry}) {
      if (failure == null || !context.mounted) return;
      // A failed write is the snackbar tier: the screen behind it is still
      // perfectly usable, so it gets a message and a way to try again rather
      // than being replaced.
      showFailureSnackBar(
        context,
        failure: failure,
        t: t,
        onRetry: onRetry,
      );
    }

    // Auto-clears the instant the list finishes, when this list's own
    // "Clear checked after shopping" preference (decisions #79) is on --
    // silently, no prompt, which is why the celebration card below is also
    // gated on this being off: the two are mutually exclusive ways of
    // handling the same moment, not layered on top of each other. The
    // preference check happens inside the callback, not around the
    // `ref.listen` call itself, so this is called unconditionally every
    // build regardless of the preference's current value.
    ref.listen(itemsControllerProvider(list.id), (previous, next) {
      if (!list.clearCheckedAfterShopping) return;
      final previousItems = previous?.dataOrNull;
      final nextItems = next.dataOrNull;
      // No real prior snapshot yet (this is the initial load resolving, not
      // a change witnessed during this session) -- a list that already
      // happened to be fully checked when opened must not auto-clear the
      // instant it loads, only a transition that actually happens while
      // someone is looking at it.
      if (previousItems == null || nextItems == null) return;
      final previousAllDone =
          previousItems.isNotEmpty && previousItems.every((i) => i.isChecked);
      final nextAllDone =
          nextItems.isNotEmpty && nextItems.every((i) => i.isChecked);
      if (!previousAllDone && nextAllDone) {
        unawaited(controller.clearChecked().then(report));
      }
    });

    // A Stack, not a Column: Flow 09 calls this "the FAB" for a reason -- a
    // real floating action button overlays scrollable content, it doesn't
    // sit in its own docked row shrinking the list to make room. The list
    // fills the whole area; the add control (and, above it, the completion
    // celebration) floats on top, anchored to the bottom. _ItemList carries
    // its own bottom padding so its last rows clear the floating cluster
    // rather than rendering underneath it.
    return Stack(
      children: [
        Positioned.fill(
          // Keyed per branch, not just switched: without a key that
          // actually changes across shop tabs, two non-empty shops both
          // rendering an `_ItemList` are the *same* widget as far as
          // Flutter's tree-diffing is concerned -- it just updates the
          // existing element's `rows` in place, so switching shops with
          // items in both used to hard-cut with no transition at all,
          // unlike the header's own themed colour reveal. A shop-scoped key
          // makes every switch -- list-to-list included -- a genuine child
          // replacement AnimatedSwitcher can cross-fade.
          child: AnimatedSwitcher(
            duration: AppMotion.durationFor(context, AppMotion.standard),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.enter,
            child: switch (items) {
              AsyncLoading<Result<List<ShoppingItem>>>() => const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
              AsyncError<Result<List<ShoppingItem>>>() => Center(
                key: const ValueKey('error'),
                child: Text(t.errors.unexpected),
              ),
              AsyncOutcome<List<ShoppingItem>>(:final value?) => switch (value) {
                Err<List<ShoppingItem>>(:final failure) => Center(
                  key: const ValueKey('error'),
                  child: Text(failure.toMessage(t)),
                ),
                // Search bypasses the shop filter and the open/done split
                // entirely (§16: "one flat list across all shops") -- checked
                // first, ahead of the ordinary empty-state and list branches,
                // so it wins regardless of what they would have shown. Not
                // keyed per-query -- re-fading on every keystroke would be
                // noise, not a "switched to a different view" moment.
                Ok<List<ShoppingItem>>(value: final all) when search.active =>
                  SearchResults(
                    // Not 'search' -- the app bar's own search TextField
                    // (list_detail_screen.dart's `_buildTitle`) already owns
                    // that key, and both are mounted at once while search is
                    // active.
                    key: const ValueKey('search-results'),
                    list: list,
                    allItems: all,
                    query: search.query,
                    t: t,
                    controller: controller,
                    report: report,
                  ),
                // Two different empties, and the difference matters: an empty
                // shop tab is a filter result, so it names the shop and tints
                // to its colour, while an empty list is the first-run state and
                // points at the add field instead.
                Ok<List<ShoppingItem>>(value: final all)
                    when visibleIn(all, shopFilter).isEmpty =>
                  _ItemsEmptyState(
                    key: ValueKey(('empty', shopFilter)),
                    listId: list.id,
                    shopFilter: shopFilter,
                    t: t,
                  ),
                Ok<List<ShoppingItem>>(value: final all) => _ItemList(
                  key: ValueKey(('list', shopFilter)),
                  rows: visibleIn(all, shopFilter),
                  list: list,
                  shopFilter: shopFilter,
                  t: t,
                  controller: controller,
                  report: report,
                  onRefresh: controller.refresh,
                ),
              },
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only once nothing else is competing for the bottom of the
              // screen -- multi-select and search each have their own
              // reason to hide the quick-add bar just below, and the same
              // reasons apply here. Never shown at all when the list
              // auto-clears (decisions #79): that preference silently
              // resolves this exact moment instead of prompting, so the two
              // are mutually exclusive, not layered.
              if (allDone &&
                  !list.clearCheckedAfterShopping &&
                  !celebrationDismissed &&
                  !selectionMode &&
                  !search.active)
                CompletionCelebrationCard(
                  list: list,
                  itemCount: allItems.length,
                  // "The list's shop colours only" (§09) — a shopless list
                  // (every item untagged) has no such palette to draw from,
                  // so the confetti falls back to the app's own preset
                  // swatches rather than the celebration silently rendering
                  // zero particles.
                  shopColors: shops.isEmpty
                      ? AppColors.presetShopColors
                      : [for (final shop in shops) Color(shop.color.argb)],
                  t: t,
                  report: report,
                ),
              // Slides out during multi-select or search (§10, §16): neither
              // leaves room for adding a fresh item the ordinary way --
              // search offers its own "Add to list" inside the no-results
              // state instead.
              AnimatedSize(
                duration: AppMotion.durationFor(context, AppMotion.standard),
                curve: AppMotion.enter,
                alignment: Alignment.topCenter,
                child: selectionMode || search.active
                    ? const SizedBox(width: double.infinity)
                    : QuickAddBar(
                        listId: list.id,
                        t: t,
                        activeShopName: activeShop?.name,
                        firstRun: shopFilter == null && allItems.isEmpty,
                        onQuickAdd: (name) async {
                          // Tags to whichever shop tab is active, the same as
                          // the details sheet already does -- "Enter" is
                          // meant to be the fast path to the same result, not
                          // a different one.
                          final failure = await controller.add(
                            name: name,
                            shopId: shopFilter,
                          );
                          report(failure);
                          return failure == null;
                        },
                        onOpenDetails: (name) async {
                          final outcome =
                              await showModalBottomSheet<ItemSheetOutcome>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => ItemSheet.add(
                                  initialName: name,
                                  shops: shops,
                                  initialShopId: shopFilter,
                                  t: t,
                                ),
                              );
                          // Only ItemSheetSave is reachable from .add --
                          // there is no Remove action to add a
                          // not-yet-created item.
                          if (outcome is! ItemSheetSave) return false;
                          final failure = await controller.add(
                            name: outcome.name,
                            quantity: outcome.quantity,
                            shopId: outcome.shopId,
                            noteText: outcome.noteText,
                          );
                          report(failure);
                          return failure == null;
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({
    required this.rows,
    required this.list,
    required this.shopFilter,
    required this.t,
    required this.controller,
    required this.report,
    required this.onRefresh,
    super.key,
  });

  final List<ShoppingItem> rows;
  final ShoppingList list;

  /// The active shop tab, or null for "All". Drag-to-reorder is scoped to
  /// one shop tab (§10: "cross-shop reordering is meaningless -- moving
  /// between shops is a swipe action instead"), so it is only offered here.
  final ShopId? shopFilter;
  final Translations t;
  final ItemsController controller;
  final void Function(Failure?, {VoidCallback? onRetry}) report;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyChecked = ref.watch(recentlyCheckedProvider(list.id));
    final holding = recentlyChecked.holding;
    final transitioning = recentlyChecked.transitioning;
    final justAddedId = ref.watch(recentlyAddedProvider(list.id));
    final collapsed = ref.watch(doneSectionCollapsedProvider(list.id));
    final selection = ref.watch(selectionControllerProvider(list.id));
    final selectionController = ref.read(
      selectionControllerProvider(list.id).notifier,
    );
    // Dragging and multi-select both want the row's gesture, so they take
    // turns: a selection in progress owns it instead.
    final canReorder = shopFilter != null && selection.isEmpty;

    // The shop dot shows on every row, filtered tab or not -- the design's
    // own reference screens carry it even on a single shop's tab, not just
    // "All" (confirmed against the mockup rather than assumed).
    final shops =
        ref.watch(shopsControllerProvider(list.id)).dataOrNull ??
        const <Shop>[];
    Color? dotFor(ShopId? shopId) {
      if (shopId == null) return null;
      final shop = shops.where((s) => s.id == shopId).firstOrNull;
      return shop == null ? null : Color(shop.color.argb);
    }

    // A row counts as "still shopping" while it is being held, so a just-ticked
    // item keeps its place for 600 ms instead of jumping the moment it is
    // tapped -- see RecentlyChecked. Once the hold ends it keeps rendering
    // for one more beat in its *old* section while `transitioning`, playing
    // its exit animation there, mirrored by an entrance animation on the
    // copy that simultaneously appears in its *new* section -- see
    // ItemTile.checkMoveEntering/checkMoveExiting below.
    final open = [
      for (final item in rows)
        if (!item.isChecked ||
            holding.contains(item.id) ||
            (item.isChecked && transitioning.contains(item.id)))
          item,
    ];
    final done = [
      for (final item in rows)
        if ((item.isChecked && !holding.contains(item.id)) ||
            (!item.isChecked && transitioning.contains(item.id)))
          item,
    ];

    // [index] is only passed for rows that can actually be multi-selected or
    // dragged (the open ones) -- a done row always renders out of both
    // modes: checked items are a settled category with their own bulk
    // action already ("Clear checked") and sit locked below the divider,
    // never draggable (§10).
    //
    // [inDoneSection] tells a mid-transition row which half of its move
    // *this* copy of it is playing -- the same item can render once in each
    // section for the duration of the move (different parents, so the same
    // ValueKey on both is not a conflict).
    Widget tileFor(
      ShoppingItem item, {
      int? index,
      bool inDoneSection = false,
    }) {
      final isMoving = transitioning.contains(item.id);
      return ItemTile(
        key: ValueKey(item.id.value),
        item: item,
        t: t,
        justAdded: item.id == justAddedId,
        index: index ?? 0,
        shopDotColor: dotFor(item.shopId),
        canReorder: index != null && canReorder,
        selectionMode: index != null && selection.isNotEmpty,
        selected: selection.contains(item.id),
        onToggleSelection: () => selectionController.toggle(item.id),
        onLongPress: () => selectionController.toggle(item.id),
        checkedByMember: item.checkedBy == null
            ? null
            : list.memberFor(item.checkedBy!),
        checkMoveEntering:
            isMoving && (inDoneSection ? item.isChecked : !item.isChecked),
        checkMoveExiting:
            isMoving && (inDoneSection ? !item.isChecked : item.isChecked),
        onToggle: () async {
          // Held on the way in, released on the way out: checking is easy to
          // mis-tap, unchecking is deliberate.
          final recent = ref.read(recentlyCheckedProvider(list.id).notifier);
          if (item.isChecked) {
            recent.release(
              item.id,
              exitDuration: AppMotion.durationFor(context, AppMotion.quick),
            );
          } else {
            recent.hold(
              item.id,
              exitDuration: AppMotion.durationFor(context, AppMotion.standard),
            );
          }
          report(
            await controller.toggle(item),
            onRetry: () async => report(await controller.toggle(item)),
          );
        },
        onSwipeDelete: () => controller.swipeDelete(item),
        onEdit: () async {
          final outcome = await showModalBottomSheet<ItemSheetOutcome>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => ItemSheet.edit(item: item, shops: shops, t: t),
          );
          switch (outcome) {
            case null:
              return;
            case ItemSheetRemove():
              report(await controller.remove(item));
            case ItemSheetSave(
              :final name,
              :final quantity,
              :final shopId,
              :final noteText,
            ):
              report(
                await controller.edit(
                  item,
                  name: name,
                  quantity: quantity,
                  shopId: shopId,
                  noteText: noteText,
                ),
              );
          }
        },
      );
    }

    // onReorderItem's newIndex is already adjusted for the dragged item's
    // own removal from oldIndex, so it names the slot to insert at directly
    // -- no "subtract one if newIndex > oldIndex" bookkeeping.
    void handleReorder(int oldIndex, int newIndex) {
      final item = open[oldIndex];
      final remaining = [...open]..removeAt(oldIndex);
      final before = newIndex > 0 ? remaining[newIndex - 1] : null;
      final after = newIndex < remaining.length ? remaining[newIndex] : null;
      unawaited(
        controller.reorder(item, before: before, after: after).then(report),
      );
    }

    Widget openSection() {
      if (!canReorder) {
        // Still indexed: selection mode needs it for the reveal's stagger
        // and to tell these rows apart from the Done section's, even when
        // dragging itself is off (the "All" tab, or mid-selection already).
        return Column(
          children: [
            for (final (index, item) in open.indexed)
              tileFor(item, index: index),
          ],
        );
      }
      return ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // The default drag-anywhere-on-mobile-after-a-long-press behavior
        // would collide with long-press already meaning "enter multi-select"
        // (§10, its own gesture) -- a dedicated handle sidesteps the clash
        // instead of overloading one gesture with two meanings.
        buildDefaultDragHandles: false,
        onReorderStart: (_) {
          if (ref.read(hapticsControllerProvider).value ?? true) {
            unawaited(HapticFeedback.selectionClick());
          }
        },
        onReorderEnd: (_) {
          if (ref.read(hapticsControllerProvider).value ?? true) {
            unawaited(HapticFeedback.lightImpact());
          }
        },
        onReorderItem: handleReorder,
        // Elevation 8, scale 1.03, opacity 95% (§10). `animation` is driven
        // by ReorderableListView's own pickup/drop transition, so this
        // tracks its actual timing rather than a separately-guessed one.
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.03 * animation.value,
            child: Material(
              elevation: 8 * animation.value,
              color: Colors.transparent,
              child: Opacity(
                opacity: 1 - 0.05 * animation.value,
                child: child,
              ),
            ),
          ),
          child: child,
        ),
        children: [
          for (final (index, item) in open.indexed) tileFor(item, index: index),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(
          bottom: ItemsSection._floatingClusterInset,
        ),
        children: [
          openSection(),
          if (done.isNotEmpty) ...[
            DoneDivider(
              label: t.items.doneCount(n: done.length),
              collapsed: collapsed,
              onToggle: ref
                  .read(doneSectionCollapsedProvider(list.id).notifier)
                  .toggle,
              clearLabel: t.items.clearChecked,
              onClear: () async => report(await controller.clearChecked()),
            ),
            // Checked rows are never removed, only folded: the shopper needs
            // to see what is already in the trolley.
            // AnimatedSize rather than AnimatedCrossFade: the folded rows
            // leave the tree entirely, so nothing reads them out or holds
            // their state while they are hidden.
            AnimatedSize(
              duration: AppMotion.durationFor(context, AppMotion.standard),
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: collapsed
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      children: [
                        for (final item in done)
                          tileFor(item, inDoneSection: true),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The empty state for the items area, in its two forms.
class _ItemsEmptyState extends ConsumerWidget {
  const _ItemsEmptyState({
    required this.listId,
    required this.shopFilter,
    required this.t,
    super.key,
  });

  final ListId listId;
  final ShopId? shopFilter;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shopFilter == null) {
      // No arrow here (§11: "no arrow, no persistent coach mark") -- the
      // first-run hint is the add control itself pulsing, wired through
      // QuickAddBar.firstRun in ItemsSection.build.
      return Padding(
        padding: const EdgeInsets.only(
          bottom: ItemsSection._floatingClusterInset,
        ),
        child: EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: t.items.emptyTitle,
          body: t.items.emptyBody,
        ),
      );
    }

    final shops = ref.watch(shopsControllerProvider(listId)).dataOrNull;
    final shop = shops?.where((s) => s.id == shopFilter).firstOrNull;
    if (shop == null) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: ItemsSection._floatingClusterInset,
        ),
        child: EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: t.items.emptyTitle,
          body: t.items.emptyBody,
        ),
      );
    }

    final tint = Color(shop.color.argb);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ItemsSection._floatingClusterInset,
      ),
      child: EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: t.items.emptyShopTitle(shop: shop.name),
        body: t.items.emptyShopBody,
        tint: tint,
        action: FilledButton(
          onPressed: () => FocusScope.of(context).nextFocus(),
          style: FilledButton.styleFrom(
            backgroundColor: tint,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.labelStrong,
          ),
          child: Text(t.items.emptyShopAction),
        ),
      ),
    );
  }
}
