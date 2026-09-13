import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/common/business/join_code_generator.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Business operations on shopping lists.
///
/// Endpoints stay thin and delegate here, so the rules live in one place that
/// is testable without going through the transport layer.
abstract final class ListService {
  /// How many times to retry on a join-code collision before giving up.
  static const int _joinCodeAttempts = 5;

  /// The message channel carrying changes to one list.
  ///
  /// Per list, not global: a client watching one list should not be woken by
  /// traffic on every other list on the server.
  static String channelFor(UuidValue listId) => 'list-$listId';

  /// Broadcasts the list's current state — with members — to everyone
  /// watching it.
  ///
  /// Unlike items, this sends the whole entity rather than a delta: a list is
  /// a single row, not a collection that could run to hundreds, so there is no
  /// merge to save bandwidth on. Fire-and-forget by design: a dropped
  /// notification must never fail the write that caused it.
  static Future<void> _announce(Session session, UuidValue listId) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) return;
    final withMembers = await _withMembers(session, list);
    await session.messages.postMessage(channelFor(listId), withMembers);
  }

  /// Every list [userId] is a member of, newest first.
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
    return Future.wait(lists.map((l) => _withMembers(session, l)));
  }

  /// One list by id, if [userId] belongs to it.
  ///
  /// Throws [ListNotFoundException] when the list is missing *or* the caller is
  /// not a member — the two are deliberately indistinguishable from outside.
  static Future<ShoppingList> byId(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    await requireMembership(session, listId, userId);
    return _withMembers(session, list);
  }

  /// Creates a list owned by [userId], with [userId] as its first member.
  ///
  /// [avatarColorArgb] and [avatarPhotoUrl] are snapshotted onto the new
  /// membership row exactly like [displayName] already is -- see
  /// `ListMember`'s own doc comment.
  static Future<ShoppingList> create(
    Session session,
    UuidValue userId,
    String name,
    String displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
  ) async {
    return session.db
        .transaction((transaction) async {
          final list = await ShoppingList.db.insertRow(
            session,
            ShoppingList(
              name: name,
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
              displayName: displayName,
              avatarColorArgb: avatarColorArgb,
              avatarPhotoUrl: avatarPhotoUrl,
              role: MemberRole.owner,
              joinedAt: DateTime.now().toUtc(),
            ),
            transaction: transaction,
          );
          return list;
        })
        .then((list) => _withMembers(session, list));
  }

  /// Adds [userId] to the list matching [rawCode].
  ///
  /// Validating the code with the domain's parser first means a typo never
  /// reaches the database.
  static Future<ShoppingList> join(
    Session session,
    UuidValue userId,
    String rawCode,
    String displayName,
    int? avatarColorArgb,
    String? avatarPhotoUrl,
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
    // Joining twice is a no-op, not an error: a re-tapped invite link should
    // land you in the list, not show a failure.
    if (existing == null) {
      await ListMember.db.insertRow(
        session,
        ListMember(
          listId: list.id!,
          userId: userId,
          displayName: displayName,
          avatarColorArgb: avatarColorArgb,
          avatarPhotoUrl: avatarPhotoUrl,
          role: MemberRole.member,
          joinedAt: DateTime.now().toUtc(),
        ),
      );
      // Only announce a genuine join: a re-tap must not wake every other
      // open client with a no-op notification.
      await _announce(session, list.id!);
    }
    return _withMembers(session, list);
  }

  /// Renames a list. Owner only.
  static Future<ShoppingList> rename(
    Session session,
    UuidValue listId,
    UuidValue userId,
    String name,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != userId) throw NotAMemberException();

    final updated = await ShoppingList.db.updateRow(
      session,
      list.copyWith(name: name),
    );
    await _announce(session, listId);
    return _withMembers(session, updated);
  }

  /// Sets whether [listId] clears its checked items automatically once
  /// everything on it is checked (decisions #79).
  ///
  /// Any member may set this, checked with [requireMembership] rather than
  /// an owner check: unlike [rename]/[delete], it is a shared
  /// shopping-behaviour preference, not an identity or destructive action --
  /// the same authorisation shape `ShopService.save` already uses for
  /// toggling a shop's `isActive`.
  static Future<ShoppingList> setClearCheckedAfterShopping(
    Session session,
    UuidValue listId,
    UuidValue userId,
    bool value,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    await requireMembership(session, listId, userId);

    final updated = await ShoppingList.db.updateRow(
      session,
      list.copyWith(clearCheckedAfterShopping: value),
    );
    await _announce(session, listId);
    return _withMembers(session, updated);
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
    // The remaining members' member count should drop live, without them
    // having to reload the list.
    await _announce(session, listId);
  }

  /// Deletes [listId], for everyone.
  ///
  /// Owner only. Leaving is the member's verb — it takes you out of a list
  /// that carries on without you — while this ends it for the household, so
  /// the two are deliberately different operations rather than one with a
  /// flag.
  ///
  /// Members, items, shops, mutes and pending notifications all go with it,
  /// through the ON DELETE CASCADE already on their foreign keys. Doing it in
  /// the database rather than in five deletes here means a crash halfway
  /// cannot leave a list that is half gone.
  static Future<void> delete(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != userId) throw NotAMemberException();

    // Announced before the row goes: afterwards there is no list to describe,
    // and open clients need to be told rather than left on a dead screen.
    await _announce(session, listId);
    await ShoppingList.db.deleteRow(session, list);
  }

  /// Removes [targetUserId] from [listId], on the owner's authority.
  ///
  /// Separate from [leave] because they are different acts: leaving is
  /// something you do to yourself, removal is something done to you. The
  /// owner cannot remove themselves this way — that would leave the list
  /// ownerless — and transferring first is the honest path out.
  static Future<void> removeMember(
    Session session,
    UuidValue listId,
    UuidValue actorId,
    UuidValue targetUserId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != actorId) throw NotAMemberException();
    // Removing yourself is `leave`; removing the owner is not a thing.
    if (targetUserId == list.ownerId) throw NotAMemberException();

    await requireMembership(session, listId, targetUserId);
    await ListMember.db.deleteWhere(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(targetUserId),
    );
    await _announce(session, listId);
  }

  /// Hands ownership of [listId] to [newOwnerId].
  ///
  /// The two role changes and the list's own `ownerId` move together in a
  /// transaction: a list with two owners, or none, is worse than one that
  /// never changed hands.
  static Future<ShoppingList> transferOwnership(
    Session session,
    UuidValue listId,
    UuidValue actorId,
    UuidValue newOwnerId,
  ) async {
    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) throw ListNotFoundException();
    if (list.ownerId != actorId) throw NotAMemberException();

    final incoming = await requireMembership(session, listId, newOwnerId);
    final outgoing = await requireMembership(session, listId, actorId);
    if (newOwnerId == actorId) return _withMembers(session, list);

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
    return _withMembers(session, updated);
  }

  /// Item counts for exactly the lists in [listIds] that [userId] actually
  /// belongs to -- the drawer's remaining-count row, fetched once per list
  /// rather than N full item-collection loads.
  ///
  /// A foreign id in [listIds] is silently skipped, not an error: a
  /// legitimate caller only ever asks about its own lists (the drawer's own
  /// [listsFor] result) anyway, so this exists as a defence against a
  /// malicious id rather than a normal code path a thrown exception would
  /// need to surface.
  static Future<List<ListSummary>> summaries(
    Session session,
    List<UuidValue> listIds,
    UuidValue userId,
  ) async {
    if (listIds.isEmpty) return [];
    final memberships = await ListMember.db.find(
      session,
      where: (t) =>
          t.listId.inSet(listIds.toSet()) & t.userId.equals(userId),
    );
    final allowed = memberships.map((m) => m.listId);

    // Two `count` queries per list rather than a row-scanning read: the ORM
    // has no GROUP BY aggregate escape hatch short of raw SQL (the same
    // reasoning ShopService.itemCount's own single-list count already
    // follows). Future.wait keeps every list's pair of counts running in
    // parallel rather than one list waiting on the last.
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

  /// Throws [NotAMemberException] unless [userId] belongs to [listId].
  ///
  /// Every read and write path funnels through this, so authorisation is one
  /// function rather than a check duplicated per endpoint method.
  static Future<ListMember> requireMembership(
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

  static Future<ShoppingList> _withMembers(
    Session session,
    ShoppingList list,
  ) async {
    final members = await ListMember.db.find(
      session,
      where: (t) => t.listId.equals(list.id!),
      orderBy: (t) => t.joinedAt,
    );
    return list.copyWith(members: members);
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
    // 32^6 codes make this effectively unreachable; failing loudly beats
    // handing out a duplicate that would send someone into a stranger's list.
    throw StateError('Could not allocate a unique join code');
  }
}
