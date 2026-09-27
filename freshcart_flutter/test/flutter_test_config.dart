import 'dart:async';

import 'package:drift/drift.dart';

/// Runs before every test file in this directory (and its subdirectories) --
/// picked up automatically by `flutter test`, no per-file import needed.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Every repository test builds its own throwaway AppDatabase
  // (NativeDatabase.memory(), one per test via setUp) -- drift's own
  // multiple-databases warning exists to catch a *production* DI bug where
  // two instances accidentally share one QueryExecutor, not this
  // deliberately-isolated-per-test pattern. This is the flag drift's own
  // warning message points at.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
