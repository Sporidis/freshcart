import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A row of pills to pick a shop: "No shop", then one per shop. Used in
/// the item sheet and the "Move to shop" sheet.
///
/// Uses the same [ShopTabPill] as the shop tabs, so a picked shop looks
/// exactly like its tab.
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
    super.key,
  });

  final List<Shop> shops;
  final ValueChanged<ShopId?> onSelected;
  final Translations t;
  final bool Function(ShopId? shopId)? isSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gapSmall,
      runSpacing: AppSpacing.gapSmall,
      children: [
        _Choice(
          label: t.shops.none,
          color: null,
          selected: isSelected?.call(null) ?? false,
          onTap: () => onSelected(null),
        ),
        for (final shop in shops)
          _Choice(
            label: shop.name,
            color: shop.color.toColor(),
            selected: isSelected?.call(shop.id) ?? false,
            onTap: () => onSelected(shop.id),
          ),
      ],
    );
  }
}

/// One pill, plus telling screen readers whether it's selected.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: ShopTabPill(
      label: label,
      active: selected,
      color: color,
      onTap: onTap,
    ),
  );
}

@Preview(group: 'Shops', name: 'Shop picker', size: Size(393, 120))
Widget shopPickerPreview() {
  final shops = [
    Shop(
      id: ShopId('s1'),
      listId: ListId('list-1'),
      name: 'Albert Heijn',
      color: HexColor.fromArgb(0xFF2456A6),
    ),
    Shop(
      id: ShopId('s2'),
      listId: ListId('list-1'),
      name: 'Colruyt',
      color: HexColor.fromArgb(0xFFE8791A),
    ),
  ];
  return previewPiece(
    ShopPicker(
      shops: shops,
      onSelected: (_) {},
      t: previewTranslations,
      isSelected: (id) => id == shops.last.id,
    ),
  );
}
