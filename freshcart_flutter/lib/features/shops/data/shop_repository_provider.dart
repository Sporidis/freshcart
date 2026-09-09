import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_repository_provider.g.dart';

/// Supplies the [ShopRepository] port.
@Riverpod(keepAlive: true)
ShopRepository shopRepository(Ref ref) =>
    ShopRepositoryImpl(ref.watch(serverpodClientProvider));
