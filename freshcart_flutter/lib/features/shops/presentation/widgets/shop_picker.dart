import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A "No shop" chip followed by one chip per shop, each tinted with its own
/// colour -- the one shop picker, wherever a shop is chosen.
///
/// [onSelected] receives null for "No shop" (untagged, a real choice). Leave
/// [isSelected] out for a one-tap picker that highlights nothing, like the
/// multi-select "Move" sheet; pass it for a field that shows its current
/// value, like the item sheet.
class ShopPicker extends StatelessWidget {
  const ShopPicker({
    required this.shops,
    required this.onSelected,
    required this.t,
    this.isSelected,
    super.key,
  });

  final List<Shop> shops;
  final ValueChanged<ShopId?> onSelected;
  final Translations t;
  final bool Function(ShopId? shopId)? isSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(t.shops.none),
          selected: isSelected?.call(null) ?? false,
          onSelected: (_) => onSelected(null),
        ),
        for (final shop in shops)
          ChoiceChip(
            avatar: CircleAvatar(
              backgroundColor: shop.color.toColor(),
              radius: 8,
            ),
            label: Text(shop.name),
            selected: isSelected?.call(shop.id) ?? false,
            onSelected: (_) => onSelected(shop.id),
          ),
      ],
    );
  }
}
