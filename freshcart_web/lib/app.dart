import 'package:freshcart_web/components/footer.dart';
import 'package:freshcart_web/components/header.dart';
import 'package:freshcart_web/content/privacy_policy_en.dart';
import 'package:freshcart_web/content/privacy_policy_nl.dart';
import 'package:freshcart_web/pages/home.dart';
import 'package:freshcart_web/pages/privacy.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The marketing website.
///
/// Only runs on the server, while the pages are built into HTML. Nothing is
/// interactive on purpose: search engines should get plain HTML they can
/// read, not an app (decisions.md #11).
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
            Route(
              path: '/privacy',
              title: 'Privacy policy',
              builder: (context, state) => const PrivacyPage(
                policy: privacyPolicyEn,
                otherLanguage: ('Nederlands', '/nl/privacy'),
              ),
            ),
            Route(
              path: '/nl/privacy',
              title: 'Privacybeleid',
              builder: (context, state) => const PrivacyPage(
                policy: privacyPolicyNl,
                otherLanguage: ('English', '/privacy'),
              ),
            ),
          ],
        ),
      ]),
      const SiteFooter(),
    ]);
  }
}
