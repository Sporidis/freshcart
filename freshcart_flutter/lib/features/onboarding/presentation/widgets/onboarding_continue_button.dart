import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';
import 'package:go_router/go_router.dart';

class OnboardingContinueButton extends ConsumerWidget {
  const OnboardingContinueButton({super.key});

  static const double _footerHeight =
      AppSizes.buttonHeight + 16 + AppSpacing.screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);
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
                        if (state.step != OnboardingStep.values.last) {
                          controller.next();
                          return;
                        }
                        final result = await controller.finish();
                        if (!context.mounted) return;
                        if (result case Err(:final failure)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                failure.toMessage(
                                  ref.read(translationsProvider),
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        context.go(Routes.lists);
                      },
                      child: Text(
                        state.step == OnboardingStep.values.last
                            ? 'Finish'
                            : 'Continue',
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('hidden-button')),
        ),
      ),
    );
  }
}
