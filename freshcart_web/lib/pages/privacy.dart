import 'package:freshcart_web/constants/site.dart';
import 'package:freshcart_web/content/privacy_policy.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The privacy policy page, in one language.
///
/// Plain, pre-rendered HTML like the rest of the site: headings, paragraphs
/// and lists, readable without JavaScript. The text itself lives in
/// `content/`, one file per language.
class PrivacyPage extends StatelessComponent {
  /// Creates the page for [policy].
  const PrivacyPage({required this.policy, required this.otherLanguage});

  /// The text to show.
  final PrivacyPolicy policy;

  /// A link to the same policy in the other language: (label, path).
  final (String, String) otherLanguage;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(
        title: '${policy.title} — ${Site.name}',
        meta: {'description': policy.intro},
      ),
      article(
        classes: 'policy',
        attributes: {'lang': policy.languageCode},
        [
          h1([Component.text(policy.title)]),
          p(classes: 'updated', [
            Component.text(policy.lastUpdated),
            const Component.text(' · '),
            a(href: otherLanguage.$2, [Component.text(otherLanguage.$1)]),
          ]),
          p([Component.text(policy.intro)]),
          for (final section in policy.sections) ...[
            h2([Component.text(section.heading)]),
            for (final block in section.blocks)
              switch (block) {
                Paragraph(:final text) => p([Component.text(text)]),
                Bullets(:final items) => ul([
                  for (final item in items) li([Component.text(item)]),
                ]),
              },
          ],
        ],
      ),
    ]);
  }
}
