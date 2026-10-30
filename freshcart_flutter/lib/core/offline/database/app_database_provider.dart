import 'package:drift_flutter/drift_flutter.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database_provider.g.dart';

/// Supplies the single [AppDatabase] instance for the app.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase(
  driftDatabase(
    name: 'freshcart',
    native: const DriftNativeOptions(
      // Stored in Application Support, not Documents. Documents is for
      // files the user made and might want to see. This is internal app
      // data.
      databaseDirectory: getApplicationSupportDirectory,
    ),
    // In a browser (the web app iPhones use), the database runs on sqlite
    // compiled to WebAssembly, in a worker. Both files live in web/ and
    // must match the drift (2.35.0) and sqlite3 (3.6.0) versions in
    // pubspec.lock; download them again from those releases on upgrade.
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ),
);
