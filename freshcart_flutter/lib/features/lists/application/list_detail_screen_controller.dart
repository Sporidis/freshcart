import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_detail_screen_controller.g.dart';

@riverpod
class ListDetailScreenController extends _$ListDetailScreenController {
  @override
  ListDetailScreenState build(ListId listId) {
    final listOutcome = ref.watch(listByIdProvider(listId));
    final list = listOutcome.dataOrNull;
    final isOwner = list != null && ref.watch(isListOwnerProvider(list));

    return ListDetailScreenState(list: list, isOwner: isOwner);
  }

  ListsController get _lists => ref.read(listsControllerProvider.notifier);

  Future<Failure?> deleteList(ListId listId) async =>
      (await _lists.delete(listId)).failureOrNull;

  Future<Failure?> leaveList(ListId listId) async =>
      (await _lists.leave(listId)).failureOrNull;

  int itemCountForDialog() =>
      ref.read(itemsControllerProvider(listId)).dataOrNull?.length ?? 0;
}
