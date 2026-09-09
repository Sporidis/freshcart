import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/notifications/data/push_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/push_token_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_repository_provider.g.dart';

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
