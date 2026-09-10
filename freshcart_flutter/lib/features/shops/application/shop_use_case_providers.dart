import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_use_case_providers.g.dart';

/// The [CreateShop] use case, wired to the shop repository.
@riverpod
CreateShop createShopUseCase(Ref ref) =>
    CreateShop(ref.watch(shopRepositoryProvider));

/// The [EditShop] use case, wired to the shop repository.
@riverpod
EditShop editShopUseCase(Ref ref) =>
    EditShop(ref.watch(shopRepositoryProvider));
