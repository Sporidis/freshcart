import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'done_section_controller.g.dart';

/// Whether the Done section is collapsed, per list.
///
/// Per list rather than globally: someone mid-shop on the big weekly list
/// wants the trolley contents visible, while a short list is easier read with
/// them folded away. Session-scoped for now — surviving a restart means a
/// stored preference, which is its own (small) piece of work.
@riverpod
class DoneSectionCollapsed extends _$DoneSectionCollapsed {
  @override
  bool build(ListId listId) => false;

  /// Folds the section away, or opens it again.
  void toggle() => state = !state;
}

/// Items checked so recently that they are still holding their place, and
/// items mid-flight between the open rows and the Done section.
///
/// The design's rule: a checked row drops below the Done divider *600 ms*
/// after being ticked, not immediately, because reordering instantly makes
/// people feel they mis-tapped -- that's [holding]. That 600 ms window is
/// one shared debounce for the whole list, not a per-row timer: checking
/// several items in a row resets it on every tap, so nothing moves until
/// 600 ms after the *last* check. Without that, the first item you ticked
/// would jump to Done mid-tap-through and shove the very rows you're about
/// to tap next. Once the debounce settles, every row still in [holding]
/// moves to Done as one batch, but not in the same frame -- each row starts
/// its own move a short beat after the previous one, so a multi-item check
/// reads as a quick cascade rather than the whole block jumping at once.
/// Moving is what puts a row into [transitioning] for one more short window,
/// which is what actually drives `ItemTile`'s cross-section move animation
/// (see `ItemTile.checkMoveEntering`/`checkMoveExiting`).
///
/// Unchecking (`release`) deliberately does *not* share this debounce: the
/// design spec treats unchecking as unambiguous, so each row starts its
/// animated return to the open rows immediately, independent of any other
/// row's state.
///
/// Held here rather than in the widget so the timers survive a rebuild -- a
/// list that repaints mid-delay must not drop the row early, and `ItemTile`
/// itself is torn down and rebuilt fresh in its new section the moment the
/// row's filter membership flips, so widget state could never carry this.
@riverpod
class RecentlyChecked extends _$RecentlyChecked {
  static const Duration holdDuration = Duration(milliseconds: 600);

  /// The one shared debounce for [holding]; reset by every [hold] call.
  Timer? _holdTimer;

  /// Per row, the timer counting down to that row's own move starting --
  /// only set while a row is waiting its turn in a settling batch's cascade.
  final Map<ItemId, Timer> _staggerTimers = {};

  /// One exit timer per row once it actually starts moving -- unlike the
  /// hold, each row's move (into Done as part of a settled batch, or back
  /// out on an uncheck) finishes on its own schedule.
  final Map<ItemId, Timer> _exitTimers = {};

  @override
  ({Set<ItemId> holding, Set<ItemId> transitioning}) build(ListId listId) {
    ref.onDispose(() {
      _holdTimer?.cancel();
      for (final timer in _staggerTimers.values) {
        timer.cancel();
      }
      _staggerTimers.clear();
      for (final timer in _exitTimers.values) {
        timer.cancel();
      }
      _exitTimers.clear();
    });
    return (holding: const {}, transitioning: const {});
  }

  /// Adds [id] to the held-in-place set and (re)starts the shared debounce.
  /// Once [holdDuration] passes with no further [hold] call, every row still
  /// held starts moving into Done, each staggered a beat after the last (a
  /// third of [exitDuration], so the cascade shortens along with the move
  /// itself under reduced motion), animated over [exitDuration] -- the
  /// caller's own `AppMotion.durationFor(context, AppMotion.standard)`, so
  /// reduced motion is already accounted for by the time it reaches here and
  /// this class never needs to know about `AppMotion` or `BuildContext`
  /// itself.
  void hold(ItemId id, {required Duration exitDuration}) {
    _staggerTimers.remove(id)?.cancel();
    _exitTimers.remove(id)?.cancel();
    state = (
      holding: {...state.holding, id},
      transitioning: {...state.transitioning}..remove(id),
    );
    _holdTimer?.cancel();
    _holdTimer = Timer(holdDuration, () {
      _holdTimer = null;
      if (!ref.mounted) return;
      final settling = state.holding.toList();
      final stagger = exitDuration ~/ 3;
      for (var i = 0; i < settling.length; i++) {
        final settledId = settling[i];
        _staggerTimers[settledId] = Timer(stagger * i, () {
          _staggerTimers.remove(settledId);
          if (!ref.mounted) return;
          state = (
            holding: {...state.holding}..remove(settledId),
            transitioning: {...state.transitioning, settledId},
          );
          _exitTimers[settledId] = Timer(exitDuration, () {
            _exitTimers.remove(settledId);
            if (!ref.mounted) return;
            state = (
              holding: state.holding,
              transitioning: {...state.transitioning}..remove(settledId),
            );
          });
        });
      }
    });
  }

  /// Starts [id]'s animated move back into the open rows immediately, for
  /// [exitDuration] (the caller's `AppMotion.durationFor(context,
  /// AppMotion.quick)`) -- no hold on the way out, matching the design's own
  /// "unchecking is unambiguous" rule, and independent of any other row's
  /// debounce.
  ///
  /// If [id] hasn't actually left the open rows yet -- still sitting in
  /// [holding], either mid-debounce or waiting its own turn in a settling
  /// batch's cascade -- there's nothing to animate back from; it's simply
  /// dropped from the pending batch.
  void release(ItemId id, {required Duration exitDuration}) {
    if (state.holding.contains(id)) {
      _staggerTimers.remove(id)?.cancel();
      state = (
        holding: {...state.holding}..remove(id),
        transitioning: state.transitioning,
      );
      return;
    }
    _exitTimers.remove(id)?.cancel();
    state = (
      holding: state.holding,
      transitioning: {...state.transitioning, id},
    );
    _exitTimers[id] = Timer(exitDuration, () {
      _exitTimers.remove(id);
      if (!ref.mounted) return;
      state = (
        holding: state.holding,
        transitioning: {...state.transitioning}..remove(id),
      );
    });
  }
}
