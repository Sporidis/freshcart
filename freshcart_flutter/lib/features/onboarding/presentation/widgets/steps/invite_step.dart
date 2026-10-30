import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/copy_to_clipboard.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/lists/application/invite_section/invite_section_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Step 4 (optional): invite others to the new list.
///
/// Design v3: once the member taps "Invite someone", the code in big boxes,
/// one character each, and a pill that copies it. "Start my list" (in the
/// footer) and Skip (in the top bar) both go to the list, because inviting
/// later is just as easy.
///
/// Only reached after [OnboardingController.submit] created the list, so
/// there is a list to invite to. No code is issued until the member asks,
/// so skipping this step leaves no unused code behind.
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
              child: _Invite(listId: list.id, t: t),
            ),
          ],
        ],
      ),
    );
  }
}

/// The invite: the "Invite someone" button until the member taps it, then
/// the code boxes, the copy pill and how long the code keeps working.
class _Invite extends ConsumerWidget {
  const _Invite({required this.listId, required this.t});

  final ListId listId;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invite = ref.watch(inviteSectionControllerProvider(listId));
    void open() =>
        ref.read(inviteSectionControllerProvider(listId).notifier).open();

    final scheme = Theme.of(context).colorScheme;
    final opened = switch (invite) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final failure = switch (invite) {
      AsyncData(value: Err(:final failure)) => failure,
      _ => null,
    };

    return Column(
      children: [
        // Empty boxes until there is a code, so nothing jumps when it
        // arrives.
        _CodeBoxes(code: opened?.code.value),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: AppMotion.durationFor(context, AppMotion.quick),
          child: opened == null
              ? _InvitePill(
                  key: const ValueKey('invite'),
                  loading: invite is AsyncLoading,
                  onTap: open,
                  t: t,
                )
              : _CopyCodePill(
                  key: const ValueKey('copy'),
                  code: opened.code.value,
                  t: t,
                ),
        ),
        const SizedBox(height: AppSpacing.gapSmall),
        if (opened != null)
          Text(
            t.household.validFor(
              n: opened.expiresAt.difference(DateTime.now()).inHours,
            ),
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        // After a failure, the reason, so the member can try again.
        else if (failure != null)
          Text(
            failure.toMessage(t),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: scheme.error),
          ),
      ],
    );
  }
}

/// The 44px pill that asks for an invite, in the theme's primary colour (so
/// it follows the shop colour). Tinted, not solid, so it doesn't compete
/// with "Start my list" in the footer. A spinner replaces the icon while
/// asking, and it can't be tapped again until the answer is in.
class _InvitePill extends StatelessWidget {
  const _InvitePill({
    required this.loading,
    required this.onTap,
    required this.t,
    super.key,
  });

  final bool loading;
  final VoidCallback onTap;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: !loading,
      child: TapTarget(
        onTap: loading ? null : onTap,
        child: Container(
          height: AppSpacing.minTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              SizedBox.square(
                dimension: 18,
                child: loading
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      )
                    : Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
              ),
              Text(
                t.household.inviteSomeone,
                style: AppTextStyles.labelStrong.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The code, one character per box (46×60, mono 24/700). Read out as the
/// whole code, not five separate letters.
///
/// Without a [code], the boxes are empty and dashed: in the design, a
/// dashed outline means "something goes here".
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.code});

  final String? code;

  static const double _width = 46;
  static const double _height = 60;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = this.code;
    if (code == null) {
      return ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            for (var i = 0; i < JoinCode.length; i++)
              CustomPaint(
                painter: DashedOutlinePainter(
                  color: scheme.outlineVariant,
                  radius: AppRadii.input,
                ),
                child: const SizedBox(width: _width, height: _height),
              ),
          ],
        ),
      );
    }
    return Semantics(
      label: code,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          for (final char in code.split(''))
            Container(
              width: _width,
              height: _height,
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
  const _CopyCodePill({required this.code, required this.t, super.key});

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
