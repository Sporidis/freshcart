import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selection_controller.g.dart';

/// Which rows of one list are multi-selected right now.
///
/// There is no separate "selection mode is active" flag: the mode *is*
/// having a non-empty selection. Long-press adds the pressed row, which is
/// how the mode is entered; deselecting the last remaining row empties the
/// set, which is how it exits. One source of truth, so the header, the
/// checkbox-slide animation and the contextual bar can never disagree about
/// whether selection is active.
@riverpod
class SelectionController extends _$SelectionController {
  @override
  Set<ItemId> build(ListId listId) => const {};

  /// Adds or removes [id] from the selection.
  void toggle(ItemId id) {
    state = state.contains(id)
        ? ({...state}..remove(id))
        : {...state, id};
  }

  /// Leaves selection mode without acting on it.
  void clear() => state = const {};
}
