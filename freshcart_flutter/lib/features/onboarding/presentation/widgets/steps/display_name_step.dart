import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/name_with_avatar_field.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';

/// Step 1: the user's name. The only personal thing we ask.
class DisplayNameStep extends ConsumerWidget {
  const DisplayNameStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final error = ref.watch(
      onboardingControllerProvider.select((s) => s.error),
    );
    final t = ref.watch(translationsProvider);

    return Padding(
      padding: onboardingStepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.nameTitle,
            subtitle: t.onboarding.nameSubtitle,
          ),
          const SizedBox(height: 28),
          OnboardingEntrance(
            index: 2,
            child: NameWithAvatarField(
              initialValue: ref.read(onboardingControllerProvider).displayName,
              hintText: t.onboarding.namePlaceholder,
              onChanged: controller.updateDisplayName,
              errorText: error?.toMessage(t),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Step 1 · Your name', size: previewPhone)
Widget displayNameStepPreview() => previewPage(const DisplayNameStep());
