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
  ),
);
