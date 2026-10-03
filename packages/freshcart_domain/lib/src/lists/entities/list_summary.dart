import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

part 'list_summary.freezed.dart';

/// How many items a list has, and how many are checked. For the drawer's
/// "6 left" / "All done".
///
/// Separate from [ShoppingList], because it's calculated from the items,
/// which are loaded separately from lists.
@freezed
abstract class ListSummary with _$ListSummary {
  /// Creates a summary.
  const factory ListSummary({
    required ListId listId,
    required int total,

    /// How many of [total] are checked.
    ///
    /// Called `checkedCount`, not `checked`, because `package:meta` already
    /// has a `checked` (an old annotation), and freezed's generated code
    /// wouldn't compile with a field of that name.
    required int checkedCount,
  }) = _ListSummary;

  const ListSummary._();

  /// How many items are still open.
  int get remaining => total - checkedCount;

  /// Whether the list has items and all are checked. An empty list is not
  /// "done".
  bool get allDone => total > 0 && remaining == 0;
}
