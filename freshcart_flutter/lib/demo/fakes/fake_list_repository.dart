import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';

/// [ListRepository] on the in-memory [DemoBackend], acting as user [_me].
///
/// Follows the server's rules (`list_service.dart`): non-members get
/// `unauthorized`, and only the owner can rename, delete, remove members or
/// hand over ownership.
class FakeListRepository implements ListRepository {
  FakeListRepository(this._db, this._me);

  final DemoBackend _db;
  final UserId _me;

  @override
  Future<Result<List<ShoppingList>>> myLists() async {
    await _db.latency();
    return Ok(_db.lists.values.where((l) => l.hasMember(_me)).toList());
  }

  @override
  Future<Result<ShoppingList>> byId(ListId id) async {
    await _db.latency();
    return _visible(id);
  }

  @override
  Future<Result<List<ListSummary>>> summaries(List<ListId> ids) async {
    await _db.latency();
    final summaries = [
      for (final id in ids)
        if (_db.lists[id]?.hasMember(_me) ?? false) _summaryFor(id),
    ];
    return Ok(summaries);
  }

  @override
  Future<Result<ShoppingList>> create({required String name}) async {
    await _db.latency();
    final me = _db.users[_me]!;
    final list = ShoppingList(
      id: ListId(_db.newId('list')),
      name: name,
      ownerId: me.id,
      createdAt: _db.now(),
      members: [_memberFor(me, MemberRole.owner)],
    );
    _db.lists[list.id] = list;
    _db.notify();
    return Ok(list);
  }

  @override
  Future<Result<ShoppingList>> joinByCode(JoinCode code) async {
    await _db.latency();
    final now = _db.now();
    final list = _db.lists.values
        .where((l) => l.invite?.code == code && l.invite!.isOpenAt(now))
        .firstOrNull;
    // Same failure the real app gets (core/error/failure_mapper.dart), for
    // an expired code as for a wrong one.
    if (list == null) {
      return const Err(
        Failure.validation(ValidationIssue.notFound(ValidatedInput.joinCode)),
      );
    }
    if (list.hasMember(_me)) return Ok(list);

    final joined = list.copyWith(
      members: [
        ...list.members,
        _memberFor(_db.users[_me]!, MemberRole.member),
      ],
    );
    _db.lists[joined.id] = joined;
    _db.notify();
    return Ok(joined);
  }

  /// Like the server: any member may ask; the open invite is reused while
  /// it's worth it, otherwise replaced by a new code.
  @override
  Future<Result<ListInvite>> openInvite(ListId id) async {
    await _db.latency();
    return _visible(id).map((list) {
      final now = _db.now();
      final current = list.invite;
      if (current != null && current.isWorthReusingAt(now)) return current;
      final invite = ListInvite.openAt(_db.newJoinCode(), now);
      _db.lists[id] = list.copyWith(invite: invite);
      _db.notify();
      return invite;
    });
  }

  @override
  Future<Result<void>> rename(ListId id, String name) async {
    await _db.latency();
    return _owned(id).map((list) {
      _db.lists[id] = list.copyWith(name: name);
      _db.notify();
    });
  }

  @override
  Future<Result<void>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  ) async {
    await _db.latency();
    // Any member may change this, not only the owner.
    return _visible(id).map((list) {
      _db.lists[id] = list.copyWith(clearCheckedAfterShopping: value);
      _db.notify();
    });
  }

  @override
  Future<Result<void>> leave(ListId id) async {
    await _db.latency();
    return _visible(id).map((list) {
      _db.lists[id] = list.copyWith(
        members: list.members.where((m) => m.userId != _me).toList(),
      );
      _db.notify();
    });
  }

  @override
  Future<Result<void>> delete(ListId id) async {
    await _db.latency();
    return _owned(id).map((_) {
      _db.lists.remove(id);
      // Like the database's cascade: the list's items and shops go too.
      _db.items.removeWhere((_, item) => item.listId == id);
      _db.shops.removeWhere((_, shop) => shop.listId == id);
      _db.notify();
    });
  }

  @override
  Future<Result<void>> removeMember(ListId id, UserId userId) async {
    await _db.latency();
    return _owned(id).flatMap<void>((list) {
      // The owner can't be removed; they transfer ownership first.
      if (userId == list.ownerId) return const Err(Failure.unauthorized());
      if (!list.hasMember(userId)) return const Err(Failure.notFound());
      _db.lists[id] = list.copyWith(
        members: list.members.where((m) => m.userId != userId).toList(),
      );
      _db.notify();
      return const Ok(null);
    });
  }

  @override
  Future<Result<void>> transferOwnership(
    ListId id,
    UserId userId,
  ) async {
    await _db.latency();
    return _owned(id).flatMap((list) {
      if (!list.hasMember(userId)) return const Err(Failure.notFound());
      final updated = list.copyWith(
        ownerId: userId,
        members: [
          for (final m in list.members)
            if (m.userId == userId)
              m.copyWith(role: MemberRole.owner)
            else if (m.userId == list.ownerId)
              m.copyWith(role: MemberRole.member)
            else
              m,
        ],
      );
      _db.lists[id] = updated;
      _db.notify();
      return const Ok(null);
    });
  }

  @override
  Stream<Result<ShoppingList>> watch(ListId id) =>
      _db.watch(() => _visible(id));

  /// List [id] if it exists and [_me] is on it.
  Result<ShoppingList> _visible(ListId id) => switch (_db.lists[id]) {
    null => const Err(Failure.notFound()),
    final list when !list.hasMember(_me) => const Err(Failure.unauthorized()),
    final list => Ok(list),
  };

  /// List [id] if [_me] owns it.
  Result<ShoppingList> _owned(ListId id) => _visible(id).flatMap(
    (list) =>
        list.isOwnedBy(_me) ? Ok(list) : const Err(Failure.unauthorized()),
  );

  ListSummary _summaryFor(ListId id) {
    final items = _db.items.values.where((i) => i.listId == id);
    return ListSummary(
      listId: id,
      total: items.length,
      checkedCount: items.where((i) => i.isChecked).length,
    );
  }

  ListMember _memberFor(AuthUser user, MemberRole role) => ListMember(
    userId: user.id,
    displayName: user.displayName,
    role: role,
    joinedAt: _db.now(),
    avatarColor: user.avatarColor,
    avatarPhotoUrl: user.avatarPhotoUrl,
  );
}
