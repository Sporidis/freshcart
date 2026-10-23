import 'package:freshcart_domain/freshcart_domain.dart';

/// One row of the drawer.
class ListsDrawerRow {
  const ListsDrawerRow({
    required this.list,
    required this.summary,
    required this.othersInList,
    this.shopColors = const [],
  });

  final ShoppingList list;

  /// Item counts ("6 left" / "All done"), or null until loaded.
  final ListSummary? summary;

  /// Everyone on [list] except you. Shown as avatars.
  final List<ListMember> othersInList;

  /// The colours of the list's shops, in tab order.
  final List<HexColor> shopColors;
}
