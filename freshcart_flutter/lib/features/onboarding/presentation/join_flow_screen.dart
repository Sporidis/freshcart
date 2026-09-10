import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/join_code_input.dart';
import 'package:go_router/go_router.dart';

/// Welcome's second exit: someone joining a list someone else already made,
/// rather than starting their own. Two questions (a name, a code) and a
/// beat of confirmation, then straight into the list — matching the
/// design's own "Join by code" and "Joined" frames.
class JoinFlowScreen extends ConsumerWidget {
  /// Creates the screen.
  const JoinFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final step = ref.watch(joinFlowControllerProvider.select((s) => s.step));

    return Scaffold(
      appBar: AppBar(
        leading: step == JoinFlowStep.confirmation
            ? null
            : BackButton(
                onPressed: step == JoinFlowStep.name
                    ? () => context.go(Routes.welcome)
                    : controller.back,
              ),
      ),
      body: SafeArea(
        child: switch (step) {
          JoinFlowStep.name => const _NameStep(),
          JoinFlowStep.code => const _CodeStep(),
          JoinFlowStep.confirmation => const _ConfirmationStep(),
        },
      ),
    );
  }
}

class _NameStep extends ConsumerStatefulWidget {
  const _NameStep();

  @override
  ConsumerState<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<_NameStep> {
  late final _controller = TextEditingController(
    text: ref.read(joinFlowControllerProvider).displayName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final controller = ref.read(joinFlowControllerProvider.notifier);
    final displayName = ref.watch(
      joinFlowControllerProvider.select((s) => s.displayName),
    );
    final canContinue = ref.watch(
      joinFlowControllerProvider.select((s) => s.canContinue),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.onboarding.nameTitle, style: AppTextStyles.largeTitle),
          const SizedBox(height: 8),
          Text(
            t.onboarding.nameSubtitle,
            style: AppTextStyles.secondary.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.avatarColorFor(displayName),
                foregroundColor: Colors.white,
                child: Text(
                  displayName.trim().isEmpty
                      ? '?'
                      : displayName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: controller.updateDisplayName,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: t.onboarding.namePlaceholder,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: canContinue ? controller.continueFromName : null,
              child: Text(t.onboarding.continueCta),
            ),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.join.codeTitle, style: AppTextStyles.largeTitle),
          const SizedBox(height: 8),
          Text(
            t.join.codeSubtitle,
            style: AppTextStyles.secondary.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          JoinCodeInput(
            value: state.code,
            onChanged: controller.updateCode,
            autofocus: true,
          ),
          if (state.error case final failure?) ...[
            const SizedBox(height: 8),
            Text(
              failure.toMessage(t),
              style: AppTextStyles.label.copyWith(color: AppColors.destructive),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: state.isSubmitting || !state.canContinue
                  ? null
                  : controller.submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.join.submit),
            ),
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

  @override
  void initState() {
    super.initState();
    // "A beat of payoff before the list appears" (design note) — routes on
    // automatically, the same 1.4s the "Joined" frame specifies.
    _timer = Timer(const Duration(milliseconds: 1400), () {
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
    final list = ref.watch(
      joinFlowControllerProvider.select((s) => s.joinedList),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 16),
            Text(t.join.confirmTitle, style: AppTextStyles.sheetTitle),
            const SizedBox(height: 7),
            if (list != null)
              Text(
                t.join.confirmBody(list: list.name),
                style: AppTextStyles.secondary.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Join flow', size: previewPhone)
Widget joinFlowScreenPreview() => previewApp(const JoinFlowScreen());
