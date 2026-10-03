import 'package:freshcart_web/components/feature_card.dart';
import 'package:freshcart_web/constants/site.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The home page.
///
/// A normal `StatelessComponent`, not `@client`: nothing on it is
/// interactive, so no JavaScript is needed. It's all built into HTML
/// ahead of time.
class Home extends StatelessComponent {
  /// Creates the landing page.
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // Title and description for THIS page (not the whole site). The most
      // important thing for search engines.
      Document.head(
        title: '${Site.name} — ${Site.tagline}',
        // Only `name=` meta tags go in this map. Open Graph tags use
        // `property=`, which this map can't do, so they're added separately
        // below.
        meta: {
          'description': Site.tagline,
          'twitter:card': 'summary_large_image',
          'twitter:title': Site.name,
          'twitter:description': Site.tagline,
        },
        children: [
          const link(rel: 'canonical', href: Site.canonicalUrl),
          for (final entry in const {
            'og:title': Site.name,
            'og:description': Site.description,
            'og:type': 'website',
            'og:url': Site.canonicalUrl,
            'og:locale': 'en',
          }.entries)
            meta(attributes: {'property': entry.key, 'content': entry.value}),
          // Structured data (JSON-LD), so search engines know exactly what
          // this page is about and can show a richer result.
          const script(
            attributes: {'type': 'application/ld+json'},
            content: _structuredData,
          ),
        ],
      ),
      section(classes: 'hero', [
        const h1([Component.text(Site.name)]),
        const p(classes: 'tagline', [Component.text(Site.tagline)]),
        const p(classes: 'cta-row', [
          a(href: '/app', classes: 'cta', [Component.text('Open the app')]),
        ]),
        p(classes: 'languages', [
          Component.text('Available in ${Site.languages.join(' · ')}'),
        ]),
      ]),
      section(classes: 'features', [
        const h2([
          Component.text('Built for the way households actually shop'),
        ]),
        div(classes: 'feature-grid', [
          const FeatureCard(
            icon: '⚡',
            title: 'Live, not eventually',
            body:
                'Tick something off and it disappears from everyone else\'s '
                'list straight away. No refreshing, no arguing over who '
                'bought the milk.',
          ),
          FeatureCard(
            icon: '🔗',
            title: 'Share with a ${Site.joinCodeLength}-character code',
            body:
                'No accounts to create, no invitations to accept. Read the '
                'code out loud and they are in.',
          ),
          const FeatureCard(
            icon: '🎨',
            title: 'Follows the shop you are in',
            body:
                'Tag items to a shop and filter to it. The whole app takes '
                'on that shop\'s colour, so a glance tells you where you are.',
          ),
          const FeatureCard(
            icon: '📝',
            title: 'Notes that prevent the wrong purchase',
            body:
                'Add "the oat one, not soy" to an item so nobody has to '
                'send a photo from the aisle.',
          ),
        ]),
      ]),
      section(classes: 'how', [
        const h2([Component.text('How it works')]),
        ol([
          const li([
            Component.text(
              'Open the app. You get a working list immediately — there '
              'is no sign-up form.',
            ),
          ]),
          li([
            Component.text(
              'Create a list and share its '
              '${Site.joinCodeLength}-character code.',
            ),
          ]),
          const li([
            Component.text(
              'Everyone adds, ticks off and annotates. Changes appear as '
              'they happen.',
            ),
          ]),
        ]),
      ]),
    ]);
  }

  static const String _structuredData = '''
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "FreshCart",
  "applicationCategory": "LifestyleApplication",
  "operatingSystem": "Android, iOS, Web",
  "offers": { "@type": "Offer", "price": "0", "priceCurrency": "EUR" }
}''';
}
