import 'package:freshcart_domain/freshcart_domain.dart';

/// The items in [current] that just arrived: on the list now, not in
/// [previous]. Those rows get the v3 "new row" entrance and flash, whoever
/// added them (you, or someone in the household, live).
///
/// Not every new row on screen is a new item, so this compares data, not
/// widgets: rows are also built on the first load, on a tab switch and
/// when scrolled into view. With no [previous] (the first load) nothing
/// has arrived.
///
/// One exception: an item added offline syncs by swapping its temporary
/// row for the server's, under a new id. That's the same item, so it
/// doesn't count: a pending row that left in this update takes a new row
/// with the same name with it.
Set<ItemId> itemArrivals(
  List<ShoppingItem>? previous,
  List<ShoppingItem> current,
) {
  if (previous == null) return const {};
  final before = {for (final item in previous) item.id};
  final now = {for (final item in current) item.id};

  String key(ShoppingItem item) => item.name.trim().toLowerCase();
  final synced = {
    for (final item in previous)
      if (item.pending && !now.contains(item.id)) key(item),
  };

  return {
    for (final item in current)
      if (!before.contains(item.id) && !synced.contains(key(item))) item.id,
  };
}
