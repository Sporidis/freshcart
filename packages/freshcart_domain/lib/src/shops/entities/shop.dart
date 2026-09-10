import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
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

  /// The longest a shop name may be.
  ///
  /// Shorter than a list's: a shop name has to fit inside a tab pill in a
  /// horizontally scrolling strip, so a long one is unreadable by design
  /// rather than merely inconvenient.
  static const int maxNameLength = 40;

  /// Validates a proposed shop name, returning it trimmed.
  ///
  /// On the entity for the same reason [ShoppingItem.validateName] is:
  /// creating a shop and renaming one are two doors into the same field.
  static Result<String> validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(Failure.validation('name', 'Give the shop a name'));
    }
    if (trimmed.length > maxNameLength) {
      return const Err(
        Failure.validation('name', 'That name is too long for a tab'),
      );
    }
    return Ok(trimmed);
  }
}
