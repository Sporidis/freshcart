import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
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
    final t = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Matches the design's own split: the shop list scrolls in its own
        // `flex:1` area (there is no cap on how many shops someone adds),
        // while the tabs preview below stays pinned as a fixed footer —
        // a plain Column here would either overflow once enough shops (or a
        // taller keyboard-shrunk viewport) push past the available height,
        // or push the preview off-screen instead of keeping it in view.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.onboarding.shopsTitle,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.gapSmall),
                Text(
                  t.onboarding.shopsSubtitle,
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
                    '+ ${t.onboarding.addShop}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gap),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ShopTabsPreview(shops: selectedShops, t: t),
        ),
      ],
    );
  }
}

Color _flutterColor(HexColor color) => Color.fromARGB(
  color.alpha,
  color.red,
  color.green,
  color.blue,
);

@Preview(group: 'Onboarding', name: 'Step 3 · Your shops', size: previewPhone)
Widget addShopStepPreview() => previewPage(const AddShopStep());
