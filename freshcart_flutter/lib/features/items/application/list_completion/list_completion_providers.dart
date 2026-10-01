import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_ui/items_ui_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_completion_providers.g.dart';

/// Whether [items] is a finished list: something on it, and all of it
/// checked.
bool allChecked(List<ShoppingItem> items) =>
    items.isNotEmpty && items.every((i) => i.isChecked);

/// Reacts to [list] *becoming* finished or unfinished. A side effect only,
/// with no value, the same shape as `queueDrainCoordinator`:
///
/// - No longer finished: a "Keep list" dismissal is forgotten, so the next
///   completion celebrates again.
/// - Just finished, with "Clear checked after shopping" on (decisions #79):
///   the checked items are cleared. Not on the initial load, so a list that
///   was already finished when opened never wipes itself on arrival.
///
/// Why its own provider: both rules compare the items *before* and *after*
/// a change, which takes a `ref.listen` that survives the change.
/// `ItemsSectionController` also *watches* the items, so every change
/// rebuilds it, and a listener registered in its `build()` is replaced
/// before it can ever fire. This provider watches nothing, so its
/// listener lives as long as the section does (`ItemsSectionController`
/// watches it to keep it alive). See decisions #99.
@riverpod
void listCompletion(Ref ref, ShoppingList list) {
  ref.listen(itemsControllerProvider(list.id), (previous, next) {
    final before = previous?.dataOrNull;
    final after = next.dataOrNull;
    if (after == null) return;

    if (!allChecked(after)) {
      ref.read(itemsUiControllerProvider(list.id).notifier).resetCelebration();
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
