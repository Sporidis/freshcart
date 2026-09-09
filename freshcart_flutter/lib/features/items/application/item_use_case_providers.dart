import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_use_case_providers.g.dart';

/// Supplies [AddItem], wired to the repository port.
@riverpod
AddItem addItemUseCase(Ref ref) => AddItem(ref.watch(itemRepositoryProvider));

/// Supplies [ToggleItemChecked], wired to the repository port.
@riverpod
ToggleItemChecked toggleItemCheckedUseCase(Ref ref) =>
    ToggleItemChecked(ref.watch(itemRepositoryProvider));
