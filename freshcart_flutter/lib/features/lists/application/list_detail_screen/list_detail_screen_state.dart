import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_screen/items_screen_state.dart';
import 'package:meta/meta.dart';

/// The list-level half of `ListDetailScreen`: the route shell, its theming
/// and the header menu. The rows are `ItemsScreenState`'s business.
///
/// Pure Dart on purpose (domain types only, [HexColor] rather than Flutter's
/// `Color`), same as the other screen states.
///
/// Value equality is load-bearing: the view model re-runs on every item
/// change (it reads the items mode), and Riverpod only notifies when the new
/// state `!=` the old one -- so the whole screen rebuilds when one of *these*
/// fields changes, not on every tick of a checkbox.
@immutable
class ListDetailScreenState {
  const ListDetailScreenState({
    required this.list,
    required this.isOwner,
    this.activeShopColor,
    this.mode = ItemsMode.browse,
    this.isLoading = false,
    this.loadFailure,
  });

  /// The list; null until it has loaded.
  final ShoppingList? list;

  /// Decides delete-for-everyone versus leave in the menu. False until the
  /// signed-in identity resolves -- the safe default (see `isListOwner`).
  final bool isOwner;

  /// The active shop tab's colour, seeding the items area's theme. Null for
  /// "All" -- the neutral brand seed.
  final HexColor? activeShopColor;

  /// The items area's mode: the drawer and the filter strip hide while
  /// selecting or rearranging.
  final ItemsMode mode;

  final bool isLoading;

  /// The list failed to load at all: the screen tier, replacing the page.
  final Failure? loadFailure;

  /// Switching lists mid-select or mid-rearrange would abandon that work.
  bool get canOpenDrawer =>
      list != null && mode != ItemsMode.select && mode != ItemsMode.rearrange;

  /// Search results already span every shop, and rearrange has its own
  /// header: a filter strip has nothing to do in either.
  bool get showShopFilter =>
      mode == ItemsMode.browse || mode == ItemsMode.select;

  @override
  bool operator ==(Object other) =>
      other is ListDetailScreenState &&
      other.list == list &&
      other.isOwner == isOwner &&
      other.activeShopColor == activeShopColor &&
      other.mode == mode &&
      other.isLoading == isLoading &&
      other.loadFailure == loadFailure;

  @override
  int get hashCode => Object.hash(
    list,
    isOwner,
    activeShopColor,
    mode,
    isLoading,
    loadFailure,
  );
}
