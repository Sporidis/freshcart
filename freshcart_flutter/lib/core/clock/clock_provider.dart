import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// "Now", as a seam. Anything that buckets or compares against the current
/// time reads it from here, so a test can pin it with
/// `clockProvider.overrideWithValue(() => fixed)` instead of depending on
/// the day it happens to run.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
