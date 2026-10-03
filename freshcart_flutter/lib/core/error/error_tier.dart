import 'package:freshcart_domain/freshcart_domain.dart';

/// Where an error came from.
///
/// This matters because the same error can need different handling. A
/// "not found" after typing a join code is just a typo. A "not found" for the
/// list you're looking at means the list is gone.
enum FailureSource {
  /// Something the user typed or submitted. They can fix it and try again.
  input,

  /// Saving a change to data that's already on screen. The screen stays.
  write,

  /// Loading the screen's own data. Without it, there's nothing to show.
  load,
}

/// How an error is shown to the user.
///
/// All screens decide this through [tierFor], so errors look the same
/// everywhere in the app.
enum ErrorTier {
  /// Under the text field that caused it, so the user can fix their input.
  inline,

  /// A snackbar at the bottom. The screen itself is still fine.
  snackbar,

  /// A full error screen, because there's nothing else to show.
  screen,
}

/// Picks how to show [failure], based on where it came from.
///
/// A [ValidationFailure] is always shown inline, because it points at a
/// specific field the user can fix.
ErrorTier tierFor(Failure failure, FailureSource source) =>
    switch ((failure, source)) {
      (ValidationFailure(), _) => ErrorTier.inline,
      (_, FailureSource.input) => ErrorTier.inline,
      (_, FailureSource.write) => ErrorTier.snackbar,
      (_, FailureSource.load) => ErrorTier.screen,
    };

/// Whether the text field should shake for this error.
///
/// Shaking means "you typed something wrong". So it only shakes for user
/// mistakes, not for things like no internet or an expired invite.
bool shakesOn(Failure failure) => switch (failure) {
  ValidationFailure() || NotFoundFailure() => true,
  NetworkFailure() || UnauthorizedFailure() => false,
  ConflictFailure() || UnexpectedFailure() => false,
};
