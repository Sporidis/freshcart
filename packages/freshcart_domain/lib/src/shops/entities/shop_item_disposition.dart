/// What happens to the items tagged to a shop when that shop is deleted.
///
/// Modelled explicitly, and with no default at the call sites that matter,
/// because the rule the design insists on is that products are never destroyed
/// silently. Making the caller name the outcome is what turns "delete this
/// shop" from a question with a hidden answer into one with a stated one.
enum ShopItemDisposition {
  /// Leave the items on the list, untagged.
  untag,

  /// Move the items to another shop on the same list first.
  moveToShop,

  /// Delete the items along with the shop.
  deleteItems,
}
