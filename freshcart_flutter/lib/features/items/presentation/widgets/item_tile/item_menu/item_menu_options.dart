import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_menu/move_to_shop_pills.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The options in the hold menu:
/// - Edit details: opens the edit sheet;
/// - Move to shop: swaps the options for shop pills, right in the card
///   (design v3), so moving is one more tap, not a sheet;
/// - Rearrange list, Delete, Select more….
class ItemMenuOptions extends StatefulWidget {
  const ItemMenuOptions({
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
    super.key,
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
  State<ItemMenuOptions> createState() => _ItemMenuOptionsState();
}

class _ItemMenuOptionsState extends State<ItemMenuOptions> {
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
          ? MoveToShopPills(
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

// ── Building blocks ─────────────────────────────────────────────────────

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
