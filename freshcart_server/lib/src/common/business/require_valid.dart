import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/generated/protocol.dart';

/// The value a domain rule accepted (for a name: trimmed), or throws a
/// [ValidationException] with the rule's own field and message, so the app
/// shows exactly what its own check would have.
T requireValid<T>(domain.Result<T> result) => switch (result) {
  domain.Ok(:final value) => value,
  domain.Err(failure: domain.ValidationFailure(:final field, :final message)) =>
    throw ValidationException(
      field: field,
      message: message,
    ),
  domain.Err(:final failure) => throw StateError(
    'A domain rule returned $failure',
  ),
};
