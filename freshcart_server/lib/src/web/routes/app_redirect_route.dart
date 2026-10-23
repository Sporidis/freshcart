import 'package:serverpod/serverpod.dart';

/// Sends visitors of the server's root to the Flutter web app at `/app`.
class AppRedirectRoute extends WidgetRoute {
  @override
  Future<WebWidget> build(Session session, Request request) async =>
      RedirectWidget(url: '/app');
}
