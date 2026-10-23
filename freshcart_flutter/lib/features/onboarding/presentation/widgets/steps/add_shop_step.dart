import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker_pill.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_sheet.dart';

/// Step 3: pick your shops (design v3).
///
/// The shops are tinted `ShopPickerPill`s that wrap, the same pill used to
/// pick a shop everywhere else in the app. Picked ones go solid with a
/// tick. A dashed "+" adds a shop that isn't offered; it arrives picked.
/// Under the pills, how many are picked.
///
/// It scrolls, because users can add as many shops as they want.
class AddShopStep extends ConsumerWidget {
  const AddShopStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final picked = s.selectedShops.length;

    return SingleChildScrollView(
      padding: onboardingStepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.shopsTitle,
            subtitle: t.onboarding.shopsSubtitle,
          ),
          const SizedBox(height: 22),
          OnboardingEntrance(
            index: 2,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final shop in s.shopOptions)
                  ShopPickerPill(
                    key: ValueKey(shop.name),
                    label: shop.name,
                    color: shop.color.toColor(),
                    selected: s.isShopSelected(shop.name),
                    onTap: () => controller.toggleShop(shop.name, shop.color),
                  ),
                _AddShopPill(
                  tooltip: t.onboarding.addShop,
                  onTap: () => showAppSheet<void>(
                    context: context,
                    // Drafts aren't saved shops yet, so there's nothing to
                    // clash with; the name follows the same rule as a real
                    // shop's.
                    builder: (_) => ShopSheet(
                      shop: null,
                      siblings: const [],
                      onSave: ({required name, required color}) async {
                        switch (Shop.validateName(name)) {
                          case Err(:final failure):
                            return failure.toMessage(t);
                          case Ok():
                            controller.addShop(name, color);
                            return null;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingEntrance(
            index: 3,
            child: Text(
              picked == 0
                  ? t.onboarding.noShops
                  : t.onboarding.shopsPicked(n: picked),
              style: AppTextStyles.secondary.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed 40px circle with "+", the same size as the pills next to it.
/// Opens the add-shop sheet.
class _AddShopPill extends StatelessWidget {
  const _AddShopPill({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TapTarget(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: SizedBox.square(
          dimension: ShopPickerPill.height,
          child: CustomPaint(
            painter: DashedOutlinePainter(
              color: scheme.onSurface.withValues(alpha: .36),
              strokeWidth: 1.5,
            ),
            child: Icon(Icons.add, size: 16, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
