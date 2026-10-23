import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker_pill.dart';

/// "Move to" and a pill per shop, "No shop" first, the current one picked.
///
/// v3 entrance when it replaces the options: the block fades in, falling
/// 6px (240ms), and each pill pops from 90% with a small overshoot, 260ms
/// each, 40ms apart from 60ms.
class MoveToShopPills extends StatefulWidget {
  const MoveToShopPills({
    required this.label,
    required this.shops,
    required this.current,
    required this.noShopLabel,
    required this.reduced,
    required this.onPick,
    super.key,
  });

  final String label;
  final List<Shop> shops;
  final ShopId? current;
  final String noShopLabel;
  final bool reduced;
  final ValueChanged<ShopId?> onPick;

  @override
  State<MoveToShopPills> createState() => _MoveToShopPillsState();
}

class _MoveToShopPillsState extends State<MoveToShopPills>
    with SingleTickerProviderStateMixin {
  static const int _blockMs = 240;
  static const int _pillStart = 60;
  static const int _pillStep = 40;
  static const int _pillMs = 260;

  /// "No shop" plus every shop.
  int get _pills => widget.shops.length + 1;
  int get _totalMs =>
      math.max(_blockMs, _pillStart + (_pills - 1) * _pillStep + _pillMs);

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
    value: widget.reduced ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) unawaited(_in.forward());
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Animation<double> _slice(int startMs, int lengthMs, Curve curve) =>
      CurvedAnimation(
        parent: _in,
        curve: Interval(
          startMs / _totalMs,
          math.min(1, (startMs + lengthMs) / _totalMs),
          curve: curve,
        ),
      );

  Widget _pill(int index, Widget child) => ScaleTransition(
    scale: Tween(begin: .9, end: 1.0).animate(
      _slice(_pillStart + index * _pillStep, _pillMs, AppMotion.pop),
    ),
    child: FadeTransition(
      opacity: _slice(_pillStart + index * _pillStep, _pillMs, Curves.linear),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = _slice(0, _blockMs, AppMotion.enter);
    return FadeTransition(
      opacity: block,
      child: AnimatedBuilder(
        animation: block,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -6 * (1 - block.value)),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.secondaryStrong.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _pill(
                    0,
                    ShopPickerPill(
                      label: widget.noShopLabel,
                      color: null,
                      selected: widget.current == null,
                      onTap: () => widget.onPick(null),
                    ),
                  ),
                  for (final (i, shop) in widget.shops.indexed)
                    _pill(
                      i + 1,
                      ShopPickerPill(
                        label: shop.name,
                        color: shop.color.toColor(),
                        selected: shop.id == widget.current,
                        onTap: () => widget.onPick(shop.id),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
