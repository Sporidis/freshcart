import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/check_circle.dart';

/// One shop on the "Where do you shop?" step: its colour dot, its name, and
/// whether it is picked.
///
/// The dot is the only place the shop's colour appears. The check is the
/// app's ink [CheckCircle], the same one an item row uses -- picking a shop
/// and checking an item are the same gesture, so they look the same, and
/// the shop's colour stays a label rather than also becoming a state.
class ShopOption extends StatefulWidget {
  const ShopOption({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ShopOption> createState() => _ShopOptionState();
}

class _ShopOptionState extends State<ShopOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: AppMotion.bouncy,
    value: widget.selected ? 1 : 0,
  );

  @override
  void didUpdateWidget(ShopOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    _fill.duration = AppMotion.durationFor(context, AppMotion.bouncy);
    unawaited(widget.selected ? _fill.forward() : _fill.reverse());
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: widget.selected,
      child: AnimatedScale(
        scale: widget.selected ? 1.015 : 1,
        duration: AppMotion.durationFor(context, AppMotion.quick),
        curve: AppMotion.curveFor(context, AppMotion.pop),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap,
                vertical: AppSpacing.rowVertical,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.shopDotLarge,
                    height: AppSizes.shopDotLarge,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  CheckCircle(value: widget.selected, fillProgress: _fill),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(
  group: 'Onboarding',
  name: 'Shop option · both states',
  size: Size(393, 200),
)
Widget shopOptionPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      ShopOption(
        name: 'Albert Heijn',
        color: AppColors.swatchBlue,
        selected: true,
        onTap: () {},
      ),
      ShopOption(
        name: 'Delhaize',
        color: AppColors.swatchRed,
        selected: false,
        onTap: () {},
      ),
    ],
  ),
);
