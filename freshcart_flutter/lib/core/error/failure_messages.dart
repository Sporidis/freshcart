import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/validation_messages.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Turns a [Failure] into a message the user can read.
///
/// This is the only place it happens. If a new kind of [Failure] is added,
/// the compiler will point here because the `switch` must cover every case.
extension FailureMessage on Failure {
  /// The translated message for this failure.
  String toMessage(Translations t) => switch (this) {
    NetworkFailure() => t.errors.network,
    NotFoundFailure() => t.errors.notFound,
    UnauthorizedFailure() => t.errors.unauthorized,
    ConflictFailure() => t.errors.conflict,
    ValidationFailure(:final issue) => issue.toMessage(t),
    RateLimitedFailure() => t.errors.rateLimited,
    UnexpectedFailure() => t.errors.unexpected,
  };
}
