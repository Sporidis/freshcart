import 'package:freshcart_flutter/features/sync/data/pending_operations_queue_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_write_count_provider.g.dart';

/// How many offline writes are still waiting to reach the server.
@Riverpod(keepAlive: true)
Stream<int> pendingWriteCount(Ref ref) =>
    ref.watch(pendingOperationsQueueProvider).watchCount();
