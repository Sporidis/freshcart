import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/invite_card.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:go_router/go_router.dart';

/// Step 4: the new list's own join code, framed as optional in the copy
/// itself rather than only through a skip link — both its buttons lead to
/// the same place, because inviting later is exactly as easy as inviting now.
///
/// Only reachable once [OnboardingController.submit] has actually created
/// the list — this is the one step with something real to show.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.onboarding.inviteTitle, style: AppTextStyles.largeTitle),
          const SizedBox(height: 8),
          Text(
            t.onboarding.inviteSubtitle,
            style: AppTextStyles.secondary.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          if (list != null) ...[
            Text(
              t.onboarding.shareCode,
              style: AppTextStyles.label.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            InviteCard(joinCode: list.joinCode.value, t: t),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: () => context.go(Routes.lists),
              child: Text(t.onboarding.startMyList),
            ),
          ),
          const SizedBox(height: 12),
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
