import 'package:serverpod_auth_idp_server/core.dart';

/// Endpoint to refresh login tokens. The app uses it automatically.
/// Just extending [RefreshJwtTokensEndpoint] is enough.
class JwtRefreshEndpoint extends RefreshJwtTokensEndpoint {}
