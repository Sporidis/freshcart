import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_footer.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_indicator.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_transition.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/add_shop_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/create_list_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/display_name_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/steps/invite_step.dart';
import 'package:go_router/go_router.dart';

/// The onboarding wizard: your name, list name, shops, then an optional
/// invite.
///
/// Design v3 top bar: Back on the left, the step dots in the middle, and
/// Skip on the right on the invite step (the only skippable one: the list
/// already exists by then).
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
    final t = ref.watch(translationsProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = ref.watch(onboardingControllerProvider.select((s) => s.step));
    final isInvite = step == OnboardingStep.invite;

    void goBack() => step == OnboardingStep.values.first
        ? context.go(Routes.welcome)
        : controller.back();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: goBack),
          centerTitle: true,
          title: OnboardingStepIndicator(step: step),
          actions: [
            // Kept in the tree and faded, so the dots stay centred and
            // don't jump when it appears.
            AnimatedOpacity(
              opacity: isInvite ? 1 : 0,
              duration: AppMotion.durationFor(context, AppMotion.quick),
              child: IgnorePointer(
                ignoring: !isInvite,
                child: ExcludeSemantics(
                  excluding: !isInvite,
                  child: TextButton(
                    onPressed: () => context.go(Routes.lists),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      textStyle: AppTextStyles.labelStrong,
                    ),
                    child: Text(t.onboarding.skip),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OnboardingStepTransition(
                  index: step.index,
                  child: switch (step) {
                    OnboardingStep.displayName => const DisplayNameStep(),
                    OnboardingStep.createList => const CreateListStep(
                      scriptedField: ScriptedField.onboardingListName,
                    ),
                    OnboardingStep.addShop => const AddShopStep(),
                    OnboardingStep.invite => const InviteStep(),
                  },
                ),
              ),
              const OnboardingFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
