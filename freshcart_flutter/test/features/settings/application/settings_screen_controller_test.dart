import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_list_row.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_controller.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_list_repository.dart';
import '../../../fakes/fake_shop_repository.dart';

void main() {
  const groceriesId = '00000000-0000-4000-8000-000000000001';
  const hardwareId = '00000000-0000-4000-8000-000000000002';

  late FakeAuthRepository auth;
  late FakeListRepository lists;

  setUp(() {
    auth = FakeAuthRepository();
    lists = FakeListRepository()
      ..myListsResult = Ok([
        buildList(id: groceriesId, name: 'Groceries'),
        buildList(id: hardwareId, name: 'Hardware'),
      ]);
  });
  tearDown(() => auth.dispose());

  /// The VM's rows once every source has settled, with [lastOpened] as the
  /// list the app remembers opening.
  Future<List<SettingsListRow>> rows({String? lastOpened}) async {
    SharedPreferences.setMockInitialValues({
      'last_opened_list_id': ?lastOpened,
    });
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        listRepositoryProvider.overrideWithValue(lists),
        shopRepositoryProvider.overrideWithValue(FakeShopRepository()),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(settingsScreenControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(settingsScreenControllerProvider).lists;
  }

  test('one row per list, with its shop count once loaded', () async {
    final result = await rows();
    expect([for (final r in result) r.list.name], ['Groceries', 'Hardware']);
    expect([for (final r in result) r.shopCount], [0, 0]);
  });

  test('"Open now" follows the last opened list, not the first one', () async {
    // The regression this VM exists for: the widget used to mark whichever
    // list came first, while the app actually opens the last-opened one.
    // Hardware is second, so the old rule and the real one disagree here.
    final result = await rows(lastOpened: hardwareId);
    expect(
      {for (final r in result) r.list.name: r.isOpen},
      {
        'Groceries': false,
        'Hardware': true,
      },
    );
  });

  test('with nothing opened yet, the first list is the open one', () async {
    final result = await rows();
    expect(
      {for (final r in result) r.list.name: r.isOpen},
      {
        'Groceries': true,
        'Hardware': false,
      },
    );
  });
}
