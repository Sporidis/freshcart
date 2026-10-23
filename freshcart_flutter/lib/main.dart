import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_client/freshcart_client.dart';
import 'package:freshcart_flutter/app/app.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/firebase_messaging_token_source.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';
import 'package:freshcart_flutter/features/notifications/data/sources/unconfigured_push_token_source.dart';
import 'package:freshcart_flutter/firebase_options.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // slang has no plural rules for Dutch and Tagalog, so we register our own.
  // Must happen before any text is shown. See decisions.md #25.
  configurePluralResolvers();

  // Push notifications only exist on Android and iOS, so the web build skips
  // Firebase completely. See decisions.md #7 and #8.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Where the server lives. Checked in this order:
  // 1. --dart-define=SERVER_URL
  // 2. assets/config.json
  // 3. http://localhost:8080/
  // On a real phone, localhost is the phone itself, so pass your computer's
  // LAN address with --dart-define.
  final serverUrl = await getServerUrl();

  final client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  // Web gets a placeholder that always says "push not supported".
  // Phones get the real Firebase one.
  final PushTokenSource tokenSource = kIsWeb
      ? const UnconfiguredPushTokenSource(DevicePlatform.web)
      : FirebaseMessagingTokenSource(
          Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        );

  // We create the ProviderContainer ourselves (instead of a plain
  // ProviderScope) so we can read providers below, before the UI exists.
  final container = ProviderContainer(
    // This is the only place the real client is created. Everything else gets
    // it through the provider, so tests can swap in a fake client.
    overrides: [
      serverpodClientProvider.overrideWithValue(client),
      pushTokenSourceProvider.overrideWithValue(tokenSource),
    ],
  );

  // Start signing in now, but don't wait for it. The SplashScreen shows while
  // sign-in is running. Starting it here, instead of letting the splash
  // screen start it, just saves one frame.
  unawaited(
    container.read(signInResultProvider.future).then((signIn) {
      // Registering for push needs a signed-in user, so it waits for sign-in.
      // We don't wait for it to finish: if it fails, the app still works,
      // the user just won't get push notifications.
      if (signIn.isOk) {
        unawaited(
          container.read(notificationRepositoryProvider).registerDevice(),
        );
      }
    }),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FreshCartApp(),
    ),
  );
}
