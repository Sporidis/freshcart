import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';

/// The button/pill itself. At [openness] 0 it's a round button in the
/// shop's colour, at 1 a wide white pill.
///
/// A separate widget so `Theme.of(context)` reads the theme from inside
/// WaveThemed. That way its colours change with the wave (decisions.md
/// #90).
class QuickAddPill extends StatelessWidget {
  const QuickAddPill({
    required this.openness,
    required this.width,
    required this.height,
    required this.field,
    required this.button,
    super.key,
  });

  final double openness;
  final double width;
  final double height;

  /// The text field. Null when fully closed, so WaveThemed can safely build
  /// this twice.
  final Widget? field;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = this.field;
    // The background goes from shop colour to white as it opens.
    final fill = Color.lerp(
      theme.colorScheme.primary,
      theme.colorScheme.surface,
      openness,
    )!;
    // The shadow: shop-coloured when closed, grey when open. Material's
    // `elevation` shadow can only be grey, so we draw our own shadow and
    // leave elevation at 0.
    final shadowColor = Color.lerp(
      theme.colorScheme.primary.withValues(alpha: 0.35),
      Colors.black.withValues(alpha: 0.10),
      openness.clamp(0.0, 1.0),
    )!;
    // One StadiumBorder for both: when width == height it's a circle, when
    // wider it's a pill.
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          key: const ValueKey('quick-add-pill'),
          color: fill,
          elevation: 0,
          shape: StadiumBorder(
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: openness.clamp(0.0, 1.0),
              ),
            ),
          ),
          child: Row(
            children: [
              if (field != null)
                Expanded(
                  // The placeholder fades in during the last 40% of opening,
                  // once there's room for it.
                  child: Opacity(
                    opacity: ((openness - 0.6) / 0.4).clamp(0.0, 1.0),
                    child: field,
                  ),
                ),
              button,
            ],
          ),
        ),
      ),
    );
  }
}
