import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';

/// What the user chose to do with a shop's products.
typedef ShopDeletion = ({ShopItemDisposition disposition, ShopId? moveTo});

/// Asks what happens to a shop's products before deleting it.
///
/// Never a bare confirm. A shop holding six products is not the same decision
/// as an empty one, so the count leads and the options are real alternatives
/// rather than OK and Cancel — the design's rule is that products are never
/// destroyed silently, and a confirm dialog that quietly untags them is only
/// a kinder way of being silent.
///
/// An empty shop skips the choice entirely: there is nothing to decide.
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

  /// How many products are tagged to it.
  final int itemCount;

  /// The other shops on this list, as possible destinations.
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

    // Scrollable, because the option list grows with the household's shops:
    // a fixed column reads fine with two and overflows with six.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        0,
        AppSpacing.sheetH,
        AppSpacing.screen,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.shops.deleteTitle(name: shop.name),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.gapSmall),
          Text(
            itemCount == 0
                ? t.shops.deleteEmpty
                : t.shops.deleteHolds(name: shop.name, n: itemCount),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.screen),
          if (itemCount > 0) ...[
            // The safe ways out first -- each keeps every product.
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
            // Then a clear break before the one option that destroys
            // something: it must never read as "one more of the above".
            const SizedBox(height: AppSpacing.gapSmall),
            const Divider(),
            const SizedBox(height: AppSpacing.gap),
            _Option(
              leading: const Icon(
                Icons.delete_outline,
                size: AppSizes.quantityIcon,
                color: AppColors.destructive,
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
            // The design's destructive button: red, named for exactly what
            // it deletes -- not the ink primary every safe action uses.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop((
                disposition: ShopItemDisposition.untag,
                moveTo: null,
              )),
              child: Text(t.shops.deleteConfirm(name: shop.name)),
            ),
          const SizedBox(height: AppSpacing.gapSmall),
          // Quiet, so it never competes with the choices above it.
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: muted,
              textStyle: AppTextStyles.secondaryStrong,
            ),
            child: Text(t.common.cancel),
          ),
        ],
      ),
    );
  }
}

/// One answer to "what happens to the products". Safe answers carry a
/// chevron (they go somewhere); the destructive one is tinted red instead,
/// and has none -- it ends something.
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

  /// The destructive card's faint red wash and border -- enough to separate
  /// it at a glance without shouting louder than the title.
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
                  ? AppColors.destructive.withValues(alpha: _washAlpha)
                  : null,
              border: Border.all(
                color: destructive
                    ? AppColors.destructive.withValues(alpha: _borderAlpha)
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
                          color: destructive ? AppColors.destructive : null,
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

@Preview(
  group: 'Shops',
  name: 'Delete shop · holds products',
  size: Size(393, 560),
)
Widget deleteShopSheetPreview() {
  Shop shop(String id, String name, int argb) => Shop(
    id: ShopId(id),
    listId: ListId('list-1'),
    name: name,
    color: HexColor.fromArgb(argb),
  );

  return previewApp(
    Scaffold(
      body: DeleteShopSheet(
        shop: shop('s1', 'Colruyt', 0xFFE8791A),
        itemCount: 6,
        siblings: [
          shop('s1', 'Colruyt', 0xFFE8791A),
          shop('s2', 'Albert Heijn', 0xFF2456A6),
        ],
      ),
    ),
  );
}

/// An empty shop needs no decision, so it is not asked for one.
@Preview(group: 'Shops', name: 'Delete shop · empty', size: Size(393, 360))
Widget deleteShopSheetEmptyPreview() => previewApp(
  Scaffold(
    body: DeleteShopSheet(
      shop: Shop(
        id: ShopId('s1'),
        listId: ListId('list-1'),
        name: 'Colruyt',
        color: HexColor.fromArgb(0xFFE8791A),
      ),
      itemCount: 0,
      siblings: const [],
    ),
  ),
);
