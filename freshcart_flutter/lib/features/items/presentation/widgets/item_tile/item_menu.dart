import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The menu that appears when you hold an item: the row lifts up, with the
/// options below it.
///
/// Shown in an [OverlayEntry], not as a dialog or route. A dialog has its
/// own animation and position; this needs to start exactly where the row
/// is.
///
/// Design v3: the card starts on the row and travels to a place where it
/// fits on screen (a row near the bottom gets its menu moved up), lifting
/// as it goes; the options unroll under it and fall in one by one. All of
/// it comes from [motion].
class ItemMenu extends StatelessWidget {
  const ItemMenu({
    required this.globalPosition,
    required this.size,
    required this.motion,
    required this.item,
    required this.isChecked,
    required this.onChanged,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.strikeProgress,
    required this.fillProgress,
    required this.isMenuClosed,
    required this.t,
    this.onSelectMore,
    this.onRearrange,
    this.shops = const [],
    this.onMove,
    this.shopColor,
    this.shopName,
    this.checkedByMember,
    super.key,
  });

  static const _cardInset = 9.0;

  final Offset globalPosition;
  final Size size;
  final ItemMenuMotion motion;
  final ShoppingItem item;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSelectMore;
  final VoidCallback? onRearrange;
  final List<Shop> shops;
  final ValueChanged<ShopId?>? onMove;
  final ValueChanged<int> onQuantityChanged;
  final Animation<double> strikeProgress;
  final Animation<double> fillProgress;
  final Translations t;
  final ListMember? checkedByMember;
  final bool isMenuClosed;
  final Color? shopColor;
  final String? shopName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // A dark layer over the whole screen. Tap it to close the menu.
        //
        // It must come BEFORE the card in this Stack. A Stack checks taps on
        // the last child first, so if it came after, it would catch taps
        // meant for the card.
        //
        // Plain black (not a theme colour), because it just darkens
        // whatever is behind it, in light and dark mode.
        //
        // It fades in and out with the card.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: motion.close.value > 0,
            child: GestureDetector(
              onTap: onClose,
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.15 * motion.opacity.clamp(0, 1),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            // Closing: let taps through to the list straight away.
            ignoring: motion.close.value > 0,
            child: CustomSingleChildLayout(
              delegate: _MenuPlacement(
                row: globalPosition & size,
                inset: _cardInset,
                padding: MediaQuery.paddingOf(context),
                keyboard: MediaQuery.viewInsetsOf(context).bottom,
                travel: motion.travel,
              ),
              child: Opacity(
                opacity: motion.opacity.clamp(0, 1),
                child: Transform.scale(
                  scale: motion.scale,
                  // The overlay is outside the screen's Scaffold, so it
                  // needs its own Material for widgets like Checkbox.
                  child: Material(
                    type: MaterialType.transparency,
                    // Catches taps on empty space inside the card. Without
                    // this, a tap on padding or a gap would go through to
                    // the dark layer behind and close the menu. (Padding,
                    // Column etc. don't catch taps by themselves.)
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          // Theme colour, so the card is dark in dark mode.
                          color: scheme.surface,
                          // v3: 18, a step rounder than rows, so it reads
                          // as a card floating over them.
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            // A black shadow (shadows are always dark), so
                            // the card looks lifted off the list.
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.26),
                              blurRadius: 34,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ItemRowContent(
                              item: item,
                              isChecked: isChecked,
                              onChanged: onChanged,
                              strikeProgress: strikeProgress,
                              fillProgress: fillProgress,
                              isMenuClosed: isMenuClosed,
                              shopColor: shopColor,
                              shopName: shopName,
                              onQuantityChanged: onQuantityChanged,
                              t: t,
                              checkedByMember: checkedByMember,
                            ),
                            // v3 unrolls the body with a clip-path, which
                            // only changes what's painted. A ClipRect with
                            // a growing clip does the same; resizing it
                            // instead (Align.heightFactor) would change the
                            // card's height, and near the bottom of the
                            // screen the card would creep up as it grew.
                            ClipRect(
                              clipper: _Unroll(motion.body),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Divider(
                                    height: 1,
                                    indent: 13,
                                    endIndent: 13,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  _ItemMenuOptions(
                                    onClose: onClose,
                                    onEdit: onEdit,
                                    shops: shops,
                                    currentShop: item.shopId,
                                    onMove: onMove,
                                    onDelete: onDelete,
                                    onSelectMore: onSelectMore,
                                    onRearrange: onRearrange,
                                    shopColor: shopColor,
                                    optionIn: motion.option,
                                    reduced: motion.reduced,
                                    t: t,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Places the menu card: it starts on [row] and, as [travel] goes 0 → 1,
/// moves to the nearest spot where the whole card fits between the status
/// bar and the bottom of the screen (or the keyboard).
///
/// A layout delegate, because only layout knows the card's real height.
/// The card's height doesn't change while it opens (the unroll is a paint
/// clip), so the spot it heads for stays put.
class _MenuPlacement extends SingleChildLayoutDelegate {
  _MenuPlacement({
    required this.row,
    required this.inset,
    required this.padding,
    required this.keyboard,
    required this.travel,
  }) : super(relayout: travel);

  final Rect row;
  final double inset;
  final EdgeInsets padding;
  final double keyboard;
  final Animation<double> travel;

  /// Space kept free above and below the card.
  static const double _margin = 12;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tightFor(
        width: row.width - inset * 2,
      ).copyWith(maxHeight: constraints.maxHeight);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = padding.top + _margin;
    final bottom = size.height - math.max(padding.bottom, keyboard) - _margin;
    // Too tall to fit anywhere: keep its top in view.
    final settled = childSize.height > bottom - top
        ? top
        : row.top.clamp(top, bottom - childSize.height);
    final y = row.top + (settled - row.top) * travel.value;
    return Offset(row.left + inset, y);
  }

  @override
  bool shouldRelayout(_MenuPlacement oldDelegate) =>
      row != oldDelegate.row ||
      padding != oldDelegate.padding ||
      keyboard != oldDelegate.keyboard ||
      travel != oldDelegate.travel;
}

/// Shows the top [progress] of its child, growing downwards.
class _Unroll extends CustomClipper<Rect> {
  _Unroll(this.progress) : super(reclip: progress);

  final Animation<double> progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * progress.value);

  @override
  bool shouldReclip(_Unroll oldClipper) => progress != oldClipper.progress;
}

/// One option falling 6px into place as it fades in (v3).
class _OptionIn extends StatelessWidget {
  const _OptionIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * (1 - animation.value)),
        child: child,
      ),
    ),
  );
}

/// The options in the hold menu:
/// - Edit details: opens the edit sheet;
/// - Move to shop: swaps the options for shop pills, right in the card
///   (design v3), so moving is one more tap, not a sheet;
/// - Rearrange list, Delete, Select more….
class _ItemMenuOptions extends StatefulWidget {
  const _ItemMenuOptions({
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.shops,
    required this.currentShop,
    required this.optionIn,
    required this.reduced,
    required this.t,
    this.onMove,
    this.onSelectMore,
    this.onRearrange,
    this.shopColor,
  });

  /// Option i's entrance, from the menu's motion.
  final Animation<double> Function(int index) optionIn;
  final bool reduced;

  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<Shop> shops;
  final ShopId? currentShop;
  final ValueChanged<ShopId?>? onMove;
  final VoidCallback? onSelectMore;
  final VoidCallback? onRearrange;
  final Color? shopColor;
  final Translations t;

  @override
  State<_ItemMenuOptions> createState() => _ItemMenuOptionsState();
}

class _ItemMenuOptionsState extends State<_ItemMenuOptions> {
  bool _moving = false;

  void _close(VoidCallback? then) {
    widget.onClose();
    then?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final onMove = widget.onMove;
    Widget option(int index, Widget child) =>
        _OptionIn(animation: widget.optionIn(index), child: child);

    // v3 swaps straight to the pills (no crossfade): the pills bring their
    // own entrance. AnimatedSize smooths the card's height change.
    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.standard),
      curve: AppMotion.emphasized,
      alignment: Alignment.topCenter,
      child: _moving && onMove != null
          ? _MovePills(
              key: const ValueKey('move'),
              label: t.items.moveTo,
              shops: widget.shops,
              current: widget.currentShop,
              noShopLabel: t.shops.none,
              reduced: widget.reduced,
              onPick: (shopId) {
                widget.onClose();
                if (shopId != widget.currentShop) onMove(shopId);
              },
            )
          : Padding(
              key: const ValueKey('options'),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  option(
                    0,
                    _MenuOptionRow(
                      icon: Icons.edit_outlined,
                      label: t.items.menuEditDetails,
                      onTap: () => _close(widget.onEdit),
                    ),
                  ),
                  option(
                    1,
                    _MenuOptionRow(
                      icon: Icons.arrow_forward_rounded,
                      label: t.items.menuMoveToShop,
                      // Without a mover (search), fall back to the sheet.
                      onTap: onMove == null
                          ? () => _close(widget.onEdit)
                          : () => setState(() => _moving = true),
                      trailing: widget.shopColor == null
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.shopColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  option(
                    2,
                    _MenuOptionRow(
                      icon: Icons.reorder,
                      label: t.items.menuRearrangeList,
                      onTap: () => _close(widget.onRearrange),
                    ),
                  ),
                  option(
                    3,
                    _MenuOptionRow(
                      icon: Icons.delete_outline,
                      label: t.common.delete,
                      isDestructive: true,
                      onTap: () => _close(widget.onDelete),
                    ),
                  ),
                  const Divider(height: 1, indent: 13, endIndent: 13),
                  option(
                    4,
                    _MenuOptionRow(
                      icon: Icons.check_box_outlined,
                      label: t.items.menuSelectMore,
                      onTap: () => _close(widget.onSelectMore),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// "Move to" and a pill per shop, "No shop" first, the current one picked.
///
/// v3 entrance when it replaces the options: the block fades in, falling
/// 6px (240ms), and each pill pops from 90% with a small overshoot, 260ms
/// each, 40ms apart from 60ms.
class _MovePills extends StatefulWidget {
  const _MovePills({
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
  State<_MovePills> createState() => _MovePillsState();
}

class _MovePillsState extends State<_MovePills>
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

class _MenuOptionRow extends StatelessWidget {
  const _MenuOptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Theme colours (red for Delete, normal text for the rest), so the text
    // is readable in dark mode too.
    final color = isDestructive ? scheme.error : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color.withValues(alpha: isDestructive ? 1 : 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
