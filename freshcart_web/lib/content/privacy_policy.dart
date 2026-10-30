/// The privacy policy as data: headings, paragraphs and lists, one instance
/// per language. The page only lays it out, so the two languages can't end
/// up with a different structure.
class PrivacyPolicy {
  /// Creates a policy text.
  const PrivacyPolicy({
    required this.languageCode,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  /// `en` or `nl`, for the page's `lang` attribute.
  final String languageCode;

  /// The page heading.
  final String title;

  /// "Last updated: …", shown under the heading.
  final String lastUpdated;

  /// The opening paragraph.
  final String intro;

  /// The numbered sections, in order.
  final List<PolicySection> sections;
}

/// One section: a heading and its paragraphs and lists.
class PolicySection {
  /// Creates a section.
  const PolicySection(this.heading, this.blocks);

  /// The section heading.
  final String heading;

  /// What the section says, in order.
  final List<PolicyBlock> blocks;
}

/// A paragraph or a bulleted list.
sealed class PolicyBlock {
  const PolicyBlock();
}

/// A plain paragraph.
final class Paragraph extends PolicyBlock {
  /// Creates a paragraph.
  const Paragraph(this.text);

  /// The paragraph's text.
  final String text;
}

/// A bulleted list.
final class Bullets extends PolicyBlock {
  /// Creates a list.
  const Bullets(this.items);

  /// One string per bullet.
  final List<String> items;
}

/// Facts the policy states in every language, kept in one place.
abstract final class PolicyFacts {
  /// Who is responsible for the data (the controller).
  static const String controller = 'Nikolaos Sporidis';

  /// Where the controller is based.
  static const String place = 'Roeselare, Belgium';

  /// Where privacy questions and requests go.
  static const String contactEmail = 'nikosporidis@gmail.com';

  /// Who runs the server and the database (the hosting processor). Where
  /// it is, is said in each language's own words.
  static const String hosting = 'Oracle Cloud Infrastructure';
}
