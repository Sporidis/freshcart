import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_filter_controller.g.dart';

/// Which shop the list is currently filtered to, or null for "all shops".
///
/// Drives two things at once: which items are visible, and what colour the app
/// is themed from. Keeping it as one piece of state is what makes those two
/// stay in step.
@riverpod
class ShopFilterController extends _$ShopFilterController {
  @override
  ShopId? build(ListId listId) => null;

  /// Filters to [shopId], or clears the filter when null.
  void select(ShopId? shopId) => state = shopId;
}
