import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

/// The signed-in user's id, as the server sees it.
///
/// Needed by the optimistic paths: to show "you ticked this" before the server
/// has answered, the client has to know who it is. The id is minted server-side
/// and derived from the session, never asserted by the client.
///
/// Only the id, deliberately. The full [AuthUser] — display name, whether the
/// account is still anonymous — arrives in phase 10, when linking a provider
/// makes `isAnonymous` a question worth answering. Inventing a value for it now
/// would be a lie the compiler could not catch later.
@Riverpod(keepAlive: true)
Future<Result<UserId>> currentUserId(Ref ref) async {
  final client = ref.watch(serverpodClientProvider);
  try {
    final me = await client.profile.me();
    return Ok(UserId(me.userId.uuid));
  } on Object catch (error) {
    return Err(mapExceptionToFailure(error));
  }
}
