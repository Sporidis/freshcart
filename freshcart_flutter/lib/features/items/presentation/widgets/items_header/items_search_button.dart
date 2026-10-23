import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';

/// The magnifier in the list header: opens item search.
class ItemsSearchButton extends ConsumerWidget {
  /// Creates the button for [list]'s items.
  const ItemsSearchButton({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.search),
    tooltip: ref.watch(translationsProvider).search.hint,
    onPressed: () =>
        ref.read(itemsSectionControllerProvider(list).notifier).openSearch(),
  );
}
