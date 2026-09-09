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
  static Future<ShoppingList> create(
    Session session,
    UuidValue userId,
    String name,
    String displayName,
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
          role: MemberRole.member,
          joinedAt: DateTime.now().toUtc(),
        ),
      );
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
