import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

part 'shop.freezed.dart';

/// A shop that items can belong to, like "Colruyt" or "the bakery".
///
/// Shops belong to a list (not to a user), so everyone on the list sees the
/// same shops (decisions.md #19).
///
/// [color] is the shop's colour. When its tab is selected, the list area
/// takes on this colour.
@freezed
abstract class Shop with _$Shop {
  /// Creates a shop.
  const factory Shop({
    required ShopId id,
    required ListId listId,
    required String name,
    required HexColor color,
    // True by default, so shops that existed before this field still show
    // their tab.
    @Default(true) bool isActive,
  }) = _Shop;

  const Shop._();

  /// Shows or hides this shop's tab.
  ///
  /// Only the tab is hidden. The shop can still be picked in the item
  /// sheet, because "not going there this week" isn't the same as "this
  /// shop doesn't exist".
  Shop toggleActive() => copyWith(isActive: !isActive);

  /// Maximum shop name length. Shorter than a list name, because it has to
  /// fit in a tab.
  static const int maxNameLength = 40;

  /// Checks a shop name and returns it without spaces at the ends. On the
  /// entity, so creating and renaming use the same rule.
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
