import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';

/// Joins a shared list from a code the user typed or pasted.
///
/// The parse step lives here rather than in the UI so an invalid code costs no
/// round trip, and so every entry point — the join screen, a deep link, a
/// pasted invite — validates identically.
class JoinList {
  /// Creates the use case against a [ListRepository].
  const JoinList(this._lists);

  final ListRepository _lists;

  /// Validates [rawCode] and joins the list it identifies.
  ///
  /// Returns `Failure.validation` if the code is malformed, `Failure.notFound`
  /// if no list matches it.
  Future<Result<ShoppingList>> call(String rawCode) async {
    final parsed = JoinCode.parse(rawCode);
    return switch (parsed) {
      Err<JoinCode>(:final failure) => Err<ShoppingList>(failure),
      Ok<JoinCode>(:final value) => await _lists.joinByCode(value),
    };
  }
}
