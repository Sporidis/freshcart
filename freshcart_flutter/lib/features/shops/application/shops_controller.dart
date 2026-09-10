import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/shops/application/shop_use_case_providers.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shops_controller.g.dart';

/// The shops belonging to one list.
@riverpod
class ShopsController extends _$ShopsController {
  @override
  Future<Result<List<Shop>>> build(ListId listId) =>
      ref.watch(shopRepositoryProvider).byList(listId);

  /// Creates a shop and refreshes the collection on success.
  Future<Result<Shop>> create({
    required String name,
    required HexColor color,
  }) async {
    final result = await ref.read(createShopUseCaseProvider)(
      listId: listId,
      name: name,
      color: color,
    );
    if (result.isOk) ref.invalidateSelf();
    return result;
  }

  /// Renames and/or recolours a shop, refreshing the collection on success.
  ///
  /// Recolouring re-seeds the app theme when this shop is the active one, so
  /// the refresh is what makes the new colour take hold everywhere.
  Future<Result<Shop>> edit(Shop shop, {String? name, HexColor? color}) async {
    final result = await ref.read(editShopUseCaseProvider)(
      shop,
      name: name,
      color: color,
    );
    if (result.isOk) ref.invalidateSelf();
    return result;
  }

  /// How many items are tagged to [id], for the delete sheet to lead with.
  Future<Result<int>> itemCount(ShopId id) =>
      ref.read(shopRepositoryProvider).itemCount(id);

  /// Deletes a shop, disposing of its items as [disposition] says.
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    ShopId? moveTo,
  }) async {
    final result = await ref
        .read(shopRepositoryProvider)
        .remove(id, disposition: disposition, moveTo: moveTo);
    if (result.isOk) ref.invalidateSelf();
    return result;
  }
}

/// Which shop the list is currently filtered to, or null for "all shops".
///
/// Drives two things at once: which items are visible, and what colour the app
/// is themed from. Keeping it as one piece of state is what makes those two
/// stay in step.
@riverpod
class ShopFilter extends _$ShopFilter {
  @override
  ShopId? build(ListId listId) => null;

  /// Filters to [shopId], or clears the filter when null.
  void select(ShopId? shopId) => state = shopId;
}

/// The colour of the active shop, or null when no shop is selected.
///
/// Derived rather than stored, so it cannot drift out of step with the filter.
@riverpod
HexColor? activeShopColor(Ref ref, ListId listId) {
  final filter = ref.watch(shopFilterProvider(listId));
  if (filter == null) return null;

  final shops = ref.watch(shopsControllerProvider(listId));
  final loaded = switch (shops) {
    AsyncValue<Result<List<Shop>>>(value: Ok<List<Shop>>(:final value)) =>
      value,
    _ => const <Shop>[],
  };
  for (final shop in loaded) {
    if (shop.id == filter) return shop.color;
  }
  return null;
}
