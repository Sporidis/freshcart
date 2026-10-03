import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen/household_screen_state.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_screen_controller.g.dart';

/// The controller for `HouseholdScreen`: who's on the list, who you are,
/// and the two things the owner can do to members (remove, make owner).
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

  /// Removes [member] from the list. Only the owner can do this.
  Future<Failure?> removeMember(ListMember member) async =>
      (await _lists.removeMember(listId, member.userId)).failureOrNull;

  /// Makes [member] the owner. You stop being the owner.
  Future<Failure?> transferOwnership(ListMember member) async =>
      (await _lists.transferOwnership(listId, member.userId)).failureOrNull;

  /// Reloads the user's lists. Called before leaving an error screen, so
  /// `/lists` doesn't send the user back to a list that's gone.
  Future<void> refreshLists() => _lists.refresh();
}
