import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// A row of colour circles to pick one from: a shop's tab colour, or a
/// person's avatar colour.
///
/// Used by edit shop, onboarding and edit profile. Each circle is 32 px and
/// gets a dark ring with a white dot when selected.
///
/// Each circle sits in a 44 px tap area. That tap area is also what creates
/// the space between the circles.
class ColorSwatchPicker extends StatelessWidget {
  /// Creates the picker over [colors], with [selected] picked (if any).
  const ColorSwatchPicker({
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    this.marked = const {},
    this.keyPrefix = 'swatch-',
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final List<Color> colors;

  /// The picked colour, or null when none of [colors] is.
  final Color? selected;

  /// Called with the tapped colour. If null, nothing can be tapped (for
  /// example while the last choice is still saving).
  final ValueChanged<Color>? onSelected;

  /// What a screen reader says for each circle, followed by its number
  /// ("Tab colour 3").
  final String? semanticLabel;

  /// Colours other shops already use, with a note for screen readers
  /// ("Used by Albert Heijn"). The key is the colour's ARGB value.
  ///
  /// These can still be picked, they just get a mark. Two shops can have the
  /// same colour if the user really wants.
  final Map<int, String> marked;

  /// Start of each circle's key (followed by its ARGB value), so tests can
  /// tap a specific colour.
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
            taken: marked.containsKey(color.toARGB32()),
            label: [
              if (semanticLabel case final label?) '$label ${index + 1}',
              ?marked[color.toARGB32()],
            ].join(', '),
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
    required this.taken,
    required this.label,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;

  /// Already used by another shop: shows a white ring inside the circle.
  /// If the circle is also selected, only the selected look is shown.
  final bool taken;
  final String label;
  final VoidCallback? onTap;

  static const double _ringWidth = 2.5;
  static const double _centreDot = 9;
  static const double _takenRing = 14;
  static const double _takenRingWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final quick = AppMotion.durationFor(context, AppMotion.quick);
    return Semantics(
      button: true,
      selected: selected,
      label: label.isEmpty ? null : label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: AppSpacing.minTapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: quick,
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: taken && !selected ? 1 : 0,
                    duration: quick,
                    child: Container(
                      width: _takenRing,
                      height: _takenRing,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: _takenRingWidth,
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: quick,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
