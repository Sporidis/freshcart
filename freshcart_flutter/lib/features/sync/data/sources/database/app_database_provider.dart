import 'package:drift_flutter/drift_flutter.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database_provider.g.dart';

/// Supplies the single [AppDatabase] instance for the app.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase(
  driftDatabase(
    name: 'freshcart',
    native: const DriftNativeOptions(
      // The queue is internal app state, not user-generated — belongs in
      // Application Support, not Documents. See path_provider's own doc
      // comments on the two: Documents is for data the user created and may
      // want to see or export; this isn't that.
      databaseDirectory: getApplicationSupportDirectory,
    ),
  ),
);
