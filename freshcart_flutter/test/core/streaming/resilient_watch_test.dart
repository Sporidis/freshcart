import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/streaming/resilient_watch.dart';

void main() {
  group('resilientWatch', () {
    test(
      'a fetch failure on the very first call ends the stream with one Err',
      () async {
        final events = await resilientWatch<int, int>(
          fetch: () async => throw TimeoutException('down'),
          watch: () => const Stream<int>.empty(),
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
        ).toList();

        expect(events, hasLength(1));
        expect(events.single, isA<Err<int>>());
        expect(
          (events.single as Err<int>).failure,
          isA<NetworkFailure>(),
        );
      },
    );

    test(
      'the normal path seeds once, then re-emits on every watch event',
      () async {
        final controller = StreamController<int>();
        final events = <Result<int>>[];
        final sub = resilientWatch<int, int>(
          fetch: () async => 1,
          watch: () => controller.stream,
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        controller.add(2);
        await Future<void>.delayed(Duration.zero);
        controller.add(3);
        await Future<void>.delayed(Duration.zero);

        expect(events.map((e) => e.valueOrNull), [1, 3, 6]);

        // Close the source *before* cancelling the outer subscription: the
        // generator is parked inside `await for` on controller.stream, and
        // cancelling the consumer first can deadlock waiting for a
        // generator that only ever wakes up in response to its own source
        // (confirmed with a standalone repro -- this isn't hypothetical).
        await controller.close();
        await sub.cancel();
      },
    );

    test(
      'a network blip on watch keeps the last good value, waits for '
      'online, then re-fetches a fresh snapshot and resubscribes to a new '
      'watch stream',
      () async {
        var fetchCallCount = 0;
        final watchControllers = <StreamController<int>>[];
        // Broadcast: a non-broadcast stream can only ever be listened to
        // once in its lifetime, and resilientWatch calls online() fresh on
        // every reconnect attempt.
        final onlineController = StreamController<bool>.broadcast();

        Future<int> fetch() async {
          fetchCallCount++;
          return fetchCallCount == 1 ? 1 : 100;
        }

        Stream<int> watch() {
          final controller = StreamController<int>();
          watchControllers.add(controller);
          return controller.stream;
        }

        final events = <Result<int>>[];
        final sub = resilientWatch<int, int>(
          fetch: fetch,
          watch: watch,
          reduce: (current, event) => current + event,
          online: () => onlineController.stream,
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        expect(fetchCallCount, 1);
        expect(events.single.valueOrNull, 1);

        // A normal delta still works before anything goes wrong.
        watchControllers.single.add(2);
        await Future<void>.delayed(Duration.zero);
        expect(events.last.valueOrNull, 3);

        // The live socket dies -- no Err should reach the listener, and the
        // last good value (3) must stay exactly as it was.
        watchControllers.single.addError(
          TimeoutException('socket dropped'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(events, hasLength(2));
        expect(events.last.valueOrNull, 3);

        // Still offline: no re-fetch has happened yet.
        expect(fetchCallCount, 1);

        // Reconnect.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCallCount, 2); // a fresh full snapshot, not a resume
        expect(events.last.valueOrNull, 100);
        expect(watchControllers, hasLength(2)); // resubscribed to a new stream

        // The new subscription is genuinely live again.
        watchControllers.last.add(5);
        await Future<void>.delayed(Duration.zero);
        expect(events.last.valueOrNull, 105);

        for (final c in watchControllers) {
          await c.close();
        }
        await onlineController.close();
        await sub.cancel();
      },
    );

    test(
      'a non-network failure from watch ends the stream immediately, not '
      'treated as recoverable',
      () async {
        final controller = StreamController<int>();
        var fetchCallCount = 0;
        final events = <Result<int>>[];

        final sub = resilientWatch<int, int>(
          fetch: () async {
            fetchCallCount++;
            return 1;
          },
          watch: () => controller.stream,
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        controller.addError(Exception('list deleted'));
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(2)); // seed Ok, then one Err
        expect(events.first.valueOrNull, 1);
        expect(events.last, isA<Err<int>>());
        expect(fetchCallCount, 1); // no reconnect attempt was made

        await controller.close();
        await sub.cancel();
      },
    );

    test(
      'a NetworkFailure on the post-reconnect re-fetch retries after the '
      'backoff instead of giving up',
      () async {
        var fetchCallCount = 0;
        final watchControllers = <StreamController<int>>[];
        final onlineController = StreamController<bool>.broadcast();

        Future<int> fetch() async {
          fetchCallCount++;
          if (fetchCallCount == 2) {
            // The device is back online, but the server itself is still
            // unreachable -- this is the case reconnectBackoff exists for.
            throw TimeoutException('still down');
          }
          return fetchCallCount == 1 ? 1 : 100;
        }

        final events = <Result<int>>[];
        final sub = resilientWatch<int, int>(
          fetch: fetch,
          watch: () {
            final controller = StreamController<int>();
            watchControllers.add(controller);
            return controller.stream;
          },
          reduce: (current, event) => current + event,
          online: () => onlineController.stream,
          reconnectBackoff: Duration.zero,
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        watchControllers.single.addError(TimeoutException('dropped'));
        await Future<void>.delayed(Duration.zero);

        // First reconnect attempt: the re-fetch (call #2) fails again.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(fetchCallCount, 2);
        expect(events.any((e) => e is Err<int>), isFalse);

        // One more tick: reconnectBackoff (also Duration.zero) was
        // scheduled *after* the delay above, so it needs its own turn
        // before resilientWatch is actually back at online().firstWhere(),
        // subscribed again -- push the next event too early and this
        // broadcast stream (no replay for late listeners) just drops it.
        await Future<void>.delayed(Duration.zero);

        // Second reconnect attempt: the re-fetch (call #3) succeeds.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCallCount, 3);
        expect(events.last.valueOrNull, 100);
        expect(events.any((e) => e is Err<int>), isFalse);

        for (final c in watchControllers) {
          await c.close();
        }
        await onlineController.close();
        await sub.cancel();
      },
    );

    test(
      'a non-network failure on the post-reconnect re-fetch ends the '
      'stream with Err, rather than retrying forever',
      () async {
        var fetchCallCount = 0;
        final watchController = StreamController<int>();
        final onlineController = StreamController<bool>.broadcast();

        Future<int> fetch() async {
          fetchCallCount++;
          if (fetchCallCount == 2) {
            // Anything that isn't recognized by mapExceptionToFailure ends
            // up UnexpectedFailure -- the point here is just that it is
            // *not* NetworkFailure, so it should not be retried.
            throw StateError('list is gone');
          }
          return 1;
        }

        final events = <Result<int>>[];
        final sub = resilientWatch<int, int>(
          fetch: fetch,
          watch: () => watchController.stream,
          reduce: (current, event) => current + event,
          online: () => onlineController.stream,
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        watchController.addError(TimeoutException('dropped'));
        await Future<void>.delayed(Duration.zero);

        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCallCount, 2);
        expect(events.last, isA<Err<int>>());
        expect(
          (events.last as Err<int>).failure,
          isA<UnexpectedFailure>(),
        );

        await watchController.close();
        await onlineController.close();
        await sub.cancel();
      },
    );

    test(
      'a fetch failure on cold start falls back to a cached value, then '
      'waits for reconnect before ever subscribing to watch',
      () async {
        final onlineController = StreamController<bool>.broadcast();
        var fetchCallCount = 0;
        final watchControllers = <StreamController<int>>[];

        Future<int> fetch() async {
          fetchCallCount++;
          if (fetchCallCount == 1) throw TimeoutException('down');
          return 100;
        }

        final events = <Result<int>>[];
        final sub = resilientWatch<int, int>(
          fetch: fetch,
          watch: () {
            final controller = StreamController<int>();
            watchControllers.add(controller);
            return controller.stream;
          },
          reduce: (current, event) => current + event,
          online: () => onlineController.stream,
          cacheRead: () async => 42,
        ).listen(events.add);

        await Future<void>.delayed(Duration.zero);
        expect(fetchCallCount, 1);
        expect(
          events.single.valueOrNull,
          42,
        ); // the cached value, shown at once
        expect(watchControllers, isEmpty); // still offline, nothing live yet

        // Reconnect.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCallCount, 2); // a fresh full snapshot, not the cache
        expect(events.last.valueOrNull, 100);
        expect(watchControllers, hasLength(1)); // now subscribed for real

        watchControllers.single.add(5);
        await Future<void>.delayed(Duration.zero);
        expect(events.last.valueOrNull, 105);

        await watchControllers.single.close();
        await onlineController.close();
        await sub.cancel();
      },
    );

    test(
      'a fetch failure on cold start with nothing cached ends the stream '
      'with one Err, same as if cacheRead were never provided',
      () async {
        final events = await resilientWatch<int, int>(
          fetch: () async => throw TimeoutException('down'),
          watch: () => const Stream<int>.empty(),
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
          cacheRead: () async => null,
        ).toList();

        expect(events, hasLength(1));
        expect(events.single, isA<Err<int>>());
      },
    );

    test(
      'a non-network failure on cold start never consults the cache, even '
      'when cacheRead is provided',
      () async {
        var cacheReadCalled = false;
        final events = await resilientWatch<int, int>(
          fetch: () async => throw StateError('list is gone'),
          watch: () => const Stream<int>.empty(),
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
          cacheRead: () async {
            cacheReadCalled = true;
            return 42;
          },
        ).toList();

        expect(cacheReadCalled, isFalse);
        expect(events.single, isA<Err<int>>());
        expect(
          (events.single as Err<int>).failure,
          isA<UnexpectedFailure>(),
        );
      },
    );

    test(
      'cacheWrite is called with every value this stream yields, seed and '
      'every later delta alike',
      () async {
        final controller = StreamController<int>();
        final written = <int>[];
        final sub = resilientWatch<int, int>(
          fetch: () async => 1,
          watch: () => controller.stream,
          reduce: (current, event) => current + event,
          online: () => const Stream<bool>.empty(),
          cacheWrite: written.add,
        ).listen((_) {});

        await Future<void>.delayed(Duration.zero);
        controller.add(2);
        await Future<void>.delayed(Duration.zero);

        expect(written, [1, 3]);

        await controller.close();
        await sub.cancel();
      },
    );
  });
}
