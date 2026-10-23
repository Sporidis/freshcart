import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/copy_to_clipboard.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Step 4 (optional): the new list's join code, to invite others.
///
/// Design v3: the code in big boxes, one character each, and a pill that
/// copies it. "Start my list" (in the footer) and Skip (in the top bar)
/// both go to the list, because inviting later is just as easy.
///
/// Only reached after [OnboardingController.submit] created the list, so
/// the code is real.
class InviteStep extends ConsumerWidget {
  /// Creates the step.
  const InviteStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final list = ref.watch(
      onboardingControllerProvider.select((s) => s.createdList),
    );

    return SingleChildScrollView(
      padding: onboardingStepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.inviteTitle,
            subtitle: t.onboarding.inviteSubtitle,
          ),
          if (list != null) ...[
            const SizedBox(height: 34),
            OnboardingEntrance(
              index: 2,
              child: _CodeBoxes(code: list.joinCode.value),
            ),
            const SizedBox(height: 22),
            OnboardingEntrance(
              index: 3,
              child: Center(
                child: _CopyCodePill(code: list.joinCode.value, t: t),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The code, one character per box (46×60, mono 24/700). Read out as the
/// whole code, not five separate letters.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: code,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          for (final char in code.split(''))
            Container(
              width: 46,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.fill,
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              child: Text(
                char,
                style: AppTextStyles.codeLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 44px outlined pill: "Copy code", then "Copied" with a tick for a
/// moment. No toast, so nothing covers the code (same as `InviteCard`).
class _CopyCodePill extends StatelessWidget {
  const _CopyCodePill({required this.code, required this.t});

  final String code;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CopyToClipboard(
      text: code,
      builder: (context, copied, copy) => Semantics(
        button: true,
        child: TapTarget(
          onTap: copy,
          child: Container(
            height: AppSpacing.minTapTarget,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.durationFor(context, AppMotion.quick),
              child: Row(
                key: ValueKey(copied),
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                    color: copied ? AppColors.success : scheme.onSurface,
                  ),
                  Text(
                    copied ? t.household.copied : t.onboarding.copyCode,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
