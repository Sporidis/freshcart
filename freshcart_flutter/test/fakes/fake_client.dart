import 'package:freshcart_client/freshcart_client.dart' as dto;

/// A [dto.Client] that answers endpoint calls from memory instead of a network.
///
/// Ordinary RPC methods funnel through [callServerEndpoint]; streaming methods
/// (anything declared to return a `Stream` on the endpoint) funnel through the
/// separate [callStreamingServerEndpoint] — a real Serverpod client opens a
/// WebSocket for those, which is a distinct code path from a plain HTTP call.
/// Overriding both intercepts the whole client without a mocking package and
/// without a running server. The repository under test is the real one — only
/// the transport is faked.
class FakeClient extends dto.Client {
  /// Creates a fake pointed at an unusable host, which is never contacted.
  FakeClient() : super('http://localhost:0/');

  /// Answers an ordinary (non-streaming) call. Return a value to succeed, or
  /// throw to fail.
  Object? Function(String endpoint, String method, Map<String, dynamic> args)?
  handler;

  /// Answers a streaming call, returning the `Stream` the endpoint would emit.
  Stream<Object?> Function(
    String endpoint,
    String method,
    Map<String, dynamic> args,
  )?
  streamHandler;

  /// Every non-streaming call made, in order, for asserting on what the
  /// repository sent.
  final List<({String endpoint, String method, Map<String, dynamic> args})>
  calls = [];

  /// Every streaming call made, in order.
  final List<({String endpoint, String method, Map<String, dynamic> args})>
  streamCalls = [];

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    calls.add((endpoint: endpoint, method: method, args: args));
    final handle = handler;
    if (handle == null) {
      throw StateError('FakeClient.handler was not configured');
    }
    return handle(endpoint, method, args) as T;
  }

  @override
  dynamic callStreamingServerEndpoint<T, G>(
    String endpoint,
    String method,
    Map<String, dynamic> args,
    Map<String, Stream<dynamic>> streams, {
    bool authenticated = true,
  }) {
    streamCalls.add((endpoint: endpoint, method: method, args: args));
    final handle = streamHandler;
    if (handle == null) {
      throw StateError('FakeClient.streamHandler was not configured');
    }
    return handle(endpoint, method, args);
  }
}
