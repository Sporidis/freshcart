import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's own header: avatar, name, and -- once the account
/// is linked -- the email securing it, plus the door into
/// [EditProfileScreen].
///
/// The email lives here and only here. It used to show in this header *and*
/// in a "Your account is secured" card right below it; now a linked account
/// has no card at all, and a small verified tick beside the address says
/// the same thing in one place.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, required this.t, super.key});

  final AsyncValue<Result<AuthUser>> user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = user.dataOrNull;
    final displayName = account?.displayName ?? '';
    final email = account?.email;
    final linked = account != null && !account.isAnonymous && email != null;

    return Row(
      children: [
        UserAvatar(
          seed: account?.id.value ?? '',
          initial: initialFor(displayName),
          photoUrl: account?.avatarPhotoUrl,
          color: account?.avatarColor,
          radius: AppSizes.avatarLarge / 2,
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: theme.textTheme.titleMedium),
              if (linked)
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: AppSizes.shopDotLarge,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.gapSmall / 2),
                    Flexible(
                      child: Text(
                        email,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // A text link in the drawer's action style (ink, bold), not a
        // default TextButton -- it is one more door, not a button competing
        // with the rows below.
        TextButton(
          onPressed: () => context.push(Routes.editProfile),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            textStyle: AppTextStyles.labelStrong,
          ),
          child: Text(t.settings.editProfile),
        ),
      ],
    );
  }
}
