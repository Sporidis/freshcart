import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/theme/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_recently_bought.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Search's results list (§16): one flat list across every shop, regardless
/// of the active tab, with a small dot standing in for the shop column
/// disambiguating rows that would otherwise be indistinguishable.
///
/// A separate widget from [ItemsSection]'s normal list rather than a fourth
/// mode threaded through it: search bypasses the shop filter entirely, does
/// not split into open/done, and none of [ItemTile]'s selection or drag
/// wiring applies here -- keeping it its own small widget is plainer than
/// growing the other one's branching further.
class SearchResults extends ConsumerWidget {
  /// Creates the results list for [query] against every item on [list].
  const SearchResults({
    required this.list,
    required this.allItems,
    required this.query,
    required this.t,
    required this.controller,
    required this.report,
    super.key,
  });

  /// The list being searched, for member names and its id.
  final ShoppingList list;

  /// Every item on the list, unfiltered by shop or checked state -- search
  /// looks across all of it.
  final List<ShoppingItem> allItems;

  /// What has been typed so far.
  final String query;

  final Translations t;
  final ItemsController controller;
  final void Function(Failure?, {VoidCallback? onRetry}) report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmed = query.trim();
    // Nothing typed yet: not a blank canvas any more -- §06's "Recently
    // bought" is exactly the browseable "everything, grouped" view for this
    // moment, distinct from the shop tabs' own purpose (browsing this list's
    // *current* items, not its history).
    if (trimmed.isEmpty) {
      return SearchRecentlyBought(
        listId: list.id,
        t: t,
        controller: controller,
        report: report,
      );
    }

    final lower = trimmed.toLowerCase();
    final matches = [
      for (final item in allItems)
        if (item.name.toLowerCase().contains(lower)) item,
    ];

    if (matches.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: t.search.noResultsTitle(query: trimmed),
        body: t.search.noResultsBody,
        action: _AddToListButton(
          label: t.search.addAction(query: trimmed),
          onPressed: () async => report(await controller.add(name: trimmed)),
        ),
      );
    }

    final shops =
        ref.watch(shopsControllerProvider(list.id)).dataOrNull ??
        const <Shop>[];
    Color? dotFor(ShopId? shopId) {
      if (shopId == null) return null;
      final shop = shops.where((s) => s.id == shopId).firstOrNull;
      return shop?.color.toColor();
    }

    return ListView(
      children: [
        for (final item in matches)
          ItemTile(
            key: ValueKey(item.id.value),
            item: item,
            t: t,
            shopColor: dotFor(item.shopId),
            checkedByMember: item.checkedBy == null
                ? null
                : list.memberFor(item.checkedBy!),
            onToggle: () async => report(await controller.toggle(item)),
            onDelete: () => controller.swipeDelete(item),
            onQuantityChanged: (quantity) async => report(
              await controller.edit(
                item,
                name: item.name,
                quantity: quantity,
                shopId: item.shopId,
                noteText: item.note?.text,
              ),
            ),
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
          ),
      ],
    );
  }
}

/// The no-results empty state's "Add '{query}' to this list" action -- a
/// haptic on tap and a guard against a rapid double-tap starting the add
/// twice, the same shape [_ReAddButton] in `search_recently_bought.dart`
/// uses (no pop animation here: §06's "pop" is spec'd for the Recently
/// bought "+" specifically, not this button).
class _AddToListButton extends ConsumerStatefulWidget {
  const _AddToListButton({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;

  @override
  ConsumerState<_AddToListButton> createState() => _AddToListButtonState();
}

class _AddToListButtonState extends ConsumerState<_AddToListButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (ref.read(hapticsControllerProvider).value ?? true) {
      unawaited(HapticFeedback.lightImpact());
    }
    await widget.onPressed();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _busy ? null : _handleTap,
    child: Text(widget.label),
  );
}
