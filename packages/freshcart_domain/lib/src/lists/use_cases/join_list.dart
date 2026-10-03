import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';

/// Joins a list with a code the user typed or pasted.
///
/// The code is checked here (not in the UI), so a wrong code doesn't need
/// a server call, and every screen checks it the same way.
class JoinList {
  /// Creates the use case against a [ListRepository].
  const JoinList(this._lists);

  final ListRepository _lists;

  /// Checks [rawCode] and joins its list.
  ///
  /// Returns `Failure.validation` if the code isn't valid, or
  /// `Failure.notFound` if no list has that code.
  Future<Result<ShoppingList>> call(String rawCode) async {
    final parsed = JoinCode.parse(rawCode);
    return switch (parsed) {
      Err<JoinCode>(:final failure) => Err<ShoppingList>(failure),
      Ok<JoinCode>(:final value) => await _lists.joinByCode(value),
    };
  }
}
