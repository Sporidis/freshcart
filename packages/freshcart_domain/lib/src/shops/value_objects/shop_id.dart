/// The id of a shop.
///
/// An [extension type](https://dart.dev/language/extension-types): when the
/// app runs it's just a [String] (no extra cost), but the compiler won't let
/// you pass a ShopId where another kind of id is expected. So you can't mix
/// up a list id and an item id by accident.
///
/// The value is the server's UUID as a string. The domain doesn't use the
/// `uuid` package; converting is done by the mappers in `data/`.
extension type const ShopId._(String value) implements Object {
  /// Wraps [value], which must not be empty.
  ///
  /// Throws [ArgumentError] if it's empty. That would be a bug (the server
  /// never sends an empty id), so it throws instead of returning a `Result`.
  factory ShopId(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'ShopId must not be empty');
    }
    return ShopId._(value);
  }
}
