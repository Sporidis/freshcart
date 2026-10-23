import 'package:freshcart_domain/freshcart_domain.dart';
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
  Future<Result<ShoppingList>> create(String name) async {
    final result = await CreateList(ref.read(listRepositoryProvider))(name);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Joins a list with a code, then reloads the lists if it worked.
  Future<Result<ShoppingList>> join(String rawCode) async {
    final result = await JoinList(ref.read(listRepositoryProvider))(rawCode);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Renames a list, then reloads the lists if it worked.
  ///
  /// Returns the [Result] like [create], so the error shows next to the
  /// name being edited.
  Future<Result<void>> rename(ListId id, String name) async {
    final result = await RenameList(ref.read(listRepositoryProvider))(id, name);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Sets whether list [id] removes checked items automatically once
  /// everything is checked (decisions.md #79).
  ///
  /// Calls the repository directly (no use case), because a true/false
  /// has nothing to validate.
  Future<Result<void>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  ) async {
    final result = await ref
        .read(listRepositoryProvider)
        .setClearCheckedAfterShopping(id, value);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Leaves a list, then reloads so it disappears from the user's lists.
  ///
  /// Leaving isn't deleting: the list still exists for the others. To
  /// delete it for everyone, the owner uses [delete].
  Future<Result<void>> leave(ListId id) async {
    final result = await ref.read(listRepositoryProvider).leave(id);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Deletes a list for everyone. Only the owner can (the server checks).
  Future<Result<void>> delete(ListId id) async {
    final result = await ref.read(listRepositoryProvider).delete(id);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Removes another member. Only the owner can do this.
  Future<Result<void>> removeMember(ListId id, UserId userId) async {
    final result = await ref
        .read(listRepositoryProvider)
        .removeMember(id, userId);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Makes another member the owner.
  Future<Result<void>> transferOwnership(
    ListId id,
    UserId userId,
  ) async {
    final result = await ref
        .read(listRepositoryProvider)
        .transferOwnership(id, userId);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Reloads the lists, but only if this provider still exists.
  ///
  /// The screen can close while a save is still running. Then this provider
  /// is already disposed, and there's nothing to reload. That's fine.
  void _refreshIfAlive() {
    if (ref.mounted) ref.invalidateSelf();
  }

  /// Reloads the lists (pull-to-refresh, after leaving a list).
  Future<void> refresh() async => ref.invalidateSelf();
}
