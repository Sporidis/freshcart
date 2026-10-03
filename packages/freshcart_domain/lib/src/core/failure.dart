import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// An error we expect can happen (no internet, not found...).
///
/// Repositories and use cases return these inside a [Result] instead of
/// throwing, so the compiler makes callers handle them. Exceptions are only
/// for real bugs (decisions.md #9).
///
/// The UI turns a [Failure] into a translated message before showing it.
@freezed
sealed class Failure with _$Failure {
  /// Couldn't reach the server, or it didn't answer.
  const factory Failure.network([String? message]) = NetworkFailure;

  /// The thing doesn't exist, or this user can't see it.
  const factory Failure.notFound() = NotFoundFailure;

  /// Not signed in, or not allowed to do this.
  const factory Failure.unauthorized() = UnauthorizedFailure;

  /// Someone else changed the same thing at the same time, so the server
  /// rejected this change. The caller undoes it on screen.
  const factory Failure.conflict() = ConflictFailure;

  /// The input broke a rule (like "name too long"). [field] says which field.
  const factory Failure.validation(String field, String message) =
      ValidationFailure;

  /// Anything else (a bug). [cause] is for logging, never shown to users.
  const factory Failure.unexpected([Object? cause]) = UnexpectedFailure;
}
