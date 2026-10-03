import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';

/// A live data stream that survives losing the internet connection.
///
/// How it works:
/// 1. It starts listening to [watch] (the small changes), holding them
///    back for now.
/// 2. [fetch] loads the full data once. Then the held changes are applied
///    with [reduce], and every later change as it arrives.
/// 3. If the connection drops, the user keeps seeing the last data. When
///    [online] says we're back, it does 1 and 2 again (to catch up on what
///    was missed).
///
/// Why listen before fetching: a change that happens while the snapshot is
/// loading would otherwise be in neither, and lost until the next reload.
/// That's exactly what happened after coming back online: the offline
/// queue replays your changes at the same moment the list reloads, so some
/// of them landed in that gap and the list kept showing them undone (and a
/// later edit was refused as out of date). Listening first means such a
/// change may arrive twice (in the snapshot and as a change); [reduce]
/// must cope with that, which ours does, since each change carries the
/// item's whole new state.
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
///
/// Built on a [StreamController], not an `async*` generator: cancelling a
/// generator that's waiting inside `await for` only takes effect at its
/// next event, so leaving a list kept its live connection open until that
/// list changed again. Here, cancelling cancels the live subscription at
/// once.
Stream<Result<T>> resilientWatch<T, E>({
  required Future<T> Function() fetch,
  required Stream<E> Function() watch,
  required T Function(T current, E event) reduce,
  required Stream<bool> Function() online,
  Duration reconnectBackoff = const Duration(seconds: 3),
  void Function(T snapshot)? cacheWrite,
  Future<T?> Function()? cacheRead,
}) {
  late final StreamController<Result<T>> out;
  StreamSubscription<E>? source;
  StreamController<E>? inbox;
  var stopped = false;

  /// Starts listening to [watch] now. Its changes wait in the returned
  /// stream until they're read, so none are missed while fetching.
  Stream<E> listenLive() {
    final box = StreamController<E>();
    inbox = box;
    try {
      source = watch().listen(
        box.add,
        onError: box.addError,
        onDone: box.close,
      );
    } on Object catch (error, stack) {
      // Couldn't even start (for example a closed client): treat it like a
      // live stream that failed straight away.
      box.addError(error, stack);
    }
    return box.stream;
  }

  void stopLive() {
    unawaited(source?.cancel());
    source = null;
    unawaited(inbox?.close());
    inbox = null;
  }

  void finish([Failure? failure]) {
    stopLive();
    if (out.isClosed) return;
    if (failure != null) out.add(Err(failure));
    unawaited(out.close());
  }

  void show(T value, {bool save = true}) {
    if (save) cacheWrite?.call(value);
    out.add(Ok(value));
  }

  /// Waits until we're online, then listens to [watch] and fetches. If the
  /// fetch fails because of the network, waits [reconnectBackoff] and tries
  /// again. Returns null if stopped, or the failure if it can't recover.
  Future<Result<(T, Stream<E>)>?> reconnect() async {
    while (!stopped) {
      await online().firstWhere((isOnline) => isOnline);
      if (stopped) return null;
      final live = listenLive();
      try {
        return Ok((await fetch(), live));
      } on Object catch (error) {
        stopLive();
        final failure = mapExceptionToFailure(error);
        if (failure is! NetworkFailure) return Err(failure);
        await Future<void>.delayed(reconnectBackoff);
      }
    }
    return null;
  }

  Future<void> run() async {
    // Step 1: the first full load, listening already.
    T current;
    var live = listenLive();
    try {
      current = await fetch();
      if (stopped) return;
      show(current);
    } on Object catch (error) {
      stopLive();
      final failure = mapExceptionToFailure(error);
      // Only fall back to the saved copy if the problem is the network.
      final cached = failure is NetworkFailure ? await cacheRead?.call() : null;
      if (stopped) return;
      if (cached == null) return finish(failure);

      // Offline at startup, but we have saved data: show it, then wait
      // until we're online and load the real data.
      current = cached;
      show(current, save: false);
      final result = await reconnect();
      if (result == null || stopped) return;
      switch (result) {
        case Ok(value: (final value, final stream)):
          current = value;
          live = stream;
          show(current);
        case Err(:final failure):
          return finish(failure);
      }
    }

    // Step 2: apply the changes, the held-back ones first, forever.
    while (!stopped) {
      try {
        await for (final event in live) {
          if (stopped) return;
          current = reduce(current, event);
          show(current);
        }
        // The server closed the stream normally (or we were cancelled).
        return finish();
      } on Object catch (error) {
        stopLive();
        if (stopped) return;
        final failure = mapExceptionToFailure(error);
        if (failure is! NetworkFailure) return finish(failure);

        // Step 3: connection lost. Keep the last data, wait to be online,
        // reload, keep going.
        final result = await reconnect();
        if (result == null || stopped) return;
        switch (result) {
          case Ok(value: (final value, final stream)):
            current = value;
            live = stream;
            show(current);
          case Err(:final failure):
            return finish(failure);
        }
      }
    }
  }

  out = StreamController<Result<T>>(
    onListen: () => unawaited(
      run().catchError((Object error, StackTrace stack) {
        if (!out.isClosed) out.addError(error, stack);
      }),
    ),
    onCancel: () {
      stopped = true;
      stopLive();
    },
  );
  return out.stream;
}
