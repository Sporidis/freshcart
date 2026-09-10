import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/create_list_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/display_name_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/invite_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_indicator.dart';

@Preview(group: 'Onboarding', name: 'Wizard shell', size: previewPhone)
Widget onboardingScreenPreview() => previewApp(const OnboardingScreen());

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isInvited;
  const OnboardingScreen({super.key, this.isInvited = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = ref.watch(onboardingControllerProvider.select((s) => s.step));

    // The controller is the source of truth for the step; this just makes
    // the PageView follow it instead of the other way around.
    ref.listen(onboardingControllerProvider.select((s) => s.step), (
      _,
      next,
    ) {
      _pageController.animateToPage(
        next.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: step == OnboardingStep.values.first
            ? null
            : BackButton(onPressed: controller.back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepIndicator(step: step),
            Expanded(
              child: PageView(
                controller: _pageController,
                // No user-driven scrolling — Continue/Back own navigation.
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  DisplayNameStep(),
                  CreateListStep(),
                  AddShopStep(),
                  InviteStep(),
                ],
              ),
            ),
            // Step 4 draws its own two buttons inline (design: "Start my
            // list" / "I'll do this later", both leading the same place) —
            // the shared footer below is for the three steps that each have
            // exactly one way forward.
            if (step != OnboardingStep.invite) const OnboardingContinueButton(),
          ],
        ),
      ),
    );
  }
}
