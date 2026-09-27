import 'package:freshcart_flutter/features/items/data/repositories/item_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/queue_drainer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'queue_drainer_provider.g.dart';

@Riverpod(keepAlive: true)
QueueDrainer queueDrainer(Ref ref) => QueueDrainer(
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(itemRepositoryProvider),
  ref.watch(listRepositoryProvider),
);
