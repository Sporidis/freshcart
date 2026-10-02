import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/swipe_to_delete.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/delete_item_with_undo.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_recently_bought.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The search results: one list with matches from all shops (ignoring the
/// selected tab). A small dot shows each item's shop.
///
/// A separate widget, not another mode of [ItemsSection]'s list: search
/// has no shop filter, no open/done split, and no select or drag. Simpler
/// as its own small widget.
class SearchResults extends StatelessWidget {
  /// Creates the results list for [state]'s query.
  const SearchResults({
    required this.state,
    required this.vm,
    required this.t,
    required this.dotFor,
    required this.onEdit,
    required this.report,
    super.key,
  });

  /// The items state: search text, matches, and the list (for member
  /// names).
  final ItemsSectionState state;

  /// The controller. All actions go through it, like in the normal list.
  final ItemsSectionController vm;

  final Translations t;
  final void Function(Failure?, {VoidCallback? onRetry}) report;

  /// Called when the user wants to edit [item].
  final void Function(ShoppingItem item) onEdit;

  /// The shop dot colour for an item, or `null` if it has no shop.
  final Color? Function(ShopId? shopId) dotFor;

  @override
  Widget build(BuildContext context) {
    final trimmed = state.trimmedQuery;
    // Nothing typed yet: show "Recently bought" (the list's history).
    if (trimmed.isEmpty) {
      return SearchRecentlyBought(
        listId: state.list.id,
        t: t,
        vm: vm,
        report: report,
      );
    }
    final matches = state.searchMatches;

    if (matches.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: t.search.noResultsTitle(query: trimmed),
        body: t.search.noResultsBody,
        action: _AddToListButton(
          label: t.search.addAction(query: trimmed),
          onPressed: () async => report(await vm.addFromSearch(trimmed)),
        ),
      );
    }

    return ListView(
      children: [
        for (final item in matches)
          SwipeToDelete(
            key: ValueKey(item.id.value),
            dismissKey: ValueKey('swipe-${item.id.value}'),
            semanticLabel: t.common.delete,
            onSwipe: () async => true,
            onDismissed: () => deleteItemWithUndo(
              context,
              item: item,
              delete: vm.swipeDelete,
              t: t,
            ),
            child: ItemTile(
              item: item,
              t: t,
              shopColor: dotFor(item.shopId),
              checkedByMember: item.checkedBy == null
                  ? null
                  : state.list.memberFor(item.checkedBy!),
              onToggle: () async => report(await vm.toggle(item)),
              onDelete: () => deleteItemWithUndo(
                context,
                item: item,
                delete: vm.swipeDelete,
                t: t,
              ),
              onQuantityChanged: (quantity) async => report(
                await vm.setQuantity(item, quantity),
              ),
              onEdit: () => onEdit(item),
              highlightQuery: trimmed,
            ),
          ),
      ],
    );
  }
}

/// The "Add '{query}' to this list" button, shown when search finds
/// nothing. Vibrates on tap, and blocks a fast double-tap from adding
/// twice.
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
    ref.haptic(HapticFeedback.lightImpact);
    await widget.onPressed();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _busy ? null : _handleTap,
    child: Text(widget.label),
  );
}
