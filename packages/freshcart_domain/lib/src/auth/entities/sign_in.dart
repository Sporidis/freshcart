import 'package:freshcart_domain/src/auth/entities/auth_user.dart';

/// Who is signed in after [AuthPort.ensureSignedIn], and whether that
/// account was only just created (first launch: show onboarding).
typedef SignIn = ({AuthUser user, bool isNewAccount});
