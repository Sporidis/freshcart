import 'dart:math';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/fakes/fake_auth.dart';
import 'package:freshcart_flutter/demo/fakes/fake_item_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_list_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_shop_repository.dart';

/// One user's view of the shared [DemoBackend]: what one demo phone holds.
class DemoPhoneFakes {
  DemoPhoneFakes(DemoBackend db, this.id)
    : lists = FakeListRepository(db, id),
      items = FakeItemRepository(db, id),
      shops = FakeShopRepository(db, id),
      auth = FakeAuth(db, id);

  final UserId id;
  final FakeListRepository lists;
  final FakeItemRepository items;
  final FakeShopRepository shops;
  final FakeAuth auth;
}

/// A backend with two seeded users, [a] and [b], and no latency.
///
/// The clock ticks one second per read, so every write gets a later
/// `updatedAt` than the one before (the conflict check depends on that).
class DemoWorld {
  DemoWorld() {
    for (final (id, name) in [(aId, 'Nikolaos'), (bId, 'Anna')]) {
      db.users[id] = AuthUser(id: id, displayName: name, isAnonymous: true);
    }
  }

  static final aId = UserId('user-a');
  static final bId = UserId('user-b');

  var _now = DateTime.utc(2026, 10, 3, 9);

  late final db = DemoBackend(
    clock: () => _now = _now.add(const Duration(seconds: 1)),
    simulateLatency: false,
    random: Random(42),
  );
  late final a = DemoPhoneFakes(db, aId);
  late final b = DemoPhoneFakes(db, bId);

  /// A creates list "Home" and B joins it. Returns the list as B sees it.
  Future<ShoppingList> sharedList() async {
    final created = (await a.lists.create(name: 'Home')).valueOrNull!;
    return (await b.lists.joinByCode(created.joinCode)).valueOrNull!;
  }
}
