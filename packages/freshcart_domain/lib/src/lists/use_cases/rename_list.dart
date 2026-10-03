import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

/// Renames a shopping list.
///
/// Uses the same name rules as [CreateList] ([ShoppingList.validateName]).
///
/// Doesn't check WHO may rename; the server does that. Checking here too
/// would mean two places deciding the same thing. [ShoppingList.isOwnedBy]
/// is only for the UI, to hide the option.
class RenameList {
  /// Creates the use case against a [ListRepository].
  const RenameList(this._lists);

  final ListRepository _lists;

  /// Checks [name] and renames list [id].
  Future<Result<ShoppingList>> call(ListId id, String name) async =>
      switch (ShoppingList.validateName(name)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _lists.rename(id, value),
      };
}
