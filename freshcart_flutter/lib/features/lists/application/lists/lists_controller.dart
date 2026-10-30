import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lists_controller.g.dart';

/// All lists the signed-in user is on.
@riverpod
class ListsController extends _$ListsController {
  @override
  Future<Result<List<ShoppingList>>> build() =>
      ref.watch(listRepositoryProvider).myLists();

  /// Creates a list, then reloads the lists if it worked.
  ///
  /// Returns the [Result] (instead of putting an error in the state), so
  /// the dialog can show the error under its text field.
  Future<Result<ShoppingList>> create(String name) =>
      _thenRefresh(CreateList(_lists)(name));

  /// Joins a list with a code, then reloads the lists if it worked.
  Future<Result<ShoppingList>> join(String rawCode) =>
      _thenRefresh(JoinList(_lists)(rawCode));

  /// Renames a list, then reloads the lists if it worked.
  ///
  /// Returns the [Result] like [create], so the error shows next to the
  /// name being edited.
  Future<Result<void>> rename(ListId id, String name) =>
      _thenRefresh(RenameList(_lists)(id, name));

  /// Sets whether list [id] removes checked items automatically once
  /// everything is checked (decisions.md #79).
  ///
  /// Calls the repository directly (no use case), because a true/false
  /// has nothing to validate.
  Future<Result<void>> setClearCheckedAfterShopping(ListId id, bool value) =>
      _thenRefresh(_lists.setClearCheckedAfterShopping(id, value));

  /// Leaves a list, then reloads so it disappears from the user's lists.
  ///
  /// Leaving isn't deleting: the list still exists for the others. To
  /// delete it for everyone, the owner uses [delete].
  Future<Result<void>> leave(ListId id) => _thenRefresh(_lists.leave(id));

  /// Deletes a list for everyone. Only the owner can (the server checks).
  Future<Result<void>> delete(ListId id) => _thenRefresh(_lists.delete(id));

  /// Removes another member. Only the owner can do this.
  Future<Result<void>> removeMember(ListId id, UserId userId) =>
      _thenRefresh(_lists.removeMember(id, userId));

  /// Makes another member the owner.
  Future<Result<void>> transferOwnership(ListId id, UserId userId) =>
      _thenRefresh(_lists.transferOwnership(id, userId));

  ListRepository get _lists => ref.read(listRepositoryProvider);

  /// Waits for [write], and reloads the lists if it worked.
  ///
  /// Only if this provider still exists: the screen can close while a save
  /// is still running, and then there's nothing to reload. That's fine.
  Future<Result<T>> _thenRefresh<T>(Future<Result<T>> write) async {
    final result = await write;
    if (result.isOk && ref.mounted) ref.invalidateSelf();
    return result;
  }

  /// Reloads the lists (pull-to-refresh, after leaving a list, "Try
  /// again"). Signs in again first if that is what failed.
  Future<void> refresh() async {
    await retrySignInIfFailed(ref);
    if (ref.mounted) ref.invalidateSelf();
  }
}
