import 'package:freshcart_domain/src/auth/entities/auth_user.dart';

/// Who is signed in after [AuthRepository.ensureSignedIn], and whether they
/// have set up a profile yet (picked a name).
///
/// Not "is this account new": the account is created on first launch, so
/// after a restart halfway through onboarding it already exists.
typedef SignIn = ({AuthUser user, bool hasProfile});
