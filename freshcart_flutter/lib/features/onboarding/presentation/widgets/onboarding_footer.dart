import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:go_router/go_router.dart';

/// The bottom of the wizard: one big button (design v3).
///
/// "Continue" on steps 1-3, "Start my list" on the invite step, which opens
/// the new list. Always visible and always enabled: pressing it with a bad
/// answer shows what's wrong, under the field.
class OnboardingFooter extends ConsumerWidget {
  const OnboardingFooter({super.key});

  Future<void> _onContinue(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.read(onboardingControllerProvider);

    if (state.step == OnboardingStep.invite) {
      context.go(Routes.lists);
      return;
    }

    // Going from Shops to Invite saves everything (creates the list and
    // shops). Other steps just move on.
    // If the list already exists (the user went back and pressed Continue
    // again), don't save again, or we'd create a second list.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: OnboardingPrimaryButton(
        label: step == OnboardingStep.invite
            ? t.onboarding.startMyList
            : t.onboarding.continueCta,
        isLoading: isSubmitting,
        onPressed: () => _onContinue(context, ref),
      ),
    );
  }
}
