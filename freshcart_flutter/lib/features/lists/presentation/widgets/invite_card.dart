import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/copy_to_clipboard.dart';
import 'package:freshcart_flutter/features/lists/application/invite_section/invite_section_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/open_invite_button.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list's invite: an "Invite someone" button until a member asks, then
/// the code to share and how long it keeps working.
class InviteCard extends ConsumerWidget {
  /// Creates the card for [listId].
  const InviteCard({required this.listId, required this.t, super.key});

  /// The list to invite someone to.
  final ListId listId;

  /// Translations for the active locale.
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invite = ref.watch(inviteSectionControllerProvider(listId));
    void open() =>
        ref.read(inviteSectionControllerProvider(listId).notifier).open();

    switch (invite) {
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      case AsyncData(value: Ok(:final value)):
        return _CodeCard(invite: value, t: t);
      case AsyncData(value: Err(:final failure)):
        // The button stays, so the member can try again (e.g. once back
        // online), with the reason underneath.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OpenInviteButton(onPressed: open, t: t),
            const SizedBox(height: AppSpacing.gapSmall),
            Text(
              failure.toMessage(t),
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        );
      default:
        return OpenInviteButton(onPressed: open, t: t);
    }
  }
}

/// The code with a copy button, and how many hours it keeps working.
///
/// After copying, the button shows a checkmark for 1.6 s. No snackbar,
/// because it would cover the code.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.invite, required this.t});

  final ListInvite invite;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoursLeft = invite.expiresAt.difference(DateTime.now()).inHours;
    final codeBox = Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gap,
        AppSpacing.gapSmall,
        AppSpacing.gapSmall,
        AppSpacing.gapSmall,
      ),
      // v3's translucent fill with no border, like the code boxes in
      // onboarding, so the code looks the same wherever it's shown.
      decoration: BoxDecoration(
        color: theme.colorScheme.fill,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              invite.code.value,
              style: AppTextStyles.codeLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          CopyToClipboard(
            text: invite.code.value,
            builder: (context, copied, copy) => IconButton(
              onPressed: copy,
              tooltip: t.household.copyCode,
              icon: AnimatedSwitcher(
                duration: AppMotion.durationFor(context, AppMotion.quick),
                child: copied
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('copied'),
                        // Our own success green. Not `tertiary`: in our theme
                        // that's a random colour, not green.
                        color: AppColors.success,
                      )
                    : const Icon(Icons.copy_outlined, key: ValueKey('copy')),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        codeBox,
        const SizedBox(height: AppSpacing.gapSmall),
        Text(
          t.household.validFor(n: hoursLeft),
          style: AppTextStyles.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
