import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A "No shop" pill followed by one pill per shop -- the one shop picker,
/// wherever a shop is chosen (the item sheet, the multi-select Move sheet).
///
/// Built from the strip's own [ShopTabPill], not Material `ChoiceChip`s. A
/// selected `ChoiceChip` drew its checkmark *over* the shop's colour dot on
/// an ink fill, so the moment a shop was picked its colour vanished -- while
/// the tab strip on the same screen showed the same choice as a pill filled
/// with that colour. Now a picked shop looks exactly like its own tab, and
/// "No shop" behaves like "All": ink when picked.
///
/// [onSelected] receives null for "No shop" (untagged, a real choice). Leave
/// [isSelected] out for a one-tap picker that highlights nothing, like the
/// Move sheet; pass it for a field that shows its current value, like the
/// item sheet.
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

/// One pill, with the selection state a screen reader needs -- the visual
/// pill alone only *shows* "selected".
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
