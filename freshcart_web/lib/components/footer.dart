import 'package:freshcart_web/constants/site.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The site footer.
class SiteFooter extends StatelessComponent {
  /// Creates the footer.
  const SiteFooter({super.key});

  @override
  Component build(BuildContext context) {
    return const footer(classes: 'site', [
      p([Component.text('${Site.name} — built with Dart, end to end.')]),
      p([
        a(href: '/privacy', [Component.text('Privacy policy')]),
        Component.text(' · '),
        a(href: '/nl/privacy', [Component.text('Privacybeleid')]),
      ]),
    ]);
  }
}
