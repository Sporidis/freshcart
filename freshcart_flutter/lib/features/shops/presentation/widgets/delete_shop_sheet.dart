import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_sizes.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/destructive_button.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';

/// What the user chose to do with a shop's products.
typedef ShopDeletion = ({ShopItemDisposition disposition, ShopId? moveTo});

/// Asks what should happen to a shop's items before deleting it.
///
/// Not just "OK / Cancel". It shows how many items the shop has, and gives
/// real choices (move them, untag them, or delete them). Items are never
/// removed without the user choosing it.
///
/// An empty shop skips this sheet, there's nothing to decide.
class DeleteShopSheet extends ConsumerWidget {
  /// Creates the sheet for [shop].
  const DeleteShopSheet({
    required this.shop,
    required this.itemCount,
    required this.siblings,
    super.key,
  });

  /// The shop being deleted.
  final Shop shop;

  /// How many items have this shop.
  final int itemCount;

  /// The other shops on this list, where the items could be moved to.
  final List<Shop> siblings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final destinations = [
      for (final other in siblings)
        if (other.id != shop.id) other,
    ];

    final muted = theme.colorScheme.onSurfaceVariant;

    // AppSheetScaffold scrolls, because there's one option per shop. With
    // many shops it wouldn't fit.
    return AppSheetScaffold(
      title: t.shops.deleteTitle(name: shop.name),
      subtitle: itemCount == 0
          ? t.shops.deleteEmpty
          : t.shops.deleteHolds(name: shop.name, n: itemCount),
      children: [
        if (itemCount > 0) ...[
          // Safe options first: these keep all the items.
          for (final target in destinations)
            _Option(
              leading: _Dot(color: target.color.toColor()),
              title: t.shops.moveTo(name: target.name),
              subtitle: t.shops.moveKeeps(n: itemCount),
              onTap: () => Navigator.of(context).pop((
                disposition: ShopItemDisposition.moveToShop,
                moveTo: target.id,
              )),
            ),
          _Option(
            leading: Icon(
              Icons.label_off_outlined,
              size: AppSizes.quantityIcon,
              color: muted,
            ),
            title: t.shops.untag,
            subtitle: t.shops.moveKeeps(n: itemCount),
            onTap: () => Navigator.of(context).pop((
              disposition: ShopItemDisposition.untag,
              moveTo: null,
            )),
          ),
          // Then a gap, and the option that deletes the items, so it's
          // clearly different from the ones above.
          const SizedBox(height: AppSpacing.gapSmall),
          const Divider(),
          const SizedBox(height: AppSpacing.gap),
          _Option(
            leading: Icon(
              Icons.delete_outline,
              size: AppSizes.quantityIcon,
              color: Theme.of(context).colorScheme.error,
            ),
            title: t.shops.deleteItemsToo,
            subtitle: t.shops.deleteItemsBody(n: itemCount),
            destructive: true,
            onTap: () => Navigator.of(context).pop((
              disposition: ShopItemDisposition.deleteItems,
              moveTo: null,
            )),
          ),
        ] else
          // Red button, saying exactly what it deletes.
          DestructiveButton.block(
            onPressed: () => Navigator.of(context).pop((
              disposition: ShopItemDisposition.untag,
              moveTo: null,
            )),
            child: Text(t.shops.deleteConfirm(name: shop.name)),
          ),
        const SizedBox(height: AppSpacing.gapSmall),
        // A plain text button, so it doesn't stand out.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: muted,
            textStyle: AppTextStyles.secondaryStrong,
          ),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}

/// One option in the delete sheet. Safe options have a ">" arrow. The
/// option that deletes items is red, without an arrow.
class _Option extends StatelessWidget {
  const _Option({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  /// The light red background and border of the delete option.
  static const double _washAlpha = 0.06;
  static const double _borderAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gapSmall),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap,
              vertical: AppSpacing.rowVertical,
            ),
            decoration: BoxDecoration(
              color: destructive
                  ? Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: _washAlpha)
                  : null,
              border: Border.all(
                color: destructive
                    ? Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: _borderAlpha)
                    : theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: destructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (!destructive)
                  Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.shopDotLarge,
    height: AppSizes.shopDotLarge,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
