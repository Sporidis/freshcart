import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:freshcart_server/src/lists/business/list_broadcast.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/lists/business/member_profiles.dart';
import 'package:freshcart_server/src/lists/business/shopping_list_invite.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/profile/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Who is on a list: joining, leaving, removing someone, and handing the
/// list to a new owner.
///
/// Split from [ListService], which handles the list itself (its name,
/// settings and lifetime).
abstract final class ListMembershipService {
  /// Adds [userId] to the list with code [rawCode].
  ///
  /// The code is checked first (with the domain's parser), so a typo never
  /// reaches the database.
  static Future<ShoppingList> join(
    Session session,
    UuidValue userId,
    String rawCode,
  ) async {
    final parsed = domain.JoinCode.parse(rawCode);
    final code = switch (parsed) {
      domain.Ok<domain.JoinCode>(:final value) => value.value,
      domain.Err<domain.JoinCode>() => throw InvalidJoinCodeException(),
    };

    final list = await ShoppingList.db.findFirstRow(
      session,
      where: (t) => t.joinCode.equals(code),
    );
    // Expired and unknown codes raise the same error, so callers cannot
    // learn whether a code was ever issued.
    final isOpen = list?.invite?.isOpenAt(DateTime.now().toUtc()) ?? false;
    if (list == null || !isOpen) throw InvalidJoinCodeException();

    final existing = await ListMember.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(list.id!) & t.userId.equals(userId),
    );
    // Already a member: do nothing (no error). Tapping an invite twice
    // should just open the list.
    if (existing == null) {
      await ListMember.db.insertRow(
        session,
        ListMember(
          listId: list.id!,
          userId: userId,
          role: MemberRole.member,
          joinedAt: DateTime.now().toUtc(),
        ),
      );
      // Only notify others for a real new member, not when someone already
      // on the list taps the invite again (decisions.md #80).
      await ListBroadcast.send(session, list.id!);
      await NotificationService.notifyMemberJoined(
        session,
        list.id!,
        newMemberId: userId,
        newMemberName: await ProfileService.displayNameFor(session, userId),
        listName: list.name,
      );
    }
    return MemberProfiles.attachTo(session, list);
  }

  /// Removes [userId] from [listId].
  static Future<void> leave(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListMember.db.deleteWhere(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    );
    // Tell the other members, so their member count updates right away.
    await ListBroadcast.send(session, listId);
  }

  /// Removes member [targetUserId] from [listId]. Only the owner can.
  ///
  /// Different from [leave] (you leave yourself; the owner removes someone
  /// else). The owner can't remove themselves, or the list would have no
  /// owner. They should transfer ownership first.
  static Future<void> removeMember(
    Session session,
    UuidValue listId,
    UuidValue actorId,
    UuidValue targetUserId,
  ) async {
    final list = await ListAccess.requireOwner(session, listId, actorId);
    // To remove yourself, use `leave`. The owner can't be removed.
    if (targetUserId == list.ownerId) throw NotAMemberException();

    await ListAccess.requireMember(session, listId, targetUserId);
    await ListMember.db.deleteWhere(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(targetUserId),
    );
    await ListBroadcast.send(session, listId);
  }

  /// Makes [newOwnerId] the owner of [listId].
  ///
  /// Both role changes and the list's `ownerId` change in one transaction,
  /// so a list can never end up with two owners or none.
  static Future<ShoppingList> transferOwnership(
    Session session,
    UuidValue listId,
    UuidValue actorId,
    UuidValue newOwnerId,
  ) async {
    final list = await ListAccess.requireOwner(session, listId, actorId);

    final incoming = await ListAccess.requireMember(
      session,
      listId,
      newOwnerId,
    );
    final outgoing = await ListAccess.requireMember(session, listId, actorId);
    if (newOwnerId == actorId) return MemberProfiles.attachTo(session, list);

    final updated = await session.db.transaction((transaction) async {
      await ListMember.db.updateRow(
        session,
        incoming.copyWith(role: MemberRole.owner),
        transaction: transaction,
      );
      await ListMember.db.updateRow(
        session,
        outgoing.copyWith(role: MemberRole.member),
        transaction: transaction,
      );
      return ShoppingList.db.updateRow(
        session,
        list.copyWith(ownerId: newOwnerId),
        transaction: transaction,
      );
    });

    await ListBroadcast.send(session, listId);
    return MemberProfiles.attachTo(session, updated);
  }
}
