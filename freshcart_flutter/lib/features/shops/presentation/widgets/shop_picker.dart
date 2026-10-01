import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
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

  /// A background's contrasting foreground -- the same formula
  /// `AppTheme`/`ShopTabPill` use for the same reason (arbitrary shop
  /// colours, not a matched M3 pair, so estimate rather than assume).
  static Color _onColorFor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : AppColors.ink;

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
            // Active: white, matching the fill's own contrast -- inactive:
            // the shop's literal colour. Same inversion rule ShopTabPill's
            // own dot already follows, so a selected chip's dot never sits
            // at the same hue as the chip's own selected-colour fill.
            avatar: CircleAvatar(
              backgroundColor: (isSelected?.call(shop.id) ?? false)
                  ? _onColorFor(shop.color.toColor())
                  : shop.color.toColor(),
              radius: AppSizes.tabDot / 2,
            ),
            label: Text(shop.name),
            selected: isSelected?.call(shop.id) ?? false,
            onSelected: (_) => onSelected(shop.id),
          ),
      ],
    );
  }
}
