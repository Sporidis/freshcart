import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serverpod_client_provider.g.dart';

/// The single Serverpod [dto.Client] for the whole app.
///
/// Deliberately unimplemented here and overridden at the root `ProviderScope`.
/// The client needs a server URL that is only known asynchronously at startup
/// (`--dart-define`, then `assets/config.json`, then a localhost default), and
/// resolving that inside a provider would make every consumer async for no
/// benefit. Overriding also means a widget test can inject a fake client
/// without touching the network.
///
/// `keepAlive` because the client owns a connection and an auth session; it
/// must outlive any single screen.
@Riverpod(keepAlive: true)
dto.Client serverpodClient(Ref ref) => throw UnimplementedError(
  'serverpodClientProvider must be overridden in the root ProviderScope',
);
