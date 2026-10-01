import 'package:freshcart_domain/freshcart_domain.dart';

/// [NameHistoryEntry] grouped by recency; see [bucketByRecency].
typedef RecencyBuckets = ({
  List<NameHistoryEntry> thisWeek,
  List<NameHistoryEntry> lastWeek,
  List<NameHistoryEntry> earlier,
});

/// Buckets [entries] into "this week" / "last week" / "earlier" using
/// rolling 7-day windows measured back from [now], not calendar-week
/// boundaries -- the app ships five locales with different week-start
/// conventions (some start Monday, some Sunday), and a rolling window means
/// the same label reads the same regardless of which day a calendar week is
/// considered to start on.
///
/// [entries] is expected already ordered by [NameHistoryEntry.lastUsedAt]
/// descending (what `recentNamesProvider` returns) -- bucketing is a single
/// pass that preserves that order within each group, not a sort of its own.
RecencyBuckets bucketByRecency(List<NameHistoryEntry> entries, DateTime now) {
  final thisWeek = <NameHistoryEntry>[];
  final lastWeek = <NameHistoryEntry>[];
  final earlier = <NameHistoryEntry>[];
  for (final entry in entries) {
    final age = now.difference(entry.lastUsedAt);
    if (age <= const Duration(days: 7)) {
      thisWeek.add(entry);
    } else if (age <= const Duration(days: 14)) {
      lastWeek.add(entry);
    } else {
      earlier.add(entry);
    }
  }
  return (thisWeek: thisWeek, lastWeek: lastWeek, earlier: earlier);
}

/// Reads on [RecencyBuckets] a record type cannot declare itself.
extension RecencyBucketsX on RecencyBuckets {
  /// No history at all -- every bucket empty.
  bool get isEmpty => thisWeek.isEmpty && lastWeek.isEmpty && earlier.isEmpty;
}
