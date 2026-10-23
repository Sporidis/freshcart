import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/check_circle.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/checked_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/quantity_stepper.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What an item row looks like (design v3): check ring, name with an
/// optional subtitle, and "×2" on the right.
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
    this.shopName,
    this.isSelecting = false,
    this.faded = false,
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

  /// The item's shop colour: the check fills with it. Null is "No shop",
  /// which fills grey.
  final Color? shopColor;

  /// Shown before the note in the subtitle. Pass it on the All tab only:
  /// there the row has no other sign of its shop; on a shop tab, it's
  /// already obvious.
  final String? shopName;

  /// In select mode the circle means "selected", so it fills with ink, not
  /// the shop colour.
  final bool isSelecting;

  /// The row is in Done: it steps back to 45%.
  final bool faded;
  final ValueChanged<int> onQuantityChanged;
  final Translations t;

  /// The drag handle, before the checkbox. Null outside rearrange mode.
  final Widget? dragHandle;

  /// Who checked this item off. A checked row always shows them first,
  /// with their avatar, ahead of the shop and note.
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
    final fill = isSelecting ? null : shopColor ?? AppColors.shopColorFallback;
    final fade = AppMotion.durationFor(context, AppMotion.standard);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: faded ? 52 : 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
        child: Row(
          spacing: 14,
          children: [
            ?dragHandle,
            AnimatedOpacity(
              opacity: faded ? .45 : 1,
              duration: fade,
              child: CheckCircle(
                value: isChecked,
                onChanged: onChanged,
                fillProgress: fillProgress,
                color: fill,
                tickColor: fill == null ? null : AppTheme.onColorFor(fill),
              ),
            ),
            Expanded(
              child: AnimatedOpacity(
                opacity: faded ? .45 : 1,
                duration: fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrikeThrough(
                      progress: strikeProgress,
                      color: muted,
                      child: _nameText(
                        theme.textTheme.bodyLarge?.copyWith(height: 21 / 16),
                      ),
                    ),
                    ?_buildSubtitle(muted),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.quick,
              child: isMenuClosed
                  ? _Quantity(quantity: item.quantity, faded: faded)
                  : QuantityStepper(
                      quantity: item.quantity,
                      decreaseLabel: t.items.decrease,
                      increaseLabel: t.items.increase,
                      // At 1, the minus button is removed (not just
                      // disabled), because the quantity can't go below 1.
                      onDecrement: item.quantity > 1
                          ? () => onQuantityChanged(item.quantity - 1)
                          : null,
                      onIncrement: () => onQuantityChanged(item.quantity + 1),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The line under the name: the shop (All tab only) and the note, joined
  /// with " · ".
  ///
  /// A checked row leads with who checked it: their avatar (photo if they
  /// have one) and "Checked off by Sam", then the shop and note after a
  /// " · ". It used to be shown only when there was no shop or note, so
  /// on the All tab, where nearly every row names its shop, it never
  /// appeared. Who got it matters most once it's in the basket.
  Widget? _buildSubtitle(Color muted) {
    final style = AppTextStyles.caption.copyWith(
      fontSize: 13,
      height: 17 / 13,
      color: muted,
    );
    final parts = [?shopName, if (item.hasNote) item.note!.text];
    final member = checkedByMember;

    if (isChecked && member != null) {
      final text = [
        t.items.checkedBy(name: member.displayName),
        ...parts,
      ].join(' · ');
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          spacing: 6,
          children: [
            UserAvatar(
              seed: member.userId.value,
              initial: initialFor(member.displayName),
              photoUrl: member.avatarPhotoUrl,
              color: member.avatarColor,
              radius: _checkerAvatar / 2,
            ),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      );
    }

    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  /// The checker's avatar on a checked row: about the height of the line.
  static const double _checkerAvatar = 16;
}

/// "×2" in secondary ink, nothing for 1: one of something is the default and
/// doesn't need saying.
class _Quantity extends StatelessWidget {
  const _Quantity({required this.quantity, required this.faded});

  final int quantity;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    if (quantity <= 1) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: faded ? .6 : 1,
      duration: AppMotion.durationFor(context, AppMotion.standard),
      child: Text(
        '×$quantity',
        style: AppTextStyles.body.copyWith(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
