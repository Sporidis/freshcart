import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';

/// [ItemRepository] on the in-memory [DemoBackend], acting as user [_me].
///
/// Follows the server's rules (`item_service.dart`): adding the same open
/// product bumps its quantity, a save with a stale `updatedAt` is a
/// conflict, and the "server" decides who checked an item and when.
class FakeItemRepository implements ItemRepository {
  FakeItemRepository(this._db, this._me);

  final DemoBackend _db;
  final UserId _me;

  /// What the suggestion chips and "Recently bought" offer in the demo.
  static const demoNames = [
    'Milk',
    'Bread',
    'Eggs',
    'Bananas',
    'Coffee',
    'Butter',
    'Tomatoes',
    'Cheese',
  ];

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) async {
    await _db.latency();
    return _itemsOn(listId);
  }

  @override
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    await _db.latency();
    return _requireMember(listId).map((_) {
      final now = _db.now();
      final open = _sorted(listId).where((i) => !i.isChecked);
      final existing = open
          .where(
            (i) =>
                i.shopId == shopId &&
                ShoppingItem.sameProduct(
                  nameA: i.name,
                  noteTextA: i.note?.text,
                  nameB: name,
                  noteTextB: noteText,
                ),
          )
          .firstOrNull;

      final item =
          existing?.copyWith(
            quantity: existing.quantity + quantity,
            updatedAt: now,
          ) ??
          ShoppingItem(
            id: ItemId(_db.newId('item')),
            listId: listId,
            name: name,
            quantity: quantity,
            addedBy: _me,
            createdAt: now,
            updatedAt: now,
            sortOrder: _appendSortOrder(listId),
            shopId: shopId,
            note: noteText == null
                ? null
                : Note(text: noteText, authorId: _me, updatedAt: now),
          );
      _db.items[item.id] = item;
      _db.notify();
      return item;
    });
  }

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) async {
    await _db.latency();
    final stored = _db.items[item.id];
    if (stored == null) return const Err(Failure.notFound());
    return _requireMember(stored.listId).flatMap((_) {
      if (!stored.updatedAt.isAtSameMomentAs(item.updatedAt)) {
        return const Err(Failure.conflict());
      }
      final now = _db.now();
      final becameChecked = item.isChecked && !stored.isChecked;
      final becameUnchecked = !item.isChecked && stored.isChecked;
      // Like the server: the app can't move an item to another list, change
      // who added it, or claim someone else checked it.
      final saved = item.copyWith(
        listId: stored.listId,
        addedBy: stored.addedBy,
        createdAt: stored.createdAt,
        updatedAt: now,
        checkedBy: becameChecked
            ? _me
            : (becameUnchecked ? null : stored.checkedBy),
        checkedAt: becameChecked
            ? now
            : (becameUnchecked ? null : stored.checkedAt),
        pending: false,
      );
      _db.items[saved.id] = saved;
      _db.notify();
      return Ok(saved);
    });
  }

  @override
  Future<Result<void>> remove(ItemId id) async {
    await _db.latency();
    final stored = _db.items[id];
    if (stored == null) return const Err(Failure.notFound());
    return _requireMember(stored.listId).map((_) {
      _db.items.remove(id);
      _db.notify();
    });
  }

  @override
  Future<Result<int>> clearChecked(ListId listId) async {
    await _db.latency();
    return _requireMember(listId).map(
      (_) => _removeWhere((i) => i.listId == listId && i.isChecked),
    );
  }

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) async {
    await _db.latency();
    return _requireMember(listId).map(
      (_) => _removeWhere((i) => i.listId == listId && ids.contains(i.id)),
    );
  }

  @override
  Future<Result<int>> moveMany(
    ListId listId,
    List<ItemId> ids,
    ShopId? shopId,
  ) async {
    await _db.latency();
    return _requireMember(listId).map((_) {
      final now = _db.now();
      final moving = _db.items.values
          .where((i) => i.listId == listId && ids.contains(i.id))
          .toList();
      for (final item in moving) {
        _db.items[item.id] = item.copyWith(shopId: shopId, updatedAt: now);
      }
      if (moving.isNotEmpty) _db.notify();
      return moving.length;
    });
  }

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      _db.watch(() => _itemsOn(listId));

  @override
  Future<Result<List<String>>> suggestNames(ListId listId, String query) async {
    final q = query.trim().toLowerCase();
    return Ok(
      [
        for (final name in demoNames)
          if (name.toLowerCase().startsWith(q)) name,
      ].take(5).toList(),
    );
  }

  @override
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId) async {
    final now = _db.now();
    return Ok([
      for (final (i, name) in demoNames.indexed)
        NameHistoryEntry(
          name: name,
          lastUsedAt: now.subtract(Duration(days: i + 1)),
        ),
    ]);
  }

  /// `Ok` if list [listId] exists and [_me] is on it.
  Result<void> _requireMember(ListId listId) => switch (_db.lists[listId]) {
    null => const Err(Failure.notFound()),
    final list when !list.hasMember(_me) => const Err(Failure.unauthorized()),
    _ => const Ok(null),
  };

  Result<List<ShoppingItem>> _itemsOn(ListId listId) =>
      _requireMember(listId).map((_) => _sorted(listId));

  List<ShoppingItem> _sorted(ListId listId) =>
      _db.items.values.where((i) => i.listId == listId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// After the last item, like the server's `_appendSortOrder`.
  double _appendSortOrder(ListId listId) =>
      (_sorted(listId).lastOrNull?.sortOrder ?? 0) + ShoppingItem.sortOrderGap;

  int _removeWhere(bool Function(ShoppingItem) test) {
    final ids = [
      for (final item in _db.items.values)
        if (test(item)) item.id,
    ];
    ids.forEach(_db.items.remove);
    if (ids.isNotEmpty) _db.notify();
    return ids.length;
  }
}
