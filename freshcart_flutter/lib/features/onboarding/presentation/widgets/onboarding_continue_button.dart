import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/onboarding/application/screen/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/screen/onboarding_state.dart';

class OnboardingContinueButton extends ConsumerWidget {
  const OnboardingContinueButton({super.key});

  static const double _footerHeight =
      AppSizes.buttonHeight + 16 + AppSpacing.screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);
    final t = ref.watch(translationsProvider);
    final isShopStep = state.step == OnboardingStep.addShop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isShopStep
          ? (isDark ? AppColors.subtleDark : AppColors.subtleLight)
          : Colors.transparent,
      child: SizedBox(
        height: _footerHeight,
        child: AnimatedSwitcher(
          duration: AppMotion.bouncy,
          switchInCurve: AppMotion.pop,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: state.canContinue
              ? Padding(
                  key: const ValueKey('continue-button'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    16,
                    AppSpacing.screen,
                    AppSpacing.screen,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Shops -> Invite is the one transition that does
                        // real work (creates the list and its shops) — every
                        // other step is a plain, synchronous advance. Once
                        // that has already succeeded once (state.createdList
                        // is set), Back-then-Continue must not repeat it: a
                        // second submit would create a second list.
                        if (state.step == OnboardingStep.addShop) {
                          if (state.createdList != null) {
                            controller.next();
                            return;
                          }
                          final result = await controller.submit();
                          if (!context.mounted) return;
                          if (result case Err(:final failure)) {
                            showFailureSnackBar(
                              context,
                              failure: failure,
                              t: t,
                            );
                          }
                          return;
                        }
                        controller.next();
                      },
                      child: Text(t.onboarding.continueCta),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('hidden-button')),
        ),
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Continue button', size: Size(393, 140))
Widget onboardingContinueButtonPreview() => previewApp(
  const Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: OnboardingContinueButton(),
    ),
  ),
);
