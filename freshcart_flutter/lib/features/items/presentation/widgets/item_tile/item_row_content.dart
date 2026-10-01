import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/check_circle.dart';
import 'package:freshcart_flutter/core/ui/checked_state.dart';
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
    this.highlightQuery,
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

  /// Search's query (Motion spec §16: "matching substrings are weight-600
  /// rather than highlighted"), or null outside search -- every other caller
  /// of this row just gets a plain name.
  final String? highlightQuery;

  /// The name, in weight-600 where it matches [highlightQuery] -- a plain
  /// [Text] when there's nothing to match (the overwhelmingly common case,
  /// so it stays the cheap path).
  Widget _nameText(TextStyle? style) {
    final query = highlightQuery?.trim();
    if (query == null || query.isEmpty) return Text(item.name, style: style);
    final name = item.name;
    final index = name.toLowerCase().indexOf(query.toLowerCase());
    if (index < 0) return Text(name, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name.substring(0, index)),
          TextSpan(
            text: name.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: name.substring(index + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.rowVertical,
        horizontal: 16,
      ),
      child: Row(
        children: [
          if (dragHandle != null) ...[dragHandle!, const SizedBox(width: 8)],
          CheckCircle(
            value: isChecked,
            onChanged: onChanged,
            fillProgress: fillProgress,
          ),
          const SizedBox(width: AppSpacing.gap),
          Container(
            decoration: BoxDecoration(
              color: shopColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
            width: AppSizes.shopDot,
            height: AppSizes.shopDot,
          ),

          const SizedBox(width: AppSpacing.gap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrikeThrough(
                  progress: strikeProgress,
                  color: muted,
                  child: _nameText(theme.textTheme.bodyLarge),
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
                    style: theme.textTheme.bodySmall,
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
    if (item.hasNote) {
      return Text(
        item.note!.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: muted),
      );
    }

    final member = checkedByMember;
    if (!isChecked || member == null) return null;
    return Text(
      t.items.checkedBy(name: member.displayName),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption.copyWith(color: muted),
    );
  }
}
