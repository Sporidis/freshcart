import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/ports/list_repository.dart';

/// Creates a shopping list owned by the signed-in user.
class CreateList {
  /// Creates the use case against a [ListRepository].
  const CreateList(this._lists);

  final ListRepository _lists;

  /// The longest a list name may be.
  static const int maxNameLength = 60;

  /// Validates [name] and creates the list.
  ///
  /// The name rules live here rather than in the create dialog so every entry
  /// point — a dialog, a deep link, a future import — enforces them equally.
  Future<Result<ShoppingList>> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(Failure.validation('name', 'Give the list a name'));
    }
    if (trimmed.length > maxNameLength) {
      return const Err(Failure.validation('name', 'That name is too long'));
    }
    return _lists.create(name: trimmed);
  }
}
