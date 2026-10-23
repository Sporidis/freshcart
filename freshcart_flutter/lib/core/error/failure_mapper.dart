import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

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
  dto.NotAMemberException() => const Failure.unauthorized(),
  dto.EditConflictException() => const Failure.conflict(),
  // TODO: this message is hard-coded English, and `toMessage` shows a
  // validation message as-is, so nl/fr/ru/tl users see English here. Give
  // it a translation key (e.g. a failure the UI maps via `t.errors`).
  dto.InvalidJoinCodeException() => const Failure.validation(
    'joinCode',
    'That code does not match a list',
  ),

  // Serverpod's built-in HTTP errors.
  dto.ServerpodClientUnauthorized() ||
  dto.ServerpodClientForbidden() => const Failure.unauthorized(),
  dto.ServerpodClientNotFound() => const Failure.notFound(),
  dto.ServerpodClientException() => Failure.network(error.toString()),

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
