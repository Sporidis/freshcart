import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One feature on the landing page.
///
/// Rendered as an `<article>` with a real `<h3>`: this is a content site, and
/// the semantic structure is the thing a crawler reads
/// (`docs/decisions.md` #11).
class FeatureCard extends StatelessComponent {
  /// Creates a card.
  const FeatureCard({
    required this.title,
    required this.body,
    required this.icon,
    super.key,
  });

  /// The feature's heading.
  final String title;

  /// The supporting sentence.
  final String body;

  /// A decorative emoji, hidden from assistive technology.
  final String icon;

  @override
  Component build(BuildContext context) {
    return article(classes: 'feature', [
      span(
        classes: 'feature-icon',
        attributes: {'aria-hidden': 'true'},
        [
          Component.text(icon),
        ],
      ),
      h3([Component.text(title)]),
      p([Component.text(body)]),
    ]);
  }
}
