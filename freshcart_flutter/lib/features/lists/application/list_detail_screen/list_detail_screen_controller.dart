import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_detail_screen_controller.g.dart';

/// The controller for `ListDetailScreen`: the list, whether you own it,
/// the selected shop's colour, the items mode, and renaming. Deleting and
/// leaving live in List settings, which the header's avatars open.
///
/// The item rows have their own controller, `ItemsSectionController`. This
/// one only reads its mode.
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

  /// Renames this list (from tapping the title).
  Future<Failure?> rename(String name) async =>
      (await _lists.rename(listId, name)).failureOrNull;

  /// Reloads the user's lists. Called before leaving an error screen, so
  /// `/lists` doesn't send the user back to a list that's gone.
  Future<void> refreshLists() => _lists.refresh();
}
