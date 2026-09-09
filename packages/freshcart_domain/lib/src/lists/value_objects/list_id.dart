/// Identifies a shopping list.
///
/// An [extension type](https://dart.dev/language/extension-types): at runtime
/// this *is* the underlying [String], so wrapping costs nothing, but the
/// compiler still refuses to let a ListId stand in for any other id type. That
/// removes a whole class of "passed the wrong id" bugs for free.
///
/// The value is the string form of the server's UUID. The domain deliberately
/// does not depend on the `uuid` package — converting to and from
/// `UuidValue` is the mapper's job at the `data/` boundary.
extension type const ListId._(String value) implements Object {
  /// Wraps [value], which must be a non-empty id string.
  ///
  /// Throws [ArgumentError] on an empty value. That is a programmer error —
  /// the server never issues one — so it throws rather than returning a
  /// `Result`, per the convention in `CLAUDE.md`.
  factory ListId(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'ListId must not be empty');
    }
    return ListId._(value);
  }
}
