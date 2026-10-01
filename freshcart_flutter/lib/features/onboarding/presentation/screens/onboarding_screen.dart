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

/// The first-list wizard: name, list, shops, then an optional invite.
///
/// Back always goes somewhere. On step 1 that is Welcome -- Welcome reaches
/// this screen with `context.go`, so there is no route underneath to pop
/// to, and without this a new user who tapped "Get started" by mistake had
/// no way back to "I have an invite code" short of killing the app. The
/// system back gesture follows the same rule through [PopScope].
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
              // Step 4 draws its own two buttons inline (design: "Start my
              // list" / "I'll do this later", both leading the same place) --
              // the shared footer is for the three steps that each have
              // exactly one way forward.
              if (step != OnboardingStep.invite) const OnboardingFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
