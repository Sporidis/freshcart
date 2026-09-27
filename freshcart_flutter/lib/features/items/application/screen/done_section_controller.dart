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
class DoneSectionController extends _$DoneSectionController {
  @override
  bool build(ListId listId) => false;

  /// Folds the section away, or opens it again.
  void toggle() => state = !state;
}
