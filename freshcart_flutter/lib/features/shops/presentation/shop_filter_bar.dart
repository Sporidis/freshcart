import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview.dart';
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

    final loaded = shops.dataOrNull ?? const <Shop>[];
    // Nothing to filter by yet — a single "all shops" chip would be noise.
    if (loaded.isEmpty) return const SizedBox.shrink();

    // Remaining, not total: the count answers "how much is left to find in
    // here?", so a checked-off item should make it tick down. It hides at
    // zero rather than showing "0", which would read as a broken badge.
    final items =
        ref.watch(itemsControllerProvider(listId)).dataOrNull ??
        const <ShoppingItem>[];
    int remainingIn(ShopId? shop) => items
        .where((item) => !item.isChecked && item.matchesShopFilter(shop))
        .length;

    String labelFor(String name, ShopId? shop) {
      final remaining = remainingIn(shop);
      return remaining == 0 ? name : '$name · $remaining';
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: FilterChip(
              label: Text(labelFor(t.shops.all, null)),
              // The theme's labelStyle already switches colour by selection;
              // weight is the one thing a ChipThemeData can't resolve per
              // state, so the chip supplies it itself, since it already
              // knows whether it is selected.
              labelStyle: selected == null ? AppTextStyles.labelStrong : null,
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
                  // Through the preview: this is the pill the design means
                  // when it says a swatch retints live behind the sheet.
                  backgroundColor: Color(
                    ref.watch(effectiveShopColorProvider(shop)).argb,
                  ),
                  radius: 8,
                ),
                label: Text(labelFor(shop.name, shop.id)),
                labelStyle: selected == shop.id
                    ? AppTextStyles.labelStrong
                    : null,
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
