import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/add_shop_sheet.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_option.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';

/// Step 3: pick the shops the list will be split by.
///
/// Only the shop list lives here, scrolling in its own area (there is no cap
/// on how many shops someone adds). The "Your tabs will look like this"
/// preview sits in the wizard's footer tray instead, pinned beside Continue
/// -- see `OnboardingFooter` -- so it stays in view however long this list
/// grows, and shares one surface with the button rather than two.
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
            child: _AddShopRow(
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

/// "+ Add a shop not listed": dashed and muted, the design's mark for "add
/// another" -- the same dash as the list screen's permanent "+" tab, so the
/// two read as the same action.
class _AddShopRow extends StatelessWidget {
  const _AddShopRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: CustomPaint(
          painter: DashedOutlinePainter(
            color: theme.colorScheme.outline,
            radius: AppRadii.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap,
              vertical: AppSpacing.rowVertical,
            ),
            child: Row(
              children: [
                Icon(Icons.add, size: AppSizes.shopDotLarge, color: muted),
                const SizedBox(width: AppSpacing.gap),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.secondaryStrong.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Step 3 · Your shops', size: previewPhone)
Widget addShopStepPreview() => previewPage(const AddShopStep());
