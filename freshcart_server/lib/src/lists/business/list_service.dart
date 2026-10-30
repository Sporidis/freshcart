import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/common/business/require_valid.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/join_code_generator.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:freshcart_server/src/lists/business/list_broadcast.dart';
import 'package:freshcart_server/src/lists/business/member_profiles.dart';
import 'package:freshcart_server/src/lists/business/shopping_list_invite.dart';
import 'package:serverpod/serverpod.dart';

/// The logic for shopping lists.
///
/// Endpoints are kept small and call this. So the rules are in one place,
/// and can be tested without going through HTTP.
abstract final class ListService {
  /// How many times to try a new join code if one is already taken.
  static const int _joinCodeAttempts = 5;

  /// All lists [userId] is on, newest first.
  static Future<List<ShoppingList>> listsFor(
    Session session,
    UuidValue userId,
  ) async {
    final memberships = await ListMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (memberships.isEmpty) return [];

    final listIds = memberships.map((m) => m.listId).toList();
    final lists = await ShoppingList.db.find(
      session,
      where: (t) => t.id.inSet(listIds.toSet()),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
    return Future.wait(lists.map((l) => MemberProfiles.attachTo(session, l)));
  }

  /// One list by id, if [userId] belongs to it.
  ///
  /// Throws [ListNotFoundException] if the list doesn't exist OR the user
  /// isn't a member. Same error on purpose, so outsiders can't find out
  /// which lists exist.
  static Future<ShoppingList> byId(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    await ListAccess.requireMember(session, listId, userId);
    return MemberProfiles.attachTo(session, list);
  }

  /// Creates a list owned by [userId], with [userId] as its first member.
  static Future<ShoppingList> create(
    Session session,
    UuidValue userId,
    String name,
  ) async {
    final validName = requireValid(domain.ShoppingList.validateName(name));
    return session.db
        .transaction((transaction) async {
          final list = await ShoppingList.db.insertRow(
            session,
            ShoppingList(
              name: validName,
              ownerId: userId,
              createdAt: DateTime.now().toUtc(),
            ),
            transaction: transaction,
          );
          await ListMember.db.insertRow(
            session,
            ListMember(
              listId: list.id!,
              userId: userId,
              role: MemberRole.owner,
              joinedAt: DateTime.now().toUtc(),
            ),
            transaction: transaction,
          );
          return list;
        })
        .then((list) => MemberProfiles.attachTo(session, list));
  }

  /// Returns [listId] with an invite [userId] can share: the current invite
  /// if it is worth reusing, otherwise a newly issued one.
  ///
  /// Open to any member. The row is locked for the duration of the
  /// transaction, so concurrent requests receive the same code rather than
  /// overwriting each other.
  static Future<ShoppingList> openInvite(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListAccess.requireMember(session, listId, userId);
    final now = DateTime.now().toUtc();

    final (:list, :replaced) = await session.db.transaction((
      transaction,
    ) async {
      final current = await ShoppingList.db.findById(
        session,
        listId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (current == null) throw ListNotFoundException();
      final list = await _withInviteWorthSharing(
        session,
        current,
        now,
        transaction: transaction,
      );
      return (list: list, replaced: list.joinCode != current.joinCode);
    });

    // Members currently viewing the list display the code as well.
    if (replaced) await ListBroadcast.send(session, listId);
    return MemberProfiles.attachTo(session, list);
  }

  /// Returns [list] ready to share at [now]: unchanged if its invite is
  /// worth reusing, otherwise persisted with a new code valid for
  /// [domain.ListInvite.lifetime].
  static Future<ShoppingList> _withInviteWorthSharing(
    Session session,
    ShoppingList list,
    DateTime now, {
    required Transaction transaction,
  }) async {
    final invite = list.invite;
    if (invite != null && invite.isWorthReusingAt(now)) return list;

    final newCode = await _uniqueJoinCode(session, transaction: transaction);
    return ShoppingList.db.updateRow(
      session,
      list.copyWith(
        joinCode: newCode,
        joinCodeExpiresAt: now.add(domain.ListInvite.lifetime),
      ),
      transaction: transaction,
    );
  }

  /// Renames a list. Owner only.
  static Future<ShoppingList> rename(
    Session session,
    UuidValue listId,
    UuidValue userId,
    String name,
  ) async {
    final list = await ListAccess.requireOwner(session, listId, userId);
    final validName = requireValid(domain.ShoppingList.validateName(name));

    final updated = await ShoppingList.db.updateRow(
      session,
      list.copyWith(name: validName),
    );
    await ListBroadcast.send(session, listId);
    return MemberProfiles.attachTo(session, updated);
  }

  /// Sets whether [listId] removes checked items automatically when
  /// everything is checked (decisions.md #79).
  ///
  /// Any member can change this (not only the owner), like turning a shop
  /// tab on or off. It's a shared preference, not a dangerous action.
  static Future<ShoppingList> setClearCheckedAfterShopping(
    Session session,
    UuidValue listId,
    UuidValue userId,
    bool value,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    await ListAccess.requireMember(session, listId, userId);

    final updated = await ShoppingList.db.updateRow(
      session,
      list.copyWith(clearCheckedAfterShopping: value),
    );
    await ListBroadcast.send(session, listId);
    return MemberProfiles.attachTo(session, updated);
  }

  /// Deletes [listId] for everyone. Only the owner can.
  ///
  /// Separate from [ListMembershipService.leave] on purpose (leaving only removes you).
  ///
  /// Members, items, shops, mutes and waiting notifications are deleted too,
  /// by the database itself (ON DELETE CASCADE on their foreign keys). That's
  /// safer than five separate deletes here: a crash can't leave a list half
  /// deleted.
  static Future<void> delete(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ListAccess.requireOwner(session, listId, userId);

    // Tell watchers BEFORE deleting (after, there's no list left to send).
    // Otherwise their screen would just stop updating.
    await ListBroadcast.send(session, listId);
    await ShoppingList.db.deleteRow(session, list);
  }

  /// Item counts for the lists in [listIds] that [userId] is on. For the
  /// drawer's "6 left". Counts only, instead of loading all items.
  ///
  /// Lists the user isn't on are skipped (no error). The app only asks for
  /// its own lists anyway; this just protects against someone asking for
  /// other people's.
  static Future<List<ListSummary>> summaries(
    Session session,
    List<UuidValue> listIds,
    UuidValue userId,
  ) async {
    if (listIds.isEmpty) return [];
    final memberships = await ListMember.db.find(
      session,
      where: (t) => t.listId.inSet(listIds.toSet()) & t.userId.equals(userId),
    );
    final allowed = memberships.map((m) => m.listId);

    // Two `count` queries per list. (Serverpod's query builder has no GROUP
    // BY without writing raw SQL.) Future.wait runs them all at the same
    // time instead of one after another.
    Future<ListSummary> summaryFor(UuidValue listId) async {
      final total = await ShoppingItem.db.count(
        session,
        where: (t) => t.listId.equals(listId),
      );
      final checkedCount = await ShoppingItem.db.count(
        session,
        where: (t) => t.listId.equals(listId) & t.isChecked.equals(true),
      );
      return ListSummary(
        listId: listId,
        total: total,
        checkedCount: checkedCount,
      );
    }

    return Future.wait(allowed.map(summaryFor));
  }

  static Future<String> _uniqueJoinCode(
    Session session, {
    required Transaction transaction,
  }) async {
    for (var attempt = 0; attempt < _joinCodeAttempts; attempt++) {
      final candidate = JoinCodeGenerator.generate();
      final clash = await ShoppingList.db.findFirstRow(
        session,
        where: (t) => t.joinCode.equals(candidate),
        transaction: transaction,
      );
      if (clash == null) return candidate;
    }
    // With 32^5 (about 33 million) possible codes, this should never happen.
    // Throwing is better than giving out a duplicate code, which would let
    // someone join a stranger's list.
    throw StateError('Could not allocate a unique join code');
  }
}
