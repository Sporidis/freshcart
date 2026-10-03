import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';

/// Creates a shopping list owned by the signed-in user.
class CreateList {
  /// Creates the use case against a [ListRepository].
  const CreateList(this._lists);

  final ListRepository _lists;

  /// Checks [name] and creates the list.
  ///
  /// The name rules are on [ShoppingList], so creating and renaming use the
  /// same ones.
  Future<Result<ShoppingList>> call(String name) async =>
      switch (ShoppingList.validateName(name)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _lists.create(name: value),
      };
}
