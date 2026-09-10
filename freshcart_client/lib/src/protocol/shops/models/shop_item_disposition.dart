/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// What happens to the products tagged to a shop when that shop is deleted.
///
/// Explicit rather than implied, because the design's rule is that products
/// are never destroyed silently: the caller has to say which of these it
/// means, and there is no default.
enum ShopItemDisposition implements _i1.SerializableModel {
  /// Leave the products on the list, untagged. The schema's ON DELETE SET
  /// NULL already does this, so it is the cheapest of the three.
  untag,

  /// Move the products to another shop before deleting this one.
  moveToShop,

  /// Delete the products along with the shop.
  deleteItems;

  static ShopItemDisposition fromJson(String name) {
    switch (name) {
      case 'untag':
        return ShopItemDisposition.untag;
      case 'moveToShop':
        return ShopItemDisposition.moveToShop;
      case 'deleteItems':
        return ShopItemDisposition.deleteItems;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ShopItemDisposition"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
