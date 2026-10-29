import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/core/validation_issue.dart';

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
  /// Couldn't reach the server at all, e.g., no internet or server down.
  const factory Failure.network([String? message]) = NetworkFailure;

  /// The thing doesn't exist, or this user can't see it.
  const factory Failure.notFound() = NotFoundFailure;

  /// Not signed in, or not allowed to do this.
  const factory Failure.unauthorized() = UnauthorizedFailure;

  /// Someone else changed the same thing at the same time, so the server
  /// rejected this change. The caller undoes it on screen.
  const factory Failure.conflict() = ConflictFailure;

  /// The input broke a rule. [issue] says which input and what's wrong,
  /// as data: the app turns it into text in the user's language.
  const factory Failure.validation(ValidationIssue issue) = ValidationFailure;

  /// Too many tries in a short time; the server refuses more for a while.
  /// The user should wait, not change what they typed.
  const factory Failure.rateLimited() = RateLimitedFailure;

  /// Anything else (a bug). [cause] is for logging, never shown to users.
  const factory Failure.unexpected([Object? cause]) = UnexpectedFailure;
}
