import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/shops/application/manage_shops_screen/manage_shops_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_shops_screen_controller.g.dart';

/// The view model behind `ManageShopsScreen`: one list's shops, and the
/// edit and delete flows around them.
///
/// Earns its place by combining [ShopsController] with the colour preview,
/// and by owning the rule that a preview never outlives the edit sheet --
/// see [endEdit]. The sheets themselves stay in the widget, which asks this
/// for each step.
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

  /// Fetched fresh on every use, since holding on to a notifier instance
  /// could outlive it.
  ShopsController get _shops =>
      ref.read(shopsControllerProvider(listId).notifier);

  /// Saves a rename and/or recolour of [shop].
  Future<Failure?> edit(Shop shop, {String? name, HexColor? color}) async =>
      (await _shops.edit(shop, name: name, color: color)).failureOrNull;

  /// Ends an edit, saved or dismissed alike: an abandoned colour left
  /// tinting the app would be a lie about what is stored.
  void endEdit() =>
      ref.read(shopColorPreviewControllerProvider.notifier).clear();

  /// How many items [shop] holds -- fetched before asking, because it is the
  /// question: an empty shop needs no decision, a full one needs a real one.
  Future<Result<int>> itemCountForDelete(Shop shop) =>
      _shops.itemCount(shop.id);

  /// Deletes [shop], doing with its items what [disposition] says.
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
