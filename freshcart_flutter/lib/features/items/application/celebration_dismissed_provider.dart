import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celebration_dismissed_provider.g.dart';

/// Whether the completion celebration for [listId] has been dismissed via
/// "Keep list", for however long the list has been sitting fully checked.
///
/// Provider state, not widget state — the same reasoning as the "recently
/// checked" hold (decisions #47): this is a fact about *this list right
/// now*, and a screen that gets rebuilt (rotation, a route pop-and-push)
/// must not forget it and pop the card back up on its own.
///
/// [ItemsSection] resets this the moment the list stops being fully
/// checked — an item gets added, unchecked, or cleared — so the *next* time
/// it reaches all-done, the celebration shows again rather than staying
/// dismissed forever from one long-ago tap.
@riverpod
class CelebrationDismissed extends _$CelebrationDismissed {
  @override
  bool build(ListId listId) => false;

  /// "Keep list": hide the card without touching any items.
  void dismiss() => state = true;

  /// Called once the list is no longer fully checked, so the dismissal
  /// does not carry over to the next time it is.
  void reset() => state = false;
}
