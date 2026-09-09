import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// An *expected* failure that crosses a layer boundary.
///
/// Repositories and use cases return these inside a [Result] rather than
/// throwing, so the compiler forces callers to handle them. Exceptions stay
/// reserved for genuine programmer errors (see `docs/decisions.md` #9).
///
/// Presentation maps a [Failure] to a localized message; it never renders one
/// directly.
@freezed
sealed class Failure with _$Failure {
  /// The request could not reach the server, or the server never answered.
  const factory Failure.network([String? message]) = NetworkFailure;

  /// The requested resource does not exist, or is not visible to this user.
  const factory Failure.notFound() = NotFoundFailure;

  /// The caller is not signed in, or lacks permission for this resource.
  const factory Failure.unauthorized() = UnauthorizedFailure;

  /// The write clashed with a concurrent change — an optimistic update that the
  /// server rejected. Callers roll their local change back.
  const factory Failure.conflict() = ConflictFailure;

  /// Input rejected by a domain invariant, naming the offending [field].
  const factory Failure.validation(String field, String message) =
      ValidationFailure;

  /// Anything unanticipated. [cause] is for logging, never for display.
  const factory Failure.unexpected([Object? cause]) = UnexpectedFailure;
}
