import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The menu that appears when you hold an item: the row lifts up, with the
/// options below it.
///
/// Shown in an [OverlayEntry], not as a dialog or route. A dialog has its
/// own animation and position; this needs to appear exactly where the row
/// is.
class ItemMenu extends StatelessWidget {
  const ItemMenu({
    required this.globalPosition,
    required this.size,
    required this.scale,
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
  final double scale;
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
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        Positioned(
          top: globalPosition.dy,
          left: globalPosition.dx + _cardInset,
          // No `height:`: the card is taller than the row (the options are
          // below it), so it sizes itself.
          width: size.width - _cardInset * 2,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            // The overlay is outside the screen's Scaffold, so it needs its
            // own Material for widgets like Checkbox.
            child: Material(
              type: MaterialType.transparency,
              // Catches taps on empty space inside the card. Without this, a
              // tap on padding or a gap would go through to the dark layer
              // behind and close the menu. (Padding, Column etc. don't
              // catch taps by themselves.)
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    // Theme colour, so the card is dark in dark mode.
                    color: scheme.surface,
                    // v3: 18, a step rounder than rows, so it reads as a
                    // card floating over them.
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      // A black shadow (shadows are always dark), so the
                      // card looks lifted off the list.
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
                        t: t,
                      ),
                    ],
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
    required this.t,
    this.onMove,
    this.onSelectMore,
    this.onRearrange,
    this.shopColor,
  });

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
    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.standard),
      curve: AppMotion.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.durationFor(context, AppMotion.quick),
        child: _moving && onMove != null
            ? _MovePills(
                key: const ValueKey('move'),
                label: t.items.moveTo,
                shops: widget.shops,
                current: widget.currentShop,
                noShopLabel: t.shops.none,
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
                    _MenuOptionRow(
                      icon: Icons.edit_outlined,
                      label: t.items.menuEditDetails,
                      onTap: () => _close(widget.onEdit),
                    ),
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
                    _MenuOptionRow(
                      icon: Icons.reorder,
                      label: t.items.menuRearrangeList,
                      onTap: () => _close(widget.onRearrange),
                    ),
                    _MenuOptionRow(
                      icon: Icons.delete_outline,
                      label: t.common.delete,
                      isDestructive: true,
                      onTap: () => _close(widget.onDelete),
                    ),
                    const Divider(height: 1, indent: 13, endIndent: 13),
                    _MenuOptionRow(
                      icon: Icons.check_box_outlined,
                      label: t.items.menuSelectMore,
                      onTap: () => _close(widget.onSelectMore),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// "Move to" and a pill per shop, "No shop" first, the current one picked.
class _MovePills extends StatelessWidget {
  const _MovePills({
    required this.label,
    required this.shops,
    required this.current,
    required this.noShopLabel,
    required this.onPick,
    super.key,
  });

  final String label;
  final List<Shop> shops;
  final ShopId? current;
  final String noShopLabel;
  final ValueChanged<ShopId?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.secondaryStrong.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ShopPickerPill(
                label: noShopLabel,
                color: null,
                selected: current == null,
                onTap: () => onPick(null),
              ),
              for (final shop in shops)
                ShopPickerPill(
                  label: shop.name,
                  color: shop.color.toColor(),
                  selected: shop.id == current,
                  onTap: () => onPick(shop.id),
                ),
            ],
          ),
        ],
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
