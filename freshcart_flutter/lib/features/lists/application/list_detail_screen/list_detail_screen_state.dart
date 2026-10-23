import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:meta/meta.dart';

/// The data for `ListDetailScreen` itself: the list and its colours. The
/// item rows use `ItemsSectionState` instead.
///
/// Plain Dart (no Flutter types, so [HexColor] instead of `Color`).
///
/// The `==` override matters: this controller re-runs on every item
/// change. Riverpod only rebuilds widgets when the new state is not `==`
/// the old one. So checking an item doesn't rebuild the whole screen,
/// only a change to these fields does.
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

  /// Whether the title can be renamed (owner only). False until we know
  /// who the user is, to be safe (see `isListOwner`).
  final bool isOwner;

  /// The selected shop tab's colour, used to colour the items area. Null
  /// for "All" (neutral colours).
  final HexColor? activeShopColor;

  /// What the items area is doing (normal, selecting, searching,
  /// rearranging). Decides what the screen hides.
  final ItemsMode mode;

  final bool isLoading;

  /// Set when the list couldn't load. Then a full error screen is shown.
  final Failure? loadFailure;

  /// Whether the drawer can open. Not while selecting or rearranging,
  /// because switching lists would lose that work.
  bool get canOpenDrawer =>
      list != null && mode != ItemsMode.select && mode != ItemsMode.rearrange;

  /// Whether to show the shop tabs. Hidden while searching (search covers
  /// all shops) and rearranging (it has its own header).
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
