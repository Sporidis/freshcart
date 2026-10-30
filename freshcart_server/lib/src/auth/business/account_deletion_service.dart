import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/join_attempts.dart';
import 'package:freshcart_server/src/lists/business/list_broadcast.dart';
import 'package:freshcart_server/src/profile/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Deletes a user's account (GDPR Art. 17, Apple 5.1.1(v)), as decided in
/// decisions.md #119: everything about the person goes, the household's
/// shared lists stay.
abstract final class AccountDeletionService {
  /// Deletes [userId]'s account and everything about them.
  ///
  /// One transaction for the database, so a crash can't leave half an
  /// account. The avatar file is deleted after it commits: storage isn't
  /// part of the transaction, and deleting it first would lose the photo
  /// if the transaction then rolled back.
  static Future<void> delete(Session session, UuidValue userId) async {
    final photoPath = await ProfileService.avatarPhotoPathFor(session, userId);

    final changedLists = await session.db.transaction((transaction) async {
      // Lists they own: handed over or deleted, before their membership
      // rows (which say who joined first) are gone.
      final owned = await ShoppingList.db.find(
        session,
        where: (t) => t.ownerId.equals(userId),
        transaction: transaction,
      );
      final handedOver = <UuidValue>[];
      for (final list in owned) {
        if (await _handOverOrDelete(session, list, userId, transaction)) {
          handedOver.add(list.id!);
        }
      }

      // Lists they're only a member of: tell the others they left.
      final memberships = await ListMember.db.deleteWhere(
        session,
        where: (t) => t.userId.equals(userId),
        transaction: transaction,
      );

      await DeviceToken.db.deleteWhere(
        session,
        where: (t) => t.ownerId.equals(userId),
        transaction: transaction,
      );
      await NotificationPreferences.db.deleteWhere(
        session,
        where: (t) => t.userId.equals(userId),
        transaction: transaction,
      );
      await ListMute.db.deleteWhere(
        session,
        where: (t) => t.userId.equals(userId),
        transaction: transaction,
      );
      // They store the name as text, so they'd still say who it was.
      await PendingItemNotification.db.deleteWhere(
        session,
        where: (t) => t.actorId.equals(userId),
        transaction: transaction,
      );

      // Login, email, password hash and sessions cascade with the auth
      // user, and so does the MemberProfile (name, colour).
      await AuthServices.instance.authUsers.delete(
        session,
        authUserId: userId,
        transaction: transaction,
      );

      return {...handedOver, for (final m in memberships) m.listId};
    });

    await JoinAttempts.forget(session, userId);
    if (photoPath != null) {
      await ProfileService.deleteAvatarFile(session, photoPath);
    }
    // After the commit, so the other members' screens load the new state.
    for (final listId in changedLists) {
      await ListBroadcast.send(session, listId);
    }
  }

  /// For one list [userId] owns: hands it to the member who joined
  /// earliest, or deletes it if [userId] is its only member (its items,
  /// shops and members go with it, by the database's cascade).
  ///
  /// Returns true if it was handed over (so the list still exists, and its
  /// members should hear about the change).
  static Future<bool> _handOverOrDelete(
    Session session,
    ShoppingList list,
    UuidValue userId,
    Transaction transaction,
  ) async {
    final oldestMember = await ListMember.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(list.id!) & t.userId.notEquals(userId),
      orderBy: (t) => t.joinedAt,
      transaction: transaction,
    );

    if (oldestMember != null) {
      await ListMember.db.updateRow(
        session,
        oldestMember.copyWith(role: MemberRole.owner),
        transaction: transaction,
      );
      await ShoppingList.db.updateRow(
        session,
        list.copyWith(ownerId: oldestMember.userId),
        transaction: transaction,
      );
      return true;
    }
    await ShoppingList.db.deleteRow(session, list, transaction: transaction);
    return false;
  }
}
