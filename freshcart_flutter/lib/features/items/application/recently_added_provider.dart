import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recently_added_provider.g.dart';

/// The item [ItemsController.add] most recently landed, for as long as its
/// row's entrance flash should still be playing.
///
/// Mirrors [RecentlyChecked]'s shape (`done_section_controller.dart`) for
/// the same reason: a timer needs to survive a rebuild. Unlike that hold,
/// this only needs to answer one question once -- `ItemTile`'s own
/// `initState` reads it at the moment a new row's tile first mounts and
/// decides then and there whether to play its one-shot entrance animation,
/// so the flag being accurate for the rest of the 900 ms is not load-bearing
/// the way [RecentlyChecked] staying accurate for its whole 600 ms is. It
/// still auto-clears on the same timer, so an unrelated remount later (the
/// row leaving and re-entering the tree on a shop-tab switch, say) does not
/// find a stale flag still set and flash again for no reason.
@riverpod
class RecentlyAdded extends _$RecentlyAdded {
  static const Duration flashDuration = Duration(milliseconds: 900);

  Timer? _timer;

  @override
  ItemId? build(ListId listId) {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Flags [id] as just added, for [flashDuration].
  void flash(ItemId id) {
    _timer?.cancel();
    state = id;
    _timer = Timer(flashDuration, () {
      if (ref.mounted && state == id) state = null;
    });
  }
}
