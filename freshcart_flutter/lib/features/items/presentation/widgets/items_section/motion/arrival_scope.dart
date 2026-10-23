import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_section/item_arrivals.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/arrival_flash.dart';

/// Works out which items just arrived (see [itemArrivals]) by keeping the
/// previous list, and offers that to the rows below, for [ArrivalFlash].
///
/// Outside the state switch, like [TabSwitchMotion], so an empty tab in
/// between doesn't forget the previous items.
class ArrivalScope extends StatefulWidget {
  const ArrivalScope({
    super.key,
    required this.items,
    required this.me,
    required this.child,
  });

  /// Every item on the list, or null while still loading.
  final List<ShoppingItem>? items;
  final UserId? me;
  final Widget child;

  static _ArrivalInfo? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ArrivalInfo>();

  /// Whether [id] arrived in the latest update.
  static bool isNew(BuildContext context, ItemId id) =>
      _of(context)?.arrived.contains(id) ?? false;

  /// Whether the signed-in user added [item].
  static bool isMine(BuildContext context, ShoppingItem item) =>
      _of(context)?.me == item.addedBy;

  @override
  State<ArrivalScope> createState() => _ArrivalScopeState();
}

class _ArrivalScopeState extends State<ArrivalScope> {
  Set<ItemId> _arrived = const {};

  @override
  void didUpdateWidget(ArrivalScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final items = widget.items;
    // Only a new list of items can bring arrivals. Any other rebuild keeps
    // the last answer, so a row that's flashing isn't cut short.
    if (items == null || identical(items, oldWidget.items)) return;
    _arrived = itemArrivals(oldWidget.items, items);
  }

  @override
  Widget build(BuildContext context) =>
      _ArrivalInfo(arrived: _arrived, me: widget.me, child: widget.child);
}

class _ArrivalInfo extends InheritedWidget {
  const _ArrivalInfo({
    required this.arrived,
    required this.me,
    required super.child,
  });

  final Set<ItemId> arrived;
  final UserId? me;

  @override
  bool updateShouldNotify(_ArrivalInfo oldWidget) =>
      !identical(arrived, oldWidget.arrived) || me != oldWidget.me;
}
