import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/notifications/data/push_token_source.dart';

/// The Serverpod-backed [PushPort].
///
/// ## Documented platform limitation
///
/// iOS web push for installable PWAs is gated in the EU, so an EU iPhone user
/// on the free PWA install path will **not** receive background notifications.
/// Live in-app updates still work for them — those come from the Serverpod
/// stream, not from here. Real iOS background push needs a native build and a
/// paid Apple Developer account, which is deferred
/// (`docs/decisions.md` #8). [isSupported] reports this honestly so the UI can
/// avoid offering a setting the platform will ignore.
class PushRepositoryImpl implements PushPort {
  /// Creates the repository against a client and a token source.
  const PushRepositoryImpl(this._client, this._tokens);

  final dto.Client _client;
  final PushTokenSource _tokens;

  @override
  Future<bool> isSupported() => _tokens.isSupported();

  @override
  Future<Result<void>> registerDevice() => _guard(() async {
    final token = await _tokens.token();
    // No token is not a failure: it is the expected state on a platform that
    // cannot deliver push. The caller has already been told via isSupported.
    if (token == null) return;
    await _client.notification.registerDevice(token, _tokens.platform);
  });

  @override
  Future<Result<void>> unregisterDevice() => _guard(() async {
    final token = await _tokens.token();
    if (token == null) return;
    await _client.notification.unregisterDevice(token);
  });

  @override
  Future<Result<void>> setListMuted(ListId listId, {required bool muted}) =>
      _guard(
        () => _client.notification.setListMuted(
          dto.UuidValue.withValidation(listId.value),
          muted,
        ),
      );

  @override
  Future<Result<bool>> isListMuted(ListId listId) => _guard(
    () => _client.notification.isListMuted(
      dto.UuidValue.withValidation(listId.value),
    ),
  );

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}
