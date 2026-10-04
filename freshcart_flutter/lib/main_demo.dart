import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_overrides.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The web demo: the real app on in-memory fakes, no server needed.
///
/// Phase D2 shape: one phone (persona A). D3 turns this into two views of
/// one engine. See docs/web-demo-plan.md.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Same as main.dart: Dutch and Tagalog plural rules (decisions.md #25).
  configurePluralResolvers();

  // The demo is embedded in another site, so go_router must never touch
  // that page's address bar or history. `null` turns that off entirely.
  setUrlStrategy(null);

  final db = DemoBackend(clock: systemClock);
  runApp(
    UncontrolledProviderScope(
      container: createPhoneContainer(db, DemoPersona.a),
      child: const FreshCartApp(),
    ),
  );
}
