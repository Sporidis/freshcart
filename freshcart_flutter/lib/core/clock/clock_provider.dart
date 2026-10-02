import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Gives the current time.
///
/// Code that needs "now" reads it from here instead of calling
/// `DateTime.now()` directly. Then tests can fix the time with
/// `clockProvider.overrideWithValue(() => fixed)`.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
