import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A row of pills to pick a shop: "No shop", then one per shop. Used in
/// the item sheet and the "Move to shop" sheet.
///
/// Uses [ShopPickerPill], not the tab pill: a tab filters, this chooses.
///
/// [onSelected] gets null for "No shop". Leave [isSelected] out if nothing
/// should look selected (like the Move sheet). Pass it to show the current
/// shop (like the item sheet).
class ShopPicker extends StatelessWidget {
  const ShopPicker({
    required this.shops,
    required this.onSelected,
    required this.t,
    this.isSelected,
    this.showNoShop = true,
    super.key,
  });

  /// Whether "No shop" is offered. The product sheet hides it when adding
  /// from a shop's tab: you're adding to that shop.
  final bool showNoShop;

  final List<Shop> shops;
  final ValueChanged<ShopId?> onSelected;
  final Translations t;
  final bool Function(ShopId? shopId)? isSelected;

  @override
  Widget build(BuildContext context) {
    // TapTarget gives each 40px pill 2px of tap margin above and below, so
    // the visual gap between rows stays 8.
    return Wrap(
      spacing: AppSpacing.gapSmall,
      runSpacing: AppSpacing.xs,
      children: [
        if (showNoShop)
          ShopPickerPill(
            label: t.shops.none,
            color: null,
            selected: isSelected?.call(null) ?? false,
            onTap: () => onSelected(null),
          ),
        for (final shop in shops)
          ShopPickerPill(
            label: shop.name,
            color: shop.color.toColor(),
            selected: isSelected?.call(shop.id) ?? false,
            onTap: () => onSelected(shop.id),
          ),
      ],
    );
  }
}
