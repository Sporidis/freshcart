import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/copy_to_clipboard.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list's join code, with a copy button.
///
/// After copying, the button shows a checkmark for 1.6 s. No snackbar,
/// because it would cover the code.
class InviteCard extends StatelessWidget {
  /// Creates the card for [joinCode].
  const InviteCard({required this.joinCode, required this.t, super.key});

  /// The code someone types to join.
  final String joinCode;

  /// Translations for the active locale.
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              joinCode,
              style: AppTextStyles.codeLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          CopyToClipboard(
            text: joinCode,
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
  }
}
