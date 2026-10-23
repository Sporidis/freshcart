import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// One shop tab: "All" or a single shop (design v3: a plain 36px pill).
///
/// Unselected: a hairline outline, ink text, a dot in the shop's colour
/// ("All" has no dot), and the remaining count at 60%. Selected: the text
/// and dot turn to the on-colour. The fill comes from one of two places:
/// - the strip draws a single highlight that slides between tabs, and
///   passes `showFill: false`;
/// - standalone (previews, onboarding) the pill fills itself.
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
    this.showFill = true,
    super.key,
  });

  /// Whether a selected pill paints its own fill. The strip turns this off
  /// because its sliding highlight is the fill.
  final bool showFill;

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
    final active = widget.active;
    final fg = active ? onFill : theme.colorScheme.onSurface;
    final count = widget.count;
    final duration = AppMotion.durationFor(context, AppMotion.standard);

    return TapTarget(
      onTap: _handleTap,
      onTapDown: widget.onTapDown,
      child: ScaleTransition(
        scale: _kickScale,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.enter,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active && widget.showFill ? fill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.color != null) ...[
                AnimatedContainer(
                  duration: duration,
                  width: AppSizes.tabDot,
                  height: AppSizes.tabDot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? onFill : widget.color,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: duration,
                style: AppTextStyles.secondaryStrong.copyWith(
                  fontSize: 14,
                  color: fg,
                ),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      // A "0" badge looks broken, so an empty tab shows none.
                      if (count != null && count > 0)
                        TextSpan(
                          text: '  $count',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: fg.withValues(alpha: .6),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
