import 'package:freshcart_domain/freshcart_domain.dart';

/// Item names split into "this week", "last week" and "earlier". Made by
/// [bucketByRecency].
typedef RecencyBuckets = ({
  List<NameHistoryEntry> thisWeek,
  List<NameHistoryEntry> lastWeek,
  List<NameHistoryEntry> earlier,
});

/// Splits [entries] into "this week" / "last week" / "earlier".
///
/// "This week" means the last 7 days from [now], not the calendar week.
/// Countries start the week on different days (Monday or Sunday), and this
/// way it works the same everywhere.
///
/// [entries] must already be sorted newest first. This keeps that order,
/// it doesn't sort.
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

/// Extra getters for [RecencyBuckets] (a record can't have its own).
extension RecencyBucketsX on RecencyBuckets {
  /// True if all three groups are empty.
  bool get isEmpty => thisWeek.isEmpty && lastWeek.isEmpty && earlier.isEmpty;
}
