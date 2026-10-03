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
  }) async {
    final result = await CreateShop(ref.read(shopRepositoryProvider))(
      listId: listId,
      name: name,
      color: color,
    );
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Changes a shop's name and/or colour, then reloads the shops if it
  /// worked. The reload is what makes a new colour show everywhere.
  Future<Result<Shop>> edit(Shop shop, {String? name, HexColor? color}) async {
    final result = await EditShop(ref.read(shopRepositoryProvider))(
      shop,
      name: name,
      color: color,
    );
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Shows or hides [shop]'s tab, then reloads the shops if it worked.
  ///
  /// If the hidden shop is the selected tab, the filter goes back to "All".
  /// Otherwise the user would be stuck on a tab that no longer exists.
  Future<Result<Shop>> toggleActive(Shop shop) async {
    final result = await ToggleShopActive(ref.read(shopRepositoryProvider))(
      shop,
    );
    if (result.isOk) {
      _refreshIfAlive();
      if (result.valueOrNull?.isActive == false &&
          ref.read(shopFilterControllerProvider(shop.listId)) == shop.id) {
        ref
            .read(shopFilterControllerProvider(shop.listId).notifier)
            .select(null);
      }
    }
    return result;
  }

  /// How many items have shop [id]. Shown in the delete sheet.
  Future<Result<int>> itemCount(ShopId id) =>
      ref.read(shopRepositoryProvider).itemCount(id);

  /// Deletes a shop. [disposition] says what happens to its items.
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    ShopId? moveTo,
  }) async {
    final result = await ref
        .read(shopRepositoryProvider)
        .remove(id, disposition: disposition, moveTo: moveTo);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Reloads the shops, but only if this provider still exists.
  ///
  /// The screen can close while a save is still running. Then this provider
  /// is already disposed, and there's nothing to reload. That's fine.
  void _refreshIfAlive() {
    if (ref.mounted) ref.invalidateSelf();
  }
}
