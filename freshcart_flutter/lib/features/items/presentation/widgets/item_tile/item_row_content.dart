import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/check_circle.dart';
import 'package:freshcart_flutter/core/ui/checked_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What an item row looks like (dot, name, quantity...).
///
/// Used in the list, and also at the top of `ItemMenu` when the row lifts
/// up. Same widget in both places, so they always look the same.
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

  /// The drag handle, before the checkbox. Null outside rearrange mode.
  final Widget? dragHandle;

  /// Who checked this item off. If there's a note, the note is shown
  /// instead.
  final ListMember? checkedByMember;

  /// The search text. Matching letters in the name are shown bold. Null
  /// outside search.
  final String? highlightQuery;

  /// The item name, with the part matching [highlightQuery] in bold. Just a
  /// plain [Text] when not searching (the usual case).
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
                    // At 1, the minus button is removed (not just disabled),
                    // because the quantity can't go below 1.
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

  /// The line under the name: the note if there is one, otherwise (when
  /// checked) who checked it. The note wins because it's an instruction
  /// for the shopper.
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
