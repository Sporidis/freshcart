/// Gives the current time.
///
/// Use cases take a Clock instead of calling [DateTime.now] directly. Then
/// tests can use a fixed time and check exact timestamps. The app uses
/// [systemClock].
typedef Clock = DateTime Function();

/// The real clock, in UTC.
///
/// UTC because phones can be in different time zones, and the server uses
/// UTC. Showing local time is done in the UI.
DateTime systemClock() => DateTime.now().toUtc();
