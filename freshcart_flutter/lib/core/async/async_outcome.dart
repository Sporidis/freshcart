import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

/// The shape every controller in this app exposes.
///
/// Two wrappers, because they mean different things and collapsing them would
/// lose information:
///
/// * [AsyncValue] carries *loading* — a fact about the request, not the domain.
/// * [Result] carries *expected failure* — offline, not found, conflict — which
///   `CLAUDE.md` requires to travel as a value rather than a thrown exception.
///
/// An `AsyncError` therefore means something genuinely unexpected happened (a
/// bug), while `AsyncData(Err(...))` means the operation completed and failed
/// in a way the UI is expected to handle. Throwing a [Failure] into
/// [AsyncValue]'s error channel would have blurred the two — and would have
/// needed a fake exception wrapper, since `Failure` is deliberately not an
/// `Exception`.
/// Named `AsyncOutcome`, not `AsyncResult`: Riverpod 3 already exports an
/// `AsyncResult` of its own, and shadowing a framework type would be a trap for
/// the next reader.
typedef AsyncOutcome<T> = AsyncValue<Result<T>>;

/// Convenience readers for [AsyncOutcome], so a screen does not have to
/// hand-roll the same two-level `switch` every time it needs to ask "is
/// there a value to show?" or "is there a failure to show instead?"
///
/// Both are pure data extraction: neither builds a widget or decides how a
/// failure is presented, because that differs by screen — some replace
/// themselves entirely with an error screen, others show it inline.
extension AsyncOutcomeX<T> on AsyncOutcome<T> {
  /// The value once this has settled as [AsyncData] wrapping an [Ok] — `null`
  /// for every other state: still loading, an unexpected [AsyncError], or a
  /// settled [Err].
  T? get dataOrNull => value?.valueOrNull;

  /// The failure behind a failed *load*, or `null` if there isn't one.
  ///
  /// Collapses the two ways a load can fail into one: an [AsyncError] (a
  /// genuinely unexpected error — a bug) reports as [Failure.unexpected],
  /// and a settled [Err] (an expected failure a repository returned) reports
  /// as itself.
  ///
  /// `isLoading` is checked first and wins outright, even when a previous
  /// [Err] is still sitting in [value] (Riverpod carries the last value
  /// through a reload). A retry in flight means "we don't know yet," not
  /// "still failing" — so this deliberately goes quiet rather than keep
  /// reporting a failure a fresh attempt might be about to resolve.
  Failure? get loadFailure {
    if (isLoading) return null;
    if (hasError) return const Failure.unexpected();
    return value?.failureOrNull;
  }
}
