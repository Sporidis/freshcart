import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

/// How the domain asks for background push, without naming a vendor.
///
/// The only implementation is an FCM adapter, and it is the only place Firebase
/// appears in the app (`docs/decisions.md` #7). Live in-app updates are a
/// *different* mechanism — Serverpod streams via the repository `watch` methods
/// — and do not go through this port.
///
/// ## Documented platform limitation
///
/// iOS web push for installable PWAs is gated in the EU, so an EU iPhone user
/// on the free PWA install path will **not** receive background notifications.
/// Live in-app updates still work for them. Real iOS background push needs a
/// native build and a paid Apple Developer account, which is deferred. Treat a
/// registration failure there as expected, not as a bug to chase.
abstract interface class PushPort {
  /// Whether background push can work on this device at all.
  ///
  /// False on EU iOS PWA installs. Callers use it to avoid promising a
  /// notification setting the platform will not honour.
  Future<bool> isSupported();

  /// Registers this device to receive pushes for the signed-in user.
  Future<Result<void>> registerDevice();

  /// Stops pushes to this device. Called on sign-out.
  Future<Result<void>> unregisterDevice();

  /// Mutes or unmutes notifications for a single list.
  Future<Result<void>> setListMuted(ListId listId, {required bool muted});

  /// Whether the signed-in user has muted [listId].
  ///
  /// The read half of [setListMuted] -- the server has carried this since
  /// decisions #37, but nothing above the transport layer could read it back
  /// to initialise a settings row until now (decisions #80).
  Future<Result<bool>> isListMuted(ListId listId);
}
