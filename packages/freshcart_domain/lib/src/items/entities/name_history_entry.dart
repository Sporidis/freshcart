import 'package:freezed_annotation/freezed_annotation.dart';

part 'name_history_entry.freezed.dart';

/// One product name a list has had before, and when it was last used --
/// the "Recently bought" shortcut (§06: "the weekly-staples shortcut
/// without building a template feature").
///
/// Deliberately thin: it does not carry a shop, because the underlying
/// history is not shop-scoped (`docs/decisions.md` -- a name can move
/// between shops across separate adds, and the current schema records only
/// the most recent add, not a full history per shop). Screens presenting
/// this must not invent a shop dot for it.
@freezed
abstract class NameHistoryEntry with _$NameHistoryEntry {
  /// Creates an entry.
  const factory NameHistoryEntry({
    required String name,
    required DateTime lastUsedAt,
  }) = _NameHistoryEntry;
}
