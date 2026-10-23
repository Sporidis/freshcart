import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Who may read or change a list. Every service asks here, so each
/// permission rule exists once.
abstract final class ListAccess {
  /// Throws [NotAMemberException] if [userId] isn't on [listId].
  static Future<ListMember> requireMember(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final membership = await ListMember.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    );
    if (membership == null) throw NotAMemberException();
    return membership;
  }

  /// The list, if [userId] owns it.
  ///
  /// Throws [ListNotFoundException] if there's no such list, and
  /// [NotListOwnerException] if someone else owns it.
  static Future<ShoppingList> requireOwner(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != userId) throw NotListOwnerException();
    return list;
  }
}
