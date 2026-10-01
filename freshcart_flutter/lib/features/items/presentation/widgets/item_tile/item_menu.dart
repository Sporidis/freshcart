import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_row_content.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The row's floating, expanded state once held past the long-press
/// threshold. An [OverlayEntry]'s content, not a route — a route (dialog,
/// menu, bottom sheet) owns its own canned transition and anchors to the
/// screen or a corner, not to this specific row's live position.
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
    this.shopColor,
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
  final ValueChanged<int> onQuantityChanged;
  final Animation<double> strikeProgress;
  final Animation<double> fillProgress;
  final Translations t;
  final ListMember? checkedByMember;
  final bool isMenuClosed;
  final Color? shopColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Full-screen barrier, tap-to-close. Must be listed before the card
        // below — Stack hit-tests the last child first, so a barrier listed
        // after the card would swallow taps meant for the card itself.
        //
        // A plain black scrim, not a scheme colour -- a modal barrier's job
        // is to dim whatever is behind it regardless of that content's own
        // theme, the same reasoning Flutter's own default barrierColor is
        // brightness-invariant.
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        Positioned(
          top: globalPosition.dy,
          left: globalPosition.dx + _cardInset,
          // No `height:` here — the card is taller than the row it grew
          // from once the option list is attached below the header, so it
          // has to size itself to its own content instead of being pinned
          // to the row's original height.
          width: size.width - _cardInset * 2,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            // OverlayEntry content sits outside the screen's own Scaffold,
            // so Checkbox (and anything else Material-dependent) needs its
            // own Material ancestor here.
            child: Material(
              type: MaterialType.transparency,
              // Plain layout boxes (Padding, Column, Row, a decorated
              // Container) don't claim a hit-test on their own -- only an
              // actual interactive widget or an explicitly opaque one does.
              // Without this, a tap on any blank space inside the card (the
              // padding, a gap between rows, the divider) falls straight
              // through to the full-screen barrier below and closes the
              // menu. This absorbs every tap in the card's bounds so only a
              // tap genuinely outside it can reach the barrier.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    // `colorScheme.surface`, not `Colors.white` -- the fixed
                    // white card used to stay white in dark mode too, a
                    // bright rectangle stamped over an otherwise dark screen.
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: [
                      // A plain black shadow either way: an elevation shadow
                      // simulates cast light, not surface colour, the same
                      // reasoning the barrier above stays literal black.
                      // Values from Flow 03 "Hold an item" -- a card that
                      // has actually lifted off the list, not a flat menu.
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

/// The five actions behind a hold, below [ItemRowContent]'s header.
///
/// All five call real callbacks: Edit details and Move to shop both open the
/// same edit flow, Delete removes the row, Select more… seeds the selection
/// with this row, and Rearrange list puts the whole list into rearrange
/// mode.
class _ItemMenuOptions extends StatelessWidget {
  const _ItemMenuOptions({
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.t,
    this.onSelectMore,
    this.onRearrange,
    this.shopColor,
  });

  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSelectMore;
  final VoidCallback? onRearrange;
  final Color? shopColor;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          _MenuOptionRow(
            icon: Icons.edit_outlined,
            label: t.items.menuEditDetails,
            onTap: () {
              onClose();
              onEdit();
            },
          ),
          _MenuOptionRow(
            icon: Icons.arrow_forward_rounded,
            label: t.items.menuMoveToShop,
            onTap: () {
              onClose();
              onEdit();
            },
            trailing: shopColor == null
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: shopColor,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          _MenuOptionRow(
            icon: Icons.reorder,
            label: t.items.menuRearrangeList,
            onTap: () {
              onClose();
              onRearrange?.call();
            },
          ),
          _MenuOptionRow(
            icon: Icons.delete_outline,
            label: t.common.delete,
            isDestructive: true,
            onTap: () {
              onClose();
              onDelete();
            },
          ),
          const Divider(height: 1, indent: 13, endIndent: 13),
          _MenuOptionRow(
            icon: Icons.check_box_outlined,
            label: t.items.menuSelectMore,
            onTap: () {
              onClose();
              onSelectMore?.call();
            },
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
    // `colorScheme.error`/`onSurface`, not the fixed `Theme.of(context).colorScheme.error`/
    // `bgDark` this used to read -- ink text on a white-only assumption went
    // unreadable on the now dark-mode-aware card above.
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
