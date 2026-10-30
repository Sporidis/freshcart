import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show EmailAccountRequestException, EmailAccountRequestExceptionReason;

/// Turns any exception from the server or network into a domain [Failure].
///
/// This is the only place that knows about Serverpod's exception types.
/// Everything above the `data/` layer only sees [Failure], so the backend
/// could be replaced without changing the rest of the app. See decisions.md #2.
Failure mapExceptionToFailure(Object error) => switch (error) {
  // Our own exceptions, thrown on purpose by the server.
  dto.ListNotFoundException() ||
  dto.ItemNotFoundException() ||
  dto.ShopNotFoundException() => const Failure.notFound(),
  dto.NotAMemberException() ||
  dto.NotListOwnerException() => const Failure.unauthorized(),
  dto.EditConflictException() => const Failure.conflict(),
  dto.ValidationException(:final kind, :final input, :final limit) =>
    switch (ValidationIssueWire.fromWire(
      kind: kind,
      input: input,
      limit: limit,
    )) {
      final issue? => Failure.validation(issue),
      // A newer server's rule this version doesn't know yet.
      null => Failure.unexpected(error),
    },
  dto.InvalidJoinCodeException() => const Failure.validation(
    ValidationIssue.notFound(ValidatedInput.joinCode),
  ),
  // Too many failed joins: says nothing about the code just tried.
  dto.TooManyJoinAttemptsException() => const Failure.rateLimited(),
  // The owner tried to leave (the app only offers it to other members, so
  // this is a queued "leave" replayed after they became owner): a conflict,
  // so the replayer drops it instead of retrying it forever.
  dto.OwnerCannotLeaveException() => const Failure.conflict(),
  // Serverpod's email sign-up steps, used to link an email. The reason is
  // deliberately vague (no hint whether an address has an account).
  EmailAccountRequestException(:final reason) => switch (reason) {
    // Both happen at the code step and have the same fix: a new code.
    EmailAccountRequestExceptionReason.invalid ||
    EmailAccountRequestExceptionReason.expired => const Failure.validation(
      ValidationIssue.invalidFormat(ValidatedInput.verificationCode),
    ),
    // The app checks the password with the server's rule first, so in
    // practice this is a malformed address at the start.
    EmailAccountRequestExceptionReason.policyViolation =>
      const Failure.validation(
        ValidationIssue.invalidFormat(ValidatedInput.email),
      ),
    EmailAccountRequestExceptionReason.tooManyAttempts =>
      const Failure.rateLimited(),
    // A reason this version doesn't know (a newer server).
    EmailAccountRequestExceptionReason.unknown => Failure.unexpected(error),
  },

  // Serverpod's built-in HTTP errors.
  dto.ServerpodClientUnauthorized() ||
  dto.ServerpodClientForbidden() => const Failure.unauthorized(),
  dto.ServerpodClientNotFound() => const Failure.notFound(),
  // Only "no answer at all" is a network failure; an error the server
  // answered with (a 500) is a bug on its side.
  dto.ServerpodClientException() =>
    isUnreachable(error)
        ? Failure.network(error.toString())
        : Failure.unexpected(error),

  // The request took too long.
  TimeoutException() => Failure.network(error.toString()),

  // Live updates use a separate WebSocket. When it drops, it throws this
  // instead of the HTTP errors above.
  dto.MethodStreamException() => Failure.network(error.toString()),

  // Anything else is a bug. Keep the original error so it can be logged.
  _ => Failure.unexpected(error),
};

/// Runs [body], and tries again if the server couldn't be reached.
///
/// Tries at most [maxAttempts] times in total. Any other error is rethrown
/// straight away.
Future<T> retryOnUnreachable<T>(
  Future<T> Function() body, {
  int maxAttempts = 2,
}) async {
  try {
    return await body();
  } on Object catch (error) {
    if (isUnreachable(error) && maxAttempts > 1) {
      return await retryOnUnreachable(body, maxAttempts: maxAttempts - 1);
    }
    rethrow;
  }
}

/// Whether [error] means we couldn't reach the server at all.
///
/// Serverpod uses status code -1 when no response came back.
bool isUnreachable(Object error) =>
    (error is dto.ServerpodClientException && error.statusCode == -1) ||
    error is TimeoutException;
