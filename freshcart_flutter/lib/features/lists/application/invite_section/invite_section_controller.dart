import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invite_section_controller.g.dart';

/// The controller for the invite section of a list: the code to share, once
/// a member asks for one.
///
/// Null until the member taps "Invite". The code is not loaded when the
/// section appears, so opening a screen never issues a code nobody shares.
///
/// Calls the repository directly (no use case): whether to reuse or replace
/// the code is decided on the server, with the domain's rule.
@riverpod
class InviteSectionController extends _$InviteSectionController {
  @override
  AsyncOutcome<ListInvite>? build(ListId listId) => null;

  /// Asks the server for an invite to share, and shows it.
  ///
  /// While loading, the state is [AsyncLoading]. A failure (offline, not a
  /// member anymore) is kept as `AsyncData(Err(...))` for the section to
  /// show, and the member can tap again.
  Future<void> open() async {
    state = const AsyncLoading();
    final result = await ref.read(listRepositoryProvider).openInvite(listId);
    if (!ref.mounted) return;
    state = AsyncData(result);
  }
}
