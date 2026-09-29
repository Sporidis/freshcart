import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/notifications/data/mappers/notification_preferences_mapper.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository_impl.g.dart';

/// The Serverpod-backed [PushPort].
///
/// ## Documented platform limitation
///
/// iOS web push for installable PWAs is gated in the EU, so an EU iPhone user
/// on the free PWA install path will **not** receive background notifications.
/// Live in-app updates still work for them — those come from the Serverpod
/// stream, not from here. Real iOS background push needs a native build and a
/// paid Apple Developer account, which is deferred
/// (`docs/decisions.md` #8). [isSupported] reports this honestly so the UI can
/// avoid offering a setting the platform will ignore.
class PushRepositoryImpl implements PushPort {
  /// Creates the repository against a client and a token source.
  const PushRepositoryImpl(this._client, this._tokens);

  final dto.Client _client;
  final PushTokenSource _tokens;

  @override
  Future<bool> isSupported() => _tokens.isSupported();

  @override
  Future<Result<void>> registerDevice() => _guard(() async {
    final token = await _tokens.token();
    // No token is not a failure: it is the expected state on a platform that
    // cannot deliver push. The caller has already been told via isSupported.
    if (token == null) return;
    await _client.notification.registerDevice(token, _tokens.platform);
  });

  @override
  Future<Result<void>> unregisterDevice() => _guard(() async {
    final token = await _tokens.token();
    if (token == null) return;
    await _client.notification.unregisterDevice(token);
  });

  @override
  Future<Result<void>> setListMuted(ListId listId, {required bool muted}) =>
      _guard(
        () => _client.notification.setListMuted(
          dto.UuidValue.withValidation(listId.value),
          muted,
        ),
      );

  @override
  Future<Result<bool>> isListMuted(ListId listId) => _guard(
    () => _client.notification.isListMuted(
      dto.UuidValue.withValidation(listId.value),
    ),
  );

  @override
  Future<Result<NotificationPreferences>> notificationPreferences() => _guard(
    () async => (await _client.notification.preferences()).toDomain(),
  );

  @override
  Future<Result<NotificationPreferences>> setItemAddedNotificationsEnabled(
    bool value,
  ) => _guard(
    () async =>
        (await _client.notification.setItemAddedEnabled(value)).toDomain(),
  );

  @override
  Future<Result<NotificationPreferences>> setMemberJoinedNotificationsEnabled(
    bool value,
  ) => _guard(
    () async =>
        (await _client.notification.setMemberJoinedEnabled(value)).toDomain(),
  );

  @override
  Future<Result<NotificationPreferences>> setListFinishedNotificationsEnabled(
    bool value,
  ) => _guard(
    () async =>
        (await _client.notification.setListFinishedEnabled(value)).toDomain(),
  );

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}

/// Which platform this build is running on, for device registration.
@Riverpod(keepAlive: true)
dto.DevicePlatform devicePlatform(Ref ref) {
  if (kIsWeb) return dto.DevicePlatform.web;
  return Platform.isIOS ? dto.DevicePlatform.ios : dto.DevicePlatform.android;
}

/// Supplies the device's push token.
///
/// Overridden with a Firebase-backed source once a project is configured; the
/// rest of the app is unaffected.
@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(Ref ref) =>
    UnconfiguredPushTokenSource(ref.watch(devicePlatformProvider));

/// Supplies the [PushPort].
@Riverpod(keepAlive: true)
PushPort pushRepository(Ref ref) => PushRepositoryImpl(
  ref.watch(serverpodClientProvider),
  ref.watch(pushTokenSourceProvider),
);
