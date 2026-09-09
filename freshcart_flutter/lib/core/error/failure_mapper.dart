import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Translates transport-level errors into domain [Failure]s.
///
/// This is the *only* place Serverpod's exception types are interpreted.
/// Everything above `data/` sees a `Failure` and never learns that a network,
/// let alone Serverpod, was involved — which is what makes the backend
/// swappable (`docs/decisions.md` #2).
Failure mapExceptionToFailure(Object error) => switch (error) {
  // Exceptions the server declares in its protocol. These are the interesting
  // ones: they carry meaning the UI acts on.
  dto.ListNotFoundException() ||
  dto.ItemNotFoundException() => const Failure.notFound(),
  dto.NotAMemberException() => const Failure.unauthorized(),
  dto.EditConflictException() => const Failure.conflict(),
  dto.InvalidJoinCodeException() => const Failure.validation(
    'joinCode',
    'That code does not match a list',
  ),

  // Transport-level failures.
  dto.ServerpodClientUnauthorized() ||
  dto.ServerpodClientForbidden() => const Failure.unauthorized(),
  dto.ServerpodClientNotFound() => const Failure.notFound(),
  dto.ServerpodClientException() => Failure.network(error.toString()),

  // Anything else is a bug rather than an expected outcome, so it keeps its
  // cause for logging and shows a generic message.
  _ => Failure.unexpected(error),
};
