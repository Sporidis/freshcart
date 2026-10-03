import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// Which kinds of push notifications the user wants, for all lists
/// (decisions.md #80).
///
/// Muting one list is separate ([PushPort.setListMuted]). This is "which
/// kinds do I want"; muting is "nothing from this list".
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  /// Creates preferences.
  const factory NotificationPreferences({
    /// "Someone adds an item". The only one on by default (nobody installs a
    /// list app for lots of alerts).
    @Default(true) bool itemAdded,

    /// "Someone joins a list."
    @Default(false) bool memberJoined,

    /// "A list is finished": when the last item is checked.
    @Default(false) bool listFinished,
  }) = _NotificationPreferences;
}
