import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

/// The state type every controller in this app uses.
///
/// It's two wrappers inside each other, and each one answers a different
/// question:
///
/// * [AsyncValue] (outside): is the request still loading, done, or did
///   something crash?
/// * [Result] (inside): did it work ([Ok]), or did it fail in a way we
///   expected, like being offline or the list not existing ([Err])?
///
/// So `AsyncError` means a bug. `AsyncData(Err(...))` means a normal failure
/// the UI should show to the user.
///
/// Called `AsyncOutcome` because Riverpod already has its own `AsyncResult`.
typedef AsyncOutcome<T> = AsyncValue<Result<T>>;

/// Shortcuts for reading an [AsyncOutcome], so screens don't have to unwrap
/// both layers by hand every time.
///
/// They only pull data out. Each screen decides for itself how to show it.
extension AsyncOutcomeX<T> on AsyncOutcome<T> {
  /// The value if everything worked, otherwise `null` (still loading, crashed,
  /// or failed).
  T? get dataOrNull => value?.valueOrNull;

  /// Why loading failed, or `null` if it didn't fail.
  ///
  /// A crash ([AsyncError]) becomes [Failure.unexpected]. A normal failure
  /// ([Err]) is returned as is.
  ///
  /// While a retry is loading this returns `null`, even if the last attempt
  /// failed. We don't know yet if the retry will work, so we stop showing the
  /// old error.
  Failure? get loadFailure {
    if (isLoading) return null;
    if (hasError) return const Failure.unexpected();
    return value?.failureOrNull;
  }
}
