import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `HouseholdScreen` shows.
class HouseholdScreenState {
  const HouseholdScreenState({
    required this.list,
    required this.me,
    required this.isOwner,
    this.loadFailure,
  });

  /// The list; null until it has loaded.
  final ShoppingList? list;

  /// The signed-in user; null until known.
  final UserId? me;

  /// Whether the signed-in user owns the list.
  final bool isOwner;

  /// Set when the list couldn't load. Then a full error screen is shown.
  final Failure? loadFailure;

  bool isMe(ListMember member) => member.userId == me;

  /// Whether to show "remove" / "make owner" for [member]. Only for the
  /// owner, and never on themselves. The server checks this too; this just
  /// hides buttons that would fail anyway.
  bool canManage(ListMember member) => isOwner && !isMe(member);
}
