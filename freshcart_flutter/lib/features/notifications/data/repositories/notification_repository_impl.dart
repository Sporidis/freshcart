import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/notifications/data/mappers/notification_preferences_mapper.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/unconfigured_push_token_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_repository_impl.g.dart';

/// The real [NotificationRepository], talking to the Serverpod server.
///
/// ## Known limitation
///
/// On an iPhone in the EU, the web app (PWA) can't get push notifications.
/// Live updates inside the app still work (they come from Serverpod, not
/// from here). Real iOS push needs the native app and a paid Apple
/// Developer account (decisions.md #8). [isSupported] says when push isn't
/// possible, so the UI doesn't show settings that won't work.
class NotificationRepositoryImpl implements NotificationRepository {
  /// Creates the repository against a client and a token source.
  const NotificationRepositoryImpl(this._client, this._tokens);

  final dto.Client _client;
  final PushTokenSource _tokens;

  @override
  Future<bool> isSupported() => _tokens.isSupported();

  @override
  Future<Result<void>> registerDevice() => _guard(() async {
    final token = await _tokens.token();
    // No token isn't an error: it's normal on a platform without push
    // (isSupported already says so).
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

/// Which platform the app runs on (sent when registering the device).
@Riverpod(keepAlive: true)
dto.DevicePlatform devicePlatform(Ref ref) {
  if (kIsWeb) return dto.DevicePlatform.web;
  return Platform.isIOS ? dto.DevicePlatform.ios : dto.DevicePlatform.android;
}

/// Supplies the [PushTokenSource].
///
/// `main.dart` overrides it: Firebase on Android/iOS, a placeholder on web.
@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(Ref ref) =>
    UnconfiguredPushTokenSource(ref.watch(devicePlatformProvider));

/// Supplies the [NotificationRepository] (the push repository).
@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepositoryImpl(
      ref.watch(serverpodClientProvider),
      ref.watch(pushTokenSourceProvider),
    );
