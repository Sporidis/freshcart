/// A source of the current time.
///
/// Use cases take one of these instead of calling [DateTime.now] directly, so a
/// test can pin "now" and assert on exact timestamps rather than tolerating a
/// range. Production wiring passes [systemClock].
typedef Clock = DateTime Function();

/// The real clock, in UTC.
///
/// UTC on purpose: timestamps cross devices in different timezones, and the
/// server stores UTC. Converting for display is the presentation layer's job.
DateTime systemClock() => DateTime.now().toUtc();
