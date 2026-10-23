import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts our domain enum into Serverpod's enum.
///
/// The two enums have the same values on purpose. Serverpod types must
/// never be used in the domain (golden rule 2), so we keep our own copy.
/// If either enum gets a new value, this `switch` won't compile until it's
/// handled.
extension ShopItemDispositionX on ShopItemDisposition {
  /// The matching Serverpod value.
  dto.ShopItemDisposition toDto() => switch (this) {
    ShopItemDisposition.untag => dto.ShopItemDisposition.untag,
    ShopItemDisposition.moveToShop => dto.ShopItemDisposition.moveToShop,
    ShopItemDisposition.deleteItems => dto.ShopItemDisposition.deleteItems,
  };
}
