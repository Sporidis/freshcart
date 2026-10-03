import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';

/// A live data stream that survives losing the internet connection.
///
/// How it works:
/// 1. [fetch] loads the full data once.
/// 2. [watch] then sends small changes, and [reduce] applies each change to
///    the current data.
/// 3. If the connection drops, the user keeps seeing the last data. When
///    [online] says we're back, it calls [fetch] again (to catch up on what
///    was missed) and starts watching again.
///
/// Only network errors are retried. Other errors (list deleted, no access)
/// end the stream with an [Err], because retrying won't fix them.
///
/// [reconnectBackoff] is the wait between retries when the phone is online
/// but the server still can't be reached. Without it we'd retry nonstop.
///
/// [cacheWrite] and [cacheRead] are optional. If given, every new value is
/// saved to disk. Then if the app starts without internet, it can show the
/// saved data instead of an error.
Stream<Result<T>> resilientWatch<T, E>({
  required Future<T> Function() fetch,
  required Stream<E> Function() watch,
  required T Function(T current, E event) reduce,
  required Stream<bool> Function() online,
  Duration reconnectBackoff = const Duration(seconds: 3),
  void Function(T snapshot)? cacheWrite,
  Future<T?> Function()? cacheRead,
}) async* {
  // Step 1: the first full load.
  T current;
  try {
    current = await fetch();
    cacheWrite?.call(current);
  } on Object catch (error) {
    final failure = mapExceptionToFailure(error);
    // Only fall back to the saved copy if the problem is the network.
    final cached = failure is NetworkFailure ? await cacheRead?.call() : null;
    if (cached == null) {
      yield Err(failure);
      return;
    }

    // Offline at startup, but we have saved data: show it, then wait until
    // we're online and load the real data.
    current = cached;
    yield Ok(current);
    switch (await _reconnect(
      fetch: fetch,
      online: online,
      backoff: reconnectBackoff,
    )) {
      case Ok(:final value):
        current = value;
        cacheWrite?.call(current);
      case Err(:final failure):
        yield Err(failure);
        return;
    }
  }
  yield Ok(current);

  // Step 2: listen for live changes, forever.
  while (true) {
    try {
      await for (final event in watch()) {
        current = reduce(current, event);
        cacheWrite?.call(current);
        yield Ok(current);
      }
      // The server closed the stream normally, so we're done.
      return;
    } on Object catch (error) {
      final failure = mapExceptionToFailure(error);
      if (failure is! NetworkFailure) {
        yield Err(failure);
        return;
      }

      // Step 3: connection lost. Wait to be online, reload, keep going.
      switch (await _reconnect(
        fetch: fetch,
        online: online,
        backoff: reconnectBackoff,
      )) {
        case Ok(:final value):
          current = value;
          cacheWrite?.call(current);
        case Err(:final failure):
          yield Err(failure);
          return;
      }
      yield Ok(current);
      // Loop back to the top and start watching again.
    }
  }
}

/// Waits until we're online, then tries [fetch].
///
/// If it fails because of the network, waits [backoff] and tries again.
/// If it fails for any other reason, gives up and returns the [Err].
Future<Result<T>> _reconnect<T>({
  required Future<T> Function() fetch,
  required Stream<bool> Function() online,
  required Duration backoff,
}) async {
  while (true) {
    await online().firstWhere((isOnline) => isOnline);
    try {
      return Ok(await fetch());
    } on Object catch (error) {
      final failure = mapExceptionToFailure(error);
      if (failure is! NetworkFailure) return Err(failure);
      await Future<void>.delayed(backoff);
    }
  }
}
