import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/list_settings_screen/list_settings_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_settings_screen_controller.g.dart';

@riverpod
class ListSettingsScreenController extends _$ListSettingsScreenController {
  @override
  ListSettingsScreenState build(ListId listId) {
    final listOutcome = ref.watch(listByIdProvider(listId));
    final list = listOutcome.dataOrNull;
    final allLists =
        ref.watch(listsControllerProvider).dataOrNull ?? const <ShoppingList>[];
    final shops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];

    final isOwner = list != null && ref.watch(isListOwnerProvider(list));

    return ListSettingsScreenState(
      list: list,
      allLists: allLists,
      shops: shops,
      isOwner: isOwner,
      isLoading: listOutcome.isLoading && list == null,
      loadFailure: listOutcome.loadFailure,
    );
  }

  /// Read again every time, instead of stored in a field. A stored notifier
  /// could be disposed while we still hold it.
  ListsController get _lists => ref.read(listsControllerProvider.notifier);

  ShopsController get _shops =>
      ref.read(shopsControllerProvider(listId).notifier);

  /// Renames this list. The "saving" flag and error are kept in the screen
  /// (see [ListSettingsScreenState] for why).
  Future<Failure?> rename(String name) async =>
      (await _lists.rename(listId, name)).failureOrNull;

  /// Shows or hides [shop]'s tab on this list.
  Future<Failure?> toggleShopActive(Shop shop) async =>
      (await _shops.toggleActive(shop)).failureOrNull;

  /// Turns "Clear checked after shopping" on or off (decisions.md #79).
  Future<Failure?> setClearCheckedAfterShopping(bool clear) async =>
      (await _lists.setClearCheckedAfterShopping(listId, clear)).failureOrNull;

  /// Reloads the user's lists. Called before leaving an error screen, so
  /// `/lists` doesn't send the user back to a list that's gone.
  Future<void> refreshLists() => _lists.refresh();

  /// Deletes this list for everyone. Only the owner can (the server checks).
  Future<Failure?> deleteList() async =>
      (await _lists.delete(listId)).failureOrNull;

  /// Leaves this list. It still exists for the others.
  Future<Failure?> leaveList() async =>
      (await _lists.leave(listId)).failureOrNull;

  /// How many items will be deleted with the list (shown in the delete
  /// dialog). 0 if the items haven't loaded.
  ///
  /// Read once when asked, not watched. Watching would rebuild this
  /// controller on every item change, just for a number shown once.
  int itemCountForDialog() =>
      ref.read(itemsControllerProvider(listId)).dataOrNull?.length ?? 0;
}
