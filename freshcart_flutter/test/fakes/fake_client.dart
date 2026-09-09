import 'package:freshcart_client/freshcart_client.dart' as dto;

/// A [dto.Client] that answers endpoint calls from memory instead of a network.
///
/// Every generated endpoint method funnels through [callServerEndpoint], so
/// overriding that one method intercepts the whole client without a mocking
/// package and without a running server. The repository under test is the real
/// one — only the transport is faked.
class FakeClient extends dto.Client {
  /// Creates a fake pointed at an unusable host, which is never contacted.
  FakeClient() : super('http://localhost:0/');

  /// Answers a call. Return a value to succeed, or throw to fail.
  Object? Function(String endpoint, String method, Map<String, dynamic> args)?
  handler;

  /// Every call made, in order, for asserting on what the repository sent.
  final List<({String endpoint, String method, Map<String, dynamic> args})>
  calls = [];

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
}
