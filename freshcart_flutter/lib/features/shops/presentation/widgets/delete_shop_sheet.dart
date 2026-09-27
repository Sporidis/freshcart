import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/hex_color_x.dart';

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

    // Scrollable, because the option list grows with the household's shops:
    // a fixed column reads fine with two and overflows with six.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        8,
        AppSpacing.sheetH,
        30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.shops.deleteTitle(name: shop.name),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            itemCount == 0
                ? t.shops.deleteEmpty
                : t.shops.deleteHolds(name: shop.name, n: itemCount),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (itemCount > 0) ...[
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
              leading: const Icon(Icons.label_off_outlined, size: 20),
              title: t.shops.untag,
              subtitle: t.shops.moveKeeps(n: itemCount),
              onTap: () => Navigator.of(context).pop((
                disposition: ShopItemDisposition.untag,
                moveTo: null,
              )),
            ),
            _Option(
              leading: const Icon(
                Icons.delete_outline,
                size: 20,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop((
                  disposition: ShopItemDisposition.untag,
                  moveTo: null,
                )),
                child: Text(t.shops.delete),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: destructive
                  ? AppColors.destructive.withValues(alpha: 0.3)
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
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
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
