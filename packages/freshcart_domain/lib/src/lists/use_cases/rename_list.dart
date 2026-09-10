import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

/// Renames a shopping list.
///
/// The counterpart to [CreateList], and deliberately sharing its rules through
/// [ShoppingList.validateName]: renaming used to reach the repository
/// unvalidated, so a list could be renamed to a blank string that could never
/// have been created.
///
/// Says nothing about *who* may rename — the server owns that check
/// (`ListService.requireMembership`), and duplicating it here would be a
/// second source of truth. [ShoppingList.isOwnedBy] exists for the UI to grey
/// the action out, not to enforce it.
class RenameList {
  /// Creates the use case against a [ListRepository].
  const RenameList(this._lists);

  final ListRepository _lists;

  /// Validates [name] and renames the list [id] identifies.
  Future<Result<ShoppingList>> call(ListId id, String name) async =>
      switch (ShoppingList.validateName(name)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _lists.rename(id, value),
      };
}
