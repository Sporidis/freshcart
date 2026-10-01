import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `EditProfileScreen` renders, already derived.
///
/// Only what `build()` can recompute from the profile. The name/avatar
/// saving flags and their errors are *not* here, for the same reason as
/// `ListSettingsScreenState`: this state is rebuilt every time the profile
/// changes -- including the publish that a save itself triggers -- which
/// would reset a flag mid-save.
class EditProfileScreenState {
  const EditProfileScreenState({this.user, this.loadFailure});

  /// The signed-in user; null until the profile has loaded.
  final AuthUser? user;

  /// The profile failed to load at all: the screen tier, replacing the form.
  final Failure? loadFailure;
}
