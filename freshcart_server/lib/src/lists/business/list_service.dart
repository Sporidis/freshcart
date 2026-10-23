import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/common/business/require_valid.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/join_code_generator.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/profile/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// The logic for shopping lists.
///
/// Endpoints are kept small and call this. So the rules are in one place,
/// and can be tested without going through HTTP.
abstract final class ListService {
  /// How many times to try a new join code if one is already taken.
  static const int _joinCodeAttempts = 5;

  /// The channel name for updates to one list.
  ///
  /// One channel per list, so someone watching one list doesn't get
  /// messages about all other lists.
  static String channelFor(UuidValue listId) => 'list-$listId';

  /// Sends the list (with members) to everyone watching it.
  ///
  /// Sends the whole list (not just what changed, like for items), because
  /// a list is one small row. It runs after the save, so a failure here is
  /// logged, not thrown: the change went through, and other phones catch up
  /// when they next load or reconnect.
  static Future<void> _announce(Session session, UuidValue listId) async {
    try {
      final list = await ShoppingList.db.findById(session, listId);
      if (list == null) return;
      final withProfiles = await _withMemberProfiles(session, list);
      await session.messages.postMessage(channelFor(listId), withProfiles);
    } on Object catch (error, stackTrace) {
      session.log(
        'Broadcasting list $listId failed',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

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
    return Future.wait(lists.map((l) => _withMemberProfiles(session, l)));
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
    return _withMemberProfiles(session, list);
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
              joinCode: await _uniqueJoinCode(
                session,
                transaction: transaction,
              ),
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
        .then((list) => _withMemberProfiles(session, list));
  }

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
    if (list == null) throw InvalidJoinCodeException();

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
      await _announce(session, list.id!);
      await NotificationService.notifyMemberJoined(
        session,
        list.id!,
        newMemberId: userId,
        newMemberName: await ProfileService.displayNameFor(session, userId),
        listName: list.name,
      );
    }
    return _withMemberProfiles(session, list);
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
    await _announce(session, listId);
    return _withMemberProfiles(session, updated);
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
    await _announce(session, listId);
    return _withMemberProfiles(session, updated);
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
    await _announce(session, listId);
  }

  /// Deletes [listId] for everyone. Only the owner can.
  ///
  /// Separate from [leave] on purpose (leaving only removes you).
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
    await _announce(session, listId);
    await ShoppingList.db.deleteRow(session, list);
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
    await _announce(session, listId);
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
    if (newOwnerId == actorId) return _withMemberProfiles(session, list);

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

    await _announce(session, listId);
    return _withMemberProfiles(session, updated);
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

  /// [list] with its members, each with their current name, colour and
  /// photo (from `MemberProfile`).
  ///
  /// Every list read and broadcast goes through here, so people always show
  /// with their current profile (decisions.md #98). Two queries per list,
  /// not one per member.
  static Future<ShoppingList> _withMemberProfiles(
    Session session,
    ShoppingList list,
  ) async {
    final members = await ListMember.db.find(
      session,
      where: (t) => t.listId.equals(list.id!),
      orderBy: (t) => t.joinedAt,
    );
    final profiles = await ProfileService.profilesFor(session, {
      for (final m in members) m.userId,
    });
    return list.copyWith(
      members: [
        for (final m in members)
          m.copyWith(
            displayName:
                profiles[m.userId]?.displayName ??
                ProfileService.fallbackDisplayName,
            avatarColorArgb: profiles[m.userId]?.avatarColorArgb,
            avatarPhotoUrl: await ProfileService.photoUrlFor(
              session,
              profiles[m.userId]?.avatarPhotoPath,
            ),
          ),
      ],
    );
  }

  /// Sends every list [userId] is on again, after they changed their name,
  /// colour or photo. So others see the change right away.
  ///
  /// Like [_announce], a failure is logged, not thrown: the profile is
  /// already saved.
  static Future<void> announceMemberChanged(
    Session session,
    UuidValue userId,
  ) async {
    final memberships = await ListMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    for (final m in memberships) {
      await _announce(session, m.listId);
    }
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
