import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One feature on the home page.
///
/// An `<article>` with a real `<h3>`, so search engines understand the
/// structure (decisions.md #11).
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

  /// The short description under the heading.
  final String body;

  /// A decorative emoji, hidden from screen readers.
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
