import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shops_controller.g.dart';

/// The shops belonging to one list.
@riverpod
class ShopsController extends _$ShopsController {
  @override
  Future<Result<List<Shop>>> build(ListId listId) =>
      ref.watch(shopRepositoryProvider).byList(listId);

  /// Creates a shop, then reloads the shops if it worked.
  Future<Result<Shop>> create({
    required String name,
    required HexColor color,
  }) => _thenRefresh(
    CreateShop(_shops)(listId: listId, name: name, color: color),
  );

  /// Changes a shop's name and/or colour, then reloads the shops if it
  /// worked. The reload is what makes a new colour show everywhere.
  Future<Result<Shop>> edit(Shop shop, {String? name, HexColor? color}) =>
      _thenRefresh(EditShop(_shops)(shop, name: name, color: color));

  /// Shows or hides [shop]'s tab, then reloads the shops if it worked.
  ///
  /// If the hidden shop is the selected tab, the filter goes back to "All".
  /// Otherwise the user would be stuck on a tab that no longer exists.
  Future<Result<Shop>> toggleActive(Shop shop) async {
    final result = await _thenRefresh(ToggleShopActive(_shops)(shop));
    if (result.valueOrNull?.isActive == false &&
        ref.read(shopFilterControllerProvider(shop.listId)) == shop.id) {
      ref.read(shopFilterControllerProvider(shop.listId).notifier).select(null);
    }
    return result;
  }

  /// How many items have shop [id]. Shown in the delete sheet.
  Future<Result<int>> itemCount(ShopId id) => _shops.itemCount(id);

  /// Deletes a shop. [disposition] says what happens to its items.
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    ShopId? moveTo,
  }) => _thenRefresh(
    _shops.remove(id, disposition: disposition, moveTo: moveTo),
  );

  ShopRepository get _shops => ref.read(shopRepositoryProvider);

  /// Waits for [write], and reloads the shops if it worked.
  ///
  /// Only if this provider still exists: the screen can close while a save
  /// is still running, and then there's nothing to reload. That's fine.
  Future<Result<T>> _thenRefresh<T>(Future<Result<T>> write) async {
    final result = await write;
    if (result.isOk && ref.mounted) ref.invalidateSelf();
    return result;
  }
}
