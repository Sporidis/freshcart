import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/preferences/shared_preferences_store.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_flutter/demo/fakes/fake_auth_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_item_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_list_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_notification_repository.dart';
import 'package:freshcart_flutter/demo/fakes/fake_shop_repository.dart';
import 'package:freshcart_flutter/demo/fakes/in_memory_preferences_store.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/data/sources/avatar_photo_source.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';

/// Builds one demo phone: the real app's providers, with everything that
/// would reach a server, a database or the network swapped for the fakes
/// on [db], acting as [persona].
///
/// One function returning the container (not a `List<Override>`), because
/// Riverpod 3 doesn't export the `Override` type.
///
/// `serverpodClientProvider` is deliberately NOT overridden: it throws when
/// read, so any path we missed fails loudly instead of trying the network.
ProviderContainer createPhoneContainer(DemoBackend db, DemoPersona persona) {
  final me = persona.id;
  // Empty name and no colour, like a real first launch.
  db.users.putIfAbsent(
    me,
    () => AuthUser(
      id: me,
      displayName: '',
      isAnonymous: true,
    ),
  );

  return ProviderContainer(
    overrides: [
      listRepositoryProvider.overrideWithValue(FakeListRepository(db, me)),
      itemRepositoryProvider.overrideWithValue(FakeItemRepository(db, me)),
      shopRepositoryProvider.overrideWithValue(FakeShopRepository(db, me)),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(db, me)),
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      // Always online with nothing queued: no connectivity_plus, no drift.
      connectivityStatusProvider.overrideWith(
        (ref) => Stream.value(ConnectivityStatus.online),
      ),
      pendingWriteCountProvider.overrideWith((ref) => Stream.value(0)),
      replayQueueWhenOnlineProvider.overrideWith((ref) {}),
      // Don't open the photo picker only for the upload to be refused.
      avatarPhotoSourceProvider.overrideWithValue(const _NoAvatarPhotoSource()),
      // Each phone keeps its own settings, and none reach the host page's
      // localStorage.
      preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
    ],
  );
}

class _NoAvatarPhotoSource implements AvatarPhotoSource {
  const _NoAvatarPhotoSource();

  @override
  Future<Result<Uint8List?>> pick() async =>
      const Err(Failure.unexpected('Not available in the demo'));
}
