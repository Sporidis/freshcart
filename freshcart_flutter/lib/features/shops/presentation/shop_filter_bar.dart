import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';

/// A row of chips for filtering a list by shop.
///
/// Selecting a chip does two things at once: it narrows the visible items and
/// it re-themes the app to that shop's colour. Both read the same piece of
/// state, so they cannot disagree.
class ShopFilterBar extends ConsumerWidget {
  /// Creates the bar for [listId].
  const ShopFilterBar({required this.listId, super.key});

  /// The list whose shops to show.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final shops = ref.watch(shopsControllerProvider(listId));
    final selected = ref.watch(shopFilterProvider(listId));

    final loaded = switch (shops) {
      AsyncValue<Result<List<Shop>>>(value: Ok<List<Shop>>(:final value)) =>
        value,
      _ => const <Shop>[],
    };
    // Nothing to filter by yet — a single "all shops" chip would be noise.
    if (loaded.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: FilterChip(
              label: Text(t.shops.all),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(shopFilterProvider(listId).notifier).select(null),
            ),
          ),
          for (final shop in loaded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: FilterChip(
                avatar: CircleAvatar(
                  backgroundColor: Color(shop.color.argb),
                  radius: 8,
                ),
                label: Text(shop.name),
                selected: selected == shop.id,
                onSelected: (isSelected) => ref
                    .read(shopFilterProvider(listId).notifier)
                    .select(isSelected ? shop.id : null),
              ),
            ),
        ],
      ),
    );
  }
}
