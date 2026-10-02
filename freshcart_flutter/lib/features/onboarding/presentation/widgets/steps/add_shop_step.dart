import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/dashed_add_row.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/add_shop_sheet.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_option.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';

/// Step 3: pick your shops.
///
/// Only the shop list is here, and it scrolls (users can add as many as
/// they want). The tab preview is in `OnboardingFooter`, next to Continue,
/// so it stays visible however long the list gets.
class AddShopStep extends ConsumerWidget {
  const AddShopStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final t = ref.watch(translationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sheetH,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.shopsTitle,
            subtitle: t.onboarding.shopsSubtitle,
          ),
          const SizedBox(height: AppSpacing.screen),
          for (final (index, shop) in s.shopOptions.indexed)
            Padding(
              key: ValueKey(shop.name),
              padding: const EdgeInsets.only(bottom: AppSpacing.gapSmall),
              child: OnboardingEntrance(
                index: index + 2,
                child: ShopOption(
                  name: shop.name,
                  color: shop.color.toColor(),
                  selected: s.isShopSelected(shop.name),
                  onTap: () => controller.toggleShop(shop.name, shop.color),
                ),
              ),
            ),
          OnboardingEntrance(
            index: s.shopOptions.length + 2,
            child: DashedAddRow(
              label: t.onboarding.addShop,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => AddShopSheet(onAdd: controller.addShop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Step 3 · Your shops', size: previewPhone)
Widget addShopStepPreview() => previewPage(const AddShopStep());
