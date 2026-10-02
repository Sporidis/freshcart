import 'package:freshcart_domain/src/core/failure.dart';
import 'package:meta/meta.dart';

/// The result of something that can fail: [Ok] with a value, or [Err] with
/// a [Failure].
///
/// Every repository and use case returns one. Because [Result] is `sealed`,
/// the compiler checks that a `switch` handles both cases:
///
/// ```dart
/// final message = switch (result) {
///   Ok(:final value) => 'Added ${value.name}',
///   Err(:final failure) => failure.toMessage(t),
/// };
/// ```
///
/// Written by hand, not with `freezed` (decisions.md #16).
@immutable
sealed class Result<T> {
  /// Used by [Ok] and [Err].
  const Result();

  /// Wraps a successful [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps an expected [failure].
  const factory Result.err(Failure failure) = Err<T>;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T>;

  /// The value if this is an [Ok], otherwise `null`.
  ///
  /// Use a `switch` if you need to handle the error. This is for when you
  /// don't care why it failed.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure if this is an [Err], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Turns both cases into one value of type [R]. Handy for UI state.
  R fold<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(value: final v) => ok(v),
    Err<T>(failure: final f) => err(f),
  };

  /// Changes the value inside an [Ok]. An [Err] stays as it is.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(value: final v) => Ok<R>(transform(v)),
    Err<T>(failure: final f) => Err<R>(f),
  };

  /// Runs the next step that can fail, but only if this one worked. Stops at
  /// the first [Err].
  ///
  /// Lets a use case do several steps in a row without lots of
  /// `if (result.isErr) return ...`.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Ok<T>(value: final v) => transform(v),
    Err<T>(failure: final f) => Err<R>(f),
  };
}

/// A successful [Result] carrying [value].
@immutable
final class Ok<T> extends Result<T> {
  /// Wraps a successful [value].
  const Ok(this.value);

  /// The produced value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok<$T>($value)';
}

/// A failed [Result] carrying [failure].
@immutable
final class Err<T> extends Result<T> {
  /// Wraps an expected [failure].
  const Err(this.failure);

  /// Why it failed.
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err<$T>($failure)';
}
