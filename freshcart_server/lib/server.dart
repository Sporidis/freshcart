import 'dart:io';

import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/auth/business/brevo_email_sender.dart';
import 'package:freshcart_server/src/auth/business/email_sender.dart';
import 'package:freshcart_server/src/generated/endpoints.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/fcm_push_sender.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/notifications/future_calls/flush_notifications_call.dart';
import 'package:freshcart_server/src/web/routes/app_config_route.dart';
import 'package:freshcart_server/src/web/routes/app_redirect_route.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Set up login. Token managers create and check login keys; identity
  // providers are the ways users can log in. The same setup is used by the
  // integration tests.
  pod.initializeAuthServices(
    tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
    identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
  );

  // Item changes are collected and sent as one push notification per list
  // (every 20 seconds), instead of one per change.
  pod.registerFutureCall(
    FlushNotificationsCall(),
    NotificationService.flushCallName,
  );

  // Real push (FCM) if a Firebase service-account key file exists.
  // Without it, notifications are only logged, and the server still starts
  // (decisions.md #7).
  final fcmSender = await FcmPushSender.tryCreate(
    'config/firebase-service-account.json',
  );
  if (fcmSender != null) {
    NotificationService.sender = fcmSender;
  }

  // Real email (Brevo) if passwords.yaml has a key and a verified sender.
  // Without them, emails are only logged, which the check before
  // pod.start() allows only in development and test.
  final brevoApiKey = pod.getPassword('brevoApiKey');
  final brevoSenderEmail = pod.getPassword('brevoSenderEmail');
  if (brevoApiKey != null && brevoSenderEmail != null) {
    AuthConfiguration.emailSender = BrevoEmailSender(
      apiKey: brevoApiKey,
      senderEmail: brevoSenderEmail,
    );
  }

  pod.webServer.addRoute(AppRedirectRoute(), '/');
  pod.webServer.addRoute(AppRedirectRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // The "build the Flutter app" page below uses its stylesheet and logo.
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

  // Last, once everything is configured: the logging email sender writes
  // verification codes to the log, so only development and test may run
  // with it. Staging counts as production.
  const logOnlyEmailModes = {
    ServerpodRunMode.development,
    ServerpodRunMode.test,
  };
  if (!logOnlyEmailModes.contains(pod.runMode) &&
      AuthConfiguration.emailSender is LoggingEmailSender) {
    throw StateError(
      'Run mode "${pod.runMode}" needs a real EmailSender, but '
      'AuthConfiguration.emailSender is LoggingEmailSender, which would '
      'write verification codes to the log. Configure an email provider '
      'before deploying.',
    );
  }

  // Start the server.
  await pod.start();
}
