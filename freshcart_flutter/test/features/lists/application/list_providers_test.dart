import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_list_repository.dart';

void main() {
  const groceriesId = '00000000-0000-4000-8000-000000000001';
  const hardwareId = '00000000-0000-4000-8000-000000000002';
  const goneId = '00000000-0000-4000-8000-000000000009';

  late FakeListRepository repository;

  setUp(() {
    repository = FakeListRepository()
      ..myListsResult = Ok([
        buildList(id: groceriesId),
        buildList(id: hardwareId, name: 'Hardware'),
      ]);
  });

  /// Resolves [listsLandingTargetProvider] once both of its sources have
  /// settled.
  Future<ListId?> landing({String? lastOpened}) async {
    SharedPreferences.setMockInitialValues({
      'last_opened_list_id': ?lastOpened,
    });
    final container = ProviderContainer(
      overrides: [listRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(listsLandingTargetProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(listsLandingTargetProvider);
  }

  group('listsLandingTarget', () {
    test('reopens the last opened list', () async {
      expect(await landing(lastOpened: hardwareId), ListId(hardwareId));
    });

    test('falls back to the first list when nothing was opened yet', () async {
      expect(await landing(), ListId(groceriesId));
    });

    test('ignores a last opened list the user is no longer on', () async {
      // Following it would land on the error screen, whose exit leads
      // straight back here.
      expect(await landing(lastOpened: goneId), ListId(groceriesId));
    });

    test('stays put when there are no lists', () async {
      repository.myListsResult = const Ok(<ShoppingList>[]);
      expect(await landing(lastOpened: groceriesId), isNull);
    });
  });
}
