import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_client/freshcart_client.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/di/is_new_identity_provider.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/notifications/data/firebase_messaging_token_source.dart';
import 'package:freshcart_flutter/features/notifications/data/push_repository_provider.dart';
import 'package:freshcart_flutter/features/notifications/data/push_token_source.dart';
import 'package:freshcart_flutter/firebase_options.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register plural rules for the locales slang does not ship (nl, tl) before
  // anything renders. See docs/decisions.md #25.
  configurePluralResolvers();

  // Mobile only — FCM is scoped to Android/iOS (docs/decisions.md #7, #8);
  // the web build never touches firebase_core at all.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Resolved in order: --dart-define=SERVER_URL, then assets/config.json, then
  // http://localhost:8080/. On a physical device the default will not reach
  // your machine — pass your LAN address with --dart-define.
  final serverUrl = await getServerUrl();

  final client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  // Awaited on purpose: the session must exist before the first frame. Every
  // endpoint requires login, so without this the first list fetch would come
  // back unauthorized.
  final session = await AnonymousSessionBootstrap.ensureSignedIn(client);

  // web keeps the honest "unsupported" source (decisions.md #8); native
  // platforms get the real Firebase-backed one now that a project exists.
  final PushTokenSource tokenSource = kIsWeb
      ? const UnconfiguredPushTokenSource(DevicePlatform.web)
      : FirebaseMessagingTokenSource(
          Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
        );

  // An explicit container, not a plain ProviderScope, because registration
  // below needs to read a provider before the first frame exists.
  final container = ProviderContainer(
    // The one place the client is constructed. Everything else reaches it
    // through the provider, so a test can substitute a fake without the app
    // knowing (docs/architecture.md, and the FakeClient in test/fakes).
    overrides: [
      serverpodClientProvider.overrideWithValue(client),
      isNewIdentityProvider.overrideWithValue(session.isNewIdentity),
      pushTokenSourceProvider.overrideWithValue(tokenSource),
    ],
  );

  // Fire-and-forget: PushRepositoryImpl guards every call into a Result, and
  // a failed registration must never delay or block the first frame — the
  // app is fully usable without push, it just would not receive it.
  unawaited(container.read(pushRepositoryProvider).registerDevice());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FreshCartApp(),
    ),
  );
}
