/// What happens to a shop's items when the shop is deleted.
///
/// There's no default: the caller must always choose. That way items are
/// never deleted without the user deciding it.
enum ShopItemDisposition {
  /// Keep the items, without a shop.
  untag,

  /// Move the items to another shop on the list.
  moveToShop,

  /// Delete the items too.
  deleteItems,
}
