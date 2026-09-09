import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Turns a [Failure] into something a person can read.
///
/// The only place this translation happens. Keeping it out of the widgets means
/// a new [Failure] case is one exhaustive `switch` to update, and the compiler
/// points at it.
extension FailureMessage on Failure {
  /// The localized message for this failure.
  String toMessage(Translations t) => switch (this) {
    NetworkFailure() => t.errors.network,
    NotFoundFailure() => t.errors.notFound,
    UnauthorizedFailure() => t.errors.unauthorized,
    ConflictFailure() => t.errors.conflict,
    // A validation failure already carries a specific, actionable message from
    // the domain, so it is shown rather than replaced with a generic one.
    ValidationFailure(:final message) => message,
    UnexpectedFailure() => t.errors.unexpected,
  };
}
