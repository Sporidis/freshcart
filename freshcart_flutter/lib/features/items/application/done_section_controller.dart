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

/// Items checked so recently that they are still holding their place.
///
/// The design's rule: a checked row drops below the Done divider *600 ms*
/// after being ticked, not immediately, because reordering instantly makes
/// people feel they mis-tapped. Unchecking is unambiguous, so it reverses with
/// no delay at all.
///
/// Held here rather than in the widget so the timer survives a rebuild — a
/// list that repaints mid-delay must not drop the row early.
@riverpod
class RecentlyChecked extends _$RecentlyChecked {
  static const Duration holdDuration = Duration(milliseconds: 600);

  final Map<ItemId, Timer> _timers = {};

  @override
  Set<ItemId> build(ListId listId) {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  /// Holds [id] in place for [holdDuration], then lets it fall below.
  void hold(ItemId id) {
    _timers[id]?.cancel();
    state = {...state, id};
    _timers[id] = Timer(holdDuration, () {
      _timers.remove(id);
      if (!ref.mounted) return;
      state = {...state}..remove(id);
    });
  }

  /// Releases [id] immediately — used when a row is unchecked.
  void release(ItemId id) {
    _timers.remove(id)?.cancel();
    if (!state.contains(id)) return;
    state = {...state}..remove(id);
  }
}
