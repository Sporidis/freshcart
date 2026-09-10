import 'package:freshcart_domain/freshcart_domain.dart';

/// Where a failure arose.
///
/// This is the discriminator the design's error rule actually turns on, and it
/// is not the same question as *what went wrong*. A [NotFoundFailure] from a
/// join code the user just typed is a correctable typo shown inline; the same
/// failure from the list they are looking at means the list is gone and there
/// is nothing left to render. One failure, two tiers, decided by origin.
enum FailureSource {
  /// Something the user just typed or submitted, and can retype.
  input,

  /// A write against data already on screen. The screen survives it.
  write,

  /// The screen's own data. Without it there is nothing to show.
  load,
}

/// How a failure should be presented.
///
/// The design's §19 rule, in one place: *three tiers, chosen by whether the
/// user can act*. Keeping the choice here rather than at each call site is
/// what stops the app growing three subtly different answers to "the server
/// said no".
enum ErrorTier {
  /// Beside the field that caused it, which keeps their text to correct.
  inline,

  /// A snackbar over a screen that is otherwise fine.
  snackbar,

  /// A full screen, because nothing else can be shown.
  screen,
}

/// Picks the tier for [failure], given where it came from.
///
/// A [ValidationFailure] is always inline regardless of origin: it names a
/// field and carries an actionable message, so burying it in a snackbar would
/// throw away the only part of it the user can act on.
ErrorTier tierFor(Failure failure, FailureSource source) =>
    switch ((failure, source)) {
      (ValidationFailure(), _) => ErrorTier.inline,
      (_, FailureSource.input) => ErrorTier.inline,
      (_, FailureSource.write) => ErrorTier.snackbar,
      (_, FailureSource.load) => ErrorTier.screen,
    };

/// Whether a failure shown inline should also shake the field.
///
/// The shake says "look again, you can fix this". A failure that is not the
/// user's typo — an expired invite, a server that cannot be reached — gets the
/// message without the reprimand, per the design's note that an expired code
/// "isn't a typo".
bool shakesOn(Failure failure) => switch (failure) {
  ValidationFailure() || NotFoundFailure() => true,
  NetworkFailure() || UnauthorizedFailure() => false,
  ConflictFailure() || UnexpectedFailure() => false,
};
