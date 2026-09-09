import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_client/freshcart_client.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/anonymous_session_bootstrap.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register plural rules for the locales slang does not ship (nl, tl) before
  // anything renders. See docs/decisions.md #25.
  configurePluralResolvers();

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
  await AnonymousSessionBootstrap.ensureSignedIn(client);

  runApp(
    ProviderScope(
      // The one place the client is constructed. Everything else reaches it
      // through the provider, so a test can substitute a fake without the app
      // knowing (docs/architecture.md, and the FakeClient in test/fakes).
      overrides: [serverpodClientProvider.overrideWithValue(client)],
      child: const FreshCartApp(),
    ),
  );
}
