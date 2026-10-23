import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_mute_controller.g.dart';

/// Whether the user muted notifications for list [listId]. For the "Per
/// list" rows on the Notifications screen (decisions.md #80).
@riverpod
class ListMuteController extends _$ListMuteController {
  @override
  Future<bool> build(ListId listId) async {
    final result = await ref
        .watch(notificationRepositoryProvider)
        .isListMuted(
          listId,
        );
    return switch (result) {
      Ok<bool>(:final value) => value,
      // If loading fails, show "not muted". Better than wrongly showing
      // "muted". (This only changes what the row shows, not what the
      // server sends.)
      Err<bool>() => false,
    };
  }

  /// Mutes or unmutes the list, and saves it on the server.
  Future<Failure?> setMuted(bool value) async {
    final result = await ref
        .read(notificationRepositoryProvider)
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
