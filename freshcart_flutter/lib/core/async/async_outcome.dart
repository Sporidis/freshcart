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
