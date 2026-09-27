import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rearrange_controller.g.dart';

/// Whether one list's open rows are in drag-to-reorder mode right now.
///
/// Its own provider rather than a field on `ItemsViewModel`: that view
/// model's `build()` re-runs whenever anything it watches changes (a live
/// item update, a shop edit), which would silently reset a flag stored on
/// it mid-drag. Same shape as [SelectionController]'s per-list mode state.
@riverpod
class RearrangeController extends _$RearrangeController {
  @override
  bool build(ListId listId) => false;

  void enter() => state = true;

  void exit() => state = false;
}
