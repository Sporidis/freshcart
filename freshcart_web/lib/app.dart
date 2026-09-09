import 'package:freshcart_web/components/footer.dart';
import 'package:freshcart_web/components/header.dart';
import 'package:freshcart_web/pages/home.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The marketing site.
///
/// Multi-page routing, so this component runs only on the server during
/// pre-rendering. Nothing here is interactive, which is the point: a
/// marketing page should be HTML a crawler can read, not an application that
/// happens to render text (`docs/decisions.md` #11).
class App extends StatelessComponent {
  /// Creates the site root.
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'main', [
      const SiteHeader(),
      main_([
        Router(
          routes: [
            Route(
              path: '/',
              title: 'FreshCart',
              builder: (context, state) => const Home(),
            ),
          ],
        ),
      ]),
      const SiteFooter(),
    ]);
  }
}
