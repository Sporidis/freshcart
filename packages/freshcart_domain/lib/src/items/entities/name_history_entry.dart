import 'package:freezed_annotation/freezed_annotation.dart';

part 'name_history_entry.freezed.dart';

/// An item name a list had before, and when it was last added. Used for
/// "Recently bought".
///
/// Has no shop: the same name can be added to different shops at different
/// times, and only the last add is stored. Screens must not show a shop dot
/// for it.
@freezed
abstract class NameHistoryEntry with _$NameHistoryEntry {
  /// Creates an entry.
  const factory NameHistoryEntry({
    required String name,
    required DateTime lastUsedAt,
  }) = _NameHistoryEntry;
}
