import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `HouseholdScreen` renders, already derived.
class HouseholdScreenState {
  const HouseholdScreenState({
    required this.list,
    required this.me,
    required this.isOwner,
    this.loadFailure,
  });

  /// The list; null until it has loaded.
  final ShoppingList? list;

  /// The signed-in user; null until the identity resolves.
  final UserId? me;

  /// Whether the signed-in user owns the list.
  final bool isOwner;

  /// The list failed to load at all: the screen tier.
  final Failure? loadFailure;

  bool isMe(ListMember member) => member.userId == me;

  /// Only the owner is offered the destructive verbs, and never against
  /// themselves -- the server enforces both, this only keeps the UI from
  /// offering what it knows will be refused.
  bool canManage(ListMember member) => isOwner && !isMe(member);
}
