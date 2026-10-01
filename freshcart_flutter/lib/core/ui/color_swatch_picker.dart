import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// A row of colour circles to pick one from: a shop's tab colour, or a
/// person's avatar colour.
///
/// One widget in `core/ui` because three screens drew their own copy (edit
/// shop, onboarding's add-a-shop sheet, edit profile) at three different
/// sizes with two different "selected" looks. The design has one: a 32 px
/// circle that gains an ink ring and a small white centre when picked.
///
/// Each circle sits in a 44 px tap target, so the visible gap between
/// circles comes from that target rather than from extra spacing.
class ColorSwatchPicker extends StatelessWidget {
  /// Creates the picker over [colors], with [selected] picked (if any).
  const ColorSwatchPicker({
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    this.keyPrefix = 'swatch-',
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final List<Color> colors;

  /// The picked colour, or null when none of [colors] is.
  final Color? selected;

  /// Called with the tapped colour. Null disables every swatch (e.g. while a
  /// previous pick is still saving).
  final ValueChanged<Color>? onSelected;

  /// What a screen reader announces before each swatch's position ("Tab
  /// colour 3"). Without a number, eight swatches would all sound the same.
  final String? semanticLabel;

  /// Prefix for each swatch's key, followed by its ARGB value -- lets a test
  /// tap one specific colour instead of guessing at an index.
  final String keyPrefix;

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;
    return Wrap(
      alignment: alignment,
      children: [
        for (final (index, color) in colors.indexed)
          _Swatch(
            key: ValueKey('$keyPrefix${color.toARGB32()}'),
            color: color,
            selected: selected?.toARGB32() == color.toARGB32(),
            label: semanticLabel == null ? null : '$semanticLabel ${index + 1}',
            onTap: onSelected == null ? null : () => onSelected(color),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final String? label;
  final VoidCallback? onTap;

  static const double _ringWidth = 2.5;
  static const double _centreDot = 9;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: AppSpacing.minTapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.durationFor(context, AppMotion.quick),
              curve: AppMotion.enter,
              width: AppSizes.swatch,
              height: AppSizes.swatch,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ink : ink.withValues(alpha: 0),
                  width: _ringWidth,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: AppMotion.durationFor(context, AppMotion.quick),
                curve: AppMotion.curveFor(context, AppMotion.pop),
                child: const SizedBox.square(
                  dimension: _centreDot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(group: 'Core', name: 'Colour swatch picker', size: Size(393, 140))
Widget colorSwatchPickerPreview() => previewPiece(
  ColorSwatchPicker(
    colors: AppColors.presetShopColors,
    selected: AppColors.swatchPurple,
    onSelected: (_) {},
  ),
);
