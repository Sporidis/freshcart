import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/feedback/shake_on_error.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/fill_or_scroll.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/join_code_input.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/name_with_avatar_field.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_transition.dart';
import 'package:go_router/go_router.dart';

/// The screen for joining someone else's list with a code (the second
/// button on Welcome).
///
/// Asks for a name, then the code, shows a short "Joined!" message, then
/// opens the list.
///
/// Uses the same header, name field, button and animations as onboarding,
/// so both flows feel the same.
class JoinFlowScreen extends ConsumerWidget {
  /// Creates the screen.
  const JoinFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final step = ref.watch(joinFlowControllerProvider.select((s) => s.step));

    void goBack() => step == JoinFlowStep.name
        ? context.go(Routes.welcome)
        : controller.back();

    return PopScope(
      // There's no screen underneath to go back to (Welcome opens this
      // with `go`). On the confirmation step, back is disabled because it
      // moves on by itself.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step != JoinFlowStep.confirmation) goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: step == JoinFlowStep.confirmation
              ? null
              : BackButton(onPressed: goBack),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: OnboardingStepTransition(
            index: step.index,
            child: switch (step) {
              JoinFlowStep.name => const _NameStep(),
              JoinFlowStep.code => const _CodeStep(),
              JoinFlowStep.confirmation => const _ConfirmationStep(),
            },
          ),
        ),
      ),
    );
  }
}

class _NameStep extends ConsumerWidget {
  const _NameStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final error = ref.watch(joinFlowControllerProvider.select((s) => s.error));

    return FillOrScroll(
      padding: onboardingStepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.nameTitle,
            subtitle: t.onboarding.nameSubtitle,
          ),
          const SizedBox(height: AppSpacing.screen),
          OnboardingEntrance(
            index: 2,
            child: NameWithAvatarField(
              initialValue: ref.read(joinFlowControllerProvider).displayName,
              hintText: t.onboarding.namePlaceholder,
              onChanged: controller.updateDisplayName,
              errorText: error?.toMessage(t),
              scriptedField: ScriptedField.joinName,
            ),
          ),
          const Spacer(),
          OnboardingPrimaryButton(
            label: t.onboarding.continueCta,
            onPressed: () {
              if (controller.continueFromName()) {
                ref.haptic(HapticFeedback.selectionClick);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends ConsumerWidget {
  const _CodeStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final state = ref.watch(joinFlowControllerProvider);
    final error = state.error;
    final errorText = error?.toMessage(t);

    return FillOrScroll(
      padding: onboardingStepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.join.codeTitle,
            subtitle: t.join.codeSubtitle,
          ),
          const SizedBox(height: AppSpacing.screen),
          OnboardingEntrance(
            index: 2,
            child: ShakeOnError(
              errorText: errorText,
              // Shake for a wrong code (the user can fix it). Don't shake
              // for a network error (not their fault).
              shake: error is ValidationFailure || error is NotFoundFailure,
              child: JoinCodeInput(
                value: state.code,
                onChanged: controller.updateCode,
                hasError: error != null,
                autofocus: true,
                scriptedField: ScriptedField.joinCode,
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.durationFor(context, AppMotion.quick),
            curve: AppMotion.enter,
            alignment: Alignment.topLeft,
            child: errorText == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.gapSmall),
                    child: Text(
                      errorText,
                      style: AppTextStyles.captionStrong.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
          ),
          const Spacer(),
          OnboardingPrimaryButton(
            label: t.join.submit,
            isLoading: state.isSubmitting,
            onPressed: () async {
              final result = await controller.submit();
              if (result is Ok) ref.haptic(HapticFeedback.selectionClick);
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends ConsumerStatefulWidget {
  const _ConfirmationStep();

  @override
  ConsumerState<_ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<_ConfirmationStep> {
  Timer? _timer;

  /// Shows "Joined!" for a moment, then opens the list by itself.
  static const Duration _hold = Duration(milliseconds: 1400);

  static const double _badgeSize = 56;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, () {
      if (mounted) context.go(Routes.lists);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final list = ref.watch(
      joinFlowControllerProvider.select((s) => s.joinedList),
    );

    return Center(
      child: Padding(
        padding: onboardingStepPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A bouncy "pop" animation, because it worked.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.durationFor(context, AppMotion.bouncy),
              curve: AppMotion.curveFor(context, AppMotion.pop),
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.screen),
            OnboardingEntrance(
              index: 1,
              child: Text(
                t.join.confirmTitle,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.gapSmall),
            if (list != null)
              OnboardingEntrance(
                index: 2,
                child: Text(
                  t.join.confirmBody(list: list.name),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
