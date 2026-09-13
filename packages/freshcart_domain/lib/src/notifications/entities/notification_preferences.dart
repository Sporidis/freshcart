import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// The signed-in user's own choices about which push notifications they
/// receive (decisions #80, phase 2) -- global, not per-list. Per-list
/// muting is a separate mechanism, reached through [PushPort.setListMuted]:
/// this is "which kinds of thing do I want to hear about at all," muting is
/// "not from this list, regardless of kind."
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  /// Creates preferences.
  const factory NotificationPreferences({
    /// "Someone adds an item" -- on by default; the design's own words:
    /// "Off by default except the first -- nobody installs a list app for
    /// alerts."
    @Default(true) bool itemAdded,

    /// "Someone joins a list."
    @Default(false) bool memberJoined,

    /// "A list is finished" -- when the last item is checked off.
    @Default(false) bool listFinished,
  }) = _NotificationPreferences;
}
