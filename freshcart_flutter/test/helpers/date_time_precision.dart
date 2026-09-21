/// Precision helpers for comparing [DateTime]s against values that have been
/// through storage that doesn't keep sub-second precision (e.g. drift's
/// default, which stores timestamps as whole-second Unix time).
extension TruncatedToSeconds on DateTime {
  /// Drops everything finer than seconds, preserving UTC vs. local.
  DateTime get truncatedToSeconds => isUtc
      ? DateTime.utc(year, month, day, hour, minute, second)
      : DateTime(year, month, day, hour, minute, second);
}
