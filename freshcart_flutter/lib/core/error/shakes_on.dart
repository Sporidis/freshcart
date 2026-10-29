import 'package:freshcart_domain/freshcart_domain.dart';

/// Whether the text field should shake for this error.
///
/// Shaking means "you typed something wrong". So it only shakes for user
/// mistakes, not for things like no internet or an expired invite.
bool shakesOn(Failure failure) => switch (failure) {
  ValidationFailure() || NotFoundFailure() => true,
  NetworkFailure() || UnauthorizedFailure() => false,
  ConflictFailure() || UnexpectedFailure() => false,
  // The user has to wait, not retype.
  RateLimitedFailure() => false,
};
