import 'dart:async';
import 'dart:math';

import 'package:freshcart_domain/freshcart_domain.dart';

/// The demo's whole "server": plain maps in memory, shared by both phones.
class DemoBackend {
  /// Creates an empty backend.
  ///
  /// Tests pass `simulateLatency: false` so they don't wait on every call,
  /// and a seeded [random] so join codes are repeatable.
  DemoBackend({
    required Clock clock,
    this.simulateLatency = true,
    Random? random,
  }) : _clock = clock,
       _random = random ?? Random();

  final Clock _clock;
  final Random _random;

  /// Whether [latency] waits. Off in tests.
  final bool simulateLatency;

  int _seq = 0;

  final lists = <ListId, ShoppingList>{};
  final items = <ItemId, ShoppingItem>{};
  final shops = <ShopId, Shop>{};
  final users = <UserId, AuthUser>{};

  // One broadcast stream = one "something changed" signal for every listener.
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  /// Tells every listener something changed. Ignored once [dispose]d: a
  /// save still in flight when the demo closes must not throw.
  void notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  DateTime now() => _clock();
  String newId(String prefix) => '$prefix-${++_seq}';

  /// Same alphabet and length as the real server, via the domain's own parser.
  JoinCode newJoinCode() {
    final raw = List.generate(
      JoinCode.length,
      (_) => JoinCode.alphabet[_random.nextInt(JoinCode.alphabet.length)],
    ).join();
    return (JoinCode.parse(raw) as Ok<JoinCode>).value;
  }

  /// Fakes a network round trip so spinners and pending states still show.
  Future<void> latency() => simulateLatency
      ? Future.delayed(Duration(milliseconds: 120 + _random.nextInt(180)))
      : Future.value();

  /// Emits the latest [read] now, then again after every [changes] event.
  ///
  /// `Stream.multi` (not `async*`) so we listen to [changes] *before* the
  /// first value goes out. An `async*` generator only subscribes after its
  /// first `yield` is delivered, and a change in that gap would be lost.
  Stream<T> watch<T>(T Function() read) => Stream<T>.multi((controller) {
    final sub = changes.listen((_) => controller.add(read()));
    controller
      ..add(read())
      ..onCancel = sub.cancel;
  });

  /// Closes the change stream. Call when the demo session ends.
  Future<void> dispose() => _changes.close();
}
