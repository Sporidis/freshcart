import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/add_shop_sheet.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_option.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_tabs_preview.dart';

class AddShopStep extends ConsumerWidget {
  const AddShopStep({super.key});

  static const shops = [
    ('Albert Heijn', AppColors.swatchBlue),
    ('Colruyt', AppColors.swatchOrange),
    ('Delhaize', AppColors.swatchRed),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedShops = ref.watch(
      onboardingControllerProvider.select((state) => state.selectedShops),
    );
    final shopOptions = <(String, Color)>[
      ...shops,
      ...selectedShops
          .where((shop) => !shops.any((preset) => preset.$1 == shop.name))
          .map((shop) => (shop.name, _flutterColor(shop.color))),
    ];
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do you shop?', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.gapSmall),
          Text(
            "Each shop gets its own tab and colour. Pick a colour you'll recognize in the aisle.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.gap * 2),
          ...shopOptions.indexed.map(
            (entry) => Padding(
              key: ValueKey(entry.$2.$1),
              padding: const EdgeInsets.only(bottom: AppSpacing.gap),
              child: ShopOptionEntrance(
                index: entry.$1,
                child: ShopOption(
                  name: entry.$2.$1,
                  color: entry.$2.$2,
                  selected: selectedShops.any(
                    (item) => item.name == entry.$2.$1,
                  ),
                  onTap: () => controller.toggleShop(
                    entry.$2.$1,
                    HexColor.fromArgb(entry.$2.$2.toARGB32()),
                  ),
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => AddShopSheet(onAdd: controller.addShop),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              alignment: Alignment.centerLeft,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
            ),
            child: Text(
              '+ Add a shop not listed',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          ShopTabsPreview(shops: selectedShops),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Color _flutterColor(HexColor color) => Color.fromARGB(
  color.alpha,
  color.red,
  color.green,
  color.blue,
);
