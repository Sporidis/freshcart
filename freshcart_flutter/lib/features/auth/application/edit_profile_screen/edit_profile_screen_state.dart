import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `EditProfileSheet` shows.
///
/// "Saving..." flags and save errors are NOT stored here. This state is
/// rebuilt every time the profile changes, and saving changes the profile.
/// So a flag stored here would be reset in the middle of saving. The
/// sheet keeps those flags itself instead (same as `ListSettingsScreenState`).
class EditProfileScreenState {
  const EditProfileScreenState({this.user, this.loadFailure});

  /// The signed-in user; null until the profile has loaded.
  final AuthUser? user;

  /// Set when the profile couldn't load. Then a full error screen is shown
  /// instead of the form.
  final Failure? loadFailure;
}
