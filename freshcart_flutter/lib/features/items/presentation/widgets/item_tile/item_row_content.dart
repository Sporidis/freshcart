import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/checked_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/check_circle.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The row's visual content, reused unmodified as `ItemMenu`'s header once
/// it lifts off the list — one object built from one set of data, in both
/// places, so they can never visually drift apart.
class ItemRowContent extends StatelessWidget {
  const ItemRowContent({
    required this.item,
    required this.isChecked,
    required this.onChanged,
    required this.strikeProgress,
    required this.fillProgress,
    required this.onQuantityChanged,
    required this.t,
    this.isMenuClosed = true,
    this.shopColor,
    this.dragHandle,
    this.checkedByMember,
    super.key,
  });

  final ShoppingItem item;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final Animation<double> strikeProgress;
  final Animation<double> fillProgress;
  final bool isMenuClosed;
  final Color? shopColor;
  final ValueChanged<int> onQuantityChanged;
  final Translations t;

  /// Rearrange mode's drag handle, at the row's leading edge ahead of the
  /// checkbox -- the design's own row order. Null outside rearrange mode.
  final Widget? dragHandle;

  /// Who checked this item off, if anyone. A note always wins over showing
  /// this -- see `ItemTile.checkedByMember`.
  final ListMember? checkedByMember;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (dragHandle != null) ...[dragHandle!, const SizedBox(width: 8)],
          CheckCircle(
            value: isChecked,
            onChanged: onChanged,
            fillProgress: fillProgress,
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: shopColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
            width: 10,
            height: 10,
          ),

          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrikeThrough(
                  progress: strikeProgress,
                  color: muted,
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ?_buildSubtitle(muted),
              ],
            ),
          ),
          const SizedBox(width: 8),

          AnimatedSwitcher(
            duration: AppMotion.quick,
            child: isMenuClosed
                ? Text(
                    'x${item.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : QuantityStepper(
                    quantity: item.quantity,
                    // No button at all below 1, not a disabled tap: this
                    // mirrors ShoppingItem.validateQuantity's own floor --
                    // "add at least one" -- so the row can't even attempt an
                    // edit the domain would reject.
                    onDecrement: item.quantity > 1
                        ? () => onQuantityChanged(item.quantity - 1)
                        : null,
                    onIncrement: () => onQuantityChanged(item.quantity + 1),
                  ),
          ),
        ],
      ),
    );
  }

  /// A note if it has one, otherwise -- once checked -- who checked it off.
  /// The note always wins: it is the shopper's own instruction and stays
  /// visible even after the item is in the trolley, same priority
  /// `item_tile.dart`'s own `_buildSubtitle` gives.
  Widget? _buildSubtitle(Color muted) {
    if (item.hasNote) return Text(item.note!.text);

    final member = checkedByMember;
    if (!isChecked || member == null) return null;
    return Text(
      t.items.checkedBy(name: member.displayName),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: muted, fontSize: 12),
    );
  }
}
