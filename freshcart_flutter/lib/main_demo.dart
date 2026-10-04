import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_phone.dart';
import 'package:freshcart_flutter/demo/multi_view_app.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The web demo: two FreshCart phones from one Flutter engine (multi-view),
/// on one in-memory backend, so a change on one phone shows on the other.
///
/// The host page starts the engine with `multiViewEnabled: true` and adds
/// one view per phone. See docs/web-demo-plan.md.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Same as main.dart: Dutch and Tagalog plural rules (decisions.md #25).
  configurePluralResolvers();

  // The demo is embedded in another site, so go_router must never touch
  // that page's address bar or history. `null` turns that off entirely.
  setUrlStrategy(null);

  final backend = DemoBackend(clock: systemClock);

  // runWidget, not runApp: runApp needs the single "implicit" view, which
  // doesn't exist in multi-view mode.
  runWidget(MultiViewApp(viewBuilder: (_) => DemoPhone(backend: backend)));
}
