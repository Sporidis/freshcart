import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section_ui/items_section_ui_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_completion_effects.g.dart';

/// Whether the list is done: it has items, and all are checked.
bool allChecked(List<ShoppingItem> items) =>
    items.isNotEmpty && items.every((i) => i.isChecked);

/// Reacts when [list] becomes done, or stops being done. Returns nothing,
/// it only does things (like `replayQueueWhenOnline`).
///
/// - No longer done: forget "Keep list", so the "all done" card shows
///   again next time.
/// - Just became done, and "Clear checked after shopping" is on
///   (decisions.md #79): remove the checked items. Not when the list is
///   first loaded, so a list that was already done doesn't clear itself
///   when you open it.
///
/// Why its own provider? Both rules compare the items before and after a
/// change, using `ref.listen`. If that listener were in
/// `ItemsSectionController.build()`, it would be replaced on every item
/// change (because that controller watches the items), before it could
/// ever run. This provider watches nothing, so its listener stays.
/// See decisions.md #99.
@riverpod
void listCompletionEffects(Ref ref, ShoppingList list) {
  ref.listen(itemsControllerProvider(list.id), (previous, next) {
    final before = previous?.dataOrNull;
    final after = next.dataOrNull;
    if (after == null) return;

    if (!allChecked(after)) {
      ref
          .read(itemsSectionUiControllerProvider(list.id).notifier)
          .resetCelebration();
      return;
    }
    if (list.clearCheckedAfterShopping &&
        before != null &&
        !allChecked(before)) {
      unawaited(
        ref.read(itemsControllerProvider(list.id).notifier).clearChecked(),
      );
    }
  });
}
