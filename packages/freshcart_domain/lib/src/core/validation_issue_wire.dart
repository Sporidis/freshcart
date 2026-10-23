import 'package:freshcart_domain/src/core/validation_issue.dart';

/// A [ValidationIssue] as three plain values, so it can cross the network:
/// the server sends them, the app rebuilds the issue with [fromWire].
extension ValidationIssueWire on ValidationIssue {
  /// Which case this is, as a name that never changes.
  String get kind => switch (this) {
    MissingInput() => 'missing',
    TooLongInput() => 'tooLong',
    TooShortInput() => 'tooShort',
    TooFewInput() => 'tooFew',
    TooLargeInput() => 'tooLarge',
    InvalidFormatInput() => 'invalidFormat',
    NotFoundInput() => 'notFound',
    AlreadyInUseInput() => 'alreadyInUse',
  };

  /// The case's number (a max, min or size), if it has one.
  int? get limit => switch (this) {
    TooLongInput(:final max) => max,
    TooShortInput(:final min) || TooFewInput(:final min) => min,
    TooLargeInput(:final maxBytes) => maxBytes,
    _ => null,
  };

  /// The issue that [kind], [input] and [limit] describe. Null when this
  /// version doesn't know them (a newer server added a case).
  static ValidationIssue? fromWire({
    required String kind,
    required String input,
    int? limit,
  }) {
    final validated = ValidatedInput.values.asNameMap()[input];
    if (validated == null) return null;
    return switch ((kind, limit)) {
      ('missing', _) => ValidationIssue.missing(validated),
      ('tooLong', final int max) => ValidationIssue.tooLong(
        validated,
        max: max,
      ),
      ('tooShort', final int min) => ValidationIssue.tooShort(
        validated,
        min: min,
      ),
      ('tooFew', final int min) => ValidationIssue.tooFew(validated, min: min),
      ('tooLarge', final int maxBytes) => ValidationIssue.tooLarge(
        validated,
        maxBytes: maxBytes,
      ),
      ('invalidFormat', _) => ValidationIssue.invalidFormat(validated),
      ('notFound', _) => ValidationIssue.notFound(validated),
      ('alreadyInUse', _) => ValidationIssue.alreadyInUse(validated),
      _ => null,
    };
  }
}
