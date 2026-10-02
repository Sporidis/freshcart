import 'package:freshcart_domain/freshcart_domain.dart';

/// What the items area is doing right now. Only one at a time.
///
/// One value instead of three booleans (rearranging, selecting, searching).
/// With booleans, every widget would need to decide which one wins.
/// `ItemsSectionController` decides that once.
enum ItemsMode { browse, search, select, rearrange }

/// The data `ItemsSection` shows.
///
/// Plain Dart (no Flutter types, so [HexColor] instead of `Color`), so it
/// can be tested without widgets.
class ItemsSectionState {
  const ItemsSectionState({
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

  /// All items, ignoring the shop tab. Search and the "all done" check use
  /// all shops.
  final List<ShoppingItem> allItems;

  final List<Shop> shops;
  final ShopId? shopFilter;

  /// Your own member entry, for the avatar in the header.
  final ListMember? me;

  final Set<ItemId> selection;
  final String searchQuery;
  final bool doneCollapsed;

  /// Whether to show the "all done" card: everything is checked, the user
  /// didn't tap "Keep list", and auto-clear is off (decisions.md #79).
  final bool showCelebration;

  /// Still loading (not the same as "loaded, but empty"). Shows a spinner,
  /// so the empty state doesn't flash.
  final bool isLoading;

  /// Set when the items couldn't load. (Failed saves aren't here; the save
  /// method returns those.)
  final Failure? loadFailure;

  /// The items in the selected shop tab (unlike [allItems]).
  List<ShoppingItem> get _visible => [
    for (final i in allItems)
      if (i.matchesShopFilter(shopFilter)) i,
  ];

  /// The items in the tab, split into open and checked.
  List<ShoppingItem> get openItems => [
    for (final i in _visible)
      if (!i.isChecked) i,
  ];
  List<ShoppingItem> get doneItems => [
    for (final i in _visible)
      if (i.isChecked) i,
  ];

  /// The search text, without spaces at the start or end.
  String get trimmedQuery => searchQuery.trim();

  /// Items whose name contains the search text (ignoring upper/lower case),
  /// in all shops.
  List<ShoppingItem> get searchMatches {
    final q = trimmedQuery.toLowerCase();
    return [
      for (final i in allItems)
        if (i.name.toLowerCase().contains(q)) i,
    ];
  }

  bool get isEmpty => _visible.isEmpty;

  /// Whether rearranging is allowed. Always true right now (on every tab).
  bool get canRearrange => true;

  /// True for a brand-new empty list (on "All"). The add button then pulses
  /// to get attention.
  bool get firstRun => shopFilter == null && allItems.isEmpty;

  Shop? get activeShop => shopFor(shopFilter);

  Shop? shopFor(ShopId? id) =>
      id == null ? null : shops.where((s) => s.id == id).firstOrNull;

  /// An item in shop [shopId] with exactly the name [name] (ignoring
  /// spaces at the ends and upper/lower case), or null.
  ///
  /// Used for the "Already on the list" warning. The same name in another
  /// shop doesn't count.
  ShoppingItem? duplicateFor(String name, ShopId? shopId) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final item in allItems) {
      if (item.shopId == shopId && item.name.trim().toLowerCase() == target) {
        return item;
      }
    }
    return null;
  }
}
