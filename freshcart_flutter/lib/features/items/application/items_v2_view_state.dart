import 'package:freshcart_domain/freshcart_domain.dart';

/// Which of its mutually exclusive modes the V2 items screen is in.
///
/// One value instead of three independent booleans (rearranging, selecting,
/// searching) that the UI would otherwise have to rank against each other in
/// every nested ternary -- the ranking lives once, in `ItemsV2ViewModel`.
enum ItemsV2Mode { browse, search, select, rearrange }

/// Everything `ItemsSectionV2` renders, already derived.
///
/// Pure Dart on purpose (domain types only, [HexColor] rather than Flutter's
/// `Color`): the screen converts at the last moment, and this stays
/// unit-testable without a widget tree.
class ItemsV2ViewState {
  const ItemsV2ViewState({
    required this.list,
    required this.mode,
    required this.allItems,
    required this.openItems,
    required this.doneItems,
    required this.shops,
    required this.shopFilter,
    required this.me,
    required this.selection,
    required this.searchQuery,
    required this.doneCollapsed,
    required this.showCelebration,
  });

  final ShoppingList list;
  final ItemsV2Mode mode;

  /// Every item on the list, ignoring the shop filter -- search and the
  /// completion celebration both span all shops.
  final List<ShoppingItem> allItems;

  /// The filtered rows, split the way the screen draws them.
  final List<ShoppingItem> openItems;
  final List<ShoppingItem> doneItems;

  final List<Shop> shops;
  final ShopId? shopFilter;

  /// The signed-in user's own membership, for the header avatar.
  final ListMember? me;

  final Set<ItemId> selection;
  final String searchQuery;
  final bool doneCollapsed;

  /// Fully checked and not yet dismissed via "Keep list".
  final bool showCelebration;

  bool get isEmpty => openItems.isEmpty && doneItems.isEmpty;

  /// Reordering is scoped to one shop tab -- moving between shops is an
  /// edit/move action instead, so on "All" there's nothing to rearrange.
  bool get canRearrange => shopFilter != null;

  /// No filter and nothing on the list yet: the add bar's first-run prompt.
  bool get firstRun => shopFilter == null && allItems.isEmpty;

  Shop? get activeShop => shopFor(shopFilter);

  Shop? shopFor(ShopId? id) =>
      id == null ? null : shops.where((s) => s.id == id).firstOrNull;
}
