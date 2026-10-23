import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu/item_menu_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu/item_menu_options.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
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
                                  ItemMenuOptions(
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

// ── Placement and unroll ────────────────────────────────────────────────

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
