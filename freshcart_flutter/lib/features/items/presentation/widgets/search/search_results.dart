import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_recently_bought.dart';
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

  /// The items section's derived state: the query, its matches (across every
  /// shop and checked state), and the list for member names.
  final ItemsSectionState state;

  /// Every action goes through the view model, same as the normal rows.
  final ItemsSectionController vm;

  final Translations t;
  final void Function(Failure?, {VoidCallback? onRetry}) report;

  /// Called when the user wants to edit [item].
  final void Function(ShoppingItem item) onEdit;

  /// The shop dot's colour for a row, or `null` for an untagged item.
  final Color? Function(ShopId? shopId) dotFor;

  @override
  Widget build(BuildContext context) {
    final trimmed = state.trimmedQuery;
    // Nothing typed yet: not a blank canvas any more -- §06's "Recently
    // bought" is exactly the browseable "everything, grouped" view for this
    // moment, distinct from the shop tabs' own purpose (browsing this list's
    // *current* items, not its history).
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
          ItemTile(
            key: ValueKey(item.id.value),
            item: item,
            t: t,
            shopColor: dotFor(item.shopId),
            checkedByMember: item.checkedBy == null
                ? null
                : state.list.memberFor(item.checkedBy!),
            onToggle: () async => report(await vm.toggle(item)),
            onDelete: () => vm.swipeDelete(item),
            onQuantityChanged: (quantity) async => report(
              await vm.setQuantity(item, quantity),
            ),
            onEdit: () => onEdit(item),
            highlightQuery: trimmed,
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
