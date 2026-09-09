import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/lists/entities/member_role.dart';

part 'list_member.freezed.dart';

/// One person's membership of a shopping list.
///
/// [displayName] is denormalised on purpose: a list shows "Mom added milk"
/// without a second lookup, and the name survives even if that account is
/// later upgraded from anonymous to Google.
@freezed
abstract class ListMember with _$ListMember {
  /// Creates a membership record.
  const factory ListMember({
    required UserId userId,
    required String displayName,
    required MemberRole role,
    required DateTime joinedAt,
  }) = _ListMember;

  const ListMember._();

  /// Whether this member owns the list.
  bool get isOwner => role == MemberRole.owner;
}
