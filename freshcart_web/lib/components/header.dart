import 'package:freshcart_web/constants/site.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The site header.
class SiteHeader extends StatelessComponent {
  /// Creates the header.
  const SiteHeader({super.key});

  @override
  Component build(BuildContext context) {
    return const header(classes: 'site', [
      span(attributes: {'aria-hidden': 'true'}, [Component.text('🧺')]),
      span(classes: 'wordmark', [Component.text(Site.name)]),
    ]);
  }
}
