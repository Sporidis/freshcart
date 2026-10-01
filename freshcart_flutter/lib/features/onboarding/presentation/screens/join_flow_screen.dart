import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/shake_on_error.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/fill_or_scroll.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/join_code_input.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/name_with_avatar_field.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_transition.dart';
import 'package:go_router/go_router.dart';

/// Welcome's second exit: someone joining a list someone else already made,
/// rather than starting their own. Two questions (a name, a code) and a
/// beat of confirmation, then straight into the list — matching the
/// design's own "Join by code" and "Joined" frames.
///
/// Shares the wizard's step header, name field, primary button and step
/// transition, so the two ways in feel like one product rather than two.
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
      // Nothing underneath to pop to (Welcome arrives here with `go`), and
      // the confirmation routes on by itself -- back there would only race
      // its own timer.
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

/// Padding every join step shares -- the same insets as the wizard's steps.
const _stepPadding = EdgeInsets.fromLTRB(
  AppSpacing.screen,
  AppSpacing.sheetH,
  AppSpacing.screen,
  AppSpacing.screen,
);

class _NameStep extends ConsumerWidget {
  const _NameStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final error = ref.watch(joinFlowControllerProvider.select((s) => s.error));

    return FillOrScroll(
      padding: _stepPadding,
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
      padding: _stepPadding,
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
              // Motion spec, error table: a mistyped or unknown code is the
              // user's to fix, so it shakes; a network failure is not their
              // mistake, so it only appears.
              shake: error is ValidationFailure || error is NotFoundFailure,
              child: JoinCodeInput(
                value: state.code,
                onChanged: controller.updateCode,
                hasError: error != null,
                autofocus: true,
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

  /// "A beat of payoff before the list appears" (design note) -- then it
  /// routes on by itself.
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
        padding: _stepPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The one moment in the flow allowed to pop: something just
            // succeeded.
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

@Preview(group: 'Onboarding', name: 'Join flow', size: previewPhone)
Widget joinFlowScreenPreview() => previewApp(const JoinFlowScreen());
