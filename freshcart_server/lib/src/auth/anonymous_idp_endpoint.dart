import 'package:serverpod_auth_idp_server/providers/anonymous.dart';

/// Endpoint for anonymous login.
///
/// Users get an account on first launch, without a signup form. Later they
/// can link email or Google to the same `authUserId` (decisions.md #6).
/// Every endpoint requires login, so without this the app couldn't call
/// anything.
///
/// Just extending the base class is enough to make it available.
class AnonymousIdpEndpoint extends AnonymousIdpBaseEndpoint {}
