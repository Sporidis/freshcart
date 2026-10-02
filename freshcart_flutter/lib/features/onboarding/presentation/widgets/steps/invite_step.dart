import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/invite_card.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/fill_or_scroll.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:go_router/go_router.dart';

/// Step 4 (optional): shows the new list's join code, to invite others.
///
/// Both buttons go to the same place (the list), because inviting later is
/// just as easy.
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
    final theme = Theme.of(context);

    return FillOrScroll(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sheetH,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.inviteTitle,
            subtitle: t.onboarding.inviteSubtitle,
          ),
          const SizedBox(height: AppSpacing.screen),
          if (list != null)
            OnboardingEntrance(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.onboarding.shareCode,
                    style: AppTextStyles.label.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gapSmall),
                  InviteCard(joinCode: list.joinCode.value, t: t),
                ],
              ),
            ),
          const Spacer(),
          OnboardingPrimaryButton(
            label: t.onboarding.startMyList,
            onPressed: () => context.go(Routes.lists),
          ),
          const SizedBox(height: AppSpacing.gapSmall),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.lists),
              child: Text(
                t.onboarding.doLater,
                style: AppTextStyles.secondaryStrong.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Step 4 · Invite', size: previewPhone)
Widget inviteStepPreview() => previewPage(const InviteStep());
