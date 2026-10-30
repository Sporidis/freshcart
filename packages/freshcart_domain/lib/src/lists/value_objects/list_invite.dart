import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';

part 'list_invite.freezed.dart';

/// An open invite to a list: a [code] anyone can join with until
/// [expiresAt].
///
/// A list has at most one at a time, and members share it, so several
/// people can join with the same code. Codes expire so a leaked one (an old
/// chat, a screenshot) stops working on its own.
@freezed
abstract class ListInvite with _$ListInvite {
  /// Creates an invite.
  const factory ListInvite({
    required JoinCode code,
    required DateTime expiresAt,
  }) = _ListInvite;

  /// A new invite with [code], valid for [lifetime] from [now].
  factory ListInvite.openAt(JoinCode code, DateTime now) =>
      ListInvite(code: code, expiresAt: now.add(lifetime));

  const ListInvite._();

  /// How long a new invite works: long enough to text it to someone who
  /// opens it after work.
  static const Duration lifetime = Duration(hours: 24);

  /// The least time an invite must have left to be handed out again,
  /// instead of being replaced by a new one.
  static const Duration minRemainingToReuse = Duration(hours: 12);

  /// Whether someone can still join with this invite at [now].
  bool isOpenAt(DateTime now) => now.isBefore(expiresAt);

  /// Whether a member asking to invite someone at [now] should get this
  /// invite again, rather than a new one.
  ///
  /// Reusing keeps one live code per list (fewer codes to guess). But an
  /// invite about to expire would die before the friend opens it.
  bool isWorthReusingAt(DateTime now) =>
      expiresAt.difference(now) >= minRemainingToReuse;
}
