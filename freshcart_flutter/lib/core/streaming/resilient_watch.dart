import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';

/// Turns a one-shot [fetch] plus a live [watch] stream into a single
/// `Stream<Result<T>>` that survives a dropped connection instead of ending
/// the moment it happens.
///
/// A [NetworkFailure] on [watch] is treated as recoverable: nothing is
/// yielded for it, [current] stays exactly as it was, and this waits for
/// [online] to report `true` again before re-running [fetch] (a full
/// snapshot, not a resume — deltas missed while disconnected never arrive
/// any other way) and re-subscribing to [watch]. Any other failure means the
/// data itself is no longer valid (not found, unauthorized, a real
/// conflict), so it ends the stream with `Err` immediately, same as before
/// this existed.
///
/// [reconnectBackoff] guards the case where the device reports online but
/// the server itself is still unreachable (mid-restart, VPN, ...) — without
/// it, a re-fetch that keeps failing with another [NetworkFailure] would
/// spin as fast as [online] can re-emit `true`.
///
/// [cacheWrite] and [cacheRead] add a persisted read cache on top of the
/// in-memory resilience above (`docs/offline-sync-plan.md` §4's "cached
/// reads"): every value this stream would otherwise yield is handed to
/// [cacheWrite], and if the very first [fetch] — a cold app launch, nothing
/// in memory yet — fails with a [NetworkFailure], [cacheRead] gets one
/// chance to supply a last-known value before this falls back to [Err].
/// Both are optional and default to doing nothing, so every existing caller
/// behaves exactly as before.
Stream<Result<T>> resilientWatch<T, E>({
  required Future<T> Function() fetch,
  required Stream<E> Function() watch,
  required T Function(T current, E event) reduce,
  required Stream<bool> Function() online,
  Duration reconnectBackoff = const Duration(seconds: 3),
  void Function(T snapshot)? cacheWrite,
  Future<T?> Function()? cacheRead,
}) async* {
  T current;
  try {
    current = await fetch();
    cacheWrite?.call(current);
  } on Object catch (error) {
    final failure = mapExceptionToFailure(error);
    final cached = failure is NetworkFailure ? await cacheRead?.call() : null;
    if (cached == null) {
      yield Err(failure);
      return;
    }

    // A cold start with nothing live yet is, from here on, exactly the same
    // situation as a live stream whose connection just dropped: show the
    // last known value, then wait for a real connection before doing
    // anything else. Route it through the same reconnect helper the watch
    // loop below uses, rather than a second copy of that logic.
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

  while (true) {
    try {
      await for (final event in watch()) {
        current = reduce(current, event);
        cacheWrite?.call(current);
        yield Ok(current);
      }
      return;
    } on Object catch (error) {
      final failure = mapExceptionToFailure(error);
      if (failure is! NetworkFailure) {
        yield Err(failure);
        return;
      }

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
      // Falls through to the top of the outer loop, re-subscribing watch()
      // on the freshly re-fetched snapshot.
    }
  }
}

/// Waits for [online] to report `true`, then retries [fetch] with [backoff]
/// between attempts, until it either succeeds or fails with something other
/// than a [NetworkFailure] (the server itself rejecting it, not just being
/// unreachable) — the one case worth giving up on rather than retrying.
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
