import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';

/// [ShopRepository] on the in-memory [DemoBackend], acting as user [_me].
class FakeShopRepository implements ShopRepository {
  FakeShopRepository(this._db, this._me);

  final DemoBackend _db;
  final UserId _me;

  @override
  Future<Result<List<Shop>>> byList(ListId listId) async {
    await _db.latency();
    return _requireMember(listId).map(
      (_) => _db.shops.values.where((s) => s.listId == listId).toList(),
    );
  }

  @override
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  }) async {
    await _db.latency();
    return _requireMember(listId).map((_) {
      final shop = Shop(
        id: ShopId(_db.newId('shop')),
        listId: listId,
        name: name,
        color: color,
      );
      _db.shops[shop.id] = shop;
      _db.notify();
      return shop;
    });
  }

  @override
  Future<Result<Shop>> save(Shop shop) async {
    await _db.latency();
    return _stored(shop.id).map((stored) {
      // A shop can't be moved to another list.
      final saved = shop.copyWith(listId: stored.listId);
      _db.shops[saved.id] = saved;
      _db.notify();
      return saved;
    });
  }

  @override
  Future<Result<int>> itemCount(ShopId id) async {
    await _db.latency();
    return _stored(id).map(
      (_) => _db.items.values.where((i) => i.shopId == id).length,
    );
  }

  @override
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition = ShopItemDisposition.untag,
    ShopId? moveTo,
  }) async {
    await _db.latency();
    return _stored(id).flatMap<void>((stored) {
      // Like the server: the target must be a real shop on the same list.
      final target = moveTo == null ? null : _db.shops[moveTo];
      if (disposition == ShopItemDisposition.moveToShop &&
          target?.listId != stored.listId) {
        return const Err(Failure.notFound());
      }

      final now = _db.now();
      final tagged = _db.items.values.where((i) => i.shopId == id).toList();
      for (final item in tagged) {
        switch (disposition) {
          case ShopItemDisposition.untag:
            _db.items[item.id] = item.copyWith(shopId: null, updatedAt: now);
          case ShopItemDisposition.moveToShop:
            _db.items[item.id] = item.copyWith(shopId: moveTo, updatedAt: now);
          case ShopItemDisposition.deleteItems:
            _db.items.remove(item.id);
        }
      }
      _db.shops.remove(id);
      _db.notify();
      return const Ok(null);
    });
  }

  /// Shop [id] if it exists and [_me] is on its list.
  Result<Shop> _stored(ShopId id) => switch (_db.shops[id]) {
    null => const Err(Failure.notFound()),
    final shop => _requireMember(shop.listId).map((_) => shop),
  };

  /// `Ok` if list [listId] exists and [_me] is on it.
  Result<void> _requireMember(ListId listId) => switch (_db.lists[listId]) {
    null => const Err(Failure.notFound()),
    final list when !list.hasMember(_me) => const Err(Failure.unauthorized()),
    _ => const Ok(null),
  };
}
