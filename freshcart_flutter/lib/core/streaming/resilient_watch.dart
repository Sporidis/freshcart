import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';

/// A live data stream that keeps working when the internet goes away.
///
/// ## How it works
///
/// 1. Start listening to [watch] (the small changes), but hold them back.
/// 2. Load everything once with [fetch]. Apply the held-back changes with
///    [reduce], then every new change as it arrives.
/// 3. Connection lost? Keep showing the last data. When [online] says
///    we're back, do steps 1 and 2 again to catch up.
///
/// ## When things go wrong
///
/// - **Network errors** are temporary. The stream sends an [Err] (or the
///   last data it had) and stays open, ready to recover.
/// - **Other errors** (list deleted, no access) end the stream with an
///   [Err]. Retrying won't fix them.
///
/// ## Options
///
/// - [cacheWrite] / [cacheRead]: save every value to disk, so a start
///   without internet can show the saved data.
/// - [reconnectBackoff]: how long to wait between retries when the phone
///   is online but the server is not. Without it we'd retry nonstop.
/// - [resync]: fetch everything again, while staying subscribed. Use it
///   when you *know* a change just reached the server (an offline change
///   that just synced). Several requests at once become one extra fetch.
///
/// ## Why it's built this way
///
/// **Listen first, then fetch.** Otherwise a change made while the data
/// is loading lands in neither, and is lost until the next reload. This
/// really happened: after coming back online, the offline queue replays
/// at the same moment the list reloads, so some changes showed as undone.
/// The catch is that a change can now arrive twice (in the data and as a
/// change), so [reduce] must handle duplicates. Ours does: every change
/// carries the item's full new state.
///
/// **Why [resync] is still needed.** Listening first only closes the gap
/// on our side. The server starts sending a moment after we subscribe,
/// and a change in that moment is still missed.
///
/// **A [StreamController], not `async*`.** Cancelling a generator stuck
/// in `await for` only takes effect at its next event, so leaving a list
/// kept the connection open until that list changed again. Here,
/// cancelling closes the connection straight away.
Stream<Result<T>> resilientWatch<T, E>({
  required Future<T> Function() fetch,
  required Stream<E> Function() watch,
  required T Function(T current, E event) reduce,
  required Stream<bool> Function() online,
  Duration reconnectBackoff = const Duration(seconds: 3),
  void Function(T snapshot)? cacheWrite,
  Future<T?> Function()? cacheRead,
  Stream<void>? resync,
}) {
  late final StreamController<Result<T>> out;
  StreamSubscription<E>? source;
  StreamController<E>? inbox;
  var stopped = false;

  // The latest value shown, kept out here so a resync can replace it.
  late T current;
  var hasCurrent = false;
  StreamSubscription<void>? resyncSub;
  var resyncing = false;
  var resyncAgain = false;

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
    current = value;
    hasCurrent = true;
    if (save) cacheWrite?.call(value);
    out.add(Ok(value));
  }

  /// Fetches a fresh snapshot without touching the live subscription. A
  /// failure is left to the live stream's own error handling.
  Future<void> resyncNow() async {
    if (resyncing) {
      resyncAgain = true;
      return;
    }
    resyncing = true;
    try {
      do {
        resyncAgain = false;
        try {
          final value = await fetch();
          if (stopped || out.isClosed) return;
          show(value);
        } on Object catch (_) {
          // Offline again, say: the live stream reconnects and re-fetches.
        }
      } while (resyncAgain && !stopped);
    } finally {
      resyncing = false;
    }
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
    Stream<E> live = listenLive();
    try {
      final value = await fetch();
      if (stopped) return;
      show(value);
    } on Object catch (error) {
      stopLive();
      final failure = mapExceptionToFailure(error);
      // Only fall back to the saved copy if the problem is the network.
      final cached = failure is NetworkFailure ? await cacheRead?.call() : null;
      if (stopped) return;
      // Not a network problem: retrying won't help, so the stream ends.
      if (failure is! NetworkFailure) return finish(failure);

      // Offline at startup. Show the saved data if there is any, or else
      // say we're offline, but keep the stream open either way. Then wait
      // until we're online and load the real data.
      if (cached case final saved?) {
        show(saved, save: false);
      } else {
        // Not show(): there is no value for later changes to build on.
        out.add(Err(failure));
      }
      final result = await reconnect();
      if (result == null || stopped) return;
      switch (result) {
        case Ok(value: (final value, final stream)):
          live = stream;
          show(value);
        case Err(:final failure):
          return finish(failure);
      }
    }

    // Step 2: apply the changes, the held-back ones first, forever.
    while (!stopped) {
      try {
        await for (final event in live) {
          if (stopped) return;
          show(reduce(current, event));
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
            live = stream;
            show(value);
          case Err(:final failure):
            return finish(failure);
        }
      }
    }
  }

  out = StreamController<Result<T>>(
    onListen: () {
      resyncSub = resync?.listen((_) {
        // Nothing to refresh before the first value.
        if (hasCurrent && !stopped) unawaited(resyncNow());
      });
      unawaited(
        run().catchError((Object error, StackTrace stack) {
          if (!out.isClosed) out.addError(error, stack);
        }),
      );
    },
    onCancel: () {
      stopped = true;
      unawaited(resyncSub?.cancel());
      stopLive();
    },
  );
  return out.stream;
}
