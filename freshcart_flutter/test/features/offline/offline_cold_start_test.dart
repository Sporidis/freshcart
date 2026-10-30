import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/database/app_database_provider.dart';
import 'package:freshcart_flutter/core/server/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_client.dart';
import '../../fakes/fake_connectivity_adapter.dart';

/// The app started without reaching the server: the session saved on the
/// phone is there, the profile never loaded. Changes made now must still
/// be queued, by the session's user, instead of crashing (B.1).
void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository()
      ..user = const Err(Failure.network())
      ..session = UserId('user-1');
    final client = FakeClient()
      // Serverpod's "no response came back at all".
      ..handler = (_, _, _) =>
          throw const dto.ServerpodClientException('down', -1);
    final db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        serverpodClientProvider.overrideWithValue(client),
        appDatabaseProvider.overrideWithValue(db),
        connectivityAdapterProvider.overrideWithValue(
          FakeConnectivityAdapter(Stream.value(false)),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(auth.dispose);
  });

  test('adding an item queues it, added by the session\'s user', () async {
    final result = await container
        .read(itemRepositoryProvider)
        .add(
          listId: ListId('00000000-0000-4000-8000-000000000001'),
          name: 'Milk',
        );

    final item = result.valueOrNull;
    expect(item?.pending, isTrue);
    expect(item?.addedBy, UserId('user-1'));
  });

  test('creating a list queues it, owned by the session\'s user', () async {
    final result = await container
        .read(listRepositoryProvider)
        .create(name: 'Groceries');

    final list = result.valueOrNull;
    expect(list?.pending, isTrue);
    expect(list?.ownerId, UserId('user-1'));
  });
}
