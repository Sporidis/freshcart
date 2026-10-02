import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_tabs/shop_tabs_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';

/// The row of shop tabs: "All", one [ShopTabPill] per shop, and a dashed
/// "+" to add a shop.
///
/// Design v3: the pills are plain, and one accent highlight slides behind
/// the selected one. It's placed by measuring the pills after layout, so it
/// follows labels and counts as their widths change.
///
/// Picking a tab filters the items and changes the screen's colour. Both
/// come from [ShopTabsController], so they always match. A swipe on the
/// strip changes tabs the same way as tapping.
///
/// Always shown, even with no shops, so "+" is always there.
class ShopFilterBar extends ConsumerStatefulWidget {
  /// Creates the bar for [listId].
  const ShopFilterBar({
    required this.listId,
    required this.revealKey,
    super.key,
  });

  /// The list whose shops to show.
  final ListId listId;

  /// Used to start the colour wave from the tap (or from the screen edge
  /// for a swipe), before the filter changes.
  final GlobalKey<ShopThemeRevealState> revealKey;

  /// The strip's height. The pills are 36, inside 44px tap targets.
  static const double height = 52;

  @override
  ConsumerState<ShopFilterBar> createState() => _ShopFilterBarState();
}

class _ShopFilterBarState extends ConsumerState<ShopFilterBar> {
  /// One key per tab, to measure where the highlight goes. Null is "All".
  final Map<ShopId?, GlobalKey> _pillKeys = {};
  final GlobalKey _rowKey = GlobalKey();

  /// The selected pill's box, relative to the row. Null until measured.
  Rect? _highlight;

  /// False until the highlight has been placed once, so it appears in place
  /// instead of sliding in from the left edge.
  bool _placed = false;

  ShopId? _lastSelected;

  /// Where the finger touched. Saved in onTapDown, used in onTap right
  /// after.
  Offset? _tapOrigin;

  /// How far the current swipe has travelled.
  double _swipe = 0;

  // A swipe changes tabs past 86px of travel or 450px/s, as in the design.
  static const double _swipeDistance = 86;
  static const double _swipeVelocity = 450;

  static const double _pillHeight = 36;

  GlobalKey _keyFor(ShopId? id) => _pillKeys.putIfAbsent(id, GlobalKey.new);

  /// After layout, moves the highlight under the selected pill.
  void _measure(ShopId? selected) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = _rowKey.currentContext?.findRenderObject();
      final pill = _pillKeys[selected]?.currentContext?.findRenderObject();
      if (row is! RenderBox || pill is! RenderBox) return;
      if (!row.hasSize || !pill.hasSize) return;
      final rect = pill.localToGlobal(Offset.zero, ancestor: row) & pill.size;
      if (rect != _highlight) setState(() => _highlight = rect);
      if (!_placed) {
        // From the next frame on, changes slide.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _placed = true);
        });
      }
    });
  }

  /// Keeps the selected pill on screen (after a swipe, it may not be).
  void _scrollTo(ShopId? selected) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pillContext = _pillKeys[selected]?.currentContext;
      if (pillContext == null || !mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          pillContext,
          alignment: .5,
          duration: AppMotion.durationFor(context, AppMotion.shopHighlight),
          curve: AppMotion.enter,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(shopTabsControllerProvider(widget.listId));
    final theme = Theme.of(context);
    final revealKey = widget.revealKey;

    _measure(s.selected);
    if (s.selected != _lastSelected) {
      if (_placed) _scrollTo(s.selected);
      _lastSelected = s.selected;
    }

    // Backup start point if there's no tap position. Shouldn't happen,
    // because onTapDown always runs before onTap.
    Offset fallbackOrigin() {
      final box = revealKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
      return Offset.zero;
    }

    // The wave must start BEFORE the filter changes (it screenshots the old
    // colour, see [ShopThemeRevealState.beginReveal]). So every tab change
    // goes through here.
    void select(ShopId? shopId, Offset? origin) {
      revealKey.currentState?.beginReveal(origin ?? fallbackOrigin());
      ref
          .read(shopTabsControllerProvider(widget.listId).notifier)
          .select(shopId);
    }

    // A swipe has no tap position, so the wave starts from a screen edge:
    // next tab from the right edge, previous tab from the left edge.
    Offset? edgeOrigin(int delta) {
      final box = revealKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      final dx = delta > 0 ? box.size.width : 0.0;
      return box.localToGlobal(Offset(dx, box.size.height / 2));
    }

    void step(int delta) {
      final target = s.neighbour(delta);
      if (target != null) select(target.shopId, edgeOrigin(delta));
    }

    Color colorOf(Shop shop) =>
        Color(ref.watch(effectiveShopColorProvider(shop)).argb);
    Color accent = theme.colorScheme.onSurface;
    for (final shop in s.tabs) {
      if (shop.id == s.selected) accent = colorOf(shop);
    }

    final highlight = _highlight;

    return SizedBox(
      height: ShopFilterBar.height,
      child: GestureDetector(
        // `translucent`, so the pills underneath still get their taps. This
        // only adds a reaction to a sideways swipe.
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _swipe = 0,
        onHorizontalDragUpdate: (details) => _swipe += details.delta.dx,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          final far = _swipe.abs() >= _swipeDistance;
          final fast = velocity.abs() >= _swipeVelocity;
          if (!far && !fast) return;
          final leftward = far ? _swipe < 0 : velocity < 0;
          step(leftward ? 1 : -1);
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: (ShopFilterBar.height - AppSpacing.minTapTarget) / 2,
          ),
          child: Stack(
            children: [
              if (highlight != null)
                AnimatedPositioned(
                  duration: _placed
                      ? AppMotion.durationFor(context, AppMotion.shopHighlight)
                      : Duration.zero,
                  curve: AppMotion.enter,
                  left: highlight.left,
                  width: highlight.width,
                  // The pill is 36 inside its 44px tap target.
                  top: highlight.top + (highlight.height - _pillHeight) / 2,
                  height: _pillHeight,
                  child: AnimatedContainer(
                    duration: AppMotion.durationFor(
                      context,
                      AppMotion.standard,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              Row(
                key: _rowKey,
                children: [
                  ShopTabPill(
                    key: _keyFor(null),
                    label: t.shops.all,
                    active: s.selected == null,
                    showFill: false,
                    count: s.remainingIn(null),
                    onTapDown: (details) => _tapOrigin = details.globalPosition,
                    onTap: () => select(null, _tapOrigin),
                  ),
                  for (final shop in s.tabs) ...[
                    const SizedBox(width: AppSpacing.gapSmall),
                    ShopTabPill(
                      key: _keyFor(shop.id),
                      label: shop.name,
                      active: s.selected == shop.id,
                      showFill: false,
                      color: colorOf(shop),
                      count: s.remainingIn(shop.id),
                      onTapDown: (details) =>
                          _tapOrigin = details.globalPosition,
                      onTap: () => select(shop.id, _tapOrigin),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.gapSmall),
                  _AddShopPill(
                    tooltip: t.shops.add,
                    onTap: () =>
                        addShop(context, ref, widget.listId, s.allShops),
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

/// The dashed 36px "+" at the end of the tabs. Opens [addShop]. It's not a
/// tab and can't be selected.
class _AddShopPill extends StatelessWidget {
  const _AddShopPill({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapTarget(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: SizedBox.square(
          dimension: 36,
          child: CustomPaint(
            painter: DashedOutlinePainter(
              color: theme.colorScheme.onSurface.withValues(alpha: .36),
              strokeWidth: 1.5,
            ),
            child: Icon(
              Icons.add,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
