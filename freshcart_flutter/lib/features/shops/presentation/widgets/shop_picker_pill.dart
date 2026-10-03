import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// A pill for picking where something goes: the product sheet's "Where",
/// the Move sheet, the hold menu's Move, and the onboarding shops step.
///
/// Different from a shop *tab* on purpose: a tab filters, this chooses. It's
/// 40px and always tinted, so every option reads as tappable:
/// - idle: the shop colour at 9% (16% in dark), ink text, a dot;
/// - picked: the solid shop colour with its on-colour text, the dot swaps
///   for a tick, and a soft coloured shadow lifts it.
///
/// [color] null is "No shop": the fill colour with a hollow dot when idle,
/// ink when picked.
class ShopPickerPill extends StatelessWidget {
  const ShopPickerPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = this.color;
    final ink = scheme.onSurface;
    // The ink-on-paper button colours: ink in light mode, paper in dark.
    final inkFg = isDark ? AppColors.ink : Colors.white;

    final Color bg;
    final Color fg;
    if (selected) {
      bg = color ?? ink;
      fg = color == null ? inkFg : AppTheme.onColorFor(color);
    } else {
      bg = color?.withValues(alpha: isDark ? .16 : .09) ?? scheme.fill;
      fg = ink;
    }
    final shadow =
        color?.withValues(alpha: .32) ?? Colors.black.withValues(alpha: .18);
    final duration = AppMotion.durationFor(context, AppMotion.standard);

    return Semantics(
      button: true,
      selected: selected,
      child: TapTarget(
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.enter,
          height: height,
          padding: const EdgeInsets.fromLTRB(13, 0, 16, 0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: selected ? shadow : shadow.withValues(alpha: 0),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 14,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: selected ? 0 : 1,
                      duration: AppMotion.durationFor(context, AppMotion.micro),
                      child: _Dot(
                        color: color,
                        ringColor: scheme.onSurfaceVariant,
                      ),
                    ),
                    AnimatedScale(
                      scale: selected ? 1 : .4,
                      duration: duration,
                      curve: AppMotion.curveFor(context, AppMotion.pop),
                      child: AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: AppMotion.durationFor(
                          context,
                          AppMotion.quick,
                        ),
                        child: Icon(Icons.check_rounded, size: 14, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 15,
                  color: fg,
                ),
                child: Text(label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The idle marker: a 9px dot in the shop colour, or a hollow ring for
/// "No shop".
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.ringColor});

  final Color? color;
  final Color ringColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: color == null ? Border.all(color: ringColor, width: 1.5) : null,
    ),
  );
}

@Preview(group: 'Shops', name: 'Shop picker pill', size: Size(393, 120))
Widget shopPickerPillPreview() => previewPiece(
  Wrap(
    spacing: AppSpacing.sm,
    children: [
      ShopPickerPill(
        label: 'No shop',
        color: null,
        selected: false,
        onTap: () {},
      ),
      ShopPickerPill(
        label: 'Colruyt',
        color: AppColors.swatchOrange,
        selected: true,
        onTap: () {},
      ),
      ShopPickerPill(
        label: 'Aldi',
        color: AppColors.swatchBlue,
        selected: false,
        onTap: () {},
      ),
    ],
  ),
);
