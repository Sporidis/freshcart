import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_screen_controller.g.dart';

/// The view model behind `HouseholdScreen`: who is on the list, who you are,
/// and the owner's two member actions.
@riverpod
class HouseholdScreenController extends _$HouseholdScreenController {
  ListsController get _lists => ref.read(listsControllerProvider.notifier);

  @override
  HouseholdScreenState build(ListId listId) {
    final outcome = ref.watch(listByIdProvider(listId));
    final list = outcome.dataOrNull;

    return HouseholdScreenState(
      list: list,
      me: ref.watch(signedInUserIdProvider),
      isOwner: list != null && ref.watch(isListOwnerProvider(list)),
      loadFailure: outcome.loadFailure,
    );
  }

  /// Removes [member] from the list, on the owner's authority.
  Future<Failure?> removeMember(ListMember member) async =>
      (await _lists.removeMember(listId, member.userId)).failureOrNull;

  /// Hands ownership to [member] -- and takes it away from you.
  Future<Failure?> transferOwnership(ListMember member) async =>
      (await _lists.transferOwnership(listId, member.userId)).failureOrNull;

  /// See `ListDetailScreenController.refreshLists`.
  Future<void> refreshLists() => _lists.refresh();
}
