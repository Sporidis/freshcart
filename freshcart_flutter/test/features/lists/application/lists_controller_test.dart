import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_list_repository.dart';

void main() {
  late FakeListRepository lists;
  late int signIns;

  /// The lists, with a sign-in that fails the first [failingSignIns] times.
  ProviderContainer start({int failingSignIns = 0}) {
    signIns = 0;
    lists = FakeListRepository()..myListsResult = Ok([buildList()]);
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(lists),
        signInResultProvider.overrideWith((ref) async {
          signIns++;
          return signIns > failingSignIns
              ? Ok(aSignIn())
              : const Err(Failure.network());
        }),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(listsControllerProvider, (_, _) {});
    addTearDown(sub.close);
    return container;
  }

  test('Try again after a failed sign-in signs in again first', () async {
    // The server was down at start: there is no session, so reloading the
    // lists alone would only say "no access".
    final container = start(failingSignIns: 1);
    await container.read(signInResultProvider.future);
    expect(signIns, 1);

    await container.read(listsControllerProvider.notifier).refresh();
    final reloaded = await container.read(listsControllerProvider.future);

    expect(signIns, 2);
    expect(reloaded.valueOrNull, hasLength(1));
  });

  test('Try again after a working sign-in only reloads the lists', () async {
    final container = start();
    await container.read(signInResultProvider.future);
    await container.read(listsControllerProvider.future);

    await container.read(listsControllerProvider.notifier).refresh();
    await container.read(listsControllerProvider.future);

    expect(signIns, 1);
  });
}
