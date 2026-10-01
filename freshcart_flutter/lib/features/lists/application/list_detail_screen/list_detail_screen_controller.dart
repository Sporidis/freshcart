import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_detail_screen_controller.g.dart';

/// The view model behind `ListDetailScreen` and its header menu: the live
/// list, whether you own it, the active shop colour and the items mode, plus
/// the list-level actions (rename, delete, leave).
///
/// The rows have their own view model, `ItemsSectionController`; this one
/// only reads its mode.
@riverpod
class ListDetailScreenController extends _$ListDetailScreenController {
  ListsController get _lists => ref.read(listsControllerProvider.notifier);

  @override
  ListDetailScreenState build(ListId listId) {
    final outcome = ref.watch(listByIdProvider(listId));
    final list = outcome.dataOrNull;

    return ListDetailScreenState(
      list: list,
      isOwner: list != null && ref.watch(isListOwnerProvider(list)),
      activeShopColor: ref.watch(activeShopColorProvider(listId)),
      mode: list == null
          ? ItemsMode.browse
          : ref.watch(itemsSectionControllerProvider(list)).mode,
      isLoading: outcome.isLoading && list == null,
      loadFailure: outcome.loadFailure,
    );
  }

  /// Renames this list -- the header's tap-to-edit title.
  Future<Failure?> rename(String name) async =>
      (await _lists.rename(listId, name)).failureOrNull;

  /// Deletes this list for everyone on it. Owner only, enforced server-side.
  Future<Failure?> deleteList() async =>
      (await _lists.delete(listId)).failureOrNull;

  /// Leaves this list; it carries on for everyone else.
  Future<Failure?> leaveList() async =>
      (await _lists.leave(listId)).failureOrNull;

  /// Forces a fresh fetch of the user's lists -- the error screen's exit
  /// needs it so `/lists` doesn't redirect straight back to a gone list.
  Future<void> refreshLists() => _lists.refresh();

  /// How many products the delete dialog says will go with the list. Read
  /// at the moment of asking, not watched: it is shown once, in a dialog.
  int itemCountForDialog() =>
      ref.read(itemsControllerProvider(listId)).dataOrNull?.length ?? 0;
}
