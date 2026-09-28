import 'package:freshcart_domain/freshcart_domain.dart';

/// Which of its mutually exclusive modes the items screen is in.
///
/// One value instead of three independent booleans (rearranging, selecting,
/// searching) that the UI would otherwise have to rank against each other in
/// every nested ternary -- the ranking lives once, in `ItemsScreenController`.
enum ItemsMode { browse, search, select, rearrange }

/// Everything `ItemsSection` renders, already derived.
///
/// Pure Dart on purpose (domain types only, [HexColor] rather than Flutter's
/// `Color`): the screen converts at the last moment, and this stays
/// unit-testable without a widget tree.
class ItemsScreenState {
  const ItemsScreenState({
    required this.list,
    required this.mode,
    required this.allItems,
    required this.shops,
    required this.shopFilter,
    required this.me,
    required this.selection,
    required this.searchQuery,
    required this.doneCollapsed,
    required this.showCelebration,
    this.isLoading = false,
    this.loadFailure,
  });

  final ShoppingList list;
  final ItemsMode mode;

  /// Every item on the list, ignoring the shop filter -- search and the
  /// completion celebration both span all shops.
  final List<ShoppingItem> allItems;

  final List<Shop> shops;
  final ShopId? shopFilter;

  /// The signed-in user's own membership, for the header avatar.
  final ListMember? me;

  final Set<ItemId> selection;
  final String searchQuery;
  final bool doneCollapsed;

  /// Fully checked, not yet dismissed via "Keep list", and the list isn't
  /// set to clear itself instead (decisions #79).
  final bool showCelebration;

  /// Items haven't arrived yet -- distinct from "arrived and empty", so the
  /// screen shows a spinner rather than flashing the empty state.
  final bool isLoading;

  /// The items failed to load at all (not a failed write -- those come back
  /// from the action that caused them).
  final Failure? loadFailure;

  /// The rows under the shop filter -- unlike [allItems], which ignores it.
  List<ShoppingItem> get _visible => [
    for (final i in allItems)
      if (i.matchesShopFilter(shopFilter)) i,
  ];

  /// The filtered rows, split the way the screen draws them.
  List<ShoppingItem> get openItems => [
    for (final i in _visible)
      if (!i.isChecked) i,
  ];
  List<ShoppingItem> get doneItems => [
    for (final i in _visible)
      if (i.isChecked) i,
  ];

  bool get isEmpty => _visible.isEmpty;

  /// Reordering is scoped to one shop tab -- moving between shops is an
  /// edit/move action instead, so on "All" there's nothing to rearrange.
  bool get canRearrange => shopFilter != null;

  /// No filter and nothing on the list yet: the add bar's first-run prompt.
  bool get firstRun => shopFilter == null && allItems.isEmpty;

  Shop? get activeShop => shopFor(shopFilter);

  Shop? shopFor(ShopId? id) =>
      id == null ? null : shops.where((s) => s.id == id).firstOrNull;
}
