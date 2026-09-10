import 'dart:io';

import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/generated/endpoints.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/fcm_push_sender.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/notifications/future_calls/flush_notifications_call.dart';
import 'package:freshcart_server/src/web/routes/app_config_route.dart';
import 'package:freshcart_server/src/web/routes/root.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  // Shared with the integration tests, so both run the same providers.
  pod.initializeAuthServices(
    tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
    identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
  );

  // Buffered item changes are summarised into one push per list per window.
  pod.registerFutureCall(
    FlushNotificationsCall(),
    NotificationService.flushCallName,
  );

  // Real FCM delivery once a service-account key exists; every developer
  // without one keeps the logging sender, and the server still starts
  // (docs/decisions.md #7).
  final fcmSender = await FcmPushSender.tryCreate(
    'config/firebase-service-account.json',
  );
  if (fcmSender != null) {
    NotificationService.sender = fcmSender;
  }

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Start the server.
  await pod.start();
}
