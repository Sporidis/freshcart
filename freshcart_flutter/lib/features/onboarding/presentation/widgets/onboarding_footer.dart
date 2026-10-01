import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_tabs_preview.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';

/// The wizard's fixed footer: Continue, and on the shops step, the "Your
/// tabs will look like this" preview above it.
///
/// Continue never hides, never disables, and never re-animates (Motion spec
/// §07: "Continue stays fixed"). It used to vanish until the current answer
/// was valid, which left a brand-new user looking at step 1 with a text
/// field and nothing to press. Now it is always there, and pressing it with
/// a bad answer is what explains what is wrong -- inline, on the field.
///
/// On the shops step the footer turns into the design's tray: one subtle
/// surface with a hairline top edge, holding the preview and the button
/// together, so the payoff sits right beside the action that commits it.
class OnboardingFooter extends ConsumerWidget {
  const OnboardingFooter({super.key});

  Future<void> _onContinue(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.read(onboardingControllerProvider);

    // Shops -> Invite is the one transition that does real work (creates
    // the list and its shops) -- every other step is a plain, synchronous
    // advance. Once that has already succeeded once (state.createdList is
    // set), Back-then-Continue must not repeat it: a second submit would
    // create a second list.
    if (state.step == OnboardingStep.addShop && state.createdList == null) {
      final result = await controller.submit();
      if (!context.mounted) return;
      switch (result) {
        case Ok():
          ref.haptic(HapticFeedback.selectionClick);
        case Err(:final failure):
          showFailureSnackBar(
            context,
            failure: failure,
            t: ref.read(translationsProvider),
          );
      }
      return;
    }
    if (controller.continueIfValid()) {
      ref.haptic(HapticFeedback.selectionClick);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final step = ref.watch(onboardingControllerProvider.select((s) => s.step));
    final isSubmitting = ref.watch(
      onboardingControllerProvider.select((s) => s.isSubmitting),
    );
    final selectedShops = ref.watch(
      onboardingControllerProvider.select((s) => s.selectedShops),
    );
    final theme = Theme.of(context);
    final isShopStep = step == OnboardingStep.addShop;
    final duration = AppMotion.durationFor(context, AppMotion.standard);

    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.enter,
      decoration: BoxDecoration(
        color: isShopStep
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface.withValues(alpha: 0),
        border: Border(
          top: BorderSide(
            color: isShopStep
                ? theme.dividerColor
                : theme.dividerColor.withValues(alpha: 0),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: duration,
            curve: AppMotion.enter,
            alignment: Alignment.bottomCenter,
            child: isShopStep
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.gap,
                      AppSpacing.screen,
                      0,
                    ),
                    child: ShopTabsPreview(shops: selectedShops, t: t),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: OnboardingPrimaryButton(
              label: t.onboarding.continueCta,
              isLoading: isSubmitting,
              onPressed: () => _onContinue(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Footer', size: Size(393, 200))
Widget onboardingFooterPreview() => previewApp(
  const Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: OnboardingFooter()),
  ),
);
