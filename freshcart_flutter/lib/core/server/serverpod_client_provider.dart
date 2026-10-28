import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serverpod_client_provider.g.dart';

/// The one Serverpod [dto.Client] the whole app shares.
///
/// It throws on purpose: the real client is created in `main.dart` and
/// passed in with an override. That's because the server URL is only known
/// after startup. Tests override it with a fake client instead.
///
/// `keepAlive` because the client holds the connection and the login
/// session, so it must never be thrown away.
@Riverpod(keepAlive: true)
dto.Client serverpodClient(Ref ref) => throw UnimplementedError(
  'serverpodClientProvider must be overridden in the root ProviderScope',
);
