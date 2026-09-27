import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_mute_controller.g.dart';

/// Whether the signed-in user has muted [listId] -- the Notifications
/// screen's "Per list" row (decisions #80).
@riverpod
class ListMuteController extends _$ListMuteController {
  @override
  Future<bool> build(ListId listId) async {
    final result = await ref
        .watch(pushRepositoryProvider)
        .isListMuted(
          listId,
        );
    return switch (result) {
      Ok<bool>(:final value) => value,
      // Fails open: a read that couldn't confirm the mute state should not
      // silently claim a list is muted when it might not be -- unmuted is
      // the safe default (the server would still deliver either way; this
      // only affects what the row shows).
      Err<bool>() => false,
    };
  }

  /// Sets the mute state and persists it.
  Future<Failure?> setMuted(bool value) async {
    final result = await ref
        .read(pushRepositoryProvider)
        .setListMuted(listId, muted: value);
    switch (result) {
      case Ok<void>():
        if (ref.mounted) state = AsyncData(value);
        return null;
      case Err<void>(:final failure):
        return failure;
    }
  }
}
