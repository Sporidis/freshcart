import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/controllers/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/controllers/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/application/providers/list_membership_provider.dart';
import 'package:freshcart_flutter/features/lists/application/screen/list_settings_screen_state.dart';
import 'package:freshcart_flutter/features/shops/application/controllers/shops_controller.dart';
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

  /// The teller, not the balance: fetched fresh on every use, since
  /// holding on to a notifier instance could outlive it.
  ListsController get _lists => ref.read(listsControllerProvider.notifier);

  ShopsController get _shops =>
      ref.read(shopsControllerProvider(listId).notifier);

  /// Renames this list. The screen keeps the saving flag and the error
  /// beside its text field -- see [ListSettingsScreenState] for why.
  Future<Failure?> rename(String name) async =>
      (await _lists.rename(listId, name)).failureOrNull;

  /// Turns [shop] on or off for this list (an inactive shop has no tab).
  Future<Failure?> toggleShopActive(Shop shop) async =>
      (await _shops.toggleActive(shop)).failureOrNull;

  /// "Clear checked after shopping" (decisions #79).
  Future<Failure?> setClearCheckedAfterShopping(bool clear) async =>
      (await _lists.setClearCheckedAfterShopping(listId, clear)).failureOrNull;

  /// Forces a fresh fetch of the user's lists -- the error screen's exit
  /// needs it so `/lists` doesn't redirect straight back to a gone list.
  Future<void> refreshLists() => _lists.refresh();

  /// Deletes this list for everyone on it. Owner only, enforced server-side.
  Future<Failure?> deleteList() async =>
      (await _lists.delete(listId)).failureOrNull;

  /// Leaves this list; it carries on for everyone else.
  Future<Failure?> leaveList() async =>
      (await _lists.leave(listId)).failureOrNull;

  /// How many products the delete dialog says will go with the list.
  ///
  /// Read at the moment of asking rather than kept in the watched state: the
  /// number is shown once, in a dialog, so watching it would rebuild this
  /// view model on every item change for nobody. Falls back to 0 if the
  /// items haven't loaded -- the same as before this moved here.
  int itemCountForDialog() =>
      ref.read(itemsControllerProvider(listId)).dataOrNull?.length ?? 0;
}
