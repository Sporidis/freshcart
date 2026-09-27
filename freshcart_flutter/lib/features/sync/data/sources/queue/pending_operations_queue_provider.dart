import 'package:freshcart_flutter/features/sync/data/sources/database/app_database_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_operations_queue_provider.g.dart';

/// Supplies the [PendingOperationsQueue], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
PendingOperationsQueue pendingOperationsQueue(Ref ref) =>
    PendingOperationsQueue(ref.watch(appDatabaseProvider));
