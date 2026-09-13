import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// One tab in the shop strip: "All" or a single shop, active or not.
///
/// Component Library §02. Replaces a stock `FilterChip` because the active
/// state is a full colour fill (not `FilterChip`'s selected-outline look),
/// and only a shop tab carries a leading dot at all -- "All" never does.
///
/// This widget only draws; it does not know about [ShopFilterProvider] or
/// remaining-item counts. Its caller resolves "am I selected" and "how many
/// are left in me" and hands both down, same as every other presentation
/// widget in this codebase (`ItemTile`, `ShopTabPill`'s own `count`).
class ShopTabPill extends StatelessWidget {
  /// Creates the pill. Pass `color: null` for the "All" tab -- it is always
  /// ink (or white-on-dark), and never draws a leading dot.
  const ShopTabPill({
    required this.label,
    required this.active,
    this.color,
    this.count,
    this.onTap,
    super.key,
  });

  /// "All", or the shop's name.
  final String label;

  /// Whether this is the currently selected tab.
  final bool active;

  /// The shop's colour, or null for the neutral "All" tab.
  final Color? color;

  /// Items still unchecked inside this tab. Hidden (not "· 0") at zero, per
  /// the component library's own note: a badge that can read "0" reads as
  /// broken, not "nothing left".
  final int? count;

  final VoidCallback? onTap;

  /// A background's contrasting foreground -- the same formula
  /// `AppTheme.forShop` uses for the same reason (arbitrary shop colours,
  /// not a matched M3 pair, so estimate rather than assume).
  static Color _onColorFor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Neutral fill tracks brightness the same way the app's own "ink" text
    // colour does (`AppTheme`'s local `ink` var) -- not a literal constant,
    // so the All tab still reads correctly in dark mode.
    final fill = color ?? theme.colorScheme.onSurface;
    final onFill = _onColorFor(fill);
    final label_ = (count == null || count == 0) ? label : '$label · $count';

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.quick),
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? fill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: active
                ? null
                : Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: AppSizes.tabDot,
                  height: AppSizes.tabDot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Active: white, matching the fill's own contrast --
                    // inactive: the shop's literal colour (component
                    // library: "inactive pills keep a small shop-colour
                    // dot").
                    color: active ? onFill : color,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label_,
                style:
                    (active
                            ? theme.textTheme.labelLarge
                            : theme.textTheme.labelMedium)
                        ?.copyWith(color: active ? onFill : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(group: 'Shops', name: 'ShopTabPill · All', size: Size(200, 60))
Widget shopTabPillAllActivePreview() => previewPiece(
  const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ShopTabPill(label: 'All', active: true, count: 3),
      SizedBox(width: 8),
      ShopTabPill(label: 'All', active: false, count: 3),
    ],
  ),
);

@Preview(group: 'Shops', name: 'ShopTabPill · shop', size: Size(240, 60))
Widget shopTabPillShopPreview() => previewPiece(
  const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ShopTabPill(
        label: 'Colruyt',
        active: true,
        color: Color(0xFFE8791A),
        count: 4,
      ),
      SizedBox(width: 8),
      ShopTabPill(
        label: 'Colruyt',
        active: false,
        color: Color(0xFFE8791A),
      ),
    ],
  ),
);
