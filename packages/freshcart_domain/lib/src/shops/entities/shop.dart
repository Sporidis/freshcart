import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

part 'shop.freezed.dart';

/// A shop that items can be tagged to — "Colruyt", "Delhaize", "the bakery".
///
/// Scoped to a list rather than to a user: everyone collaborating on a list
/// must see the same shop set, or one member's tag would be meaningless to
/// another (`docs/decisions.md` #19).
///
/// [color] is the seed the app turns into a full Material colour scheme, so
/// selecting a shop re-themes the whole app.
@freezed
abstract class Shop with _$Shop {
  /// Creates a shop.
  const factory Shop({
    required ShopId id,
    required ListId listId,
    required String name,
    required HexColor color,
  }) = _Shop;

  const Shop._();
}
