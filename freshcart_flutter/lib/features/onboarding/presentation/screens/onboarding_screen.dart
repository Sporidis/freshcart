import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_footer.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_indicator.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_transition.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/add_shop_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/create_list_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/display_name_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/invite_step.dart';
import 'package:go_router/go_router.dart';

@Preview(group: 'Onboarding', name: 'Wizard shell', size: previewPhone)
Widget onboardingScreenPreview() => previewApp(const OnboardingScreen());

/// The onboarding wizard: your name, list name, shops, then an optional
/// invite.
///
/// Back always works. On step 1 it goes to Welcome. (Welcome opens this
/// screen with `context.go`, so there's no screen underneath to pop back
/// to. Without this, a user who tapped "Get started" by mistake would be
/// stuck.) The phone's back gesture does the same, through [PopScope].
class OnboardingScreen extends ConsumerWidget {
  final bool isInvited;
  const OnboardingScreen({super.key, this.isInvited = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = ref.watch(onboardingControllerProvider.select((s) => s.step));

    void goBack() => step == OnboardingStep.values.first
        ? context.go(Routes.welcome)
        : controller.back();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: goBack)),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingStepIndicator(step: step),
              Expanded(
                child: OnboardingStepTransition(
                  index: step.index,
                  child: switch (step) {
                    OnboardingStep.displayName => const DisplayNameStep(),
                    OnboardingStep.createList => const CreateListStep(),
                    OnboardingStep.addShop => const AddShopStep(),
                    OnboardingStep.invite => const InviteStep(),
                  },
                ),
              ),
              // No footer on step 4: it has its own two buttons ("Start my
              // list" / "I'll do this later"). The footer is for steps 1-3,
              // which have one Continue button.
              if (step != OnboardingStep.invite) const OnboardingFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
