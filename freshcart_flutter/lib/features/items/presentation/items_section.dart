import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/done_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/search_controller.dart';
import 'package:freshcart_flutter/features/items/application/selection_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/add_item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_editor_dialog.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search_results.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The items of one list, filtered by the active shop, with the add field
/// pinned underneath.
class ItemsSection extends ConsumerWidget {
  /// Creates the section for [list].
  const ItemsSection({required this.list, super.key});

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
    final selectionMode = ref.watch(
      selectionControllerProvider(list.id).select((s) => s.isNotEmpty),
    );
    final search = ref.watch(searchControllerProvider(list.id));

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

    return Column(
      children: [
        Expanded(
          child: switch (items) {
            AsyncLoading<Result<List<ShoppingItem>>>() => const Center(
              child: CircularProgressIndicator(),
            ),
            AsyncError<Result<List<ShoppingItem>>>() => Center(
              child: Text(t.errors.unexpected),
            ),
            AsyncOutcome<List<ShoppingItem>>(:final value?) => switch (value) {
              Err<List<ShoppingItem>>(:final failure) => Center(
                child: Text(failure.toMessage(t)),
              ),
              // Search bypasses the shop filter and the open/done split
              // entirely (§16: "one flat list across all shops") -- checked
              // first, ahead of the ordinary empty-state and list branches,
              // so it wins regardless of what they would have shown.
              Ok<List<ShoppingItem>>(value: final all) when search.active =>
                SearchResults(
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
                  listId: list.id,
                  shopFilter: shopFilter,
                  t: t,
                ),
              Ok<List<ShoppingItem>>(value: final all) => _ItemList(
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
        // Slides out during multi-select or search (§10, §16): neither
        // leaves room for adding a fresh item the ordinary way -- search
        // offers its own "Add to list" inside the no-results state instead.
        AnimatedSize(
          duration: AppMotion.durationFor(context, AppMotion.standard),
          curve: AppMotion.enter,
          child: selectionMode || search.active
              ? const SizedBox(width: double.infinity)
              : QuickAddBar(
                  t: t,
                  onQuickAdd: (name) async {
                    final failure = await controller.add(name: name);
                    report(failure);
                    return failure == null;
                  },
                  onOpenDetails: (name) async {
                    final shops = switch (ref.read(
                      shopsControllerProvider(list.id),
                    )) {
                      AsyncValue<Result<List<Shop>>>(
                        value: Ok<List<Shop>>(:final value),
                      ) =>
                        value,
                      _ => const <Shop>[],
                    };
                    final details = await showModalBottomSheet<AddItemDetails>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) =>
                          AddItemSheet(initialName: name, shops: shops, t: t),
                    );
                    if (details == null) return;
                    report(
                      await controller.add(
                        name: details.name,
                        quantity: details.quantity,
                        shopId: details.shopId,
                      ),
                    );
                  },
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
    final holding = ref.watch(recentlyCheckedProvider(list.id));
    final collapsed = ref.watch(doneSectionCollapsedProvider(list.id));
    final selection = ref.watch(selectionControllerProvider(list.id));
    final selectionController = ref.read(
      selectionControllerProvider(list.id).notifier,
    );
    // Dragging and multi-select both want the row's gesture, so they take
    // turns: a selection in progress owns it instead.
    final canReorder = shopFilter != null && selection.isEmpty;

    // A row counts as "still shopping" while it is being held, so a just-ticked
    // item keeps its place for 600 ms instead of jumping the moment it is
    // tapped — see RecentlyChecked.
    final open = [
      for (final item in rows)
        if (!item.isChecked || holding.contains(item.id)) item,
    ];
    final done = [
      for (final item in rows)
        if (item.isChecked && !holding.contains(item.id)) item,
    ];

    // [index] is only passed for rows that can actually be multi-selected or
    // dragged (the open ones) -- a done row always renders out of both
    // modes: checked items are a settled category with their own bulk
    // action already ("Clear checked") and sit locked below the divider,
    // never draggable (§10).
    Widget tileFor(ShoppingItem item, {int? index}) => ItemTile(
      key: ValueKey(item.id.value),
      item: item,
      t: t,
      index: index ?? 0,
      canReorder: index != null && canReorder,
      selectionMode: index != null && selection.isNotEmpty,
      selected: selection.contains(item.id),
      onToggleSelection: () => selectionController.toggle(item.id),
      onLongPress: () => selectionController.toggle(item.id),
      checkedByName: item.checkedBy == null
          ? null
          : list.memberFor(item.checkedBy!)?.displayName,
      onToggle: () async {
        // Held on the way in, released on the way out: checking is easy to
        // mis-tap, unchecking is deliberate.
        final recent = ref.read(recentlyCheckedProvider(list.id).notifier);
        if (item.isChecked) {
          recent.release(item.id);
        } else {
          recent.hold(item.id);
        }
        report(
          await controller.toggle(item),
          onRetry: () async => report(await controller.toggle(item)),
        );
      },
      onSwipeDelete: () => controller.swipeDelete(item),
      onEdit: () async {
        final edit = await showDialog<ItemEdit>(
          context: context,
          builder: (context) => ItemEditorDialog(item: item, t: t),
        );
        if (edit == null) return;
        report(
          await controller.edit(
            item,
            name: edit.name,
            quantity: edit.quantity,
            shopId: item.shopId,
            noteText: edit.noteText,
          ),
        );
      },
    );

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
        // The default drag-anywhere-on-mobile-after-a-long-press behaviour
        // would collide with long-press already meaning "enter multi-select"
        // (§10, its own gesture) -- a dedicated handle sidesteps the clash
        // instead of overloading one gesture with two meanings.
        buildDefaultDragHandles: false,
        onReorderStart: (_) => unawaited(HapticFeedback.selectionClick()),
        onReorderEnd: (_) => unawaited(HapticFeedback.lightImpact()),
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
                  : Column(children: done.map(tileFor).toList()),
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
  });

  final ListId listId;
  final ShopId? shopFilter;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shopFilter == null) {
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: t.items.emptyTitle,
        body: t.items.emptyBody,
        action: const _AddNudgeArrow(),
      );
    }

    final shop = switch (ref.watch(shopsControllerProvider(listId))) {
      AsyncOutcome<List<Shop>>(:final value?) => switch (value) {
        Ok<List<Shop>>(value: final shops) =>
          shops.where((s) => s.id == shopFilter).firstOrNull,
        Err<List<Shop>>() => null,
      },
      _ => null,
    };
    if (shop == null) {
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: t.items.emptyTitle,
        body: t.items.emptyBody,
      );
    }

    final tint = Color(shop.color.argb);
    return EmptyState(
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
    );
  }
}

/// The arrow that nudges toward the quick-add bar.
///
/// Three gentle bounces, then it stops for good: a hint that keeps moving
/// forever stops reading as a hint and starts reading as a defect.
///
/// One controller running a [TweenSequence] rather than a loop of awaited
/// delays — a timer loop keeps firing after the widget is gone, and leaves
/// a pending timer behind in any test that renders this state.
class _AddNudgeArrow extends StatefulWidget {
  const _AddNudgeArrow();

  @override
  State<_AddNudgeArrow> createState() => _AddNudgeArrowState();
}

class _AddNudgeArrowState extends State<_AddNudgeArrow>
    with SingleTickerProviderStateMixin {
  static const int _bounces = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.bouncy * _bounces * 2,
  );

  late final Animation<double> _offset = TweenSequence<double>([
    for (var i = 0; i < _bounces; i++) ...[
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: AppMotion.enter),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: AppMotion.enter),
        ),
        weight: 1,
      ),
    ],
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28);
    final arrow = Icon(Icons.arrow_downward, size: 20, color: ink);
    if (AppMotion.reduced(context)) return arrow;
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 6 * _offset.value),
        child: child,
      ),
      child: arrow,
    );
  }
}
