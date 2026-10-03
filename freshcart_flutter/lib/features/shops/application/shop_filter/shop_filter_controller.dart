import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_filter_controller.g.dart';

/// Which shop the list is currently filtered to, or null for "all shops".
///
/// Controls two things: which items are shown, and the colour of the list
/// screen. Because both read this one value, they always match.
@riverpod
class ShopFilterController extends _$ShopFilterController {
  @override
  ShopId? build(ListId listId) => null;

  /// Filters to [shopId], or clears the filter when null.
  void select(ShopId? shopId) => state = shopId;
}
