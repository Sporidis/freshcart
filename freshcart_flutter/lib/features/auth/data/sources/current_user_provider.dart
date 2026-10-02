import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

/// The signed-in user's id, as the server sees it.
///
/// Needed to update the screen before the server answers. For example, to
/// show "you checked this" straight away, the app has to know who "you" is.
///
/// Only the id. For the full user (name, anonymous or not), use
/// `ProfileController`.
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
