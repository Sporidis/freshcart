import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

part 'list_summary.freezed.dart';

/// A list's item counts -- the drawer's "6 left" / "All done" row (Flow 10,
/// §4). Deliberately separate from [ShoppingList] itself: items are fetched
/// separately from lists because the two change at very different rates
/// (`ShoppingList`'s own doc comment), and a summary is still a derived
/// aggregate over items, not a field a list ever "has."
@freezed
abstract class ListSummary with _$ListSummary {
  /// Creates a summary.
  const factory ListSummary({
    required ListId listId,
    required int total,

    /// How many of [total] are checked off. Named `checkedCount`, not
    /// `checked`: `package:meta` (re-exported transitively through
    /// `freezed_annotation`) declares a top-level `checked` constant -- the
    /// old, deprecated `@checked` annotation -- and a field of that exact
    /// name fails to compile against this class's generated mixin. Avoided
    /// rather than fought.
    required int checkedCount,
  }) = _ListSummary;

  const ListSummary._();

  /// How many items are still open.
  int get remaining => total - checkedCount;

  /// Whether the list has items and every one of them is checked. A list
  /// with nothing on it yet is not "done" -- there is simply nothing to be
  /// done with.
  bool get allDone => total > 0 && remaining == 0;
}
