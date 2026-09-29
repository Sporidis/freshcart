import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lists_controller.g.dart';

/// Every list the signed-in user belongs to.
@riverpod
class ListsController extends _$ListsController {
  @override
  Future<Result<List<ShoppingList>>> build() =>
      ref.watch(listRepositoryProvider).myLists();

  /// Creates a list and refreshes the collection on success.
  ///
  /// Returns the [Result] rather than folding it into state so the calling
  /// dialog can show a validation message against its own text field instead of
  /// replacing the whole screen with an error.
  Future<Result<ShoppingList>> create(String name) async {
    final result = await CreateList(ref.read(listRepositoryProvider))(name);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Joins a list by code and refreshes the collection on success.
  Future<Result<ShoppingList>> join(String rawCode) async {
    final result = await JoinList(ref.read(listRepositoryProvider))(rawCode);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Renames a list and refreshes the collection on success.
  ///
  /// Like [create], the [Result] comes back rather than becoming state: the
  /// title is being edited in place, so a rejected name belongs beside that
  /// field, not on top of the screen.
  Future<Result<ShoppingList>> rename(ListId id, String name) async {
    final result = await RenameList(ref.read(listRepositoryProvider))(id, name);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Sets whether [id] clears its checked items automatically once
  /// everything on it is checked (decisions #79).
  ///
  /// A direct repository call, not a use case: there is nothing to validate
  /// on a plain bool, the same "trivial forward" reasoning
  /// `EditProfileScreen`'s own `setAvatarColor` already follows.
  Future<Result<ShoppingList>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  ) async {
    final result = await ref
        .read(listRepositoryProvider)
        .setClearCheckedAfterShopping(id, value);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Leaves a list, and refreshes so it drops out of the collection.
  ///
  /// Leaving is not deleting: the list carries on for everyone else. Only the
  /// owner can delete it for the household, and that operation does not exist
  /// on the server yet.
  Future<Result<void>> leave(ListId id) async {
    final result = await ref.read(listRepositoryProvider).leave(id);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Deletes a list for everyone on it. Owner only, enforced server-side.
  Future<Result<void>> delete(ListId id) async {
    final result = await ref.read(listRepositoryProvider).delete(id);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Removes another member, on the owner's authority.
  Future<Result<void>> removeMember(ListId id, UserId userId) async {
    final result = await ref
        .read(listRepositoryProvider)
        .removeMember(id, userId);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Hands ownership to another member.
  Future<Result<ShoppingList>> transferOwnership(
    ListId id,
    UserId userId,
  ) async {
    final result = await ref
        .read(listRepositoryProvider)
        .transferOwnership(id, userId);
    if (result.isOk) _refreshIfAlive();
    return result;
  }

  /// Re-reads this controller's own collection, if it is still alive.
  ///
  /// A write can outlive the screen that started it: the household screen
  /// removes a member and routes away, and nothing there watches this
  /// provider, so it auto-disposes while the request is still in flight.
  /// Refreshing a cache that no longer exists is not an error — there is
  /// simply nothing left to refresh.
  void _refreshIfAlive() {
    if (ref.mounted) ref.invalidateSelf();
  }

  /// Re-reads the lists, for pull-to-refresh and after leaving a list.
  Future<void> refresh() async => ref.invalidateSelf();
}

/// Live view of one list, for the detail screen and the router's membership
/// guard.
///
/// Backed by [ListRepository.watch] rather than a one-shot [ListRepository.byId]
/// call, so a rename or a collaborator joining while this screen is open
/// updates without a manual refresh (closes the gap `docs/decisions.md` #36
/// named). No optimistic overlay is needed here the way [ItemsController] needs
/// one: this screen has no local mutations of its own yet — rename and leave
/// exist on the port but nothing in the UI calls them. Add the same overlay
/// pattern if that changes.
@riverpod
Stream<Result<ShoppingList>> listById(Ref ref, ListId listId) =>
    ref.watch(listRepositoryProvider).watch(listId);
