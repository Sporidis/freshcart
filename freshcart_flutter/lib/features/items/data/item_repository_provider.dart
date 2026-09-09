import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_repository_provider.g.dart';

/// Supplies the [ItemRepository] port.
@Riverpod(keepAlive: true)
ItemRepository itemRepository(Ref ref) =>
    ItemRepositoryImpl(ref.watch(serverpodClientProvider));
