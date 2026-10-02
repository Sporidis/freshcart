import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_shops_screen_controller.g.dart';

/// The controller for `ManageShopsScreen`: one list's shops, plus editing
/// and deleting them.
///
/// Combines [ShopsController] with the colour preview, and makes sure the
/// preview is cleared when the edit sheet closes (see [endEdit]). The
/// sheets themselves are opened by the widget.
@riverpod
class ManageShopsScreenController extends _$ManageShopsScreenController {
  @override
  ManageShopsScreenState build(ListId listId) {
    final outcome = ref.watch(shopsControllerProvider(listId));
    final shops = outcome.dataOrNull;
    return ManageShopsScreenState(
      shops: shops,
      isLoading: outcome.isLoading && shops == null,
      loadFailure: outcome.loadFailure,
    );
  }

  /// Read again every time, instead of stored in a field. A stored notifier
  /// could be disposed while we still hold it.
  ShopsController get _shops =>
      ref.read(shopsControllerProvider(listId).notifier);

  /// Loads the shops again. Used by the Retry button.
  void retry() => ref.invalidate(shopsControllerProvider(listId));

  /// Saves a new name and/or colour for [shop].
  Future<Failure?> edit(Shop shop, {String? name, HexColor? color}) async =>
      (await _shops.edit(shop, name: name, color: color)).failureOrNull;

  /// Call when the edit sheet closes, saved or not. Clears the colour
  /// preview, so the app shows the real saved colour again.
  void endEdit() =>
      ref.read(shopColorPreviewControllerProvider.notifier).clear();

  /// How many items [shop] has. Checked before deleting: an empty shop can
  /// just be deleted, a shop with items needs the user to decide.
  Future<Result<int>> itemCountForDelete(Shop shop) =>
      _shops.itemCount(shop.id);

  /// Deletes [shop]. [disposition] says what happens to its items.
  Future<Failure?> remove(
    Shop shop, {
    required ShopItemDisposition disposition,
    ShopId? moveTo,
  }) async => (await _shops.remove(
    shop.id,
    disposition: disposition,
    moveTo: moveTo,
  )).failureOrNull;
}
