import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// One shop tab: "All" or a single shop.
///
/// When selected, the whole pill is filled with the shop's colour. When
/// not, it shows a small coloured dot. "All" has no dot.
///
/// This widget only draws. The parent tells it if it's selected and how
/// many items are left.
class ShopTabPill extends StatefulWidget {
  /// Creates the pill. Pass `color: null` for the "All" tab.
  const ShopTabPill({
    required this.label,
    required this.active,
    this.color,
    this.count,
    this.onTap,
    this.onTapDown,
    super.key,
  });

  /// "All", or the shop's name.
  final String label;

  /// Whether this is the currently selected tab.
  final bool active;

  /// The shop's colour, or null for the neutral "All" tab.
  final Color? color;

  /// How many items are still unchecked in this tab. Hidden when 0
  /// (a "0" badge looks broken).
  final int? count;

  final VoidCallback? onTap;

  /// Called before [onTap], with where the finger touched. Used to start
  /// the colour wave from that spot.
  final GestureTapDownCallback? onTapDown;

  @override
  State<ShopTabPill> createState() => _ShopTabPillState();
}

class _ShopTabPillState extends State<ShopTabPill>
    with SingleTickerProviderStateMixin {
  /// A small "pop" when tapped (size 1.0 -> 1.08 -> 1.0), so it looks like
  /// the pill starts the colour wave. See decisions.md #88.
  late final AnimationController _kick = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );

  static const double _kickPeak = 1.08;

  late final Animation<double> _kickScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: _kickPeak,
      ).chain(CurveTween(curve: AppMotion.enter)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: _kickPeak,
        end: 1,
      ).chain(CurveTween(curve: AppMotion.press)),
      weight: 1,
    ),
  ]).animate(_kick);

  @override
  void dispose() {
    _kick.dispose();
    super.dispose();
  }

  void _handleTap() {
    // No pop at all with reduced motion. A pop without the bounce would
    // just be a pause.
    if (!AppMotion.reduced(context)) unawaited(_kick.forward(from: 0));
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The "All" fill: dark in light mode, light in dark mode.
    final fill = widget.color ?? theme.colorScheme.onSurface;
    final onFill = AppTheme.onColorFor(fill);
    final label = (widget.count == null || widget.count == 0)
        ? widget.label
        : '${widget.label} · ${widget.count}';

    return TapTarget(
      onTap: _handleTap,
      onTapDown: widget.onTapDown,
      child: ScaleTransition(
        scale: _kickScale,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _handleTap,
            onTapDown: widget.onTapDown,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: AnimatedContainer(
              duration: AppMotion.durationFor(context, AppMotion.quick),
              curve: AppMotion.enter,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: widget.active ? fill : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: widget.active
                    ? null
                    : Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.color != null) ...[
                    Container(
                      width: AppSizes.tabDot,
                      height: AppSizes.tabDot,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Dot colour: white when selected, the shop's
                        // colour when not.
                        color: widget.active ? onFill : widget.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style:
                        (widget.active
                                ? theme.textTheme.labelLarge
                                : theme.textTheme.labelMedium)
                            ?.copyWith(color: widget.active ? onFill : null),
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
        color: AppColors.swatchOrange,
        count: 4,
      ),
      SizedBox(width: 8),
      ShopTabPill(
        label: 'Colruyt',
        active: false,
        color: AppColors.swatchOrange,
      ),
    ],
  ),
);
